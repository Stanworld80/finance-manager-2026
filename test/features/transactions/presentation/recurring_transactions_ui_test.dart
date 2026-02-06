import 'package:finance_manager_2026/features/accounts/data/account_providers.dart';
import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';
import 'package:finance_manager_2026/features/transactions/application/recurring_transaction_service.dart';
import 'package:finance_manager_2026/features/transactions/domain/recurring_transaction_model.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:finance_manager_2026/features/transactions/presentation/add_recurrence_page.dart';
import 'package:finance_manager_2026/features/transactions/presentation/recurrence_list_page.dart';
import 'package:finance_manager_2026/features/transactions/presentation/recurring_transaction_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'recurring_transactions_ui_test.mocks.dart';

@GenerateMocks([RecurringTransactionService, FirebaseAuth, User])
void main() {
  late MockRecurringTransactionService mockService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockService = MockRecurringTransactionService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('user1');
  });

  Widget createWidgetUnderTest(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(home: child),
    );
  }

  group('RecurrenceListPage', () {
    testWidgets('shows list of recurrences', (tester) async {
      final recurrence = RecurringTransaction(
        id: 'rec1',
        ownerId: 'user1',
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: DateTime(2026, 1, 1),
        nextOccurrence: DateTime(2026, 2, 1),
        realAccountId: 'real1',
        amount: 50.0,
        label: 'Netflix',
        type: TransactionType.debit,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          const RecurrenceListPage(),
          overrides: [
            recurringTransactionsProvider.overrideWith(
              (ref) => Stream.value([recurrence]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('50.00 €'), findsOneWidget);
      expect(find.text('Mensuel'), findsOneWidget);
    });

    testWidgets('shows empty message when no recurrences', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const RecurrenceListPage(),
          overrides: [
            recurringTransactionsProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucune récurrence définie'), findsOneWidget);
    });
  });

  group('AddRecurrencePage', () {
    final realAccount = RealAccount(
      id: 'real1',
      ownerId: 'user1',
      name: 'Main Bank',
      bankName: 'Bank',
      balance: 1000,
    );

    testWidgets('Validation errors if empty', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const AddRecurrencePage(),
          overrides: [
            realAccountsProvider.overrideWith(
              (ref) => Stream.value([realAccount]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Créer Récurrence'));
      await tester.pumpAndSettle();

      expect(find.text('Requis'), findsWidgets); // Label, Amount
    });

    testWidgets('Calls service on valid submission', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const AddRecurrencePage(),
          overrides: [
            realAccountsProvider.overrideWith(
              (ref) => Stream.value([realAccount]),
            ),
            recurringTransactionServiceProvider.overrideWith(
              (ref) => mockService,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Fill Form
      await tester.enterText(
        find.ancestor(
          of: find.text('Libellé'),
          matching: find.byType(TextFormField),
        ),
        'Gym',
      );
      await tester.enterText(
        find.ancestor(
          of: find.text('Montant'),
          matching: find.byType(TextFormField),
        ),
        '30',
      );
      // Interval defaults to 1

      await tester.tap(find.text('Créer Récurrence'));
      await tester.pumpAndSettle();

      verify(
        mockService.addRecurringTransaction(
          frequency: RecurrenceFrequency.monthly, // default
          interval: 1, // default
          startDate: anyNamed('startDate'),
          realAccountId: 'real1',
          amount: 30.0,
          label: 'Gym',
          type: TransactionType.debit, // default
          splits: anyNamed('splits'),
          endDate: anyNamed('endDate'),
        ),
      ).called(1);
    });
  });
}
