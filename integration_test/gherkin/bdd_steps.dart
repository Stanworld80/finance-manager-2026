import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_manager_2026/app.dart';
import 'package:finance_manager_2026/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finance_manager_2026/features/transactions/presentation/recurring_transactions_screen.dart';

extension BddSteps on WidgetTester {
  Future<void> givenTheAppIsRunning() async {
    await pumpWidget(const ProviderScope(child: FinanceManagerApp()));
    await pumpAndSettle();
  }

  Future<void> whenILogin(String email, String password) async {
    // Basic search by type for simplicity in this example
    final textFields = find.byType(TextField);
    await enterText(textFields.at(0), email);
    await testTextInput.receiveAction(TextInputAction.next);
    await enterText(textFields.at(1), password);
    await testTextInput.receiveAction(TextInputAction.done);
    await pumpAndSettle();

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
      // Fallback
      await tap(find.byType(ElevatedButton).at(0));
    }
    await pumpAndSettle(const Duration(seconds: 2));
  }

  Future<void> thenIShouldSeeDashboard() async {
    expect(find.byType(DashboardScreen), findsOneWidget);
  }

  Future<void> whenINavigateToRecurring() async {
    // Open Drawer/Sidebar if needed, or if layout is desktop it might be visible
    // For simplicity, let's assume we use the sidebar from AppShell
    final recurringItem = find.text('Échéanciers');
    await tap(recurringItem);
    await pumpAndSettle();
  }

  Future<void> thenIShouldSeeRecurringScreen() async {
    expect(find.byType(RecurringTransactionsScreen), findsOneWidget);
  }

  Future<void> whenITapAddRecurring() async {
    await tap(find.byIcon(Icons.add));
    await pumpAndSettle();
  }

  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    bool found = false;
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) {
        found = true;
        break;
      }
    }
    if (!found) {
      throw Exception("Timed out waiting for $finder");
    }
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
    await tap(
      find.byType(DropdownMenuItem<dynamic>).last,
    ); // Usually the first user one after system ones
    await pumpAndSettle();
  }

  Future<void> whenISubmitRecurring() async {
    await tap(find.text("Créer l'échéancier"));
    await pumpAndSettle();
  }
}
