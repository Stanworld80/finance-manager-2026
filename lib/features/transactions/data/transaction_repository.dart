import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Adds a large batch of transactions, chunked to respect Firestore limits (500 ops).
  /// Note: Not atomic across chunks.
  Future<int> addBatch(
    String userId,
    List<TransactionModel> transactions,
  ) async {
    // 1 transaction ~= 4 ops (1 create + 1 real update + 2 virtual updates)
    // Limit 500 ops => ~100 tx per batch safely.
    const int batchSize = 100;
    int successCount = 0;

    for (var i = 0; i < transactions.length; i += batchSize) {
      final end = (i + batchSize < transactions.length)
          ? i + batchSize
          : transactions.length;
      final chunk = transactions.sublist(i, end);

      try {
        await _firestore.runTransaction((tx) async {
          for (final transaction in chunk) {
            await _applyTransaction(tx, userId, transaction);
          }
        });
        successCount += chunk.length;
      } catch (e) {
        // Log error? Rethrow?
        // For import, we might want to continue or stop.
        // For now, rethrow to stop import on critical failure.
        throw Exception("Failed to import batch ${i ~/ batchSize}: $e");
      }
    }
    return successCount;
  }

  Future<void> _applyTransaction(
    Transaction tx,
    String userId,
    TransactionModel transaction,
  ) async {
    // 1. Reference the Transaction Doc (Now under accounts/{realAccountId}/transactions)
    final txRef = _firestore
        .collection('accounts')
        .doc(transaction.realAccountId)
        .collection('transactions')
        .doc(transaction.id);

    tx.set(txRef, transaction.toMap());

    // 2. Update Real Account Balance (ONLY if completed)
    if (transaction.step == TransactionStep.completed) {
      double realImpact = transaction.amount;
      final realAccountRef = _firestore
          .collection('accounts')
          .doc(transaction.realAccountId);
      tx.update(realAccountRef, {'balance': FieldValue.increment(realImpact)});
    }

    // 3. Update Virtual Accounts (Splits) (ONLY if completed or pending)
    if (transaction.step == TransactionStep.completed ||
        transaction.step == TransactionStep.pending) {
      for (var split in transaction.splits) {
        if (SystemAccounts.isSystem(split.virtualAccountId)) continue;

        final virtualAccountRef = _firestore
            .collection('accounts')
            .doc(transaction.realAccountId)
            .collection('virtual_accounts')
            .doc(split.virtualAccountId);

        tx.update(virtualAccountRef, {
          'balance': FieldValue.increment(split.amount),
        });
      }
    }
  }

  Future<void> deleteTransaction(
    String userId,
    TransactionModel transaction,
  ) async {
    return _firestore.runTransaction((tx) async {
      final txRef = _firestore
          .collection('accounts')
          .doc(transaction.realAccountId)
          .collection('transactions')
          .doc(transaction.id);

      tx.delete(txRef);

      // Inverse of creation logic
      if (transaction.step == TransactionStep.completed) {
        double realImpact = -transaction.amount;
        final realAccountRef = _firestore
            .collection('accounts')
            .doc(transaction.realAccountId);
        tx.update(realAccountRef, {
          'balance': FieldValue.increment(realImpact),
        });
      }

      if (transaction.step == TransactionStep.completed ||
          transaction.step == TransactionStep.pending) {
        for (var split in transaction.splits) {
          if (SystemAccounts.isSystem(split.virtualAccountId)) continue;

          final virtualAccountRef = _firestore
              .collection('accounts')
              .doc(transaction.realAccountId)
              .collection('virtual_accounts')
              .doc(split.virtualAccountId);

          tx.update(virtualAccountRef, {
            'balance': FieldValue.increment(-split.amount),
          });
        }
      }
    });
  }

  Stream<List<TransactionModel>> watchTransactions(String userId) {
    // We want all transactions the user can access.
    // The accessible accounts need to be looked up, OR we just use a collectionGroup
    // which requires the transaction model to know its accessibleUserIds.
    // For now, if TransactionModel does NOT have accessibleUserIds,
    // we must fetch accessible RealAccount IDs first, OR add accessibleUserIds to tx.
    // Assuming transactions are strictly bound to accounts, fetching by account is best.

    // Let's use a simpler approach for a truly global stream if we don't have tx.accessibleUserIds:
    // This is temporary until we denormalize accessibleUserIds into Transactions if needed.
    // For MVP, we'll watch a collectionGroup if we add `accessibleUserIds` to Texas,
    // otherwise we must fetch accounts and watch their txs.

    // Using collectionGroup assuming we might add accessibleUserIds later.
    // Actually, `ownerId` might be enough if we just want owned.
    // Let's use a fallback for now: watch owned.
    return _firestore
        .collectionGroup('transactions')
        .where('ownerId', isEqualTo: userId)
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
        .collectionGroup('transactions')
        .where('ownerId', isEqualTo: userId)
        .where('id', isEqualTo: transactionId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final data = snapshot.docs.first.data();
          return TransactionModel.fromMap(data);
        });
  }

  Future<TransactionModel?> getTransactionById(
    String userId,
    String transactionId,
  ) async {
    final snapshot = await _firestore
        .collectionGroup('transactions')
        .where('ownerId', isEqualTo: userId)
        .where('id', isEqualTo: transactionId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    return TransactionModel.fromMap(data);
  }

  Stream<List<TransactionModel>> watchTransactionsByRealAccount(
      String userId, String realAccountId) {
    return _firestore
        .collection('accounts')
        .doc(realAccountId)
        .collection('transactions')
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<List<TransactionModel>> getTransactionsByRealAccount(
    String userId,
    String realAccountId,
  ) async {
    final snapshot = await _firestore
        .collection('accounts')
        .doc(realAccountId)
        .collection('transactions')
        .orderBy('transactionDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<TransactionModel>> getTransactionsByVirtualAccount(
    String userId,
    String virtualAccountId,
  ) async {
    // TODO: This query needs a composite index if we want to order by date effectively
    // while filtering by array-contains.
    // 'splits' is a complex object array, so 'array-contains' might not work directly
    // on objects unless we store 'involvedVirtualAccountIds' array.
    //
    // Current TransactionModel:
    // splits: List<TransactionSplit>
    //
    // Firestore limitation: cannot 'array-contains' on list of maps easily for partial match.
    // We should refactor TransactionModel to include `involvedVirtualAccountIds` field?
    // OR we filter in client side for now (simple MVP).
    //
    // Filter client-side for MVP since dataset is small.
    // Ideally, we add a field `virtualAccountIds` to the doc.

    // Better approach for MVP without schema change:
    // Query all transactions (maybe limited by date?) and filter.
    // OR just fetch all for the user and filter.

    // WAIT! In Firestore, we can't easily query inside array of objects.
    // Let's do client side filtering for now, fetching all transactions for the user
    // is risky if many transactions.

    // Alternative: We can use `getTransactionsByRealAccount` if we know the RealAccount.
    // But a virtual account belongs to ONE RealAccount.
    // So we can:
    // 1. Fetch Real Account ID for this Virtual Account (passed in or known).
    // 2. Query transactions by RealAccount.
    // 3. Filter in Dart for `splits.any((s) => s.virtualAccountId == id)`.

    // Since we don't have RealAccountId here easily (unless queried), let's assume
    // the caller might know it.
    // But the signature requested `getTransactionsByVirtualAccount(userId, virtualAccountId)`.

    // Let's rely on client-side filtering of `watchTransactions` or similar?
    // Start with a comprehensive query?

    // Let's try to query by `realAccountId`? No, we don't have it here.

    // Let's assume we fetch all transactions for the user.
    // Warning: Potential performance issue later.
    final snapshot = await _firestore
        .collectionGroup('transactions')
        .where('ownerId', isEqualTo: userId)
        .orderBy('transactionDate', descending: true)
        .limit(500) // Safety limit
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data()))
        .where(
          (tx) => tx.splits.any((s) => s.virtualAccountId == virtualAccountId),
        )
        .toList();
  }

  Future<void> updateTransaction(
    String userId,
    TransactionModel original,
    TransactionModel updated,
  ) async {
    return _firestore.runTransaction((tx) async {
      // 1. Revert Original (Only if it affected balances)
      if (original.step == TransactionStep.completed) {
        double revertRealImpact = -original.amount;
        final realAccountRef = _firestore
            .collection('accounts')
            .doc(original.realAccountId);
        tx.update(realAccountRef, {
          'balance': FieldValue.increment(revertRealImpact),
        });
      }

      if (original.step == TransactionStep.completed ||
          original.step == TransactionStep.pending) {
        for (var split in original.splits) {
          if (SystemAccounts.isSystem(split.virtualAccountId)) continue;

          final virtualAccountRef = _firestore
              .collection('accounts')
              .doc(original.realAccountId)
              .collection('virtual_accounts')
              .doc(split.virtualAccountId);

          tx.update(virtualAccountRef, {
            'balance': FieldValue.increment(-split.amount),
          });
        }
      }

      // 2. Apply New (Updated) (Only if it affects balances)
      if (updated.step == TransactionStep.completed) {
        final newRealAccountRef = _firestore
            .collection('accounts')
            .doc(updated.realAccountId);
        tx.update(newRealAccountRef, {
          'balance': FieldValue.increment(updated.amount),
        });
      }

      if (updated.step == TransactionStep.completed ||
          updated.step == TransactionStep.pending) {
        for (var split in updated.splits) {
          if (SystemAccounts.isSystem(split.virtualAccountId)) continue;

          final virtualAccountRef = _firestore
              .collection('accounts')
              .doc(updated.realAccountId)
              .collection('virtual_accounts')
              .doc(split.virtualAccountId);

          tx.update(virtualAccountRef, {
            'balance': FieldValue.increment(split.amount),
          });
        }
      }

      // 3. Update Transaction Doc
      final txRef = _firestore
          .collection('accounts')
          .doc(updated.realAccountId)
          .collection('transactions')
          .doc(updated.id);

      tx.set(txRef, updated.toMap());
    });
  }

  Future<List<TransactionModel>> getFilteredTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? realAccountId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query;

    if (realAccountId != null) {
      query = _firestore
          .collection('accounts')
          .doc(realAccountId)
          .collection('transactions')
          .orderBy('transactionDate', descending: true);
    } else {
      query = _firestore
          .collectionGroup('transactions')
          .where('ownerId', isEqualTo: userId)
          .orderBy('transactionDate', descending: true);
    }

    if (startDate != null) {
      query = query.where('transactionDate', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('transactionDate', isLessThanOrEqualTo: endDate);
    }
    // Removed realAccountId where clause because we now branch above

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }
}

@riverpod
TransactionRepository transactionRepository(Ref ref) {
  return TransactionRepository(ref.watch(firestoreProvider));
}
