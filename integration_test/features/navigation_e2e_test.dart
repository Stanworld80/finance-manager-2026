// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finance_manager_2026/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finance_manager_2026/features/transactions/presentation/recurrence_list_page.dart';
import 'package:finance_manager_2026/features/resume/presentation/resume_screen.dart';
import 'package:finance_manager_2026/features/projects/presentation/projects_dashboard_screen.dart';
import 'package:finance_manager_2026/features/help/presentation/help_screen.dart';
import 'package:finance_manager_2026/features/import/presentation/import_screen.dart';
import 'package:finance_manager_2026/features/transactions/presentation/transaction_list_page.dart';
import '../gherkin/bdd_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature: App Navigation Flows', () {
    testWidgets('A. Dashboard is default landing page after login', (
      tester,
    ) async {
      print('[NAV_A] Starting: Default landing page');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      expect(find.byType(DashboardScreen), findsOneWidget);
      print('[NAV_A] PASS: Dashboard is default landing page');
    });

    testWidgets('B. Navigate to Transactions list page', (tester) async {
      print('[NAV_B] Starting: Transactions navigation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToTransactions();

      // TransactionListPage should be visible or "Voir tout" navigation worked
      final found =
          find.byType(TransactionListPage).evaluate().isNotEmpty ||
          find.textContaining('Transaction').evaluate().isNotEmpty;
      expect(found, isTrue, reason: 'Transaction page should be visible');
      print('[NAV_B] PASS: Transactions navigation works');
    });

    testWidgets('C. Navigate to Récurrences (Echéanciers)', (tester) async {
      print('[NAV_C] Starting: Recurring navigation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToRecurring();

      expect(
        find.byType(RecurrenceListPage),
        findsOneWidget,
        reason: 'RecurrenceListPage should be visible',
      );
      print('[NAV_C] PASS: Recurring page navigation works');
    });

    testWidgets('D. Navigate to Projets', (tester) async {
      print('[NAV_D] Starting: Projects navigation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToProjects();

      final found =
          find.byType(ProjectsDashboardScreen).evaluate().isNotEmpty ||
          find.textContaining('Projet').evaluate().isNotEmpty;
      expect(found, isTrue, reason: 'Projects page should be visible');
      print('[NAV_D] PASS: Projects navigation works');
    });

    testWidgets('E. Navigate to Résumé', (tester) async {
      print('[NAV_E] Starting: Resume navigation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToResume();

      expect(
        find.byType(ResumeScreen),
        findsOneWidget,
        reason: 'ResumeScreen should be visible',
      );
      print('[NAV_E] PASS: Resume navigation works');
    });

    testWidgets('F. Navigate to Aide (Help)', (tester) async {
      print('[NAV_F] Starting: Help navigation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToHelp();

      final found =
          find.byType(HelpScreen).evaluate().isNotEmpty ||
          find.textContaining('Aide').evaluate().isNotEmpty ||
          find.textContaining('Guide').evaluate().isNotEmpty;
      expect(found, isTrue, reason: 'Help screen should be visible');
      print('[NAV_F] PASS: Help navigation works');
    });

    testWidgets('G. Navigate to Import', (tester) async {
      print('[NAV_G] Starting: Import navigation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // Try sidebar or top icon
      final importIcon = find.byIcon(Icons.upload_file);
      if (importIcon.evaluate().isNotEmpty) {
        await tester.tap(importIcon.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else {
        await tester.whenINavigateToImport();
      }

      final found =
          find.byType(ImportScreen).evaluate().isNotEmpty ||
          find.textContaining('Import').evaluate().isNotEmpty ||
          find.textContaining('Importer').evaluate().isNotEmpty;
      expect(found, isTrue, reason: 'Import screen should be visible');
      print('[NAV_G] PASS: Import navigation works');
    });

    testWidgets('H. Navigate back to Dashboard using back/home button', (
      tester,
    ) async {
      print('[NAV_H] Starting: Back navigation to Dashboard');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // Go somewhere else
      await tester.whenINavigateToResume();
      expect(find.byType(ResumeScreen), findsOneWidget);

      // Navigate back to Dashboard via sidebar '/' or back button
      await tester.whenINavigateTo('Dashboard');

      // If sidebar label not found, try back button
      if (find.byType(DashboardScreen).evaluate().isEmpty) {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      expect(
        find.byType(DashboardScreen),
        findsOneWidget,
        reason: 'Should return to Dashboard',
      );
      print('[NAV_H] PASS: Back navigation to Dashboard works');
    });
  });
}
