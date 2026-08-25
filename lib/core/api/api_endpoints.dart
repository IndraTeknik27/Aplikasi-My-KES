/// Single source of truth for all API endpoint paths used by My KES.
///
/// Every endpoint is relative to [ApiEndpoints.baseUrl] (defined in
/// [api_client.dart]). Combine them as:
///   `final url = ApiEndpoints.baseUrl + ApiEndpoints.login;`
class ApiEndpoints {
  ApiEndpoints._();

  // ----- Auth -----
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';
  static const String updateProfile = '/auth/profile';
  static const String updatePassword = '/auth/password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String resendVerificationEmail = '/auth/email/resend';
  static const String emailStatus = '/auth/email/status';

  // ----- Catalog (public) -----
  static const String products = '/products';
  static const String featuredProducts = '/products/featured';
  static const String bestSellers = '/products/best-sellers';
  static const String newArrivals = '/products/new-arrivals';
  static String productDetail(String slug) => '/products/$slug';
  static String relatedProducts(String slug) => '/products/$slug/related';
  static String productReviews(String slug) => '/products/$slug/reviews';

  static const String categories = '/categories';
  static const String categoriesTree = '/categories/tree';
  static String categoryDetail(String slug) => '/categories/$slug';

  static const String brands = '/brands';
  static String brandDetail(String slug) => '/brands/$slug';

  static const String banners = '/banners';
  static const String settings = '/settings';
  static const String shippingSettings = '/settings/shipping';

  // ----- Cart (guest + auth via OptionalSanctumAuth) -----
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItem(int id) => '/cart/items/$id';
  static const String cartClear = '/cart';
  static const String cartCoupon = '/cart/coupon';
  static const String cartShipping = '/cart/shipping';

  // ----- Checkout -----
  static const String checkoutPreview = '/checkout/preview';
  static const String checkoutPlace = '/checkout/place-order';
  static const String checkoutValidateStock = '/checkout/validate-stock';

  // ----- Orders -----
  static const String orders = '/orders';
  static String orderDetail(String orderNumber) => '/orders/$orderNumber';
  static String orderCancel(String orderNumber) =>
      '/orders/$orderNumber/cancel';
  static String orderConfirmDelivery(String orderNumber) =>
      '/orders/$orderNumber/confirm-delivery';
  static String orderTracking(String orderNumber) =>
      '/orders/$orderNumber/tracking';
  static String orderInvoice(String orderNumber) =>
      '/orders/$orderNumber/invoice';

  // ----- Wishlist -----
  static const String wishlist = '/wishlist';
  static const String wishlistToggle = '/wishlist/toggle';
  static const String wishlistClear = '/wishlist/clear';
  static String wishlistMoveToCart(int productId) =>
      '/wishlist/move-to-cart/$productId';

  // ----- Reviews -----
  static const String reviews = '/reviews';
  static const String myReviews = '/reviews/my';
  static String reviewDetail(int id) => '/reviews/$id';

  // ----- Profile -----
  static const String profile = '/profile';
  static const String profileAvatar = '/profile/avatar';

  // ----- Addresses -----
  static const String addresses = '/addresses';
  static String addressDetail(int id) => '/addresses/$id';
  static String addressSetPrimary(int id) => '/addresses/$id/primary';

  // ----- Payments -----
  static const String paymentsHistory = '/payments/history';
  static String paymentInitiate(String orderNumber) =>
      '/payments/orders/$orderNumber/initiate';
  static String paymentStatus(String orderNumber) =>
      '/payments/orders/$orderNumber/status';
  static String paymentRefresh(String orderNumber) =>
      '/payments/orders/$orderNumber/refresh';

  // ----- Notifications -----
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationRead(int id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationDelete(int id) => '/notifications/$id';
  static const String fcmRegister = '/notifications/fcm-token';
  static const String fcmUnregister = '/notifications/fcm-token';

  // ----- Notification preferences -----
  static const String notificationPreferences = '/notification-preferences';
  static const String notificationPreferencesReset =
      '/notification-preferences/reset-all';

  // ----- Misc public -----
  static const String shippingCalculate = '/shipping/calculate';
  static const String contactStore = '/contact';
  static const String newsletterSubscribe = '/newsletter/subscribe';

  // ----- Health -----
  static const String health = '/health';
}
