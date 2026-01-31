import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers.dart';
import '../domain/transaction_model.dart';

part 'transaction_repository.g.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;

  TransactionRepository(this._firestore);

  Future<void> createTransaction(
    String userId,
    TransactionModel transaction,
  ) async {
    return _firestore.runTransaction((tx) async {
      // 1. Reference the Transaction Doc (Global collection for easy "All Transactions" query)
      final txRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transaction.id);

      tx.set(txRef, transaction.toMap());

      // 2. Update Real Account Balance
      // (This assumes the Real Movement is 'amount'. Expenses are typically negative or handled by Type)
      // If type is Expense, amount is usually stored positive in DB but subtracted?
      // Let's assume the Model stores signed amount or we rely on Type.
      // For simplicity in this implementation, I assume 'amount' is signed.
      // (e.g. -10 for expense, +100 for income).
      double realImpact = transaction.amount;
      // If the model stores +10 for expense, we need to invert.
      // Let's check Logic: Users usually enter "10", app saves "-10" or type "Expense".
      // I will assume the Service/Controller handles the sign logic before creating the Model,
      // OR the Model has helper helpers.
      // Let's assume 'amount' is the raw value to add to balance.

      final realAccountRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('real_accounts')
          .doc(transaction.realAccountId);

      // Increment is atomic
      tx.update(realAccountRef, {'balance': FieldValue.increment(realImpact)});

      // 3. Update Virtual Accounts (Splits)
      for (var split in transaction.splits) {
        final virtualAccountRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('real_accounts')
            .doc(transaction.realAccountId)
            .collection('virtual_accounts')
            .doc(split.virtualAccountId);

        tx.update(virtualAccountRef, {
          'balance': FieldValue.increment(split.amount),
        });
      }
    });
  }

  Future<void> deleteTransaction(
    String userId,
    TransactionModel transaction,
  ) async {
    return _firestore.runTransaction((tx) async {
      final txRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transaction.id);

      tx.delete(txRef);

      // Inverse of creation logic
      double realImpact = -transaction.amount;

      final realAccountRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('real_accounts')
          .doc(transaction.realAccountId);

      tx.update(realAccountRef, {'balance': FieldValue.increment(realImpact)});

      for (var split in transaction.splits) {
        final virtualAccountRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('real_accounts')
            .doc(transaction.realAccountId)
            .collection('virtual_accounts')
            .doc(split.virtualAccountId);

        tx.update(virtualAccountRef, {
          'balance': FieldValue.increment(-split.amount),
        });
      }
    });
  }

  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<TransactionModel?> watchTransaction(
    String userId,
    String transactionId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return TransactionModel.fromMap(doc.data()!);
        });
  }
}

@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  return TransactionRepository(ref.watch(firestoreProvider));
}
