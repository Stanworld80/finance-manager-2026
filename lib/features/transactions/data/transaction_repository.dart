import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/data/local_database.dart';
import '../../../../core/data/sync_manager.dart';
import '../domain/transaction_model.dart';

part 'transaction_repository.g.dart';

class TransactionRepository {
  final LocalDatabase _db;
  final SyncManager _sync;

  TransactionRepository(this._db, this._sync);

  Future<List<TransactionModel>> _loadSplitsForTransactions(List<TransactionData> txs) async {
    final list = <TransactionModel>[];
    for (final tx in txs) {
      final splits = await (_db.select(_db.transactionSplits)..where((t) => t.transactionId.equals(tx.id))).get();
      list.add(
        TransactionModel(
          id: tx.id,
          ownerId: tx.ownerId,
          realAccountId: tx.realAccountId,
          amount: tx.amount,
          label: tx.label,
          note: tx.note,
          payee: tx.payee,
          category: tx.category,
          type: TransactionType.values.firstWhere((e) => e.name == tx.type, orElse: () => TransactionType.debit),
          status: TransactionStatus.values.firstWhere((e) => e.name == tx.status, orElse: () => TransactionStatus.none),
          step: TransactionStep.values.firstWhere((e) => e.name == tx.step, orElse: () => TransactionStep.completed),
          transactionDate: tx.transactionDate,
          valueDate: tx.valueDate,
          visibilityDate: tx.visibilityDate,
          syncDate: tx.syncDate,
          provisionDate: tx.provisionDate,
          importHash: tx.importHash,
          recurringTransactionId: tx.recurringTransactionId,
          linkedTransactionId: tx.linkedTransactionId,
          splits: splits.map((s) => TransactionSplit(
            virtualAccountId: s.virtualAccountId,
            amount: s.amount,
          )).toList(),
        ),
      );
    }
    return list;
  }

  Future<void> createTransaction(String userId, TransactionModel transaction) async {
    final now = DateTime.now();

    await _db.transaction(() async {
      // 1. Insert transaction
      await _db.into(_db.transactions).insert(
        TransactionsCompanion.insert(
          id: transaction.id,
          ownerId: userId,
          realAccountId: transaction.realAccountId,
          label: Value(transaction.label),
          note: Value(transaction.note),
          payee: Value(transaction.payee),
          category: Value(transaction.category),
          amount: transaction.amount,
          type: transaction.type.name,
          transactionDate: transaction.transactionDate,
          valueDate: Value(transaction.valueDate),
          visibilityDate: Value(transaction.visibilityDate),
          syncDate: Value(transaction.syncDate),
          provisionDate: Value(transaction.provisionDate),
          step: transaction.step.name,
          status: transaction.status.name,
          importHash: Value(transaction.importHash),
          recurringTransactionId: Value(transaction.recurringTransactionId),
          linkedTransactionId: Value(transaction.linkedTransactionId),
          createdAt: transaction.transactionDate,
          updatedAt: now,
        ),
      );

      // 2. Insert splits
      for (final split in transaction.splits) {
        final splitId = '${transaction.id}_${split.virtualAccountId}';
        await _db.into(_db.transactionSplits).insert(
          TransactionSplitsCompanion.insert(
            id: splitId,
            transactionId: transaction.id,
            virtualAccountId: split.virtualAccountId,
            amount: split.amount,
          ),
        );
      }

      // 3. Update real account balance (ONLY if completed)
      if (transaction.step == TransactionStep.completed) {
        await _db.customUpdate(
          'UPDATE real_accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
          variables: [Variable(transaction.amount), Variable(now), Variable(transaction.realAccountId)],
        );
      }

      // 4. Update virtual accounts balances (ONLY if completed or pending)
      if (transaction.step == TransactionStep.completed || transaction.step == TransactionStep.pending) {
        for (final split in transaction.splits) {
          await _db.customUpdate(
            'UPDATE virtual_accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
            variables: [Variable(split.amount), Variable(now), Variable(split.virtualAccountId)],
          );
        }
      }
    });

    // 5. Send outbox payload for Cloud Firestore Sync
    final payload = transaction.toMap();
    payload['updatedAt'] = now.toIso8601String();

    await _sync.addToOutbox(
      tableName: 'transactions',
      recordId: transaction.id,
      action: 'INSERT',
      payload: payload,
    );
  }

  Future<void> createTransactions(String userId, List<TransactionModel> transactions) async {
    for (final tx in transactions) {
      await createTransaction(userId, tx);
    }
  }

  Future<int> addBatch(String userId, List<TransactionModel> transactions) async {
    await createTransactions(userId, transactions);
    return transactions.length;
  }

  Future<void> deleteTransaction(String userId, TransactionModel transaction) async {
    final now = DateTime.now();

    await _db.transaction(() async {
      // 1. Delete splits
      await (_db.delete(_db.transactionSplits)..where((t) => t.transactionId.equals(transaction.id))).go();

      // 2. Delete transaction
      await (_db.delete(_db.transactions)..where((t) => t.id.equals(transaction.id))).go();

      // 3. Revert Real Account Balance (ONLY if completed)
      if (transaction.step == TransactionStep.completed) {
        await _db.customUpdate(
          'UPDATE real_accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
          variables: [Variable(transaction.amount), Variable(now), Variable(transaction.realAccountId)],
        );
      }

      // 4. Revert Virtual Accounts Balances (ONLY if completed or pending)
      if (transaction.step == TransactionStep.completed || transaction.step == TransactionStep.pending) {
        for (final split in transaction.splits) {
          await _db.customUpdate(
            'UPDATE virtual_accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
            variables: [Variable(split.amount), Variable(now), Variable(split.virtualAccountId)],
          );
        }
      }
    });

    await _sync.addToOutbox(
      tableName: 'transactions',
      recordId: transaction.id,
      action: 'DELETE',
      payload: {'realAccountId': transaction.realAccountId},
    );
  }

  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return (_db.select(_db.transactions)
      ..where((t) => t.ownerId.equals(userId))
      ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)]))
      .watch()
      .asyncMap((rows) => _loadSplitsForTransactions(rows));
  }

  Stream<TransactionModel?> watchTransaction(String userId, String transactionId) {
    return (_db.select(_db.transactions)..where((t) => t.ownerId.equals(userId) & t.id.equals(transactionId)))
        .watchSingleOrNull()
        .asyncMap((row) async {
          if (row == null) return null;
          final list = await _loadSplitsForTransactions([row]);
          return list.first;
        });
  }

  Future<TransactionModel?> getTransactionById(String userId, String transactionId) async {
    final row = await (_db.select(_db.transactions)..where((t) => t.ownerId.equals(userId) & t.id.equals(transactionId))).getSingleOrNull();
    if (row == null) return null;
    final list = await _loadSplitsForTransactions([row]);
    return list.first;
  }

  Stream<List<TransactionModel>> watchTransactionsByRealAccount(String userId, String realAccountId) {
    return (_db.select(_db.transactions)
      ..where((t) => t.realAccountId.equals(realAccountId))
      ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)]))
      .watch()
      .asyncMap((rows) => _loadSplitsForTransactions(rows));
  }

  Future<List<TransactionModel>> getTransactionsByRealAccount(String userId, String realAccountId) async {
    final rows = await (_db.select(_db.transactions)
      ..where((t) => t.realAccountId.equals(realAccountId))
      ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)]))
      .get();
    return _loadSplitsForTransactions(rows);
  }

  Future<List<TransactionModel>> getTransactionsByVirtualAccount(String userId, String virtualAccountId) async {
    final query = _db.select(_db.transactions).join([
      innerJoin(_db.transactionSplits, _db.transactionSplits.transactionId.equalsExp(_db.transactions.id))
    ])
      ..where(_db.transactionSplits.virtualAccountId.equals(virtualAccountId))
      ..orderBy([OrderingTerm(expression: _db.transactions.transactionDate, mode: OrderingMode.desc)]);

    final rows = await query.get();
    final txRows = rows.map((r) => r.readTable(_db.transactions)).toList();
    return _loadSplitsForTransactions(txRows);
  }

  Future<void> updateTransaction(String userId, TransactionModel original, TransactionModel updated) async {
    final now = DateTime.now();

    await _db.transaction(() async {
      // 1. Revert original balances
      if (original.step == TransactionStep.completed) {
        await _db.customUpdate(
          'UPDATE real_accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
          variables: [Variable(original.amount), Variable(now), Variable(original.realAccountId)],
        );
      }
      if (original.step == TransactionStep.completed || original.step == TransactionStep.pending) {
        for (final split in original.splits) {
          await _db.customUpdate(
            'UPDATE virtual_accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
            variables: [Variable(split.amount), Variable(now), Variable(split.virtualAccountId)],
          );
        }
      }

      // 2. Delete original splits
      await (_db.delete(_db.transactionSplits)..where((t) => t.transactionId.equals(original.id))).go();

      // 3. Update transaction row
      await (_db.update(_db.transactions)..where((t) => t.id.equals(updated.id))).write(
        TransactionsCompanion(
          realAccountId: Value(updated.realAccountId),
          label: Value(updated.label),
          note: Value(updated.note),
          payee: Value(updated.payee),
          category: Value(updated.category),
          amount: Value(updated.amount),
          type: Value(updated.type.name),
          transactionDate: Value(updated.transactionDate),
          valueDate: Value(updated.valueDate),
          visibilityDate: Value(updated.visibilityDate),
          syncDate: Value(updated.syncDate),
          provisionDate: Value(updated.provisionDate),
          step: Value(updated.step.name),
          status: Value(updated.status.name),
          importHash: Value(updated.importHash),
          recurringTransactionId: Value(updated.recurringTransactionId),
          linkedTransactionId: Value(updated.linkedTransactionId),
          updatedAt: Value(now),
        ),
      );

      // 4. Insert new splits
      for (final split in updated.splits) {
        final splitId = '${updated.id}_${split.virtualAccountId}';
        await _db.into(_db.transactionSplits).insert(
          TransactionSplitsCompanion.insert(
            id: splitId,
            transactionId: updated.id,
            virtualAccountId: split.virtualAccountId,
            amount: split.amount,
          ),
        );
      }

      // 5. Apply updated balances
      if (updated.step == TransactionStep.completed) {
        await _db.customUpdate(
          'UPDATE real_accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
          variables: [Variable(updated.amount), Variable(now), Variable(updated.realAccountId)],
        );
      }
      if (updated.step == TransactionStep.completed || updated.step == TransactionStep.pending) {
        for (final split in updated.splits) {
          await _db.customUpdate(
            'UPDATE virtual_accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
            variables: [Variable(split.amount), Variable(now), Variable(split.virtualAccountId)],
          );
        }
      }
    });

    final payload = updated.toMap();
    payload['updatedAt'] = now.toIso8601String();

    await _sync.addToOutbox(
      tableName: 'transactions',
      recordId: updated.id,
      action: 'UPDATE',
      payload: payload,
    );
  }

  Future<List<TransactionModel>> getFilteredTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? realAccountId,
    int limit = 20,
    DocumentSnapshot? lastDocument, // Kept for compatibility, unused in local SQLite
  }) async {
    var query = _db.select(_db.transactions)
      ..where((t) => t.ownerId.equals(userId));

    if (realAccountId != null) {
      query = query..where((t) => t.realAccountId.equals(realAccountId));
    }
    if (startDate != null) {
      query = query..where((t) => t.transactionDate.isBiggerOrEqual(Variable(startDate)));
    }
    if (endDate != null) {
      query = query..where((t) => t.transactionDate.isSmallerOrEqual(Variable(endDate)));
    }

    query = query
      ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)])
      ..limit(limit);

    final rows = await query.get();
    return _loadSplitsForTransactions(rows);
  }
}

@riverpod
TransactionRepository transactionRepository(Ref ref) {
  return TransactionRepository(ref.watch(localDatabaseProvider), ref.watch(syncManagerProvider));
}
