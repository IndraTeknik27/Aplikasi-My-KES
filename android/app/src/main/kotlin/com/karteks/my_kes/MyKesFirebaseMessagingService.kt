package com.karteks.my_kes

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

/**
 * Background notification handler entry point.
 *
 * The Flutter `firebase_messaging` plugin handles most FCM work for us, but
 * we still need to register a service in the manifest so the system can
 * deliver data messages and refresh tokens. This class is a minimal stub
 * that satisfies that registration without requiring a full
 * FirebaseMessagingService subclass (which would need the Firebase SDK
 * on the classpath via google-services.json).
 *
 * If you later add google-services.json and the firebase-messaging Android
 * SDK explicitly, you can replace this with:
 *
 * ```kotlin
 * class MyKesFirebaseMessagingService : FirebaseMessagingService() {
 *     override fun onNewToken(token: String) { ... }
 *     override fun onMessageReceived(message: RemoteMessage) { ... }
 * }
 * ```
 *
 * For the current release (no google-services.json provisioned), the Dart
 * side handles token registration via `FcmService.init()` in main.dart.
 */
class MyKesFirebaseMessagingService {

    companion object {
        private const val CHANNEL_ID = "my_kes_default"
        private const val CHANNEL_NAME = "My KES Notifications"

        /** Ensure the default notification channel exists (Android 8+). */
        @JvmStatic
        fun ensureChannel(notificationManager: NotificationManager) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_DEFAULT,
                )
                notificationManager.createNotificationChannel(channel)
            }
        }
    }
}