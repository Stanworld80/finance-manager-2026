import 'package:finance_manager_2026/features/transactions/application/transaction_service.dart';
import 'package:finance_manager_2026/features/transactions/data/transaction_providers.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:finance_manager_2026/features/transactions/presentation/upcoming_transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';

import 'upcoming_transactions_page_test.mocks.dart';

class MockGoRouter extends Mock implements GoRouter {}

@GenerateMocks([TransactionService])
void main() {
  late MockTransactionService mockTransactionService;
  late MockGoRouter mockGoRouter;

  setUp(() {
    mockTransactionService = MockTransactionService();
    mockGoRouter = MockGoRouter();
    when(
      mockTransactionService.provisionTransaction(any),
    ).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest(List<Override> overrides) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
        home: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: const UpcomingTransactionsPage(),
        ),
      ),
    );
  }

  testWidgets(
    'UpcomingTransactionsPage displays planned and scheduled transactions',
    (tester) async {
      final transactions = [
        TransactionModel(
          id: '1',
          ownerId: 'user1',
          realAccountId: 'r1',
          amount: -50.0,
          type: TransactionType.debit,
          transactionDate: DateTime(2026, 12, 10),
          label: 'Internet Bill',
          step: TransactionStep.planned, // Planned
          splits: [],
        ),
        TransactionModel(
          id: '2',
          ownerId: 'user1',
          realAccountId: 'r1',
          amount: 2000.0,
          type: TransactionType.credit,
          transactionDate: DateTime(2026, 12, 15),
          label: 'Salary',
          step: TransactionStep.scheduled, // Scheduled
          splits: [],
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest([
          upcomingTransactionsProvider.overrideWith(
            (ref) => Stream.value(transactions),
          ),
          transactionServiceProvider.overrideWithValue(mockTransactionService),
        ]),
      );

      // Initial loading
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Échéancier / À Venir'), findsWidgets);

      // Verify Action icon
      expect(find.byIcon(Icons.repeat), findsOneWidget);

      // Verify Transactions
      expect(find.text('Internet Bill'), findsWidgets);
      expect(find.text('Salary'), findsWidgets);

      // Verify "Planifié" badge
      expect(find.text('Planifié'), findsWidgets);
    },
  );

  testWidgets('UpcomingTransactionsPage empty state', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest([
        upcomingTransactionsProvider.overrideWith((ref) => Stream.value([])),
      ]),
    );

    await tester.pumpAndSettle();

    expect(find.text('Aucune opération à venir.'), findsOneWidget);
    expect(find.byIcon(Icons.event_available), findsOneWidget);
  });

  testWidgets('UpcomingTransactionsPage supports swipe to provision', (
    tester,
  ) async {
    final transactions = [
      TransactionModel(
        id: 'tx_swipe_1',
        ownerId: 'user1',
        realAccountId: 'r1',
        amount: -50.0,
        type: TransactionType.debit,
        transactionDate: DateTime(2026, 12, 10),
        label: 'Internet Bill',
        step:
            TransactionStep.planned, // Needs to be planned to be provisionable
        splits: [],
      ),
    ];

    await tester.pumpWidget(
      createWidgetUnderTest([
        upcomingTransactionsProvider.overrideWith(
          (ref) => Stream.value(transactions),
        ),
        transactionServiceProvider.overrideWithValue(mockTransactionService),
      ]),
    );

    await tester.pumpAndSettle();

    final item = find.byKey(const Key('upcoming-tx_swipe_1'));
    expect(item, findsOneWidget);

    // Swipe Start to End
    await tester.drag(item, const Offset(500.0, 0.0));
    await tester.pumpAndSettle();

    // Verify provisionTransaction was called
    verify(mockTransactionService.provisionTransaction(any)).called(1);
  });
}
