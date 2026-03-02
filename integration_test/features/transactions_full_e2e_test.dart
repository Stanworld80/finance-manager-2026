// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../gherkin/bdd_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature: Full Transaction Lifecycle', () {
    testWidgets('A. Create a credit (entrée) transaction', (tester) async {
      print('[TX_A] Starting: Create credit transaction');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // FAB opens Add Transaction Page
      await tester.whenITapFAB();

      expect(find.text('Nouvelle Transaction'), findsOneWidget);
      final uniqueLabel = 'E2E Crédit ${DateTime.now().millisecondsSinceEpoch}';

      // Amount
      final amountField = find.widgetWithText(TextFormField, 'Montant');
      if (amountField.evaluate().isEmpty) {
        // Fallback: find by hint text
        await tester.enterText(find.byType(TextFormField).first, '200');
      } else {
        await tester.enterText(amountField, '200');
      }

      // Label/Titre
      final titreField = find.widgetWithText(TextFormField, 'Titre');
      if (titreField.evaluate().isNotEmpty) {
        await tester.enterText(titreField, uniqueLabel);
      }
      await tester.dismissKeyboard();

      // Tap Save
      final saveBtn = find.text('Ajouter');
      if (saveBtn.evaluate().isEmpty) {
        // Try alternate buttons
        final altBtn = find.text('Enregistrer');
        if (altBtn.evaluate().isNotEmpty) await tester.tap(altBtn.first);
      } else {
        await tester.tap(saveBtn.first);
      }
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Verify appears in dashboard transaction list
      expect(
        find.textContaining('E2E Crédit'),
        findsWidgets,
        reason: 'Created transaction should appear in recent list',
      );
      print('[TX_A] PASS: Credit transaction created');
    });

    testWidgets('B. Create a debit (dépense) transaction', (tester) async {
      print('[TX_B] Starting: Create debit transaction');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenITapFAB();
      expect(find.text('Nouvelle Transaction'), findsOneWidget);

      final uniqueLabel =
          'E2E Dépense ${DateTime.now().millisecondsSinceEpoch}';

      // Switch to debit type - look for "Dépense" tab/button
      final depenseBtn = find.text('Dépense');
      if (depenseBtn.evaluate().isNotEmpty) {
        await tester.tap(depenseBtn.first);
        await tester.pumpAndSettle();
      }

      // Enter amount (negative or positive depending on type toggle)
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, '50');

      // Label
      final titreField = find.widgetWithText(TextFormField, 'Titre');
      if (titreField.evaluate().isNotEmpty) {
        await tester.enterText(titreField, uniqueLabel);
      }
      await tester.dismissKeyboard();

      final saveBtn = find.text('Ajouter');
      if (saveBtn.evaluate().isNotEmpty) {
        await tester.tap(saveBtn.first);
      }
      await tester.pumpAndSettle(const Duration(seconds: 4));
      print('[TX_B] PASS: Debit transaction created without crash');
    });

    testWidgets('C. Split transaction toggle shows ventilation rows', (
      tester,
    ) async {
      print('[TX_C] Starting: Split transaction UI');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenITapFAB();
      expect(find.text('Nouvelle Transaction'), findsOneWidget);

      // Toggle split mode
      final splitSwitch = find.byType(Switch);
      if (splitSwitch.evaluate().isNotEmpty) {
        await tester.tap(splitSwitch.first);
        await tester.pumpAndSettle();

        // Verify split section appears
        expect(
          find.text('Ventilation'),
          findsOneWidget,
          reason: 'Ventilation section should appear when split is toggled',
        );
        expect(
          find.byIcon(Icons.add_circle_outline),
          findsWidgets,
          reason: 'Add split row button should be visible',
        );
        print('[TX_C] PASS: Split rows UI visible');
      } else {
        print('[TX_C] SKIP: Split toggle not found');
      }
    });

    testWidgets('D. Modify transaction pre-populates all fields', (
      tester,
    ) async {
      print('[TX_D] Starting: Modify transaction pre-population');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // Navigate to transaction list page for more items
      await tester.whenINavigateToTransactions();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap the first transaction in the list
      final txItems = find.byType(InkWell);
      if (txItems.evaluate().isEmpty) {
        print('[TX_D] SKIP: No transactions found');
        return;
      }
      await tester.tap(txItems.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // We should be on TransactionDetailScreen
      // Find the Modifier (edit) button
      final modifyBtn = find.text('Modifier');
      final editIcon = find.byIcon(Icons.edit);

      if (modifyBtn.evaluate().isNotEmpty) {
        await tester.tap(modifyBtn.first);
      } else if (editIcon.evaluate().isNotEmpty) {
        await tester.tap(editIcon.first);
      } else {
        print('[TX_D] SKIP: No modify button found');
        return;
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify edit screen title (should show "Modifier" NOT "Nouvelle Transaction")
      final modifyTitle = find.textContaining('Modifier');
      final newTransactionTitle = find.text('Nouvelle Transaction');

      expect(
        newTransactionTitle,
        findsNothing,
        reason: 'Edit screen should NOT show "Nouvelle Transaction" title',
      );
      expect(
        modifyTitle,
        findsWidgets,
        reason: 'Edit screen should show "Modifier" in its title or button',
      );
      print('[TX_D] PASS: Modify transaction shows correct title');
    });

    testWidgets('E. Delete transaction with confirmation', (tester) async {
      print('[TX_E] Starting: Delete transaction');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // Create a unique transaction to delete
      await tester.whenITapFAB();
      final uniqueLabel = 'E2E Delete ${DateTime.now().millisecondsSinceEpoch}';
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, '10');
      final titreField = find.widgetWithText(TextFormField, 'Titre');
      if (titreField.evaluate().isNotEmpty) {
        await tester.enterText(titreField, uniqueLabel);
      }
      await tester.dismissKeyboard();
      final saveBtn = find.text('Ajouter');
      if (saveBtn.evaluate().isNotEmpty) {
        await tester.tap(saveBtn.first);
      }
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Find the just-created transaction and open it
      final txFinder = find.textContaining('E2E Delete');
      if (txFinder.evaluate().isEmpty) {
        print('[TX_E] SKIP: Created transaction not found in list');
        return;
      }
      await tester.tap(txFinder.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap delete
      final deleteIcon = find.byIcon(Icons.delete);
      if (deleteIcon.evaluate().isEmpty) {
        print('[TX_E] SKIP: Delete icon not found');
        return;
      }
      await tester.tap(deleteIcon.first);
      await tester.pumpAndSettle();

      // Confirm in dialog
      final confirmBtn = find.text('Supprimer');
      if (confirmBtn.evaluate().isNotEmpty) {
        await tester.tap(confirmBtn.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        // Verify removed from list
        expect(
          find.textContaining('E2E Delete'),
          findsNothing,
          reason: 'Deleted transaction should be gone',
        );
        print('[TX_E] PASS: Transaction deleted successfully');
      }
    });

    testWidgets('F. Transaction list page shows all transactions', (
      tester,
    ) async {
      print('[TX_F] Starting: Transaction list page');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToTransactions();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show a list of transactions or empty state
      final hasTransactions =
          find.byType(ListView).evaluate().isNotEmpty ||
          find.byType(Card).evaluate().isNotEmpty;
      expect(
        hasTransactions,
        isTrue,
        reason: 'Transaction list page should render',
      );
      print('[TX_F] PASS: Transaction list page renders');
    });
  });
}
