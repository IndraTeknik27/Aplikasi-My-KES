# My KES — local run & smoke test

This is the manual smoke-test playbook for running the Flutter app against the
KARTEKS Laravel API at `http://karteks-energy-solution.test/api/v1`.

## Prerequisites

- Flutter SDK that matches `pubspec.yaml` (>= 3.13.0; tested on Flutter 3.32)
- Laragon running with the `karteks-energy-solution.test` vhost reachable
- Android emulator or USB device, or an iOS simulator

## 1. Verify the backend is reachable

```bash
curl http://karteks-energy-solution.test/api/v1/health
```

Expected: a 200 JSON with `success: true` and `data.service: karteks-energy-solution-api`.

If that doesn't work, edit `lib/core/api/api_client.dart` to point at a
different host (e.g. `http://10.0.2.2:8000/api/v1` for Android emulator
when the backend isn't on a real domain).

## 2. Resolve dependencies

```bash
flutter pub get
```

## 3. Run the app

```bash
flutter run
```

The first frame will be the splash. While the auth check runs in the
background, the splash stays. After `AuthBloc` resolves (no token stored →
unauthenticated), the router redirects to `/login`.

## 4. Smoke test checklist

Run through these in order, ticking each off as you go. Anything that fails
should be filed as a bug.

| # | Action                                            | Expected                                    |
|---|---------------------------------------------------|---------------------------------------------|
| 1 | Tap "Daftar" → fill form → submit                 | Authenticated, navigates to Home            |
| 2 | Home loads                                        | Banners, categories, best-sellers visible   |
| 3 | Tap a category card                                | Catalog tab opens                          |
| 4 | Search a product (e.g. "aki")                     | Filtered grid renders                      |
| 5 | Open a product → add to cart                      | Snackbar "Ditambahkan ke keranjang"        |
| 6 | Open cart → bump qty → apply coupon (try `HEMAT10`) | Total updates, discount line shows       |
| 7 | Tap "Checkout"                                    | Address selection shows your primary addr  |
| 8 | Pick courier/service → tap "Bayar Sekarang"      | Midtrans Snap opens (or order placed)      |
| 9 | On return, payment status shows "Menunggu..."     | Order detail reachable from orders list    |
| 10| Profile → edit name → save                        | Snackbar "Profil diperbarui"               |
| 11| Profile → Alamat → Tambah → fill → Simpan          | New address appears, primary badge correct |
| 12| Wishlist tab → tap heart on a product             | Heart fills, item appears in wishlist      |
| 13| Orders tab → open an order → tap "Batalkan"       | Cancel dialog, reason field min 5 chars    |
| 14| Logout                                            | Returns to login screen, no back nav leak  |

## 5. Where to look when something breaks

- **Network errors** — `lib/core/api/api_client.dart` (interceptor logs them
  in debug; check the device log with `flutter logs`).
- **Token refresh loop** — clear the secure storage by uninstalling the app
  and reinstalling.
- **Stale cart on a different account** — guest cart session id is stored
  in secure storage and reused after login. Wipe the app data to start
  fresh.
- **Midtrans not opening** — confirm `http://karteks-energy-solution.test`
  is reachable from the device; on emulator, the host alias must resolve.

## 6. Building release

```bash
flutter build apk --release          # Android
flutter build ios --release          # iOS
```

A debug build was verified at `build/app/outputs/flutter-apk/app-debug.apk`
during initial smoke testing.
