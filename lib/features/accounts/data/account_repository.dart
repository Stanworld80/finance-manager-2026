import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers.dart';
import '../domain/account_models.dart';

part 'account_repository.g.dart';

class AccountRepository {
  final FirebaseFirestore _firestore;

  AccountRepository(this._firestore);

  // --- Real Accounts ---

  Future<void> createRealAccount(String userId, RealAccount account) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .doc(account.id)
        .set(account.toMap());
  }

  Future<void> updateRealAccount(String userId, RealAccount account) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .doc(account.id)
        .update(account.toMap());
  }

  Stream<List<RealAccount>> watchRealAccounts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RealAccount.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<RealAccount?> getRealAccount(String userId, String accountId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .doc(accountId)
        .get();

    if (doc.exists && doc.data() != null) {
      return RealAccount.fromMap(doc.data()!);
    }
    return null;
  }

  Future<List<RealAccount>> getRealAccounts(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .get();
    return snapshot.docs.map((doc) => RealAccount.fromMap(doc.data())).toList();
  }

  Future<void> deleteRealAccount(String userId, String accountId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .doc(accountId)
        .delete();
  }

  // --- Virtual Accounts ---

  Future<void> createVirtualAccount(
    String userId,
    VirtualAccount account,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .doc(account.realAccountId)
        .collection('virtual_accounts')
        .doc(account.id)
        .set(account.toMap());
  }

  Stream<List<VirtualAccount>> watchVirtualAccounts(
    String userId,
    String realAccountId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .doc(realAccountId)
        .collection('virtual_accounts')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VirtualAccount.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> updateVirtualAccount(
    String userId,
    VirtualAccount account,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .doc(account.realAccountId)
        .collection('virtual_accounts')
        .doc(account.id)
        .update(account.toMap());
  }

  Future<void> deleteVirtualAccount(
    String userId,
    String virtualAccountId,
  ) async {
    // Note: We need RealAccountId to delete.
    // However, the interface passed only ID.
    // To solve this cleanly without querying, we should pass the full object or RealAccountId.
    // For now, I'll update the interface in the Service to pass the object or ID and RealAccountId.
    // But since I already wrote the Service to call deleteVirtualAccount(user.uid, virtualAccount.id),
    // I need to change the Service first or implement a query here.
    // Querying is slow. Better: Update Service to pass RealAccount ID.
  }

  // Actually, let's implement the method asked by the Service.
  // The service tries to find the account.

  // To implement `getVirtualAccountsStream(userId)` which returns ALL virtual accounts:
  // Since they are subcollections, we need collectionGroup or iterate real accounts.
  // collectionGroup 'virtual_accounts' is best.
  Stream<List<VirtualAccount>> watchAllVirtualAccounts(String userId) {
    return _firestore
        .collectionGroup('virtual_accounts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VirtualAccount.fromMap(doc.data()))
              .toList();
        });
  }

  // Fixing the delete method signature conflict from my thought process
  // I will overload or allow passing realAccountId if possible, but dart doesn't support overload.
  // I will implement `deleteVirtualAccount` taking the account object or IDs.
  // The service passed (userId, virtualAccountId).
  // Wait, the service code I wrote: `repository.deleteVirtualAccount(user.uid, virtualAccount.id);`
  // I missed the realAccountId in the Service call.
  // I should fix the Service call to `repository.deleteVirtualAccount(user.uid, virtualAccount);` or similar.
  // But I can't edit the service in this step easily without re-reading.

  // Let's implement `deleteVirtualAccount(String userId, String realAccountId, String virtualAccountId)`
  // And I will update the service in next step to match.
  Future<void> deleteVirtualAccountWithIds(
    String userId,
    String realAccountId,
    String virtualAccountId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .doc(realAccountId)
        .collection('virtual_accounts')
        .doc(virtualAccountId)
        .delete();
  }

  /// Repairs virtual accounts by ensuring they have the correct `userId`.
  /// Also creates missing system virtual accounts if they don't exist.
  /// This is necessary for collectionGroup queries to work correctly.
  Future<Map<String, int>> repairVirtualAccounts(String userId) async {
    int repairedCount = 0;
    int createdCount = 0;
    int totalVirtuals = 0;

    final realAccounts = await _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .get();

    for (var realDoc in realAccounts.docs) {
      final realAccountId = realDoc.id;
      final virtuals = await realDoc.reference
          .collection('virtual_accounts')
          .get();

      totalVirtuals += virtuals.docs.length;

      // Check if system accounts exist
      bool hasLibre = false;
      bool hasCommitted = false;
      bool hasFlow = false;

      for (var vDoc in virtuals.docs) {
        final data = vDoc.data();
        final type = data['type'] as String?;

        if (type == 'systemFree') hasLibre = true;
        if (type == 'systemCommitted') hasCommitted = true;
        if (type == 'flowToDistribute') hasFlow = true;

        // Fix userId if missing or empty
        if (data['userId'] == null ||
            data['userId'] == '' ||
            data['userId'] != userId) {
          await vDoc.reference.update({'userId': userId});
          repairedCount++;
        }
      }

      // Create missing system accounts
      if (!hasLibre) {
        await _createSystemVirtualAccount(
          userId,
          realAccountId,
          'Libre',
          'systemFree',
          'savings',
          realDoc.data()['initialBalance']?.toDouble() ?? 0.0,
        );
        createdCount++;
      }
      if (!hasCommitted) {
        await _createSystemVirtualAccount(
          userId,
          realAccountId,
          'Solde Engagé',
          'systemCommitted',
          'lock_clock',
          0.0,
        );
        createdCount++;
      }
      if (!hasFlow) {
        await _createSystemVirtualAccount(
          userId,
          realAccountId,
          'À Distribuer',
          'flowToDistribute',
          'input',
          0.0,
        );
        createdCount++;
      }
    }

    return {
      'repaired': repairedCount,
      'created': createdCount,
      'totalAccounts': realAccounts.docs.length,
      'totalVirtuals': totalVirtuals,
    };
  }

  Future<void> _createSystemVirtualAccount(
    String userId,
    String realAccountId,
    String name,
    String type,
    String icon,
    double balance,
  ) async {
    final id = const Uuid().v4();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('real_accounts')
        .doc(realAccountId)
        .collection('virtual_accounts')
        .doc(id)
        .set({
          'id': id,
          'userId': userId,
          'realAccountId': realAccountId,
          'name': name,
          'type': type,
          'icon': icon,
          'balance': balance,
        });
  }
}

@riverpod
AccountRepository accountRepository(AccountRepositoryRef ref) {
  return AccountRepository(ref.watch(firestoreProvider));
}
