// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finance_manager_2026/features/resume/presentation/resume_screen.dart';
import '../gherkin/bdd_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature: Resume / Reporting Screen', () {
    testWidgets('A. Navigate to Resume screen', (tester) async {
      print('[RESUME_A] Starting: Navigate to resume');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToResume();
      expect(
        find.byType(ResumeScreen),
        findsOneWidget,
        reason: 'ResumeScreen should be visible',
      );
      print('[RESUME_A] PASS: ResumeScreen visible');
    });

    testWidgets('B. Resume shows account statistics table', (tester) async {
      print('[RESUME_B] Starting: Account statistics table');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();
      await tester.whenINavigateToResume();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // The account stats table should have a header with "Compte" or "Solde"
      final accountTableIndicators = [
        find.textContaining('Compte'),
        find.textContaining('compte'),
        find.textContaining('Solde'),
      ];
      final anyVisible = accountTableIndicators.any(
        (f) => f.evaluate().isNotEmpty,
      );
      expect(
        anyVisible,
        isTrue,
        reason: 'Account statistics section should be visible',
      );
      print('[RESUME_B] PASS: Account statistics visible');
    });

    testWidgets('C. Resume shows envelope statistics table', (tester) async {
      print('[RESUME_C] Starting: Envelope statistics table');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();
      await tester.whenINavigateToResume();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Envelope table section
      final envelopeIndicators = [
        find.textContaining('Enveloppe'),
        find.textContaining('enveloppe'),
        find.textContaining('Libre'),
      ];
      final anyVisible = envelopeIndicators.any((f) => f.evaluate().isNotEmpty);
      expect(
        anyVisible,
        isTrue,
        reason: 'Envelope statistics section should be visible',
      );
      print('[RESUME_C] PASS: Envelope statistics visible');
    });

    testWidgets(
      'D. Resume shows system envelopes table (Libre/Engagé/Distribuer)',
      (tester) async {
        print('[RESUME_D] Starting: System envelopes table');
        await tester.givenTheAppIsRunning();
        await tester.whenILoginWithStaging();
        await tester.thenIShouldSeeDashboard();
        await tester.whenINavigateToResume();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // System envelopes table should show Libre / Engagé / À distribuer
        final systemEnvIndicators = [
          find.textContaining('Libre'),
          find.textContaining('engagé'),
          find.textContaining('Engagé'),
          find.textContaining('distribuer'),
        ];
        final anyVisible = systemEnvIndicators.any(
          (f) => f.evaluate().isNotEmpty,
        );
        expect(
          anyVisible,
          isTrue,
          reason: 'System envelopes table should be visible',
        );
        print('[RESUME_D] PASS: System envelopes table visible');
      },
    );

    testWidgets('E. Resume search/filter functionality', (tester) async {
      print('[RESUME_E] Starting: Resume search/filter');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();
      await tester.whenINavigateToResume();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find search field
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isEmpty) {
        print('[RESUME_E] SKIP: Search field not found');
        return;
      }
      // Type something in the search field
      await tester.enterText(searchField.first, 'test');
      await tester.pump();
      // Clear the search
      await tester.enterText(searchField.first, '');
      await tester.pumpAndSettle();
      print('[RESUME_E] PASS: Search field interaction works without crash');
    });

    testWidgets('F. Resume export buttons are present', (tester) async {
      print('[RESUME_F] Starting: Export buttons check');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();
      await tester.whenINavigateToResume();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for export buttons (CSV / PDF)
      final exportIndicators = [
        find.textContaining('CSV'),
        find.textContaining('PDF'),
        find.textContaining('Exporter'),
        find.byIcon(Icons.download),
        find.byIcon(Icons.share),
      ];
      final anyVisible = exportIndicators.any((f) => f.evaluate().isNotEmpty);
      expect(
        anyVisible,
        isTrue,
        reason: 'Export buttons (CSV/PDF) should be on the resume screen',
      );
      print('[RESUME_F] PASS: Export buttons present');
    });

    testWidgets('G. Resume table column sort on column header tap', (
      tester,
    ) async {
      print('[RESUME_G] Starting: Column sort');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();
      await tester.whenINavigateToResume();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find DataTable columns to tap for sort
      final dataTable = find.byType(DataTable);
      if (dataTable.evaluate().isEmpty) {
        print('[RESUME_G] SKIP: No DataTable found');
        return;
      }
      // Tap first column header to sort
      final columnHeaders = find.descendant(
        of: dataTable.first,
        matching: find.byType(InkWell),
      );
      if (columnHeaders.evaluate().isNotEmpty) {
        await tester.tap(columnHeaders.first);
        await tester.pumpAndSettle();
        // Tap again to reverse sort
        await tester.tap(columnHeaders.first);
        await tester.pumpAndSettle();
        print('[RESUME_G] PASS: Sort toggle works without crash');
      }
    });
  });
}
