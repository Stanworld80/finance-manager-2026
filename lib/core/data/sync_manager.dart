import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers.dart';
import 'local_database.dart';

part 'sync_manager.g.dart';

class SyncManager {
  final LocalDatabase _db;
  final FirebaseFirestore _firestore;
  final List<StreamSubscription> _subscriptions = [];
  bool _isSyncingOutbox = false;

  SyncManager(this._db, this._firestore);

  void initialize(String userId) {
    _cancelSubscriptions();
    
    // 1. Sync outbox immediately and setup trigger
    triggerSync();

    // 2. Listen to Remote Firestore Changes and write to local Drift DB
    _subscriptions.add(
      _firestore
          .collection('accounts')
          .where('accessibleUserIds', arrayContains: userId)
          .snapshots()
          .listen((snapshot) => _syncRealAccounts(snapshot)),
    );

    _subscriptions.add(
      _firestore
          .collectionGroup('virtual_accounts')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) => _syncVirtualAccounts(snapshot)),
    );

    _subscriptions.add(
      _firestore
          .collectionGroup('transactions')
          .where('ownerId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) => _syncTransactions(snapshot)),
    );
  }

  void dispose() {
    _cancelSubscriptions();
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  // --- Remote -> Local Sync ---

  Future<void> _syncRealAccounts(QuerySnapshot snapshot) async {
    final Set<String> updatedAccountIds = {};
    for (final change in snapshot.docChanges) {
      final doc = change.doc;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      if (change.type == DocumentChangeType.removed) {
        await (_db.delete(_db.realAccounts)..where((t) => t.id.equals(doc.id))).go();
      } else {
        final updatedAtStr = data['updatedAt'] ?? data['openingDate'] ?? '1970-01-01T00:00:00.000Z';
        final updatedAt = DateTime.parse(updatedAtStr);

        // Check if local is newer
        final local = await (_db.select(_db.realAccounts)..where((t) => t.id.equals(doc.id))).getSingleOrNull();
        if (local != null && local.updatedAt.isAfter(updatedAt)) {
          continue; // Keep local
        }

        await _db.into(_db.realAccounts).insertOnConflictUpdate(
          RealAccountsCompanion.insert(
            id: doc.id,
            ownerId: data['ownerId'] ?? '',
            name: data['name'] ?? '',
            bankName: Value(data['bankName']),
            initialBalance: Value((data['initialBalance'] as num?)?.toDouble() ?? 0.0),
            balance: Value((data['balance'] as num?)?.toDouble() ?? 0.0),
            type: data['type'] ?? 'internal',
            isPrincipal: Value(data['isPrincipal'] ?? false),
            sharedWithUserIds: jsonEncode(data['sharedWithUserIds'] ?? []),
            openingDate: Value(data['openingDate'] != null ? DateTime.parse(data['openingDate']) : null),
            accountNumber: Value(data['accountNumber']),
            officialName: Value(data['officialName']),
            iban: Value(data['iban']),
            bic: Value(data['bic']),
            swift: Value(data['swift']),
            updatedAt: updatedAt,
          ),
        );
        updatedAccountIds.add(doc.id);
      }
    }

    for (final accId in updatedAccountIds) {
      await reconcileRealAccountBalances(accId);
    }
  }

  Future<void> _syncVirtualAccounts(QuerySnapshot snapshot) async {
    final Set<String> updatedAccountIds = {};
    for (final change in snapshot.docChanges) {
      final doc = change.doc;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      if (change.type == DocumentChangeType.removed) {
        await (_db.delete(_db.virtualAccounts)..where((t) => t.id.equals(doc.id))).go();
      } else {
        final updatedAtStr = data['updatedAt'] ?? '1970-01-01T00:00:00.000Z';
        final updatedAt = DateTime.parse(updatedAtStr);

        final local = await (_db.select(_db.virtualAccounts)..where((t) => t.id.equals(doc.id))).getSingleOrNull();
        if (local != null && local.updatedAt.isAfter(updatedAt)) {
          continue; // Keep local
        }

        await _db.into(_db.virtualAccounts).insertOnConflictUpdate(
          VirtualAccountsCompanion.insert(
            id: doc.id,
            userId: data['userId'] ?? '',
            realAccountId: data['realAccountId'] ?? '',
            name: data['name'] ?? '',
            balance: Value((data['balance'] as num?)?.toDouble() ?? 0.0),
            type: data['type'] ?? 'userBudget',
            icon: Value(data['icon']),
            updatedAt: updatedAt,
          ),
        );
        updatedAccountIds.add(data['realAccountId'] as String);
      }
    }

    for (final accId in updatedAccountIds) {
      await reconcileRealAccountBalances(accId);
    }
  }

  Future<void> _syncTransactions(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      final doc = change.doc;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      if (change.type == DocumentChangeType.removed) {
        await (_db.delete(_db.transactions)..where((t) => t.id.equals(doc.id))).go();
      } else {
        final updatedAtStr = data['updatedAt'] ?? data['createdAt'] ?? '1970-01-01T00:00:00.000Z';
        final updatedAt = DateTime.parse(updatedAtStr);

        final local = await (_db.select(_db.transactions)..where((t) => t.id.equals(doc.id))).getSingleOrNull();
        if (local != null && local.updatedAt.isAfter(updatedAt)) {
          continue; // Keep local
        }

        // Insert/Update Transaction
        await _db.into(_db.transactions).insertOnConflictUpdate(
          TransactionsCompanion.insert(
            id: doc.id,
            ownerId: data['ownerId'] ?? '',
            realAccountId: data['realAccountId'] ?? '',
            label: Value(data['label'] ?? data['description']),
            note: Value(data['note']),
            payee: Value(data['payee']),
            category: Value(data['category']),
            amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
            type: data['type'] ?? 'debit',
            transactionDate: DateTime.parse(data['transactionDate'] ?? DateTime.now().toIso8601String()),
            valueDate: Value(data['valueDate'] != null ? DateTime.parse(data['valueDate']) : null),
            visibilityDate: Value(data['visibilityDate'] != null ? DateTime.parse(data['visibilityDate']) : null),
            syncDate: Value(data['syncDate'] != null ? DateTime.parse(data['syncDate']) : null),
            provisionDate: Value(data['provisionDate'] != null ? DateTime.parse(data['provisionDate']) : null),
            step: data['step'] ?? 'effectue',
            status: data['status'] ?? 'provisionne',
            importHash: Value(data['importHash']),
            recurringTransactionId: Value(data['recurringTransactionId']),
            linkedTransactionId: Value(data['linkedTransactionId']),
            createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
            updatedAt: updatedAt,
          ),
        );

        // Delete old splits for this transaction to avoid duplicates
        await (_db.delete(_db.transactionSplits)..where((t) => t.transactionId.equals(doc.id))).go();

        // Insert new splits
        final splitsList = data['splits'] as List<dynamic>? ?? [];
        for (final splitMap in splitsList) {
          final sData = splitMap as Map<String, dynamic>;
          await _db.into(_db.transactionSplits).insertOnConflictUpdate(
            TransactionSplitsCompanion.insert(
              id: sData['id'] ?? UniqueKey().toString(),
              transactionId: doc.id,
              virtualAccountId: sData['virtualAccountId'] ?? '',
              amount: (sData['amount'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        }
      }
    }
  }

  // --- Local -> Remote Sync (Outbox) ---

  Future<void> addToOutbox({
    required String tableName,
    required String recordId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    await _db.into(_db.syncOutbox).insert(
      SyncOutboxCompanion.insert(
        targetTable: tableName,
        recordId: recordId,
        action: action,
        payload: jsonEncode(payload),
        createdAt: DateTime.now(),
      ),
    );
    
    // Trigger sync
    triggerSync();
  }

  Future<void> triggerSync() async {
    if (_isSyncingOutbox) return;
    _isSyncingOutbox = true;

    try {
      final outboxItems = await (_db.select(_db.syncOutbox)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      if (outboxItems.isEmpty) {
        _isSyncingOutbox = false;
        return;
      }

      for (final item in outboxItems) {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;

        try {
          if (item.targetTable == 'real_accounts') {
            final docRef = _firestore.collection('accounts').doc(item.recordId);
            if (item.action == 'DELETE') {
              await docRef.delete();
            } else {
              await docRef.set(payload, SetOptions(merge: true));
            }
          } else if (item.targetTable == 'virtual_accounts') {
            final realAccountId = payload['realAccountId'] as String;
            final docRef = _firestore
                .collection('accounts')
                .doc(realAccountId)
                .collection('virtual_accounts')
                .doc(item.recordId);

            if (item.action == 'DELETE') {
              await docRef.delete();
            } else {
              await docRef.set(payload, SetOptions(merge: true));
            }
          } else if (item.targetTable == 'transactions') {
            final realAccountId = payload['realAccountId'] as String;
            final docRef = _firestore
                .collection('accounts')
                .doc(realAccountId)
                .collection('transactions')
                .doc(item.recordId);

            if (item.action == 'DELETE') {
              await docRef.delete();
            } else {
              await docRef.set(payload, SetOptions(merge: true));
            }
          }

          // Delete from local outbox after successful sync
          await (_db.delete(_db.syncOutbox)..where((t) => t.id.equals(item.id))).go();
        } catch (e) {
          debugPrint("Failed to sync outbox item ${item.id}: $e");
          break; // Stop and retry later (e.g. network offline)
        }
      }
    } finally {
      _isSyncingOutbox = false;
    }
  }

  Future<void> reconcileRealAccountBalances(String realAccountId) async {
    final realAcc = await (_db.select(_db.realAccounts)..where((t) => t.id.equals(realAccountId))).getSingleOrNull();
    if (realAcc == null) return;

    final vAccs = await (_db.select(_db.virtualAccounts)..where((t) => t.realAccountId.equals(realAccountId))).get();
    if (vAccs.isEmpty) return;

    VirtualAccountData? libreAccRow;
    for (final v in vAccs) {
      if (v.type == 'systemFree') {
        libreAccRow = v;
        break;
      }
    }
    final libreAcc = libreAccRow;
    if (libreAcc == null) return;

    double nonLibreSum = 0.0;
    for (final v in vAccs) {
      if (v.type != 'systemFree') {
        nonLibreSum += v.balance;
      }
    }

    final expectedLibreBalance = realAcc.balance - nonLibreSum;
    final diff = expectedLibreBalance - libreAcc.balance;

    if (diff.abs() > 0.001) {
      debugPrint("Reconciliation: Mismatch detected for account ${realAcc.name} (${realAcc.id}). "
          "Real Balance: ${realAcc.balance}, Non-Libre Envelopes Sum: $nonLibreSum. "
          "Adjusting Libre balance from ${libreAcc.balance} to $expectedLibreBalance (Diff: $diff).");

      // 1. Update SQLite locally
      final now = DateTime.now();
      await (_db.update(_db.virtualAccounts)..where((t) => t.id.equals(libreAcc.id))).write(
        VirtualAccountsCompanion(
          balance: Value(expectedLibreBalance),
          updatedAt: Value(now),
        ),
      );

      // 2. Push corrected Libre balance to outbox to update Firestore
      final payload = {
        'id': libreAcc.id,
        'userId': libreAcc.userId,
        'realAccountId': libreAcc.realAccountId,
        'name': libreAcc.name,
        'balance': expectedLibreBalance,
        'type': libreAcc.type,
        'icon': libreAcc.icon,
        'updatedAt': now.toIso8601String(),
      };
      await addToOutbox(
        tableName: 'virtual_accounts',
        recordId: libreAcc.id,
        action: 'UPDATE',
        payload: payload,
      );
    }
  }
}

@Riverpod(keepAlive: true)
SyncManager syncManager(Ref ref) {
  final db = ref.watch(localDatabaseProvider);
  final firestore = ref.watch(firestoreProvider);
  return SyncManager(db, firestore);
}

@Riverpod(keepAlive: true)
LocalDatabase localDatabase(Ref ref) {
  final db = LocalDatabase();
  ref.onDispose(() => db.close());
  return db;
}
