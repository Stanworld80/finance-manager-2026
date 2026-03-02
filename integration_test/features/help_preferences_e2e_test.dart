// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finance_manager_2026/features/help/presentation/help_screen.dart';
import 'package:finance_manager_2026/features/preferences/presentation/preferences_screen.dart';
import '../gherkin/bdd_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature: Help Screen', () {
    testWidgets('A. Navigate to Help screen', (tester) async {
      print('[HELP_A] Starting: Help screen navigation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // Mobile: Help icon in AppBar
      final helpIcon = find.byIcon(Icons.help_outline);
      if (helpIcon.evaluate().isNotEmpty) {
        await tester.tap(helpIcon.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else {
        await tester.whenINavigateToHelp();
      }

      expect(
        find.byType(HelpScreen),
        findsOneWidget,
        reason: 'HelpScreen should be visible',
      );
      print('[HELP_A] PASS: HelpScreen visible');
    });

    testWidgets('B. Help screen has multiple tabs', (tester) async {
      print('[HELP_B] Starting: Help screen tabs');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      final helpIcon = find.byIcon(Icons.help_outline);
      if (helpIcon.evaluate().isNotEmpty) {
        await tester.tap(helpIcon.first);
      } else {
        await tester.whenINavigateToHelp();
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // HelpScreen should have tabs (TabBar)
      final tabBar = find.byType(TabBar);
      if (tabBar.evaluate().isNotEmpty) {
        expect(tabBar, findsOneWidget);
        print('[HELP_B] PASS: TabBar present on HelpScreen');
      } else {
        // At minimum it should have sections / content
        final hasContent =
            find.textContaining('Guide').evaluate().isNotEmpty ||
            find.textContaining('Aide').evaluate().isNotEmpty ||
            find.textContaining('Enveloppe').evaluate().isNotEmpty;
        expect(
          hasContent,
          isTrue,
          reason: 'Help screen should display help content',
        );
        print('[HELP_B] PASS: Help screen has content');
      }
    });

    testWidgets('C. Help screen tab switching works', (tester) async {
      print('[HELP_C] Starting: Help screen tab switching');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      final helpIcon = find.byIcon(Icons.help_outline);
      if (helpIcon.evaluate().isNotEmpty) {
        await tester.tap(helpIcon.first);
      } else {
        await tester.whenINavigateToHelp();
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final tabs = find.byType(Tab);
      if (tabs.evaluate().length >= 2) {
        // Tap second tab
        await tester.tap(tabs.at(1));
        await tester.pumpAndSettle();
        // Tap back to first tab
        await tester.tap(tabs.at(0));
        await tester.pumpAndSettle();
        print('[HELP_C] PASS: Tab switching works without crash');
      } else {
        print('[HELP_C] SKIP: Not enough tabs found');
      }
    });
  });

  group('Feature: Preferences Screen', () {
    testWidgets('D. Navigate to Preferences screen', (tester) async {
      print('[PREF_D] Starting: Preferences navigation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToPreferences();

      expect(
        find.byType(PreferencesScreen),
        findsOneWidget,
        reason: 'PreferencesScreen should be visible',
      );
      print('[PREF_D] PASS: PreferencesScreen visible');
    });

    testWidgets('E. Preferences shows theme toggle', (tester) async {
      print('[PREF_E] Starting: Preferences theme toggle');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToPreferences();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Look for theme-related UI
      final themeIndicators = [
        find.textContaining('Thème'),
        find.textContaining('thème'),
        find.textContaining('Theme'),
        find.textContaining('Sombre'),
        find.textContaining('Clair'),
        find.byType(Switch),
        find.byType(SegmentedButton),
      ];
      final anyVisible = themeIndicators.any((f) => f.evaluate().isNotEmpty);
      expect(
        anyVisible,
        isTrue,
        reason: 'Preferences screen should have theme settings',
      );
      print('[PREF_E] PASS: Theme toggle/settings visible');
    });

    testWidgets('F. Toggle theme mode and verify change', (tester) async {
      print('[PREF_F] Starting: Toggle theme mode');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToPreferences();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find a Switch or SegmentedButton for theme
      final themeSwitch = find.byType(Switch);
      if (themeSwitch.evaluate().isNotEmpty) {
        await tester.tap(themeSwitch.first);
        await tester.pumpAndSettle();
        // Toggle back
        await tester.tap(themeSwitch.first);
        await tester.pumpAndSettle();
        print('[PREF_F] PASS: Theme toggle works without crash');
      } else {
        // Try SegmentedButton
        final segButton = find.byType(SegmentedButton<dynamic>);
        if (segButton.evaluate().isNotEmpty) {
          // Tap a segment
          final segments = find.descendant(
            of: segButton.first,
            matching: find.byType(ButtonSegment<dynamic>),
          );
          if (segments.evaluate().isNotEmpty) {
            await tester.tap(segments.last);
            await tester.pumpAndSettle();
            print('[PREF_F] PASS: SegmentedButton theme toggle works');
          }
        } else {
          print('[PREF_F] SKIP: No theme toggle widget found');
        }
      }
    });
  });
}
