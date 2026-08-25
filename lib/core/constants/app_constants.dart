/// Compile-time constants used across the app.
class AppConstants {
  AppConstants._();

  static const String appName = 'My KES';
  static const String appTagline = 'KARTEKS Energy Solution';
  static const String supportEmail = 'support@karteks.co.id';
  static const String supportPhone = '+62 21 1234 5678';

  // Pagination defaults (matches backend convention)
  static const int defaultPageSize = 20;

  // Storage buckets for image cache busting etc.
  static const Duration cacheStale = Duration(hours: 6);
  static const Duration connectTimeout = Duration(seconds: 20);

  // Storage keys (non-secret)
  static const String preferenceLocale = 'locale';
  static const String preferencePushEnabled = 'push_enabled';
}
