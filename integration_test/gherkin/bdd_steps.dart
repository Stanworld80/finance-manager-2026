import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_manager_2026/app.dart';
import 'package:finance_manager_2026/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finance_manager_2026/features/transactions/presentation/recurrence_list_page.dart';
import 'package:finance_manager_2026/features/accounts/presentation/account_detail_screen.dart';
import 'package:finance_manager_2026/features/resume/presentation/resume_screen.dart';
import 'package:finance_manager_2026/features/projects/presentation/projects_dashboard_screen.dart';
import 'package:finance_manager_2026/features/help/presentation/help_screen.dart';
import 'package:finance_manager_2026/features/import/presentation/import_screen.dart';
import 'package:finance_manager_2026/features/preferences/presentation/preferences_screen.dart';

// ─────────────────────────────────────────────
// Credentials
// ─────────────────────────────────────────────
const kTestEmail = 'comptetechnique001@stanworld.org';
const kTestPassword = 'Tester=2026';

// ─────────────────────────────────────────────
// BDD Steps Extension on WidgetTester
// ─────────────────────────────────────────────
extension BddSteps on WidgetTester {
  // ── App bootstrap ─────────────────────────
  Future<void> givenTheAppIsRunning() async {
    await pumpWidget(const ProviderScope(child: FinanceManagerApp()));
    await pumpAndSettle(const Duration(seconds: 2));
  }

  // ── Authentication ─────────────────────────
  Future<void> whenILogin(String email, String password) async {
    await pumpUntilFound(
      find.byType(TextField),
      timeout: const Duration(seconds: 8),
    );

    final textFields = find.byType(TextField);
    if (textFields.evaluate().length < 2) {
      // Maybe already logged in
      return;
    }
    await enterText(textFields.at(0), email);
    await testTextInput.receiveAction(TextInputAction.next);
    await enterText(textFields.at(1), password);
    await testTextInput.receiveAction(TextInputAction.done);
    await pump();

    // Find Sign In button (English or French)
    final signInButton = find.byWidgetPredicate(
      (w) =>
          (w is ElevatedButton || w is FilledButton) &&
          (find
                  .descendant(
                    of: find.byWidget(w),
                    matching: find.textContaining('Sign in'),
                  )
                  .evaluate()
                  .isNotEmpty ||
              find
                  .descendant(
                    of: find.byWidget(w),
                    matching: find.textContaining('Se connecter'),
                  )
                  .evaluate()
                  .isNotEmpty),
    );

    if (signInButton.evaluate().isNotEmpty) {
      await tap(signInButton.first);
    } else {
      await tap(find.byType(ElevatedButton).at(0));
    }
    await pumpAndSettle(const Duration(seconds: 5));
  }

  Future<void> whenILoginWithStaging() => whenILogin(kTestEmail, kTestPassword);

  // ── Dashboard ──────────────────────────────
  Future<void> thenIShouldSeeDashboard() async {
    expect(find.byType(DashboardScreen), findsOneWidget);
  }

  // ── Navigation helpers ─────────────────────
  /// Navigate using sidebar text label (AppShell NavigationRail/Drawer item)
  Future<void> whenINavigateTo(String label) async {
    final item = find.text(label);
    if (item.evaluate().isNotEmpty) {
      await tap(item.first);
      await pumpAndSettle(const Duration(seconds: 2));
    } else {
      // Try opening drawer first (mobile layout)
      final drawerBtn = find.byTooltip('Open navigation menu');
      if (drawerBtn.evaluate().isNotEmpty) {
        await tap(drawerBtn.first);
        await pumpAndSettle();
        await tap(find.text(label).first);
        await pumpAndSettle(const Duration(seconds: 2));
      }
    }
  }

  Future<void> whenINavigateToRecurring() => whenINavigateTo('Échéanciers');
  Future<void> whenINavigateToResume() => whenINavigateTo('Résumé');
  Future<void> whenINavigateToProjects() => whenINavigateTo('Projets');
  Future<void> whenINavigateToImport() => whenINavigateTo('Importer CSV');
  Future<void> whenINavigateToHelp() => whenINavigateTo('Aide');
  Future<void> whenINavigateToPreferences() => whenINavigateTo('Préférences');
  Future<void> whenINavigateToTransactions() => whenINavigateTo('Transactions');

  // ── Screen assertions ──────────────────────
  Future<void> thenIShouldSeeRecurringScreen() async {
    expect(find.byType(RecurrenceListPage), findsOneWidget);
  }

  Future<void> thenIShouldSeeAccountDetail() async {
    expect(find.byType(AccountDetailScreen), findsOneWidget);
  }

  Future<void> thenIShouldSeeResumeScreen() async {
    expect(find.byType(ResumeScreen), findsOneWidget);
  }

  Future<void> thenIShouldSeeProjectsScreen() async {
    expect(find.byType(ProjectsDashboardScreen), findsOneWidget);
  }

  Future<void> thenIShouldSeeImportScreen() async {
    expect(find.byType(ImportScreen), findsOneWidget);
  }

  Future<void> thenIShouldSeeHelpScreen() async {
    expect(find.byType(HelpScreen), findsOneWidget);
  }

  Future<void> thenIShouldSeePreferencesScreen() async {
    expect(find.byType(PreferencesScreen), findsOneWidget);
  }

  Future<void> thenIShouldSeeText(String text) async {
    expect(find.textContaining(text), findsWidgets);
  }

  // ── Recurring ──────────────────────────────
  Future<void> whenITapAddRecurring() async {
    await tap(find.byIcon(Icons.add));
    await pumpAndSettle();
  }

  Future<void> whenIEnterRecurringDetails({
    required String label,
    required String amount,
  }) async {
    await enterText(find.byType(TextField).at(0), amount);
    await enterText(find.byType(TextField).at(1), label);
    // Select first account in dropdown
    await tap(find.byType(DropdownButtonFormField<dynamic>).at(0));
    await pumpAndSettle();
    await tap(find.byType(DropdownMenuItem<dynamic>).last);
    await pumpAndSettle();
  }

  Future<void> whenISubmitRecurring() async {
    await tap(find.text("Créer l'échéancier"));
    await pumpAndSettle();
  }

  // ── Account creation ───────────────────────
  /// Opens "Nouveau Compte Bancaire" dialog from the dashboard desktop header
  Future<void> whenICreateAccount(String name, String balance) async {
    // Desktop: TextButton with label "Compte" in header row
    final compteBtn = find.text('Compte');
    if (compteBtn.evaluate().isNotEmpty) {
      await tap(compteBtn.first);
    } else {
      // Mobile: FAB not normally used for accounts; try create button in empty state
      final createBtn = find.text('Créer mon premier compte');
      if (createBtn.evaluate().isNotEmpty) {
        await tap(createBtn);
      }
    }
    await pumpAndSettle();
    // Fill dialog
    expect(find.text('Nouveau Compte Bancaire'), findsOneWidget);
    await enterText(find.widgetWithText(TextField, 'Nom'), name);
    await enterText(find.widgetWithText(TextField, 'Solde initial'), balance);
    await tap(find.text('Créer'));
    await pumpAndSettle(const Duration(seconds: 3));
  }

  /// Opens "Nouvelle Enveloppe" dialog from the dashboard desktop header
  Future<void> whenICreateEnvelope(String envelopeName) async {
    final envBtn = find.text('Enveloppe');
    if (envBtn.evaluate().isNotEmpty) {
      await tap(envBtn.first);
      await pumpAndSettle();
      expect(find.text('Nouvelle Enveloppe'), findsOneWidget);
      await enterText(find.widgetWithText(TextField, 'Nom'), envelopeName);
      await tap(find.text('Créer'));
      await pumpAndSettle(const Duration(seconds: 3));
    }
  }

  // ── Utilities ──────────────────────────────
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    bool found = false;
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) {
        found = true;
        break;
      }
    }
    if (!found) {
      throw Exception('Timed out waiting for: $finder');
    }
  }

  Future<void> dismissKeyboard() async {
    await testTextInput.receiveAction(TextInputAction.done);
    await pump();
  }

  /// Helper to tap the floating action button if present
  Future<void> whenITapFAB() async {
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tap(fab);
    await pumpAndSettle();
  }
}
