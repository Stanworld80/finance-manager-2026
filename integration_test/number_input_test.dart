import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finance_manager_2026/app.dart';
import 'package:finance_manager_2026/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finance_manager_2026/features/transactions/presentation/add_transaction_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Integration: Number Input Formatting', (tester) async {
    // 1. Start App
    await tester.pumpWidget(const ProviderScope(child: FinanceManagerApp()));
    await tester.pumpAndSettle();

    // 2. Login
    await tester.enterText(
      find.byType(TextField).at(0),
      'comptetechnique001@stanworld.org',
    );
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.enterText(find.byType(TextField).at(1), 'Tester=2026');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final signInButton = find.text('Sign in');
    final signInButtonFr = find.text('Se connecter');

    if (signInButton.evaluate().isNotEmpty) {
      await tester.tap(signInButton);
    } else if (signInButtonFr.evaluate().isNotEmpty) {
      await tester.tap(signInButtonFr);
    } else {
      await tester.tap(find.byType(ElevatedButton).first);
    }

    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 3. Verify on Dashboard
    expect(find.byType(DashboardScreen), findsOneWidget);

    // 4. Navigate to Add Transaction
    // Assuming there is a FloatingActionButton to add transaction
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.byType(AddTransactionPage), findsOneWidget);

    // 5. Test Number Input
    // Type "1 234,56"
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Montant Total'),
      '1 234,56',
    );
    await tester.pumpAndSettle();

    // Verify it formatted to "1234.56"
    expect(find.text('1234.56'), findsOneWidget);

    // Type "5000" (should be 5000)
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Montant Total'),
      '5000',
    );
    await tester.pumpAndSettle();
    expect(find.text('5000'), findsOneWidget);
  });
}
