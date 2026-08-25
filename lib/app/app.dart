import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'router.dart';
import 'theme.dart';
import '../features/auth/bloc/auth_bloc.dart';

/// Root app widget — wires MaterialApp.router with the auth bloc.
class App extends StatelessWidget {
  const App({super.key, required this.authBloc});

  final AuthBloc authBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authBloc,
      child: Builder(
        builder: (context) {
          final router = AppRouter.build(context.read<AuthBloc>());
          return MaterialApp.router(
            title: 'My KES',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: router,
            builder: (context, child) {
              // Clamp text scale so layouts with grids don't break on
              // accessibility settings of 1.5x+ — still allow users to
              // opt-in via OS setting.
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.of(context)
                      .textScaler
                      .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.2),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
