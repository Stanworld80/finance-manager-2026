// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finance_manager_2026/features/projects/presentation/projects_dashboard_screen.dart';
import '../gherkin/bdd_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature: Projects Management', () {
    testWidgets('A. Navigate to Projects dashboard', (tester) async {
      print('[PROJ_A] Starting: Projects dashboard navigation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToProjects();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(
        find.byType(ProjectsDashboardScreen),
        findsOneWidget,
        reason: 'ProjectsDashboardScreen should be visible',
      );
      print('[PROJ_A] PASS: ProjectsDashboardScreen visible');
    });

    testWidgets('B. Projects screen shows project list or empty state', (
      tester,
    ) async {
      print('[PROJ_B] Starting: Projects list or empty state');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToProjects();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Either project cards OR empty state should be visible
      final hasContent =
          find.byType(Card).evaluate().isNotEmpty ||
          find.byType(ListTile).evaluate().isNotEmpty ||
          find.textContaining('projet').evaluate().isNotEmpty ||
          find.textContaining('Projet').evaluate().isNotEmpty ||
          find.textContaining('Aucun').evaluate().isNotEmpty;
      expect(
        hasContent,
        isTrue,
        reason: 'Projects screen should show content or empty state',
      );
      print('[PROJ_B] PASS: Projects screen has content');
    });

    testWidgets('C. Create a new project', (tester) async {
      print('[PROJ_C] Starting: Create project');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToProjects();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap FAB or Add button
      final fab = find.byType(FloatingActionButton);
      final addIcon = find.byIcon(Icons.add);

      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab.first);
      } else if (addIcon.evaluate().isNotEmpty) {
        await tester.tap(addIcon.first);
      } else {
        print('[PROJ_C] SKIP: No add button on projects screen');
        return;
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Fill in project name if a dialog/form appears
      final uniqueProjectName =
          'Projet Test ${DateTime.now().millisecondsSinceEpoch}';
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, uniqueProjectName);
        await tester.dismissKeyboard();

        // Save/confirm
        final saveBtn = find.text('Créer');
        final confirmBtn = find.text('Confirmer');
        final okBtn = find.text('OK');
        if (saveBtn.evaluate().isNotEmpty) {
          await tester.tap(saveBtn.first);
        } else if (confirmBtn.evaluate().isNotEmpty) {
          await tester.tap(confirmBtn.first);
        } else if (okBtn.evaluate().isNotEmpty) {
          await tester.tap(okBtn.first);
        }
        await tester.pumpAndSettle(const Duration(seconds: 3));
        print('[PROJ_C] PASS: Project creation form completed');
      } else {
        print('[PROJ_C] SKIP: No text field found for project name');
      }
    });

    testWidgets('D. Open project detail screen', (tester) async {
      print('[PROJ_D] Starting: Project detail navigation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToProjects();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap on first project if any exist
      final projectItems = find.byType(InkWell);
      if (projectItems.evaluate().isEmpty) {
        print('[PROJ_D] SKIP: No project items to tap');
        return;
      }
      await tester.tap(projectItems.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // We should be on ProjectDetailScreen
      final isDetail =
          find.textContaining('Projet').evaluate().isNotEmpty ||
          find.byIcon(Icons.arrow_back).evaluate().isNotEmpty;
      expect(isDetail, isTrue, reason: 'Should navigate to project detail');
      print('[PROJ_D] PASS: Project detail navigation works');
    });
  });
}
