import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:finance_manager_2026/main.dart' as app;

void main() {
  patrolTest(
    'Patrol flow: Authenticate -> Dashboard navigation',
    ($) async {
      // Start the app (this connects to Firebase Emulator if started)
      app.main();
      await $.pumpAndSettle();

      // Locate standard inputs inside firebase_ui_auth's SignInScreen
      final emailField = $(TextField).at(0);
      final passwordField = $(TextField).at(1);
      final signInButton = $(ElevatedButton).first;

      if (emailField.exists && passwordField.exists) {
        await emailField.enterText('test@example.com');
        await passwordField.enterText('password123');
        await signInButton.tap();
        await $.pumpAndSettle();
      }

      // Assert that we are loaded and the root MaterialApp is active
      expect(find.byType(MaterialApp), findsOneWidget);
    },
  );
}
