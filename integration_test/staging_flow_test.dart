import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finance_manager_2026/main_dev.dart' as app;

// Credentials provided for staging test
const testEmail = 'comptetechnique001@stanworld.org';
const testPassword = 'Tester=2026';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Staging Verification: Login, Renaming, Split', (tester) async {
    // 1. Launch App (using main_dev which points to staging project)
    app.main();
    await tester.pumpAndSettle();

    // 2. Login Flow
    // Check if we are already logged in (Dashboard) or need to log in (AuthGate)
    final signInFinder = find.text('Sign in');
    final textFieldFinder = find.byType(TextField);

    if (signInFinder.evaluate().isNotEmpty ||
        textFieldFinder.evaluate().isNotEmpty) {
      print("Logging in...");
      // Enter Email
      final emailField = textFieldFinder.at(0); // Assuming email is first
      await tester.enterText(emailField, testEmail);
      await tester.pump();

      // Enter Password
      final passwordField = textFieldFinder.at(1);
      await tester.enterText(passwordField, testPassword);
      await tester.pump();

      // Tap Sign In
      await tester.tap(signInFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } else {
      print("Already logged in.");
    }

    // 3. Verify Dashboard
    expect(find.text('Finance Manager'), findsOneWidget);
    expect(find.text('Mes Comptes Bancaires'), findsOneWidget);

    // 4. Verify Account Renaming (UI Check)
    // Find an edit icon
    final editIcon = find.byIcon(Icons.edit).first;
    expect(
      editIcon,
      findsOneWidget,
      reason: "Edit icon should be visible on accounts",
    );

    await tester.tap(editIcon);
    await tester.pumpAndSettle();

    // Verify Dialog
    expect(find.text('Renommer le compte'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    // 5. Verify Split Transactions (UI Check)
    // Navigate to Add Transaction
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle Transaction'), findsOneWidget);

    // Toggle Split Mode
    final splitToggle = find.byType(
      Switch,
    ); // Assuming it's the only switch or labeled
    expect(splitToggle, findsOneWidget);
    await tester.tap(splitToggle);
    await tester.pumpAndSettle();

    // Verify Split Rows appear
    expect(find.text('Ventilation'), findsOneWidget);
    expect(
      find.byIcon(Icons.add_circle_outline),
      findsOneWidget,
    ); // Add Split Row button

    // Go back
    await tester.pageBack();
    await tester.pumpAndSettle();
  });
}
