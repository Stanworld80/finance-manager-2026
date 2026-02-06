import 'package:finance_manager_2026/core/utils/currency_formatter.dart';
import 'package:finance_manager_2026/features/accounts/data/account_providers.dart';
import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';
import 'package:finance_manager_2026/features/transactions/data/filtered_transactions_provider.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:finance_manager_2026/features/transactions/presentation/transaction_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  final now = DateTime(2026, 2, 3);

  final List<RealAccount> testAccounts = [
    RealAccount(
      id: 'r1',
      ownerId: 'u1',
      name: 'Main Account',
      balance: 1500.0,
      initialBalance: 0,
    ),
  ];

  final testTransactions = [
    TransactionModel(
      id: 't1',
      ownerId: 'u1',
      realAccountId: 'r1',
      amount: -50.0,
      label: 'Groceries',
      payee: 'Supermarket',
      type: TransactionType.debit,
      transactionDate: now,
    ),
    TransactionModel(
      id: 't2',
      ownerId: 'u1',
      realAccountId: 'r1',
      amount: 1000.0,
      label: 'Salary',
      payee: 'Employer',
      type: TransactionType.credit,
      transactionDate: now.subtract(const Duration(days: 1)),
    ),
  ];

  testWidgets(
    'TransactionListPage renders list of transactions grouped by date',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredTransactionsProvider.overrideWith(
              (ref) => Future.value(testTransactions),
            ),
            realAccountsProvider.overrideWith(
              (ref) => Stream.value(testAccounts),
            ),
            transactionFilterProvider.overrideWith(
              (ref) => TransactionFilterNotifier(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('fr', 'FR'), Locale('en', 'US')],
            home: TransactionListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // expect(find.text('Historique', skipOffstage: false), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Supermarket'), findsOneWidget);
      expect(find.text('Employer'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(-50.0)), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(1000.0)), findsOneWidget);
    },
  );

  testWidgets('TransactionListPage shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredTransactionsProvider.overrideWith((ref) => Future.value([])),
          realAccountsProvider.overrideWith((ref) => Stream.value([])),
          transactionFilterProvider.overrideWith(
            (ref) => TransactionFilterNotifier(),
          ),
        ],
        child: const MaterialApp(home: TransactionListPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Aucune transaction trouvée.'), findsOneWidget);
  });

  testWidgets('TransactionListPage input in search updates filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredTransactionsProvider.overrideWith(
            (ref) => Future.value(testTransactions),
          ),
          realAccountsProvider.overrideWith(
            (ref) => Stream.value(testAccounts),
          ),
          transactionFilterProvider.overrideWith(
            (ref) => TransactionFilterNotifier(),
          ),
        ],
        child: const MaterialApp(home: TransactionListPage()),
      ),
    );

    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    await tester.enterText(textField, 'Super');
    await tester.pump();
  });
}
