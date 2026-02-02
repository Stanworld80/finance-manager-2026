import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers.dart';
import '../domain/recurring_transaction.dart';

part 'recurring_transaction_repository.g.dart';

class RecurringTransactionRepository {
  final FirebaseFirestore _firestore;

  RecurringTransactionRepository(this._firestore);

  Future<void> createRecurringTransaction(
    String userId,
    RecurringTransaction recurring,
  ) async {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring_transactions')
        .doc(recurring.id)
        .set(recurring.toMap());
  }

  Future<void> updateRecurringTransaction(
    String userId,
    RecurringTransaction recurring,
  ) async {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring_transactions')
        .doc(recurring.id)
        .update(recurring.toMap());
  }

  Future<void> deleteRecurringTransaction(String userId, String id) async {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring_transactions')
        .doc(id)
        .delete();
  }

  Stream<List<RecurringTransaction>> watchRecurringTransactions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring_transactions')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RecurringTransaction.fromMap(doc.data()))
              .toList();
        });
  }

  Future<List<RecurringTransaction>> getActiveRecurringTransactions(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring_transactions')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => RecurringTransaction.fromMap(doc.data()))
        .toList();
  }
}

@riverpod
RecurringTransactionRepository recurringTransactionRepository(
  RecurringTransactionRepositoryRef ref,
) {
  return RecurringTransactionRepository(ref.watch(firestoreProvider));
}
