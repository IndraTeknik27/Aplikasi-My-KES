/// Midtrans Snap integration. Two strategies are supported:
///
/// 1. **Native SDK** (preferred when configured) — instantiates the
///    SnapKit/WebKit sheet on top of the Flutter app and returns the
///    final transaction status without leaving the app.
/// 2. **Webview fallback** — opens the Snap `redirect_url` in an
///    in-app browser, then routes to the payment-status screen so the
///    user can refresh.
///
/// The chosen strategy is gated by [MidtransAppConfig.useNativeSdk]. Flip it
/// to `true` once the merchant server key is provisioned and the SDK is
/// initialized (see [MidtransAppConfig.initSdk]).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart' as mtsdk;
import 'package:url_launcher/url_launcher.dart';

/// Status returned by [MidtransService.startPayment] once the user
/// dismisses or completes the Snap sheet.
enum MidtransResult {
  /// User completed the flow (settlement/capture reached).
  success,

  /// User dismissed or cancelled.
  cancelled,

  /// Network or SDK error — surface the message to the user.
  failed,
}

/// App-level wrapper around the Midtrans SDK. Lives outside the SDK so
/// callers don't have to import `package:midtrans_sdk` directly.
class MidtransAppConfig {
  MidtransAppConfig._();

  /// Set to `true` to use the native Snap sheet. Keep `false` until the
  /// SDK has been initialized with a valid `client_key` + `merchant_base_url`
  /// (see [initSdk] below). The webview fallback is reliable even before
  /// the SDK is configured.
  static bool useNativeSdk = false;

  /// Initialize the native Snap SDK. Call once after login (or app boot)
  /// when [useNativeSdk] is true. The keys come from your Midtrans
  /// dashboard.
  static Future<void> initSdk({
    required String clientKey,
    required String merchantBaseUrl,
    String language = 'id',
    bool enableLog = false,
  }) async {
    if (!useNativeSdk) return;
    try {
      await mtsdk.MidtransSDK.init(
        config: mtsdk.MidtransConfig(
          clientKey: clientKey,
          merchantBaseUrl: merchantBaseUrl,
          language: language,
          enableLog: enableLog,
        ),
      );
    } catch (e) {
      debugPrint('Midtrans SDK init failed: $e');
    }
  }
}

class MidtransService {
  MidtransService._();

  /// Launch the Midtrans Snap flow. Returns once the user closes the sheet
  /// (or, for the webview fallback, once they navigate back to the app).
  ///
  /// - `snapToken` — opaque token from `POST /payments/.../initiate`.
  static Future<MidtransResult> startPayment(String snapToken) async {
    if (!MidtransAppConfig.useNativeSdk) {
      // Caller should pass the redirect URL directly via [openRedirect]
      // when running with the webview fallback. Returning `failed` here
      // makes it obvious in logs that the missing config was hit.
      return MidtransResult.failed;
    }
    return _startPaymentNative(snapToken);
  }

  static Future<MidtransResult> _startPaymentNative(String snapToken) async {
    final completer = Completer<MidtransResult>();

    try {
      mtsdk.MidtransSDK().setTransactionFinishedCallback((result) {
        if (completer.isCompleted) return;
        switch (result.status.toLowerCase()) {
          case 'capture':
          case 'settlement':
            completer.complete(MidtransResult.success);
            break;
          case 'cancel':
          case 'expire':
          case 'failure':
          case 'deny':
            completer.complete(MidtransResult.cancelled);
            break;
          default:
            completer.complete(MidtransResult.failed);
        }
      });

      await mtsdk.MidtransSDK().startPaymentUiFlow(token: snapToken);
      // If `startPaymentUiFlow` returns without the callback firing, treat
      // it as a cancellation (the user closed the sheet).
      if (!completer.isCompleted) {
        completer.complete(MidtransResult.cancelled);
      }
    } catch (e) {
      debugPrint('Midtrans native payment failed: $e');
      if (!completer.isCompleted) completer.complete(MidtransResult.failed);
    }

    return completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () => MidtransResult.cancelled,
    );
  }

  /// Webview fallback. Opens the redirect URL in an in-app browser and
  /// returns success — the actual payment status is reflected via the
  /// backend webhook and refreshed on the payment-status screen.
  static Future<MidtransResult> openRedirect(String redirectUrl) async {
    final uri = Uri.parse(redirectUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!launched) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return MidtransResult.success;
  }
}
