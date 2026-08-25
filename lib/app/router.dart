import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/checkout/presentation/screens/checkout_screen.dart';
import '../features/checkout/presentation/screens/payment_status_screen.dart';
import '../features/home/presentation/screens/main_shell.dart';
import '../features/orders/presentation/screens/order_detail_screen.dart';
import '../features/orders/presentation/screens/order_invoice_screen.dart';
import '../features/orders/presentation/screens/orders_screen.dart';
import '../features/product_detail/presentation/screens/product_detail_screen.dart';
import '../features/profile/presentation/screens/address_form_screen.dart';
import '../features/profile/presentation/screens/addresses_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/wishlist/presentation/screens/wishlist_screen.dart';
import 'splash_screen.dart';

/// Centralized route names. Importing this gives compile-time safety against
/// typos when calling `context.go(Routes.cart)`.
class Routes {
  Routes._();
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  static const String home = '/home';
  static const String catalog = '/catalog';
  static const String cart = '/cart';
  static const String wishlist = '/wishlist';
  static const String profile = '/profile';

  static const String productDetail = 'product';
  static const String checkout = '/checkout';
  static const String paymentStatus = '/payment-status';

  static const String orders = '/orders';
  static String orderDetail(String orderNumber) => '/orders/$orderNumber';
  static String orderInvoice(String orderNumber) =>
      '/orders/$orderNumber/invoice';

  static const String addresses = '/addresses';
  static const String editProfile = '/edit-profile';
  static String addressForm({int? id}) =>
      id == null ? '/addresses/new' : '/addresses/$id/edit';
}

class AppRouter {
  AppRouter._();

  static GoRouter build(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: Routes.splash,
      refreshListenable: _BlocRefresh(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final loc = state.matchedLocation;

        final isAuthRoute =
            loc == Routes.login ||
            loc == Routes.register ||
            loc == Routes.forgotPassword ||
            loc == Routes.resetPassword;

        if (authState is AuthLoading || authState is AuthInitial) {
          return loc == Routes.splash ? null : Routes.splash;
        }

        if (authState is AuthAuthenticated) {
          if (loc == Routes.splash || isAuthRoute) return Routes.home;
          return null;
        }

        // Unauthenticated
        if (isAuthRoute) return null;

        // Allow public catalog browse and product detail
        if (loc == Routes.home || loc == Routes.catalog || loc == Routes.cart) {
          return null;
        }

        // Anything else requires auth → login
        return Routes.login;
      },
      routes: [
        GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: Routes.register,
          builder: (_, _) => const RegisterScreen(),
        ),
        GoRoute(
          path: Routes.forgotPassword,
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: Routes.resetPassword,
          builder: (_, _) => const ResetPasswordScreen(),
        ),

        // Main shell with bottom navigation
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const MainShell(initialIndex: 0),
        ),
        GoRoute(
          path: Routes.catalog,
          builder: (_, _) => const MainShell(initialIndex: 1),
        ),
        GoRoute(
          path: Routes.cart,
          builder: (_, _) => const MainShell(initialIndex: 2),
        ),
        GoRoute(
          path: Routes.wishlist,
          builder: (_, _) => const WishlistScreen(),
        ),
        GoRoute(
          path: Routes.profile,
          builder: (_, _) => const MainShell(initialIndex: 4),
        ),

        // Feature routes
        GoRoute(
          path: '/product/:slug',
          name: Routes.productDetail,
          builder: (context, state) =>
              ProductDetailScreen(slug: state.pathParameters['slug']!),
        ),
        GoRoute(
          path: Routes.checkout,
          builder: (_, _) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '${Routes.paymentStatus}/:orderNumber',
          builder: (context, state) => PaymentStatusScreen(
            orderNumber: state.pathParameters['orderNumber']!,
          ),
        ),
        GoRoute(path: Routes.orders, builder: (_, _) => const OrdersScreen()),
        GoRoute(
          path: '/orders/:orderNumber',
          builder: (context, state) => OrderDetailScreen(
            orderNumber: state.pathParameters['orderNumber']!,
          ),
        ),
        GoRoute(
          path: '/orders/:orderNumber/invoice',
          builder: (context, state) => OrderInvoiceScreen(
            orderNumber: state.pathParameters['orderNumber']!,
          ),
        ),
        GoRoute(
          path: Routes.addresses,
          builder: (_, _) => const AddressesScreen(),
        ),
        GoRoute(
          path: Routes.editProfile,
          builder: (_, _) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/addresses/new',
          builder: (_, _) => const AddressFormScreen(),
        ),
        GoRoute(
          path: '/addresses/:id/edit',
          builder: (context, state) => AddressFormScreen(
            addressId: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Halaman tidak ditemukan: ${state.uri}')),
      ),
    );
  }
}

class _BlocRefresh extends ChangeNotifier {
  _BlocRefresh(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
