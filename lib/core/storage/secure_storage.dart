import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps secure storage (auth token, user data) and shared prefs (non-sensitive).
/// All persistence keys are centralized here so we never sprinkle string literals
/// around the codebase.
class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Keys
  static const String _kAuthToken = 'auth_token';
  static const String _kUserData = 'user_data_json';
  static const String _kCartSessionId = 'cart_session_id';
  static const String _kFcmToken = 'fcm_token';

  // Shared prefs (non-sensitive)
  static const String _kOnboardingDone = 'onboarding_done';
  static const String _kThemeMode = 'theme_mode';

  // ---------- Auth token ----------
  static Future<void> saveToken(String token) =>
      _secure.write(key: _kAuthToken, value: token);

  static Future<String?> readToken() => _secure.read(key: _kAuthToken);

  static Future<void> deleteToken() => _secure.delete(key: _kAuthToken);

  // ---------- User data (raw JSON) ----------
  static Future<void> saveUser(String userJson) =>
      _secure.write(key: _kUserData, value: userJson);

  static Future<String?> readUser() => _secure.read(key: _kUserData);

  static Future<void> deleteUser() => _secure.delete(key: _kUserData);

  // ---------- Cart session (UUID for guest carts) ----------
  static Future<void> saveCartSessionId(String id) =>
      _secure.write(key: _kCartSessionId, value: id);

  static Future<String?> readCartSessionId() =>
      _secure.read(key: _kCartSessionId);

  static Future<void> deleteCartSessionId() =>
      _secure.delete(key: _kCartSessionId);

  // ---------- FCM token (separate from auth token) ----------
  static Future<void> saveFcmToken(String token) =>
      _secure.write(key: _kFcmToken, value: token);

  static Future<String?> readFcmToken() => _secure.read(key: _kFcmToken);

  static Future<void> deleteFcmToken() => _secure.delete(key: _kFcmToken);

  // ---------- Theme ----------
  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode);
  }

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemeMode) ?? 'system';
  }

  // ---------- Onboarding ----------
  static Future<void> setOnboardingDone(bool done) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone, done);
  }

  static Future<bool> getOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingDone) ?? false;
  }

  /// Wipes everything auth-related. Used on logout.
  static Future<void> clearAuth() async {
    await deleteToken();
    await deleteUser();
    // Cart session id is intentionally preserved so the same guest cart
    // can be resumed after re-login. Call [deleteCartSessionId] explicitly
    // if you want to start fresh.
  }
}
