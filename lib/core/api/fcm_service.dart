import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'api_endpoints.dart';
import '../storage/secure_storage.dart';

/// Wires the device's FCM token to the backend's notification API.
///
/// Lifecycle:
///   1. `init()` is called once from `main.dart` after `ensureInitialized`.
///   2. On a logged-in user, `registerToken()` POSTs to /notifications/fcm-token.
///   3. The Firebase listener auto-refreshes on token rotation.
///
/// The native side (MyKesFirebaseMessagingService on Android, AppDelegate on
/// iOS) handles background message delivery. Foreground messages arrive via
/// `FirebaseMessaging.onMessage` here and are forwarded to [_messages] so
/// widgets can subscribe.
class FcmService {
  FcmService._();

  static final StreamController<RemoteMessage> _messages =
      StreamController<RemoteMessage>.broadcast();

  /// Foreground push messages. Subscribe from any widget that wants to show
  /// an in-app banner.
  static Stream<RemoteMessage> get onMessage => _messages.stream;

  static bool _initialized = false;

  /// Initialize Firebase + permission + token listeners. Safe to call
  /// multiple times — subsequent calls are no-ops.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Initialization may fail if google-services.json / GoogleService-Info.plist
      // is missing (e.g. on a fresh clone). Log and bail out so the app keeps
      // working without push.
      debugPrint('FCM init failed (google-services.json missing?): $e');
      return;
    }

    // Ask for notification permission on iOS and Android 13+.
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('FCM permission request failed: $e');
    }

    // Foreground messages.
    FirebaseMessaging.onMessage.listen(_messages.add);

    // Auto-refresh: every time Firebase rotates the token, push the new one
    // to the backend. Even if the user is logged out, we cache the token so
    // `registerToken` can retry after login.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await SecureStorage.saveFcmToken(newToken);
      await _postTokenToBackend(newToken);
    });

    // Initial token — cached or fresh.
    final cached = await SecureStorage.readFcmToken();
    if (cached != null && cached.isNotEmpty) {
      // Verify with backend in background; this is a no-op if it matches.
      unawaited(_postTokenToBackend(cached));
    }
    try {
      final fresh = await FirebaseMessaging.instance.getToken();
      if (fresh != null && fresh.isNotEmpty) {
        await SecureStorage.saveFcmToken(fresh);
        await _postTokenToBackend(fresh);
      }
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
    }
  }

  /// Register the device token with the backend. Call after login.
  static Future<void> registerToken(String fcmToken) async {
    if (fcmToken.isEmpty) return;
    await SecureStorage.saveFcmToken(fcmToken);
    await _postTokenToBackend(fcmToken);
  }

  /// Remove the device token from the backend. Call before logout to ensure
  /// the backend stops sending pushes to this device.
  static Future<void> unregister() async {
    final token = await SecureStorage.readFcmToken();
    if (token == null || token.isEmpty) return;
    try {
      final api = ApiClient.instance;
      await api.delete<dynamic>(
        ApiEndpoints.fcmUnregister,
        body: {'token': token},
      );
    } on ApiException {
      // best-effort
    }
    await SecureStorage.deleteFcmToken();
  }

  static Future<void> _postTokenToBackend(String token) async {
    try {
      final api = ApiClient.instance;
      await api.post<dynamic>(
        ApiEndpoints.fcmRegister,
        body: {'token': token, 'platform': _platform()},
      );
    } on ApiException {
      // The user is probably not logged in; the next registerToken() call
      // after login will retry.
    }
  }

  static String _platform() {
    // The backend's `fcm_tokens` table can store a single token per
    // (user, token) pair, so platform is informational only.
    return 'mobile';
  }
}
