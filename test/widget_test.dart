// Smoke test for My KES app.
//
// The full app entry point needs platform plugins (secure storage, dio HTTP,
// shared preferences) that aren't available in widget tests. The simplest
// useful smoke test is to render the splash screen, which is pure Flutter
// and exercises the Material theme configuration.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_kes/app/splash_screen.dart';
import 'package:my_kes/app/theme.dart';

void main() {
  testWidgets('Splash screen renders My KES branding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
    );
    expect(find.text('My KES'), findsOneWidget);
    expect(find.text('KARTEKS Energy Solution'), findsOneWidget);
  });
}
