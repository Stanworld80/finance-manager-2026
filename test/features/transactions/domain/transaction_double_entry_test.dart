import 'package:flutter_test/flutter_test.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('TransactionModel Double-Entry Tests', () {
    final now = DateTime.now();
    const userId = 'user-1';
    const accountId = 'acc-1';

    test('Transaction with matching splits is balanced', () {
      final tx = TransactionModel(
        id: 'tx-1',
        ownerId: userId,
        realAccountId: accountId,
        amount: -10.0,
        type: TransactionType.debit,
        transactionDate: now,
        splits: [
          TransactionSplit(virtualAccountId: 'env-1', amount: -10.0),
          TransactionSplit(
            virtualAccountId: SystemAccounts.external,
            amount: 10.0,
          ),
        ],
      );

      expect(tx.isBalanced, isTrue);
    });

    test('Transaction with unmatching splits is NOT balanced', () {
      final tx = TransactionModel(
        id: 'tx-2',
        ownerId: userId,
        realAccountId: accountId,
        amount: -10.0,
        type: TransactionType.debit,
        transactionDate: now,
        splits: [
          TransactionSplit(virtualAccountId: 'env-1', amount: -10.0),
          TransactionSplit(
            virtualAccountId: SystemAccounts.external,
            amount: 5.0,
          ),
        ],
      );

      expect(tx.isBalanced, isFalse);
    });

    test('Transaction with multiple splits is balanced if sum is 0', () {
      final tx = TransactionModel(
        id: 'tx-3',
        ownerId: userId,
        realAccountId: accountId,
        amount: -50.0,
        type: TransactionType.debit,
        transactionDate: now,
        splits: [
          TransactionSplit(virtualAccountId: 'env-food', amount: -30.0),
          TransactionSplit(virtualAccountId: 'env-home', amount: -20.0),
          TransactionSplit(
            virtualAccountId: SystemAccounts.external,
            amount: 50.0,
          ),
        ],
      );

      expect(tx.isBalanced, isTrue);
    });

    test('Adjustment transaction is balanced', () {
      final tx = TransactionModel(
        id: 'tx-4',
        ownerId: userId,
        realAccountId: accountId,
        amount: 5.0,
        type: TransactionType.credit,
        transactionDate: now,
        splits: [
          TransactionSplit(virtualAccountId: 'env-1', amount: 5.0),
          TransactionSplit(
            virtualAccountId: SystemAccounts.externalAdjustment,
            amount: -5.0,
          ),
        ],
      );

      expect(tx.isBalanced, isTrue);
    });
  });
}
