import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/accounts/domain/account_models.dart';
import '../../features/transactions/domain/transaction_model.dart';
import 'package:uuid/uuid.dart';

class SeedService {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  SeedService(this._firestore);

  Future<void> seedTechnicalAccount(String userId) async {
    // 1. Create a Real Account
    final realAccountId = _uuid.v4();
    final realAccount = RealAccount(
      id: realAccountId,
      ownerId: userId,
      name: 'Compte Technique Test',
      bankName: 'Banque Virtuelle AI',
      initialBalance: 5000.0,
      balance: 5000.0,
      type: RealAccountType.internal,
    );

    final accToMap = realAccount.toMap();
    accToMap['accessibleUserIds'] = [userId];

    await _firestore.collection('accounts').doc(realAccountId).set(accToMap);

    // 2. Create Virtual Accounts (System Free & System Committed)
    final freeAccountId = _uuid.v4();
    final freeAccount = VirtualAccount(
      id: freeAccountId,
      userId: userId,
      realAccountId: realAccountId,
      name: 'Libre',
      balance: 5000.0,
      type: VirtualAccountType.systemFree,
    );

    final committedAccountId = _uuid.v4();
    final committedAccount = VirtualAccount(
      id: committedAccountId,
      userId: userId,
      realAccountId: realAccountId,
      name: 'Engagé',
      balance: 0.0,
      type: VirtualAccountType.systemCommitted,
    );

    final foodAccountId = _uuid.v4();
    final foodAccount = VirtualAccount(
      id: foodAccountId,
      userId: userId,
      realAccountId: realAccountId,
      name: 'Alimentation',
      balance: 0.0,
      type: VirtualAccountType.userBudget,
      icon: 'restaurant',
    );

    await _firestore
        .collection('accounts')
        .doc(realAccountId)
        .collection('virtual_accounts')
        .doc(freeAccountId)
        .set(freeAccount.toMap());

    await _firestore
        .collection('accounts')
        .doc(realAccountId)
        .collection('virtual_accounts')
        .doc(committedAccountId)
        .set(committedAccount.toMap());

    await _firestore
        .collection('accounts')
        .doc(realAccountId)
        .collection('virtual_accounts')
        .doc(foodAccountId)
        .set(foodAccount.toMap());

    // 3. Create initial transactions
    final transactionId = _uuid.v4();
    final transaction = TransactionModel(
      id: transactionId,
      ownerId: userId,
      realAccountId: realAccountId,
      amount: 5000.0,
      type: TransactionType.credit,
      transactionDate: DateTime.now(),
      label: 'Initial Seed Funding',
      category: 'Setup',
      splits: [
        TransactionSplit(virtualAccountId: freeAccountId, amount: 5000.0),
      ],
    );

    await _firestore
        .collection('accounts')
        .doc(realAccountId)
        .collection('transactions')
        .doc(transactionId)
        .set(transaction.toMap());
  }

  Future<void> clearAllData(String userId) async {
    final batch = _firestore.batch();

    // 1. Delete Transactions (Actually, transactions are under accounts now)
    // We will delete them when we iterate real accounts.

    // 2. Delete Real Accounts (and their sub-collections)
    final realAccounts = await _firestore
        .collection('accounts')
        .where('ownerId', isEqualTo: userId)
        .get();

    for (var raDoc in realAccounts.docs) {
      // Delete Virtual Accounts
      final virtualAccounts = await raDoc.reference
          .collection('virtual_accounts')
          .get();
      for (var vaDoc in virtualAccounts.docs) {
        batch.delete(vaDoc.reference);
      }
      // Delete Transactions
      final txs = await raDoc.reference.collection('transactions').get();
      for (var txDoc in txs.docs) {
        batch.delete(txDoc.reference);
      }

      batch.delete(raDoc.reference);
    }

    // We should also delete projects
    final projects = await _firestore
        .collection('projects')
        .where('ownerId', isEqualTo: userId)
        .get();
    for (var doc in projects.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
