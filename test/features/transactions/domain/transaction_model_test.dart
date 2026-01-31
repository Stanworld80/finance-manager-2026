import 'package:flutter_test/flutter_test.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';

void main() {
  group('TransactionModel', () {
    final date = DateTime(2026, 1, 30, 10, 0, 0);

    test('toMap returns correct map', () {
      final transaction = TransactionModel(
        id: 't1',
        ownerId: 'user1',
        realAccountId: 'r1',
        amount: -50.0,
        type: TransactionType.debit,
        transactionDate: date,
        label: 'Lunch',
        category: 'Food',
        payee: 'Restaurant',
        note: 'Yum',
        splits: [
          TransactionSplit(virtualAccountId: 'v1', amount: -50.0),
          TransactionSplit(virtualAccountId: 'committed', amount: 50.0),
        ],
      );

      final map = transaction.toMap();

      expect(map['id'], 't1');
      expect(map['amount'], -50.0);
      expect(map['type'], 'debit');
      expect(map['transactionDate'], date.toIso8601String());
      expect(map['splits'], isA<List>());
      expect((map['splits'] as List).length, 2);
      expect((map['splits'] as List)[0]['virtualAccountId'], 'v1');
    });

    test('fromMap returns correct object', () {
      final map = {
        'id': 't2',
        'ownerId': 'user1',
        'realAccountId': 'r1',
        'amount': 100.0,
        'type': 'credit',
        'transactionDate': date.toIso8601String(),
        'label': 'Salary',
        'splits': [],
      };

      final transaction = TransactionModel.fromMap(map);

      expect(transaction.id, 't2');
      expect(transaction.amount, 100.0);
      expect(transaction.type, TransactionType.credit);
      expect(transaction.transactionDate, date);
      expect(transaction.label, 'Salary');
      expect(transaction.splits, isEmpty);
    });

    test('fromMap handles Enum parsing', () {
      final map = {
        'id': 't3',
        'ownerId': 'user1',
        'realAccountId': 'r1',
        'amount': 0.0,
        'type': 'transfer',
        'transactionDate': date.toIso8601String(),
      };

      final transaction = TransactionModel.fromMap(map);
      expect(transaction.type, TransactionType.transfer);
    });

    test('fromMap fallback for unknown Enum', () {
      final map = {
        'id': 't4',
        'ownerId': 'user1',
        'realAccountId': 'r1',
        'amount': 0.0,
        'type': 'unknownType',
        'transactionDate': date.toIso8601String(),
      };

      final transaction = TransactionModel.fromMap(map);
      expect(transaction.type, TransactionType.debit); // Default fallback
    });

    test('TransactionSplit serialization', () {
      final split = TransactionSplit(virtualAccountId: 'v1', amount: 10.0);
      final map = split.toMap();
      expect(map['virtualAccountId'], 'v1');
      expect(map['amount'], 10.0);

      final fromMap = TransactionSplit.fromMap(map);
      expect(fromMap.virtualAccountId, 'v1');
      expect(fromMap.amount, 10.0);
    });
  });
}
