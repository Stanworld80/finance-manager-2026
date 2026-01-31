import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
}

@riverpod
AccountRepository accountRepository(AccountRepositoryRef ref) {
  return AccountRepository(ref.watch(firestoreProvider));
}
