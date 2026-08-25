import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/api/api_client.dart';
import 'core/api/fcm_service.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/cart/bloc/cart_bloc.dart';
import 'features/cart/data/cart_repository.dart';
import 'features/catalog/bloc/catalog_bloc.dart';
import 'features/catalog/data/catalog_repository.dart';
import 'features/checkout/data/checkout_repository.dart';
import 'features/home/bloc/home_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize intl locale data BEFORE any DateFormat calls
  await initializeDateFormatting('id_ID', null);

  await FcmService.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyKesBootstrap());
}

/// Root widget. Owns the singleton ApiClient and the global blocs.
/// We use a single root because every screen needs at least the auth bloc,
/// and the cart catalog blocs need to survive navigation between tabs.
class MyKesBootstrap extends StatelessWidget {
  const MyKesBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient.instance;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => CatalogRepository(client: api)),
        RepositoryProvider(create: (_) => CartRepository(client: api)),
        RepositoryProvider(create: (_) => CheckoutRepository(client: api)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc(apiClient: api)),
          BlocProvider(
            create: (ctx) => CartBloc(repository: ctx.read<CartRepository>()),
          ),
          BlocProvider(
            create: (ctx) =>
                CatalogBloc(repository: ctx.read<CatalogRepository>()),
          ),
          BlocProvider(
            create: (ctx) => HomeBloc(repo: ctx.read<CatalogRepository>()),
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (p, c) =>
              p is AuthAuthenticated || p is AuthUnauthenticated,
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.read<CartBloc>().add(const CartLoadRequested());
              // Re-register the FCM token under the freshly-logged-in user.
              // FcmService.init() may have already done this with no auth,
              // which the backend would have rejected; this catches the
              // post-login case.
              () async {
                final cached = await SecureStorage.readFcmToken();
                if (cached != null && cached.isNotEmpty) {
                  await FcmService.registerToken(cached);
                }
              }();
            } else if (state is AuthUnauthenticated) {
              FcmService.unregister();
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (p, c) => c is AuthInitial || c is AuthUnauthenticated,
            builder: (context, state) {
              if (state is AuthInitial) {
                // Kick off the auth check
                context.read<AuthBloc>().add(const AuthCheckRequested());
                return _bootstrapApp();
              }
              return _bootstrapApp();
            },
          ),
        ),
      ),
    );
  }

  Widget _bootstrapApp() {
    return Builder(
      builder: (context) {
        final router = AppRouter.build(context.read<AuthBloc>());
        return MaterialApp.router(
          title: 'My KES',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
          builder: (context, child) {
            // Clamp text scale so layouts with grids don't break on accessibility
            // settings of 1.5x+ — still allow users to opt-in via OS setting.
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.of(context).textScaler
                    .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.2),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
