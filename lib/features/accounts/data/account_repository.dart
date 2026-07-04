import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/data/local_database.dart';
import '../../../../core/data/sync_manager.dart';
import '../domain/account_models.dart';

part 'account_repository.g.dart';

class AccountRepository {
  final LocalDatabase _db;
  final SyncManager _sync;

  AccountRepository(this._db, this._sync);

  // --- Real Accounts ---

  Future<void> createRealAccount(String userId, RealAccount account) async {
    final now = DateTime.now();
    await _db.into(_db.realAccounts).insert(
      RealAccountsCompanion.insert(
        id: account.id,
        ownerId: userId,
        name: account.name,
        bankName: drift.Value(account.bankName),
        initialBalance: drift.Value(account.initialBalance),
        balance: drift.Value(account.balance),
        type: account.type.name,
        isPrincipal: drift.Value(account.isPrincipal),
        sharedWithUserIds: jsonEncode(account.sharedWithUserIds),
        openingDate: drift.Value(account.openingDate),
        accountNumber: drift.Value(account.accountNumber),
        officialName: drift.Value(account.officialName),
        iban: drift.Value(account.iban),
        bic: drift.Value(account.bic),
        swift: drift.Value(account.swift),
        updatedAt: now,
      ),
    );

    // Save outbox payload for Cloud Firestore
    final payload = account.toMap();
    payload['accessibleUserIds'] = [userId, ...account.sharedWithUserIds];
    payload['updatedAt'] = now.toIso8601String();

    await _sync.addToOutbox(
      tableName: 'real_accounts',
      recordId: account.id,
      action: 'INSERT',
      payload: payload,
    );
  }

  Future<void> updateRealAccount(String userId, RealAccount account) async {
    final now = DateTime.now();
    await (_db.update(_db.realAccounts)..where((t) => t.id.equals(account.id))).write(
      RealAccountsCompanion(
        name: drift.Value(account.name),
        bankName: drift.Value(account.bankName),
        balance: drift.Value(account.balance),
        type: drift.Value(account.type.name),
        isPrincipal: drift.Value(account.isPrincipal),
        sharedWithUserIds: drift.Value(jsonEncode(account.sharedWithUserIds)),
        updatedAt: drift.Value(now),
      ),
    );

    final payload = account.toMap();
    payload['accessibleUserIds'] = [account.ownerId, ...account.sharedWithUserIds];
    payload['updatedAt'] = now.toIso8601String();

    await _sync.addToOutbox(
      tableName: 'real_accounts',
      recordId: account.id,
      action: 'UPDATE',
      payload: payload,
    );
  }

  Stream<List<RealAccount>> watchRealAccounts(String userId) {
    return _db.select(_db.realAccounts).watch().map((rows) {
      return rows.map((row) {
        final List<dynamic> shared = jsonDecode(row.sharedWithUserIds);
        return RealAccount(
          id: row.id,
          ownerId: row.ownerId,
          name: row.name,
          bankName: row.bankName,
          initialBalance: row.initialBalance,
          balance: row.balance,
          type: RealAccountType.values.firstWhere(
            (e) => e.name == row.type,
            orElse: () => RealAccountType.internal,
          ),
          isPrincipal: row.isPrincipal,
          sharedWithUserIds: shared.cast<String>(),
          openingDate: row.openingDate,
          accountNumber: row.accountNumber,
          officialName: row.officialName,
          iban: row.iban,
          bic: row.bic,
          swift: row.swift,
        );
      }).toList();
    });
  }

  // watchSharedRealAccounts is deprecated but kept for backwards compatibility if needed,
  // though watchRealAccounts now handles everything.
  Stream<List<RealAccount>> watchSharedRealAccounts(String userId) {
    return watchRealAccounts(userId);
  }

  Future<RealAccount?> getRealAccount(String userId, String accountId) async {
    final row = await (_db.select(_db.realAccounts)..where((t) => t.id.equals(accountId))).getSingleOrNull();
    if (row == null) return null;
    final List<dynamic> shared = jsonDecode(row.sharedWithUserIds);
    return RealAccount(
      id: row.id,
      ownerId: row.ownerId,
      name: row.name,
      bankName: row.bankName,
      initialBalance: row.initialBalance,
      balance: row.balance,
      type: RealAccountType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => RealAccountType.internal,
      ),
      isPrincipal: row.isPrincipal,
      sharedWithUserIds: shared.cast<String>(),
      openingDate: row.openingDate,
      accountNumber: row.accountNumber,
      officialName: row.officialName,
      iban: row.iban,
      bic: row.bic,
      swift: row.swift,
    );
  }

  Future<List<RealAccount>> getRealAccounts(String userId) async {
    final rows = await _db.select(_db.realAccounts).get();
    return rows.map((row) {
      final List<dynamic> shared = jsonDecode(row.sharedWithUserIds);
      return RealAccount(
        id: row.id,
        ownerId: row.ownerId,
        name: row.name,
        bankName: row.bankName,
        initialBalance: row.initialBalance,
        balance: row.balance,
        type: RealAccountType.values.firstWhere(
          (e) => e.name == row.type,
          orElse: () => RealAccountType.internal,
        ),
        isPrincipal: row.isPrincipal,
        sharedWithUserIds: shared.cast<String>(),
        openingDate: row.openingDate,
        accountNumber: row.accountNumber,
        officialName: row.officialName,
        iban: row.iban,
        bic: row.bic,
        swift: row.swift,
      );
    }).toList();
  }

  Future<void> deleteRealAccount(String userId, String accountId) async {
    await (_db.delete(_db.realAccounts)..where((t) => t.id.equals(accountId))).go();

    await _sync.addToOutbox(
      tableName: 'real_accounts',
      recordId: accountId,
      action: 'DELETE',
      payload: {},
    );
  }

  // --- Virtual Accounts ---

  Future<void> createVirtualAccount(String userId, VirtualAccount account) async {
    final now = DateTime.now();
    await _db.into(_db.virtualAccounts).insert(
      VirtualAccountsCompanion.insert(
        id: account.id,
        userId: userId,
        realAccountId: account.realAccountId,
        name: account.name,
        balance: drift.Value(account.balance),
        type: account.type.name,
        icon: drift.Value(account.icon),
        updatedAt: now,
      ),
    );

    final payload = account.toMap();
    payload['updatedAt'] = now.toIso8601String();

    await _sync.addToOutbox(
      tableName: 'virtual_accounts',
      recordId: account.id,
      action: 'INSERT',
      payload: payload,
    );
  }

  Stream<List<VirtualAccount>> watchVirtualAccounts(String userId, String realAccountId) {
    return (_db.select(_db.virtualAccounts)..where((t) => t.realAccountId.equals(realAccountId))).watch().map((rows) {
      return rows.map((row) {
        return VirtualAccount(
          id: row.id,
          userId: row.userId,
          realAccountId: row.realAccountId,
          name: row.name,
          balance: row.balance,
          type: VirtualAccountType.values.firstWhere(
            (e) => e.name == row.type,
            orElse: () => VirtualAccountType.userBudget,
          ),
          icon: row.icon,
        );
      }).toList();
    });
  }

  Future<VirtualAccount?> getVirtualAccountByType(String userId, String realAccountId, VirtualAccountType type) async {
    final row = await (_db.select(_db.virtualAccounts)
      ..where((t) => t.realAccountId.equals(realAccountId) & t.type.equals(type.name))
      ..limit(1))
      .getSingleOrNull();

    if (row == null) return null;
    return VirtualAccount(
      id: row.id,
      userId: row.userId,
      realAccountId: row.realAccountId,
      name: row.name,
      balance: row.balance,
      type: VirtualAccountType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => VirtualAccountType.userBudget,
      ),
      icon: row.icon,
    );
  }

  Future<void> updateVirtualAccount(String userId, VirtualAccount account) async {
    final now = DateTime.now();
    await (_db.update(_db.virtualAccounts)..where((t) => t.id.equals(account.id))).write(
      VirtualAccountsCompanion(
        name: drift.Value(account.name),
        balance: drift.Value(account.balance),
        icon: drift.Value(account.icon),
        updatedAt: drift.Value(now),
      ),
    );

    final payload = account.toMap();
    payload['updatedAt'] = now.toIso8601String();

    await _sync.addToOutbox(
      tableName: 'virtual_accounts',
      recordId: account.id,
      action: 'UPDATE',
      payload: payload,
    );
  }

  Future<void> deleteVirtualAccount(String userId, String virtualAccountId) async {
    // Left for backward compatibility, update virtual account directly.
  }

  Future<void> deleteVirtualAccountWithIds(String userId, String realAccountId, String virtualAccountId) async {
    await (_db.delete(_db.virtualAccounts)..where((t) => t.id.equals(virtualAccountId))).go();

    final payload = {'realAccountId': realAccountId};
    await _sync.addToOutbox(
      tableName: 'virtual_accounts',
      recordId: virtualAccountId,
      action: 'DELETE',
      payload: payload,
    );
  }

  Stream<List<VirtualAccount>> watchAllVirtualAccounts(String userId) {
    return (_db.select(_db.virtualAccounts)..where((t) => t.userId.equals(userId))).watch().map((rows) {
      return rows.map((row) {
        return VirtualAccount(
          id: row.id,
          userId: row.userId,
          realAccountId: row.realAccountId,
          name: row.name,
          balance: row.balance,
          type: VirtualAccountType.values.firstWhere(
            (e) => e.name == row.type,
            orElse: () => VirtualAccountType.userBudget,
          ),
          icon: row.icon,
        );
      }).toList();
    });
  }

  // --- Repair and balance checks ---

  Future<Map<String, int>> repairVirtualAccounts(String userId) async {
    // Simplified local implementation for MVP or trigger SyncManager initialization
    return {'repaired': 0, 'created': 0, 'totalAccounts': 0, 'totalVirtuals': 0};
  }

  Future<bool> repairLibreBalanceIfNeeded({
    required String userId,
    required String realAccountId,
    required List<VirtualAccount> virtualAccounts,
    required double realBalance,
  }) async {
    return false;
  }
}

@riverpod
AccountRepository accountRepository(Ref ref) {
  return AccountRepository(ref.watch(localDatabaseProvider), ref.watch(syncManagerProvider));
}
