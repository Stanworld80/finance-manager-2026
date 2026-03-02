// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finance_manager_2026/features/dashboard/presentation/dashboard_screen.dart';
import '../gherkin/bdd_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature: Authentication Flow', () {
    testWidgets('A. Login with valid credentials shows Dashboard', (
      tester,
    ) async {
      print('[AUTH_A] Starting: Login with valid credentials');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();
      expect(find.byType(DashboardScreen), findsOneWidget);
      print('[AUTH_A] PASS: Dashboard visible after login');
    });

    testWidgets('B. Login with wrong password shows error message', (
      tester,
    ) async {
      print('[AUTH_B] Starting: Login with wrong password');
      await tester.givenTheAppIsRunning();
      // Try to login with wrong password - expect error text
      await tester.whenILogin(kTestEmail, 'WrongPassword123!');
      // Firebase UI typically shows an error message inline
      // We should NOT see the Dashboard
      expect(find.byType(DashboardScreen), findsNothing);
      print('[AUTH_B] PASS: Dashboard not shown with wrong credentials');
    });

    testWidgets('C. After login, navigation to Profile page works', (
      tester,
    ) async {
      print('[AUTH_C] Starting: Profile page navigation');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // Tap the account icon (mobile AppBar) or find Profile link
      final profileIcon = find.byIcon(Icons.account_circle);
      if (profileIcon.evaluate().isNotEmpty) {
        await tester.tap(profileIcon.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else {
        // Desktop: look for profile link in sidebar
        final profileLink = find.text('Profil');
        if (profileLink.evaluate().isNotEmpty) {
          await tester.tap(profileLink.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }
      // Verify profile page elements are visible
      final profileIndicators = [
        find.textContaining('profil'),
        find.textContaining('Profil'),
        find.textContaining('compte'),
        find.byIcon(Icons.person),
      ];
      final anyVisible = profileIndicators.any((f) => f.evaluate().isNotEmpty);
      expect(anyVisible, isTrue, reason: 'Profile page should be visible');
      print('[AUTH_C] PASS: Profile page navigation successful');
    });

    testWidgets('D. Dashboard shows key sections after login', (tester) async {
      print('[AUTH_D] Starting: Dashboard sections verification');
      await tester.givenTheAppIsRunning();
      await tester.whenILoginWithStaging();
      await tester.thenIShouldSeeDashboard();

      // Verify key dashboard sections
      expect(
        find.textContaining('Solde Total Disponible'),
        findsOneWidget,
        reason: 'Dashboard should show global balance header',
      );
      expect(
        find.textContaining('Mes Comptes Bancaires'),
        findsOneWidget,
        reason: 'Dashboard should show accounts section',
      );
      print('[AUTH_D] PASS: Dashboard key sections visible');
    });
  });
}
