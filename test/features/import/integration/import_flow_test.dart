import 'package:finance_manager_2026/features/import/application/import_service.dart';
import 'package:finance_manager_2026/features/transactions/data/transaction_repository.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock Repository using Fake to avoid implementing everything
class MockTransactionRepository extends Fake implements TransactionRepository {
  final List<TransactionModel> savedTransactions = [];
  String? lastUserId;

  @override
  Future<int> addBatch(
    String userId,
    List<TransactionModel> transactions,
  ) async {
    lastUserId = userId;
    savedTransactions.addAll(transactions);
    return transactions.length;
  }
}

void main() {
  test(
    'Import Flow: saveTransactions correctly converts and saves data',
    () async {
      // 1. Setup
      final mockRepo = MockTransactionRepository();
      final container = ProviderContainer(
        overrides: [transactionRepositoryProvider.overrideWithValue(mockRepo)],
      );

      final service = container.read(importServiceProvider.notifier);

      // 2. Prepare Data (Simulate mapped rows)
      final rawData = [
        {
          'date': DateTime(2026, 1, 1),
          'amount': -50.0,
          'description': 'Supermarket',
          'beneficiary': 'Wallmart',
          'importHash': 'hash_123',
        },
        {
          'date': DateTime(2026, 1, 2),
          'amount': 2000.0,
          'description': 'Salary',
          'importHash': 'hash_456',
        },
      ];

      // 3. Execution
      final count = await service.saveTransactions(
        rawTransactions: rawData,
        realAccountId: 'real_acc_1',
        targetVirtualAccountId: 'virt_acc_default',
        userId: 'test_user_1',
      );

      // 4. Verification
      expect(count, 2);
      expect(mockRepo.lastUserId, 'test_user_1');
      expect(mockRepo.savedTransactions.length, 2);

      // Verify Transaction 1 (Debit)
      final tx1 = mockRepo.savedTransactions[0];
      expect(tx1.amount, -50.0);
      expect(tx1.type, TransactionType.debit);
      expect(tx1.realAccountId, 'real_acc_1');
      expect(tx1.importHash, 'hash_123');
      expect(tx1.splits.length, 2);
      // Split 1: Target (Debit -> Decrease)
      expect(tx1.splits[0].virtualAccountId, 'virt_acc_default');
      expect(tx1.splits[0].amount, -50.0);
      // Split 2: External (Debit -> Increase)
      expect(tx1.splits[1].virtualAccountId, 'system:external');
      expect(tx1.splits[1].amount, 50.0);

      // Verify Transaction 2 (Credit)
      final tx2 = mockRepo.savedTransactions[1];
      expect(tx2.amount, 2000.0);
      expect(tx2.type, TransactionType.credit);
      expect(tx2.splits.length, 2);
      // Split 1: Target (Credit -> Increase)
      expect(tx2.splits[0].virtualAccountId, 'virt_acc_default');
      expect(tx2.splits[0].amount, 2000.0);
      // Split 2: External (Credit -> Decrease)
      expect(tx2.splits[1].virtualAccountId, 'system:external');
      expect(tx2.splits[1].amount, -2000.0);
    },
  );

  test('ISTQB Edge Cases: Boundary Values & Strange Inputs', () async {
    // 1. Setup
    final mockRepo = MockTransactionRepository();
    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(mockRepo)],
    );
    final service = container.read(importServiceProvider.notifier);

    final extremeData = [
      // Boundary: Zero Amount
      {
        'date': DateTime(2026, 1, 1),
        'amount': 0.0,
        'description': 'Zero Transaction',
        'importHash': 'h_zero',
      },
      // Boundary: Very Large Amount
      {
        'date': DateTime(2026, 12, 31),
        'amount': 1000000000.0, // 1 Billion
        'description': 'Billion',
        'importHash': 'h_billion',
      },
      // Strange: Special Characters & Long Strings
      {
        'date': DateTime(2026, 1, 1),
        'amount': -123.45,
        'description': 'Special: !@#\$%^&*()_+ 😊',
        'beneficiary':
            'A very long beneficiary name that might exceed normal UI limits but should be handled by logic without crashing ' *
            5,
        'importHash': 'h_strange',
      },
      // Strange: Future Date
      {
        'date': DateTime(2099, 12, 31),
        'amount': 1.0,
        'description': 'Future',
        'importHash': 'h_future',
      },
    ];

    // 2. Execution
    await service.saveTransactions(
      rawTransactions: extremeData,
      realAccountId: 'real_1',
      targetVirtualAccountId: 'virt_1',
      userId: 'u1',
    );

    expect(mockRepo.savedTransactions.length, 4);

    // Verify Zero
    // Logic: amount >= 0 is Credit. 0 >= 0 is True.
    final txZero = mockRepo.savedTransactions[0];
    expect(txZero.amount, 0.0);
    expect(txZero.type, TransactionType.credit);
    expect(txZero.isBalanced, true);

    // Verify Billion
    final txBillion = mockRepo.savedTransactions[1];
    expect(txBillion.amount, 1e9);
    expect(txBillion.isBalanced, true);

    // Verify Special Chars
    final txStrange = mockRepo.savedTransactions[2];
    expect(txStrange.label, contains('😊'));
    expect(txStrange.payee!.length, greaterThan(100));
    expect(txStrange.amount, -123.45);

    // Verify Future
    final txFuture = mockRepo.savedTransactions[3];
    expect(txFuture.transactionDate.year, 2099);
  });
}
