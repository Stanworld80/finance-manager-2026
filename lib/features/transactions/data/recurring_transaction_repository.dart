import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers.dart';
import '../domain/recurring_transaction_model.dart';

part 'recurring_transaction_repository.g.dart';

@riverpod
RecurringTransactionRepository recurringTransactionRepository(
  RecurringTransactionRepositoryRef ref,
) {
  final firestore = ref.watch(firestoreProvider);
  return RecurringTransactionRepository(firestore);
}

class RecurringTransactionRepository {
  final FirebaseFirestore _firestore;

  RecurringTransactionRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _getCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring_transactions');
  }

  Future<void> createRecurringTransaction(
    String userId,
    RecurringTransaction transaction,
  ) async {
    await _getCollection(userId).doc(transaction.id).set(transaction.toMap());
  }

  Future<void> updateRecurringTransaction(
    String userId,
    RecurringTransaction transaction,
  ) async {
    await _getCollection(
      userId,
    ).doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteRecurringTransaction(
    String userId,
    String transactionId,
  ) async {
    await _getCollection(userId).doc(transactionId).delete();
  }

  Stream<List<RecurringTransaction>> watchRecurringTransactions(String userId) {
    return _getCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => RecurringTransaction.fromMap(doc.data()))
          .toList();
    });
  }

  Future<List<RecurringTransaction>> getRecurringTransactions(
    String userId,
  ) async {
    final snapshot = await _getCollection(userId).get();
    return snapshot.docs
        .map((doc) => RecurringTransaction.fromMap(doc.data()))
        .toList();
  }
}
