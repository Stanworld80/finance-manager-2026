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
      await _applyTransaction(tx, userId, transaction);
    });
  }

  Future<void> createTransactions(
    String userId,
    List<TransactionModel> transactions,
  ) async {
    return _firestore.runTransaction((tx) async {
      for (final transaction in transactions) {
        await _applyTransaction(tx, userId, transaction);
      }
    });
  }

  Future<void> _applyTransaction(
    Transaction tx,
    String userId,
    TransactionModel transaction,
  ) async {
    // 1. Reference the Transaction Doc
    final txRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transaction.id);

    tx.set(txRef, transaction.toMap());

    // 2. Update Real Account Balance
    double realImpact = transaction.amount;

    final realAccountRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .doc(transaction.realAccountId);

    tx.update(realAccountRef, {'balance': FieldValue.increment(realImpact)});

    // 3. Update Virtual Accounts (Splits)
    for (var split in transaction.splits) {
      if (SystemAccounts.isSystem(split.virtualAccountId)) continue;

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
        if (SystemAccounts.isSystem(split.virtualAccountId)) continue;

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
