// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finance_manager_2026/main_dev.dart' as app;

// Technical Account Credentials
const testEmail = 'comptetechnique001@stanworld.org';
const testPassword = 'Tester=2026';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Screen Tour & Screenshots', (tester) async {
    // 1. Launch App (Staging Environment)
    app.main();
    await tester.pumpAndSettle();

    // 2. Login Flow (if required)
    final signInFinder = find.text('Sign in');
    final emailField = find.byType(TextField);

    if (signInFinder.evaluate().isNotEmpty) {
      print("Login required. Entering credentials...");

      // Enter Email
      await tester.enterText(emailField.at(0), testEmail);
      await tester.pump();

      // Enter Password
      await tester.enterText(emailField.at(1), testPassword);
      await tester.pump();

      // Submit
      await tester.tap(signInFinder);
      await tester.pumpAndSettle(const Duration(seconds: 8));
    }

    // 3. Verify Dashboard & Screenshot
    expect(find.text('Finance Manager'), findsOneWidget);

    // Prepare for screenshot on Web (Convert HTML canvas to image)
    try {
      await binding.convertFlutterSurfaceToImage();
    } catch (e) {
      // Ignored on non-web platforms
    }

    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_dashboard');
    print("Screenshot captured: 01_dashboard");

    // 4. Navigate to Import Screen & Screenshot
    final importNav = find.byIcon(Icons.upload_file);
    if (importNav.evaluate().isNotEmpty) {
      await tester.tap(importNav);
      await tester.pumpAndSettle();

      expect(find.text('Import Transactions'), findsOneWidget);
      await binding.takeScreenshot('02_import_screen');
      print("Screenshot captured: 02_import_screen");

      // Go back
      await tester.pageBack(); // Or verify Back button
      await tester.pumpAndSettle();
    } else {
      print("Warning: Import Navigation Icon not found");
    }

    // 5. Navigate to Account Detail (First Account)
    // Finding an edit icon usually implies an Account Card is present
    final editIcon = find.byIcon(Icons.edit).first;
    if (editIcon.evaluate().isNotEmpty) {
      // Usually clicking the card itself opens detail, but let's see.
      // Or we can assume the dashboard lists accounts.
      // We'll take a screenshot of the list first (already done in dashboard).

      // Let's try to tap a "View" or "Details" if strictly defined,
      // or just accept dashboard coverage for now.
    }

    // 6. Final verification
    expect(find.text('Finance Manager'), findsOneWidget);
  });
}
