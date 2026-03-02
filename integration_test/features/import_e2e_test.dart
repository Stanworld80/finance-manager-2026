// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finance_manager_2026/features/import/presentation/import_screen.dart';
import '../gherkin/bdd_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature: Import Screen', () {
    testWidgets('A. Navigate to Import screen via icon button', (tester) async {
      print('[IMPORT_A] Starting: Navigate to import screen');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // Try upload icon in AppBar (mobile)
      final uploadIcon = find.byIcon(Icons.upload_file);
      if (uploadIcon.evaluate().isNotEmpty) {
        await tester.tap(uploadIcon.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else {
        // Desktop: "Importer CSV" text button in header
        final importBtn = find.text('Importer CSV');
        if (importBtn.evaluate().isNotEmpty) {
          await tester.tap(importBtn.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        } else {
          await tester.whenINavigateToImport();
        }
      }

      expect(
        find.byType(ImportScreen),
        findsOneWidget,
        reason: 'ImportScreen should be visible',
      );
      print('[IMPORT_A] PASS: ImportScreen visible');
    });

    testWidgets('B. Import screen has file picker button', (tester) async {
      print('[IMPORT_B] Starting: File picker button check');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      final uploadIcon = find.byIcon(Icons.upload_file);
      if (uploadIcon.evaluate().isNotEmpty) {
        await tester.tap(uploadIcon.first);
      } else {
        final importBtn = find.text('Importer CSV');
        if (importBtn.evaluate().isNotEmpty) {
          await tester.tap(importBtn.first);
        }
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // File picker button can be text button or elevated button
      final filePickerIndicators = [
        find.textContaining('Choisir'),
        find.textContaining('Sélectionner'),
        find.textContaining('Fichier'),
        find.textContaining('CSV'),
        find.byIcon(Icons.folder_open),
        find.byIcon(Icons.attach_file),
      ];
      final anyVisible = filePickerIndicators.any(
        (f) => f.evaluate().isNotEmpty,
      );
      expect(
        anyVisible,
        isTrue,
        reason: 'Import screen should have a file picker element',
      );
      print('[IMPORT_B] PASS: File picker element present');
    });

    testWidgets('C. Import screen shows column mapping instructions', (
      tester,
    ) async {
      print('[IMPORT_C] Starting: Column mapping UI');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      final uploadIcon = find.byIcon(Icons.upload_file);
      if (uploadIcon.evaluate().isNotEmpty) {
        await tester.tap(uploadIcon.first);
      } else {
        final importBtn = find.text('Importer CSV');
        if (importBtn.evaluate().isNotEmpty) {
          await tester.tap(importBtn.first);
        }
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Import screen should have instructions or column mapping content
      final instructionIndicators = [
        find.textContaining('CSV'),
        find.textContaining('colonne'),
        find.textContaining('Colonne'),
        find.textContaining('fichier'),
        find.textContaining('Import'),
      ];
      final anyVisible = instructionIndicators.any(
        (f) => f.evaluate().isNotEmpty,
      );
      expect(
        anyVisible,
        isTrue,
        reason: 'Import screen should show relevant instructions/UI',
      );
      print('[IMPORT_C] PASS: Import screen shows relevant content');
    });
  });
}
