import 'package:finance_manager_2026/features/accounts/data/account_providers.dart';
import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';
import 'package:finance_manager_2026/features/transactions/data/transaction_providers.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:finance_manager_2026/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:finance_manager_2026/features/accounts/application/account_service.dart';
import 'package:finance_manager_2026/features/transactions/application/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'add_transaction_page_test.mocks.dart';

void main() {
  final realAccount = RealAccount(
    id: "r1",
    ownerId: "u1",
    name: "Banque A",
    initialBalance: 100,
    balance: 100,
  );

  final virtualAccount = VirtualAccount(
    id: "v1",
    userId: "u1",
    realAccountId: "r1",
    name: "Alimentation",
    balance: 50,
    type: VirtualAccountType.userBudget,
  );

  final transaction = TransactionModel(
    id: "t1",
    ownerId: "u1",
    realAccountId: "r1",
    amount: -10.0,
    transactionDate: DateTime.now(),
    type: TransactionType.debit,
    status: TransactionStatus.none,
    splits: [
      TransactionSplit(virtualAccountId: "v1", amount: -10.0),
      TransactionSplit(virtualAccountId: SystemAccounts.external, amount: 10.0),
    ],
  );

  late MockTransactionService mockTransactionService;
  late MockAccountService mockAccountService;

  setUp(() {
    mockTransactionService = MockTransactionService();
    mockAccountService = MockAccountService();
  });

  testWidgets('TransactionDetailScreen displays real account name', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          realAccountsProvider.overrideWith(
            (ref) => Stream.value([realAccount]),
          ),
          allVirtualAccountsProvider.overrideWith(
            (ref) => Stream.value([virtualAccount]),
          ),
          transactionByIdProvider(
            "t1",
          ).overrideWith((ref) => Stream.value(transaction)),
          transactionServiceProvider.overrideWith(
            (ref) => mockTransactionService,
          ),
          accountServiceProvider.overrideWith((ref) => mockAccountService),
        ],
        child: const MaterialApp(
          home: TransactionDetailScreen(transactionId: "t1"),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar
    expect(
      find.text("Détails"),
      findsOneWidget,
      reason: "AppBar title not found",
    );

    // Verify Transaction Amount (Header and potentially in splits)
    expect(find.text("-10.00 €"), findsAtLeast(1), reason: "Amount not found");

    // Verify Flux Financiers section check
    expect(
      find.text("Flux Financiers"),
      findsOneWidget,
      reason: "Flux Financiers header not found",
    );

    // Verify Real Account Name is displayed in parentheses
    // We search for the specific combined text
    expect(
      find.text("Alimentation (Banque A)", findRichText: true),
      findsOneWidget,
      reason: "Combined name not found",
    );
  });
}
