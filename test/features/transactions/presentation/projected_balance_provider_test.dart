import 'package:finance_manager_2026/features/accounts/data/account_providers.dart';
import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';
import 'package:finance_manager_2026/features/transactions/application/recurring_transaction_service.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:finance_manager_2026/features/transactions/presentation/projected_balance_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'projected_balance_provider_test.mocks.dart';

@GenerateMocks([RecurringTransactionService])
void main() {
  late MockRecurringTransactionService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockRecurringTransactionService();

    container = ProviderContainer(
      overrides: [
        recurringTransactionServiceProvider.overrideWith((ref) => mockService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('calculates projected balance correctly', () async {
    // 1. Mock Real Accounts (Current Balance)
    final account1 = RealAccount(
      id: '1',
      ownerId: 'u1',
      name: 'A1',
      bankName: 'B1',
      balance: 1000.0,
    );
    final account2 = RealAccount(
      id: '2',
      ownerId: 'u1',
      name: 'A2',
      bankName: 'B2',
      balance: 500.0,
    );

    container = ProviderContainer(
      overrides: [
        recurringTransactionServiceProvider.overrideWith((ref) => mockService),
        realAccountsProvider.overrideWith(
          (ref) => Stream.value([account1, account2]),
        ),
      ],
    );

    // 2. Mock Future Occurrences
    // Assume we have 2 future transactions: -100 and +200
    final tx1 = TransactionModel(
      id: 't1',
      ownerId: 'u1',
      realAccountId: '1',
      amount: -100.0,
      type: TransactionType.debit,
      transactionDate: DateTime.now().add(const Duration(days: 2)),
      label: 'Future Debit',
      status: TransactionStatus.none,
      step: TransactionStep.completed,
      splits: [],
    );
    final tx2 = TransactionModel(
      id: 't2',
      ownerId: 'u1',
      realAccountId: '1',
      amount: 200.0,
      type: TransactionType.credit,
      transactionDate: DateTime.now().add(const Duration(days: 5)),
      label: 'Future Credit',
      status: TransactionStatus.none,
      step: TransactionStep.completed,
      splits: [],
    );

    when(
      mockService.generateOccurrences(any),
    ).thenAnswer((_) async => [tx1, tx2]);

    // 3. Test Provider
    // Current Total: 1000 + 500 = 1500
    // Future Impact: -100 + 200 = +100
    // Projected: 1600

    final projected = await container.read(projectedBalanceProvider.future);

    expect(projected, 1600.0);
  });
}
