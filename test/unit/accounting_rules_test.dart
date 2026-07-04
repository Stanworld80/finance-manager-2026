import 'package:flutter_test/flutter_test.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';

void main() {
  group('TransactionModel isBalanced Unit Tests', () {
    test('Empty splits should not be balanced', () {
      final tx = TransactionModel(
        id: 'tx1',
        ownerId: 'user1',
        realAccountId: 'acc1',
        amount: 100.0,
        type: TransactionType.debit,
        transactionDate: DateTime.now(),
        splits: [],
      );

      expect(tx.isBalanced, false);
    });

    test('Splits summing to 0 should be balanced', () {
      final tx = TransactionModel(
        id: 'tx2',
        ownerId: 'user1',
        realAccountId: 'acc1',
        amount: 100.0,
        type: TransactionType.debit,
        transactionDate: DateTime.now(),
        splits: [
          TransactionSplit(virtualAccountId: 'env1', amount: -100.0),
          TransactionSplit(virtualAccountId: 'env2', amount: 100.0),
        ],
      );

      expect(tx.isBalanced, true);
    });

    test('Unbalanced splits should not be balanced', () {
      final tx = TransactionModel(
        id: 'tx3',
        ownerId: 'user1',
        realAccountId: 'acc1',
        amount: 100.0,
        type: TransactionType.debit,
        transactionDate: DateTime.now(),
        splits: [
          TransactionSplit(virtualAccountId: 'env1', amount: -100.0),
          TransactionSplit(virtualAccountId: 'env2', amount: 95.0),
        ],
      );

      expect(tx.isBalanced, false);
    });

    test('Splits with opposite signs but equal sums should balance', () {
      final tx = TransactionModel(
        id: 'tx4',
        ownerId: 'user1',
        realAccountId: 'acc1',
        amount: 0.0,
        type: TransactionType.transfer,
        transactionDate: DateTime.now(),
        splits: [
          TransactionSplit(virtualAccountId: 'env1', amount: -50.0),
          TransactionSplit(virtualAccountId: 'env2', amount: 50.0),
        ],
      );

      expect(tx.isBalanced, true);
    });
  });
}
