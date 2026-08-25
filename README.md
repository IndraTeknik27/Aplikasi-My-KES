# My KES — KARTEKS Energy Solution Mobile App

> A production-ready Flutter mobile app for **KARTEKS Energy Solution** —
> batteries, energy products, and services — backed by the Laravel
> API at `karteks-energy-solution.test/api/v1`.

[![Flutter](https://img.shields.io/badge/Flutter-3.32-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev)
[![Laravel API](https://img.shields.io/badge/Laravel-API-red.svg)](https://laravel.com)

---

## Table of contents

1. [Overview](#overview)
2. [Features](#features)
3. [Tech stack](#tech-stack)
4. [Architecture](#architecture)
5. [Folder structure](#folder-structure)
6. [Getting started](#getting-started)
7. [Backend integration](#backend-integration)
8. [Platform configuration](#platform-configuration)
   - [Android](#android)
   - [iOS](#ios)
9. [Push notifications (FCM)](#push-notifications-fcm)
10. [Payments (Midtrans Snap)](#payments-midtrans-snap)
11. [PDF invoices](#pdf-invoices)
12. [Testing](#testing)
13. [Continuous integration](#continuous-integration)
14. [Manual smoke test](#manual-smoke-test)
15. [Code conventions](#code-conventions)
16. [Known gaps & roadmap](#known-gaps--roadmap)
17. [Troubleshooting](#troubleshooting)

---

## Overview

**My KES** is the customer-facing mobile app for KARTEKS Energy Solution.
Customers can browse the product catalog, manage their cart, place orders,
pay via Midtrans, and track deliveries — all from their phone.

The app is a **Flutter 3.x** project that talks to the existing **Laravel
10** API over REST + JSON. Authentication is handled by **Laravel Sanctum**
(Bearer token in the `Authorization` header). The Dart `dio` client adds
that token automatically from secure storage on every request.

### Who is this for

- **Customers** browsing KARTEKS products on Android or iOS.
- **Engineers** extending the app — clean architecture + BLoC make new
  features a matter of "add a feature folder, plug in its bloc."

---

## Features

| Feature | Where | Description |
|---------|-------|-------------|
| **Splash + onboarding** | `lib/app/splash_screen.dart` | Brand splash, AuthBloc decides next route |
| **Auth** | `features/auth/` | Login, register, forgot-password, reset-password, profile + password update |
| **Home** | `features/home/` | Banners, category strip, best-seller / featured / new-arrival carousels, pull-to-refresh |
| **Catalog** | `features/catalog/` | Paginated grid, search, sort menu, filter sheet (best-seller / new / featured, price range), infinite scroll |
| **Product detail** | `features/product_detail/` | Gallery PageView with indicators, price/sale display, qty stepper, variations, specs, related products |
| **Cart** | `features/cart/` | List with qty stepper, remove confirmation, coupon apply/remove, totals summary, guest-vs-logged-in banner |
| **Checkout** | `features/checkout/` | Address selection, courier/service pickers, coupon, payment method; places order, calls `/payments/initiate`, opens **Midtrans Snap**, then routes to payment-status |
| **Orders** | `features/orders/` | List, detail with tracking timeline, cancel-with-reason, confirm-delivery, **on-screen invoice** + **shareable PDF** |
| **Wishlist** | `features/wishlist/` | Grid with toggle-to-remove |
| **Profile** | `features/profile/` | Gradient header card, sections for edit/address/orders/wishlist, sign-out |
| **Push notifications** | `core/api/fcm_service.dart` | Firebase Messaging; auto-registers token to backend on login, refresh, and boot |

---

## Tech stack

| Layer | Choice |
|-------|--------|
| **Framework** | Flutter 3.32 / Dart 3.x |
| **State management** | `flutter_bloc` + `equatable` |
| **HTTP client** | `dio` with token-refresh interceptor |
| **Auth storage** | `flutter_secure_storage` (Android Keystore / iOS Keychain) |
| **Routing** | `go_router` with auth-aware `redirect` guard |
| **Networking extras** | `url_launcher` (in-app browser for Midtrans redirect) |
| **Imaging** | `cached_network_image` + `shimmer` (skeleton placeholders) |
| **PDF** | `printing` + `pdf` packages |
| **Date/money** | `intl` (Indonesian locale) |
| **Push** | `firebase_core` + `firebase_messaging` |
| **Payments** | `midtrans_sdk` (native Snap) — webview fallback when not configured |
| **Testing** | `flutter_test` + `bloc_test` + `mocktail` |

---

## Architecture

The project follows **Clean Architecture** with three concentric layers per
feature:

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation (UI)        ← Material widgets, screens        │
│  ├── BLoC                 ← state machines, events         │
│  └── widgets              ← shared UI building blocks      │
├─────────────────────────────────────────────────────────────┤
│  Domain (models)          ← immutable Dart classes         │
│  └── pure data, no Dio, no Flutter                          │
├─────────────────────────────────────────────────────────────┤
│  Data (repositories)      ← talks to ApiClient, parses     │
│  └── one repository per feature                            │
├─────────────────────────────────────────────────────────────┤
│  Core                                                         │
│  ├── api/                ← ApiClient, ApiEndpoints, FCM,   │
│  │                        Midtrans                          │
│  ├── storage/            ← SecureStorage wrapper           │
│  ├── constants/          ← AppConstants                    │
│  ├── errors/             ← (reserved)                       │
│  └── utils/              ← formatters, status labels       │
└─────────────────────────────────────────────────────────────┘
```

**Core rules**

- BLoCs never touch `ApiClient` directly — only via a repository.
- Repositories never know about screens.
- Models are pure Dart classes with `fromJson`/`toJson` and no framework
  imports (so they're reusable in tests).
- All cross-feature dependencies go through repositories, not direct
  model imports.

---

## Folder structure

```
my_kes/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml      ← perms, network config
│       ├── kotlin/com/karteks/my_kes/
│       │   ├── MainActivity.kt
│       │   └── MyKesFirebaseMessagingService.kt
│       └── res/xml/
│           └── network_security_config.xml
├── ios/
│   └── Runner/
│       ├── AppDelegate.swift        ← notification setup
│       ├── Info.plist               ← ATS, UIBackgroundModes
│       └── Runner-Bridging-Header.h
├── lib/
│   ├── main.dart                    ← boot, providers, router
│   ├── app/
│   │   ├── app.dart                  ← MaterialApp.router wiring
│   │   ├── router.dart               ← go_router + Routes constants
│   │   ├── splash_screen.dart
│   │   └── theme.dart                ← AppColors, AppSpacing, AppRadius
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart       ← singleton Dio + auth interceptor
│   │   │   ├── api_endpoints.dart    ← every backend URL
│   │   │   └── fcm_service.dart      ← push token registration
│   │   ├── payments/
│   │   │   └── midtrans_service.dart ← Snap native + webview fallback
│   │   ├── storage/
│   │   │   └── secure_storage.dart   ← token / user / cart / fcm keys
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   └── utils/
│   │       ├── formatters.dart      ← money, dates
│   │       ├── pagination.dart      ← PaginationMeta helper
│   │       └── status_labels.dart   ← Indonesian label map
│   ├── features/
│   │   ├── auth/
│   │   ├──   ├── bloc/
│   │   │   │   ├── auth_bloc.dart
│   │   │   │   ├── auth_event.dart   ← part file
│   │   │   │   └── auth_state.dart   ← part file
│   │   │   └── data/
│   │   │       └── (uses ApiClient directly)
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           ├── login_screen.dart
│   │   │           ├── register_screen.dart
│   │   │           ├── forgot_password_screen.dart
│   │   │           └── reset_password_screen.dart
│   │   ├── home/
│   │   │   ├── bloc/                 ← home_bloc + event/state
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           ├── home_screen.dart
│   │   │           └── main_shell.dart   ← bottom-nav shell
│   │   ├── catalog/
│   │   │   ├── bloc/
│   │   │   ├── data/catalog_repository.dart
│   │   │   └── presentation/screens/catalog_screen.dart
│   │   ├── cart/                     ← bloc, data, screen
│   │   ├── checkout/                 ← bloc-less, repo + screens
│   │   ├── orders/                   ← data, screens (list/detail/invoice)
│   │   ├── wishlist/                 ← data + screen
│   │   └── profile/                  ← data + screens
│   └── shared/
│       ├── widgets/
│       │   ├── common.dart           ← LoadingButton, SafeNetworkImage,
│       │   │                            StatusChip, SectionHeader,
│       │   │                            AvatarPlaceholder
│       │   ├── states.dart           ← LoadingIndicator, EmptyState,
│       │   │                            ErrorState, InlineBanner,
│       │   │                            Skeleton
│       │   └── product_card.dart     ← ProductCard (grid) + ProductTile (list)
│       └── utils/
│           └── pagination.dart
├── test/
│   ├── widget_test.dart               ← smoke test for splash
│   └── features/
│       ├── auth/auth_bloc_test.dart
│       ├── cart/cart_bloc_test.dart
│       └── catalog/catalog_bloc_test.dart
├── docs/
│   └── smoke-test.md                  ← manual test checklist
├── .github/workflows/
│   └── ci.yml                        ← analyze + test + build APK
├── pubspec.yaml
└── README.md
```

---

## Getting started

### Prerequisites

- Flutter SDK **3.32** or newer (`flutter --version`)
- Dart **3.x** (bundled with Flutter)
- Android Studio (for Android emulator / SDK) or Xcode 15+ (for iOS sim)
- **Laragon** with the `karteks-energy-solution.test` vhost running
- Git

### Install

```bash
git clone <repo-url>
cd my_kes
flutter pub get
```

### Configure the API base URL

By default the app talks to `http://karteks-energy-solution.test/api/v1`
(see `lib/core/api/api_client.dart`). For an Android emulator pointed at
a Laravel dev server running on your host, change the constant to:

```dart
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
```

For iOS simulator or a physical device on the same Wi-Fi network, use
your host machine's LAN IP, e.g. `http://192.168.1.42:8000/api/v1`.

### Run

```bash
# Pick a device first
flutter devices

# Hot-reload dev session
flutter run -d <device-id>

# Debug APK to file
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk

# Release APK
flutter build apk --release
```

---

## Backend integration

The app integrates with the Laravel API at `karteks-energy-solution.test`.
Key endpoints (see `lib/core/api/api_endpoints.dart` for the full list):

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/auth/login` | Email + password → Bearer token |
| `POST` | `/auth/register` | New account + auto-login |
| `POST` | `/auth/forgot-password` | Trigger reset email |
| `POST` | `/auth/reset-password` | Apply new password with token |
| `GET`  | `/auth/me` | Refresh current user (used at boot) |
| `GET`  | `/products` | Paginated catalog (filters/sort/search) |
| `GET`  | `/products/{slug}` | Product detail (gallery, variations) |
| `GET`  | `/products/featured` `/best-sellers` `/new-arrivals` | Homepage carousels |
| `GET`  | `/categories` `/categories/tree` | Category list for filter sheet |
| `GET`  | `/banners?position=home_top` | Homepage banner strip |
| `GET/POST/PUT/DELETE` | `/cart/...` | Guest + authenticated cart |
| `POST` | `/checkout/preview` | Validate cart, compute totals |
| `POST` | `/checkout/place-order` | Create order |
| `POST` | `/payments/orders/{n}/initiate` | Start Midtrans payment → `snap_token` |
| `GET`  | `/payments/orders/{n}/status` | Refresh from Midtrans |
| `GET`  | `/orders` `/orders/{n}` | Order history + detail |
| `POST` | `/orders/{n}/cancel` `/confirm-delivery` | Order actions |
| `GET`  | `/orders/{n}/invoice` | Invoice JSON for PDF |
| `GET/POST/DELETE` | `/addresses/...` | Address CRUD + primary flag |
| `GET/DELETE/POST` | `/wishlist/...` | Toggle wishlist |
| `POST/DELETE` | `/notifications/fcm-token` | Push token registration |

### Auth flow

```
┌────────┐  POST /auth/login    ┌─────────┐
│ Login  │ ───────────────────▶│ Laravel │ returns access_token + user
│ Screen │ ◀───────────────────│         │
└────────┘                     └─────────┘
     │
     ▼
BlocProvider reads SecureStorage.writeToken(...) so subsequent requests
auto-attach `Authorization: Bearer <token>`.

The Dio interceptor (lib/core/api/api_client.dart) automatically:
  1. Reads the token from secure storage on every request.
  2. Sends `Authorization: Bearer <token>`.
  3. On 401, calls POST /auth/refresh once and retries the original.
  4. On 401 again, wipes auth state and the router redirects to /login.

For guest carts, the X-Session-Id UUID is generated server-side and
returned in the X-Session-Id response header. The client persists it in
secure storage on first receipt.
```

### Response envelope

Every Laravel API call returns one of two shapes:

**Success envelope** (most endpoints):
```json
{ "success": true,  "message": "...", "data": <payload>, "meta": null }
```

**Validation envelope** (Laravel default, status 422):
```json
{ "message": "...", "errors": { "field": ["msg"] } }
```

The Dart client (`ApiClient._parse`) handles both, surfacing
`ApiException` with structured `fieldErrors` for forms.

---

## Platform configuration

### Android

- **Permissions** in `AndroidManifest.xml`:
  - `INTERNET` + `ACCESS_NETWORK_STATE` — for HTTP calls
  - `POST_NOTIFICATIONS` — required for push on Android 13+
- **Cleartext traffic**: scoped to `karteks-energy-solution.test`,
  `10.0.2.2` (Android emulator → host), and `localhost` via
  [network_security_config.xml](android/app/src/main/res/xml/network_security_config.xml).
  Production domains must be HTTPS.
- **FCM service entry** in the manifest (no-op until
  `google-services.json` is added — see [Push notifications](#push-notifications-fcm)).

### iOS

- **App Transport Security** in `Info.plist`:
  - Cleartext exception for `karteks-energy-solution.test` and `localhost`
    only. All other domains enforce HTTPS.
- **Background modes**: `remote-notification` and `fetch` for FCM.
- **Notification usage description**: shown to the user on the first
  push permission prompt.
- **AppDelegate** (`ios/Runner/AppDelegate.swift`) registers for remote
  notifications and assigns itself as the UNUserNotificationCenter delegate
  before Dart takes over via the firebase_messaging plugin.

---

## Push notifications (FCM)

### How it works

```
Dart side (lib/core/api/fcm_service.dart):
  1. FcmService.init() runs at app boot.
  2. Firebase.initializeApp() — requires google-services.json on Android
     and GoogleService-Info.plist on iOS.
  3. FirebaseMessaging.instance.requestPermission() asks the user.
  4. Listens to FirebaseMessaging.onTokenRefresh — every rotation pushes
     the new token to POST /notifications/fcm-token.
  5. On login (in main.dart's BlocListener<AuthBloc>), the cached FCM
     token is re-registered under the freshly-authenticated user.
  6. On logout, the token is unregistered (DELETE
     /notifications/fcm-token).

Native side:
  Android — MyKesFirebaseMessagingService is a stub that ensures the
  default notification channel exists. After google-services.json is
  added, the stub can be replaced with a full FirebaseMessagingService
  subclass for native data-message handling.

  iOS — AppDelegate.swift registers for remote notifications and
  forwards to the Dart side via the firebase_messaging plugin.
```

### One-time setup

1. Create a Firebase project in the Firebase console.
2. Add an Android app with package `com.karteks.my_kes` → download
   `google-services.json` → place at `android/app/google-services.json`.
3. Add an iOS app with bundle id `com.karteks.my_kes` → download
   `GoogleService-Info.plist` → place at `ios/Runner/`.
4. Update `MyKesFirebaseMessagingService.kt` to extend
   `FirebaseMessagingService` (commented example in the file).
5. Run on a real device — push from the Firebase console *Notifications*
   section to verify.

Until you do this, the app keeps working without push — `FcmService.init()`
swallows the Firebase init error so the rest of the app stays alive.

---

## Payments (Midtrans Snap)

The app supports two strategies, controlled by
`MidtransAppConfig.useNativeSdk` in
[lib/core/payments/midtrans_service.dart](lib/core/payments/midtrans_service.dart).

### Default — webview fallback (works without any Midtrans SDK setup)

```
CheckoutScreen._openMidtransWeb(url, orderNumber)
  → MidtransService.openRedirect(url)     ← in app
    → launchUrl(uri, mode: LaunchMode.inAppBrowserView)
    → user pays in the system browser
    → returns to /payment-status/:orderNumber
    → user can tap refresh to poll /payments/orders/{n}/status
    → webhook (payments/midtrans/notification) updates the order server-side
```

### Optional — native Snap SDK (smoother UX, requires merchant keys)

1. Get your `client_key` + `merchant_base_url` from the Midtrans dashboard.
2. In `main.dart`, after `await FcmService.init()`, add:
   ```dart
   await MidtransAppConfig.initSdk(
     clientKey: 'Mid-client-XXXX',
     merchantBaseUrl: 'https://api.sandbox.midtrans.com',
   );
   MidtransAppConfig.useNativeSdk = true;
   ```
3. `MidtransService.startPayment(snapToken)` will now render the Snap
   sheet directly on top of the Flutter app and return a structured
   `MidtransResult` via `setTransactionFinishedCallback`.

In both cases, **the backend's webhook (`/payments/midtrans/notification`)
is the source of truth** for the order status — the app only listens
locally for the user's interaction.

---

## PDF invoices

The order-invoice screen ([lib/features/orders/presentation/screens/order_invoice_screen.dart](lib/features/orders/presentation/screens/order_invoice_screen.dart))
fetches the invoice JSON from `GET /orders/{n}/invoice` and renders it
two ways:

1. **On-screen** — a clean invoice layout built with Material widgets.
2. **PDF** — tap the print icon in the AppBar to open the system print /
   share sheet. The PDF is rendered with the `pdf` package and laid out
   for printing with `Printing.layoutPdf` (`printing` package).

The renderer ([lib/features/orders/presentation/screens/invoice_pdf.dart](lib/features/orders/presentation/screens/invoice_pdf.dart))
draws header (company + invoice number), bill-to + ship-to blocks,
meta strip (order number, date, currency), items table, totals, and
footer — all styled to print cleanly on A4.

---

## Testing

13 tests cover the three core blocs and the splash widget.

```bash
flutter test                          # run everything
flutter test --coverage               # with coverage report
flutter test test/features/cart/      # one folder
```

### What is covered

| Test file | What's tested |
|-----------|---------------|
| `test/widget_test.dart` | Splash renders "My KES" + "KARTEKS Energy Solution" |
| `test/features/auth/auth_bloc_test.dart` | Login success, 401, 422 field errors, User.fromJson tolerates missing fields |
| `test/features/cart/cart_bloc_test.dart` | Load, fetch error, addItem success, applyCoupon |
| `test/features/catalog/catalog_bloc_test.dart` | Initial fetch, loadMore pagination, sort change, fetch error |

### Adding more tests

Each feature folder has its own `bloc/` + `data/` pair. To add coverage:

```dart
blocTest<MyBloc, MyState>(
  'describe scenario',
  build: () => MyBloc(repository: MyMockRepo()),
  act: (bloc) => bloc.add(MyEvent()),
  expect: () => [isA<MyState>().having((s) => s.foo, 'foo', expected)],
);
```

For widget tests, use `pumpWidget` with `MaterialApp(home: ...)`.

---

## Continuous integration

[.github/workflows/ci.yml](.github/workflows/ci.yml) runs on every push /
PR to `main`:

| Job | Steps |
|-----|-------|
| `analyze-and-test` | `flutter pub get` → `dart format --set-exit-if-changed` → `flutter analyze` → `flutter test --coverage` → upload coverage |
| `build-android` | `flutter pub get` → `flutter build apk --debug` → upload APK artifact |

Concurrency group `ci-${{ github.ref }}` cancels in-flight runs when a
new commit lands on the same branch.

To trigger on other branches, edit the workflow's `on` section.

---

## Manual smoke test

See [docs/smoke-test.md](docs/smoke-test.md) for the full 14-step
checklist. Highlights:

1. `flutter run` against a live Laravel backend.
2. Register → login → home loads → add to cart → checkout → Midtrans
   redirect → return → status screen → order detail → invoice PDF.
4. Edit profile, manage addresses, toggle wishlist, cancel order,
   confirm delivery, logout.

---

## Code conventions

- **Formatter**: `dart format` (default Flutter style). CI runs it with
  `--set-exit-if-changed` to fail builds on unformatted code.
- **Lint**: `flutter analyze` (project uses Flutter's `flutter_lints`
  ruleset). Zero issues required for merge.
- **Naming**:
  - Files: `snake_case.dart`
  - Classes: `PascalCase`
  - Variables / methods: `camelCase`
  - Constants: `camelCase` (Dart convention) or `lowerCamelCase`
- **BLoC files**: one bloc file + `*_event.dart` + `*_state.dart`
  (part files). Use `Equatable` so transitions compare cleanly in tests.
- **Models**: implement `fromJson` and `toJson` directly on the class —
  no separate parsers.
- **Imports**:
  - `package:my_kes/...` is not used; we use relative imports.
  - Cross-feature imports go through the recipient feature's `data/`
    folder (e.g. checkout imports `orders/data/order_repository.dart`).

---

## Known gaps & roadmap

| Item | Status | Note |
|------|--------|------|
| `google-services.json` / `GoogleService-Info.plist` | **Pending** | Required for actual push delivery. Without it, FCM init silently no-ops. |
| Midtrans native SDK keys | **Pending** | Set `MidtransAppConfig.useNativeSdk = true` and pass `clientKey` / `merchantBaseUrl` after obtaining them. |
| Real-device E2E smoke | **Pending** | All tests run in `flutter test` (Dart VM) without HTTP. The `docs/smoke-test.md` checklist is the manual E2E. |
| Localization | **Partial** | All user-facing strings are Indonesian; no English / i18n. Adding `flutter_localizations` + ARB files is a future task. |
| Pagination `data.data` envelope | **Partial** | Some endpoints (orders, payments/history) wrap paginated arrays in `{data, links, meta}` instead of plain `{data, meta}`. The Dart `PaginationMeta.fromInnerData` helper exists for that, but the repos currently use `fromResponse` directly. |
| Web checkout (PWA) | **Out of scope** | This is a mobile-only repo. |

---

## Troubleshooting

### "Binding has not yet been initialized"

Tests need `TestWidgetsFlutterBinding.ensureInitialized()` at the top of
`main()`. The auth bloc test already does this.

### "Failed host lookup" / API unreachable

- Android emulator: backend must be reachable via `10.0.2.2` not
  `localhost`. Adjust `ApiClient.baseUrl`.
- iOS simulator: `localhost` works.
- Physical device: use your host machine's LAN IP, and make sure both
  devices are on the same Wi-Fi.

### "The SDK rejected the request"

If you see `ApiException` with `invalid null-aware operator`, that's a
lint-vs-SDK disagreement on Dart 3.10 syntax. We've already suppressed
the `use_null_aware_elements` lint with `// ignore_for_file:` in the
four repositories that hit it.

### Midtrans sheet doesn't open

If `MidtransAppConfig.useNativeSdk = true` but you haven't called
`initSdk()` with valid keys, the SDK throws on every payment. Check
the platform logs (`flutter logs` or Android Studio Logcat).

### Push notifications don't arrive

1. Verify `google-services.json` / `GoogleService-Info.plist` are in
   place (the app intentionally keeps working without them).
2. Confirm the device token was POSTed to `/notifications/fcm-token`
   (look for it in Laravel logs).
3. Send a test from the Firebase console — make sure you're targeting
   the right package/bundle id.

---

## License

Proprietary — © KARTEKS Energy Solution. All rights reserved.

For questions about the codebase, contact the maintainers via the
KARTEKS engineering Slack channel.