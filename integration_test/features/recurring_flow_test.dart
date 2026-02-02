import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../gherkin/bdd_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature: Recurring Transactions', () {
    testWidgets('User creates a monthly salary recurring transaction', (
      tester,
    ) async {
      await tester.givenTheAppIsRunning();

      // Note: We use the technical account for emulator/integration tests
      await tester.whenILogin(
        'comptetechnique001@stanworld.org',
        'Tester=2026',
      );

      await tester.thenIShouldSeeDashboard();

      await tester.whenINavigateToRecurring();
      await tester.thenIShouldSeeRecurringScreen();

      await tester.whenITapAddRecurring();

      await tester.whenIEnterRecurringDetails(
        label: 'Salaire Mensuel',
        amount: '3000',
      );

      await tester.whenISubmitRecurring();

      await tester.thenIShouldSeeRecurringScreen();
      // We should see the new item in the list
      expect(find.text('Salaire Mensuel'), findsOneWidget);
    });
  });
}
