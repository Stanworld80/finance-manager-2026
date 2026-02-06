import 'package:finance_manager_2026/features/accounts/application/account_service.dart';
import 'package:finance_manager_2026/features/accounts/data/account_providers.dart';
import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';
import 'package:finance_manager_2026/features/transactions/application/transaction_service.dart';
import 'package:finance_manager_2026/features/transactions/presentation/add_transaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'add_transaction_page_test.mocks.dart';

@GenerateMocks([TransactionService, AccountService])
void main() {
  late MockTransactionService mockTransactionService;
  late MockAccountService mockAccountService;

  final realAccount = RealAccount(
    id: "r1",
    ownerId: "u1",
    name: "Bank A",
    initialBalance: 100,
    balance: 100,
  );

  final virtualAccount1 = VirtualAccount(
    id: "v1",
    userId: "u1",
    realAccountId: "r1",
    name: "Groceries",
    balance: 50,
    type: VirtualAccountType.userBudget,
  );

  final virtualAccount2 = VirtualAccount(
    id: "v2",
    userId: "u1",
    realAccountId: "r1",
    name: "Alimentation", // Alphabetically before Groceries
    balance: 50,
    type: VirtualAccountType.userBudget,
  );

  setUp(() {
    mockTransactionService = MockTransactionService();
    mockAccountService = MockAccountService();
  });

  testWidgets('AddTransactionPage renders and shows sort button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          realAccountsProvider.overrideWith(
            (ref) => Stream.value([realAccount]),
          ),
          allVirtualAccountsProvider.overrideWith(
            (ref) => Stream.value([virtualAccount1, virtualAccount2]),
          ),
          transactionServiceProvider.overrideWith(
            (ref) => mockTransactionService,
          ),
          accountServiceProvider.overrideWith((ref) => mockAccountService),
        ],
        child: const MaterialApp(home: AddTransactionPage()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title
    expect(find.text("Nouvelle Transaction"), findsOneWidget);

    // Verify sort button exists
    expect(find.byIcon(Icons.sort), findsOneWidget);

    // Verify dropdowns
    expect(find.text("De (Origine)"), findsOneWidget);
    expect(find.text("À (Destination)"), findsOneWidget);
  });

  testWidgets('Sort/Group options are available', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          realAccountsProvider.overrideWith(
            (ref) => Stream.value([realAccount]),
          ),
          allVirtualAccountsProvider.overrideWith(
            (ref) => Stream.value([virtualAccount1, virtualAccount2]),
          ),
          transactionServiceProvider.overrideWith(
            (ref) => mockTransactionService,
          ),
          accountServiceProvider.overrideWith((ref) => mockAccountService),
        ],
        child: const MaterialApp(home: AddTransactionPage()),
      ),
    );

    await tester.pumpAndSettle();

    // Tap sort button
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();

    // Verify options
    expect(find.text("Par Compte Bancaire"), findsOneWidget);
    expect(find.text("Ordre Alphabétique"), findsOneWidget);
  });
}
