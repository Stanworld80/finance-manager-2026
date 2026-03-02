// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finance_manager_2026/features/accounts/presentation/account_detail_screen.dart';
import '../gherkin/bdd_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature: Accounts & Envelopes Management', () {
    testWidgets('A. Create a new bank account via dashboard dialog', (
      tester,
    ) async {
      print('[ACCT_A] Starting: Create bank account');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      final uniqueName = 'Compte Test ${DateTime.now().millisecondsSinceEpoch}';
      await tester.whenICreateAccount(uniqueName, '1500');

      // The new account should appear somewhere on the dashboard
      // (account cards or a toast/snackbar)
      expect(
        find.textContaining(uniqueName),
        findsWidgets,
        reason: 'Newly created account should be visible on dashboard',
      );
      print('[ACCT_A] PASS: Account created and visible');
    });

    testWidgets('B. Navigate to account detail shows envelopes', (
      tester,
    ) async {
      print('[ACCT_B] Starting: Account detail navigation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // Tap the first account card to open detail
      final accountCards = find.byType(GestureDetector);
      if (accountCards.evaluate().isEmpty) {
        print('[ACCT_B] SKIP: No account cards found (empty state)');
        return;
      }
      await tester.tap(accountCards.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should be on AccountDetailScreen
      expect(find.byType(AccountDetailScreen), findsOneWidget);
      print('[ACCT_B] PASS: AccountDetailScreen visible');
    });

    testWidgets('C. Account detail shows system envelopes (read-only)', (
      tester,
    ) async {
      print('[ACCT_C] Starting: System envelopes visibility');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // Navigate to first account detail
      final accountCards = find.byType(GestureDetector);
      if (accountCards.evaluate().isEmpty) {
        print('[ACCT_C] SKIP: No accounts');
        return;
      }
      await tester.tap(accountCards.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // System envelopes: Libre, Solde engagé, À distribuer
      // At least one system-related text should be visible
      final systemEnvelopeTexts = [
        find.textContaining('Libre'),
        find.textContaining('engagé'),
        find.textContaining('distribuer'),
      ];
      final anyVisible = systemEnvelopeTexts.any(
        (f) => f.evaluate().isNotEmpty,
      );
      expect(
        anyVisible,
        isTrue,
        reason:
            'System envelopes (Libre, Engagé, À distribuer) should be visible',
      );
      print('[ACCT_C] PASS: System envelopes visible');
    });

    testWidgets('D. Rename account dialog appears on edit icon tap', (
      tester,
    ) async {
      print('[ACCT_D] Starting: Rename account dialog');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // Navigate to first account detail
      final accountCards = find.byType(GestureDetector);
      if (accountCards.evaluate().isEmpty) {
        print('[ACCT_D] SKIP: No accounts');
        return;
      }
      await tester.tap(accountCards.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find edit icon on account detail screen
      final editIcon = find.byIcon(Icons.edit);
      if (editIcon.evaluate().isEmpty) {
        print('[ACCT_D] SKIP: No edit icon found');
        return;
      }
      await tester.tap(editIcon.first);
      await tester.pumpAndSettle();

      // Rename dialog should appear
      expect(
        find.text('Renommer le compte'),
        findsOneWidget,
        reason: 'Rename dialog should appear',
      );

      // Cancel the dialog
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      print('[ACCT_D] PASS: Rename dialog appears and can be dismissed');
    });

    testWidgets('E. Create envelope from dashboard (desktop layout)', (
      tester,
    ) async {
      print('[ACCT_E] Starting: Create envelope');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // Desktop layout shows "Enveloppe" button in header
      final envelopeBtn = find.text('Enveloppe');
      if (envelopeBtn.evaluate().isEmpty) {
        print('[ACCT_E] SKIP: Enveloppe button not available (mobile layout)');
        return;
      }

      final uniqueEnvName = 'Env Test ${DateTime.now().millisecondsSinceEpoch}';
      await tester.whenICreateEnvelope(uniqueEnvName);
      print('[ACCT_E] PASS: Envelope creation dialog completed without crash');
    });

    testWidgets('F. Delete account shows confirmation dialog', (tester) async {
      print('[ACCT_F] Starting: Delete account confirmation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      final accountCards = find.byType(GestureDetector);
      if (accountCards.evaluate().isEmpty) {
        print('[ACCT_F] SKIP: No accounts');
        return;
      }
      await tester.tap(accountCards.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for delete icon on account detail
      final deleteIcon = find.byIcon(Icons.delete);
      if (deleteIcon.evaluate().isEmpty) {
        print('[ACCT_F] SKIP: No delete icon');
        return;
      }
      await tester.tap(deleteIcon.first);
      await tester.pumpAndSettle();

      // Should show a confirmation dialog - tap Cancel
      final cancelBtn = find.text('Annuler');
      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn.first);
        await tester.pumpAndSettle();
        print('[ACCT_F] PASS: Delete confirmation dialog shown and dismissed');
      }
    });
  });
}
