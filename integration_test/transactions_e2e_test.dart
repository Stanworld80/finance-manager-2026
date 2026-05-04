// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finance_manager_2026/main_dev.dart' as app;

// Credentials provided for staging test
const testEmail = 'comptetechnique001@stanworld.org';
const testPassword = 'Tester=2026';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Transactions E2E: Create, Modify, Delete', (tester) async {
    // 1. Launch App (using main_dev which points to staging project)
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 2. Login Flow (similar to staging_flow_test.dart)
    final signInFinder = find.text('Sign in');
    final textFieldFinder = find.byType(TextField);

    if (signInFinder.evaluate().isNotEmpty ||
        textFieldFinder.evaluate().isNotEmpty) {
      print("Logging in...");
      // Enter Email
      final emailField = textFieldFinder.at(0);
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

    // 3. Verify Dashboard Loads
    expect(find.text('Finance Manager'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // --- CREATE TRANSACTION ---
    print('Creating a transaction...');
    // Find the FAB to add a transaction
    final fabFinder = find.byType(FloatingActionButton);
    expect(
      fabFinder,
      findsOneWidget,
      reason: 'Dashboard should have a FAB to add transactions',
    );
    await tester.tap(fabFinder);
    await tester.pumpAndSettle();

    // Verify we are on the Add Transaction screen
    expect(find.text('Nouvelle Transaction'), findsOneWidget);

    // Fill in Amount
    final amountField = find.widgetWithText(TextFormField, 'Montant');
    expect(amountField, findsOneWidget);
    await tester.enterText(amountField, '75.50');

    // Fill in Title/Label
    final uniqueTitle =
        'Integration E2E Test ${DateTime.now().millisecondsSinceEpoch}';
    final titleField = find.widgetWithText(TextFormField, 'Titre');
    expect(titleField, findsOneWidget);
    await tester.enterText(titleField, uniqueTitle);

    // Close the keyboard if open
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Save the transaction
    final saveButton = find.text('Ajouter');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle(
      const Duration(seconds: 3),
    ); // Wait for server & navigation

    // Verify it appears in the list
    expect(
      find.text(uniqueTitle),
      findsWidgets,
      reason: 'Created transaction should be visible',
    );

    // --- MODIFY TRANSACTION ---
    print('Modifying the transaction...');
    // Tap the transaction we just created
    await tester.tap(find.text(uniqueTitle).first);
    await tester.pumpAndSettle();

    // The transaction details/edit page should be open. Let's find the save/update button
    final modifyTitle = '$uniqueTitle Modified';

    // Find the title field again, but this time it already has the text
    final editTitleField = find.widgetWithText(TextFormField, uniqueTitle);
    await tester.enterText(editTitleField, modifyTitle);

    // Attempt to save
    final updateButton = find.text(
      'Sauvegarder',
    ); // Or whatever the edit button text is
    expect(updateButton, findsOneWidget);
    await tester.tap(updateButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify it appears with the new name
    expect(
      find.text(modifyTitle),
      findsWidgets,
      reason: 'Modified transaction should be visible',
    );

    // --- DELETE TRANSACTION ---
    print('Deleting the transaction...');
    // Open the modified transaction
    await tester.tap(find.text(modifyTitle).first);
    await tester.pumpAndSettle();

    // Find Delete button (typically an IconButton with delete or text 'Supprimer')
    final deleteIcon = find.byIcon(Icons.delete);
    expect(deleteIcon, findsOneWidget);
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    // Confirm dialog
    final confirmButton = find
        .text('Supprimer')
        .last; // Usually the positive action in the dialog
    expect(confirmButton, findsOneWidget);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify it's gone
    expect(
      find.text(modifyTitle),
      findsNothing,
      reason: 'Deleted transaction should not be visible',
    );
    print('E2E Transaction test passed successfully!');
  });
}
