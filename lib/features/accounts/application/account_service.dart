import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers.dart';
import '../data/account_repository.dart';
import '../domain/account_models.dart';
import '../../transactions/application/transaction_service.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../auth/data/user_repository.dart';

part 'account_service.g.dart';

@riverpod
AccountService accountService(Ref ref) {
  return AccountService(ref);
}

/// Service for managing real and virtual accounts.
///
/// This service provides high-level operations for:
/// - Creating real bank accounts with associated system virtual accounts
/// - Creating, renaming, and deleting user budget envelopes
/// - Managing account metadata (IBAN, BIC, etc.)
/// - Data repair operations
///
/// Each real account automatically gets three system virtual accounts:
/// - **Libre (Free)**: Unallocated funds
/// - **Solde Engagé (Committed)**: Funds reserved for pending transactions
/// - **À Distribuer (To Distribute)**: Income waiting to be allocated
class AccountService {
  final Ref ref;

  /// Creates an AccountService with the given Riverpod reference.
  AccountService(this.ref);

  /// Initializes the user's default accounts if they don't exist.
  /// Typically called after login.
  Future<void> ensureUserInitialized() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    final repository = ref.read(accountRepositoryProvider);
    final existingAccounts = await repository.getRealAccounts(user.uid);

    // 1. Check for Generic External Account
    final hasGenericExternal = existingAccounts.any(
      (a) => a.type == RealAccountType.externalGeneric,
    );

    if (!hasGenericExternal) {
      final uuid = const Uuid();
      final genericExternal = RealAccount(
        id: uuid.v4(),
        ownerId: user.uid,
        name: "Monde extérieur - indéfini",
        bankName: "Exterieur",
        initialBalance: 0.0,
        balance: 0.0,
        type: RealAccountType.externalGeneric,
      );
      await repository.createRealAccount(user.uid, genericExternal);
      await _createExternalSystemAccounts(user.uid, genericExternal.id);
    }
  }

  /// Helper to create default system accounts for an external entity
  Future<void> _createExternalSystemAccounts(
    String userId,
    String realAccountId,
  ) async {
    final repository = ref.read(accountRepositoryProvider);
    final uuid = const Uuid();

    // A. "Libre" (Free)
    final freeAccount = VirtualAccount(
      id: uuid.v4(),
      userId: userId,
      realAccountId: realAccountId,
      name: "Libre",
      balance: 0.0,
      type: VirtualAccountType.systemFree,
      icon: "public",
    );

    // B. "Solde Engagé" (Committed)
    final committedAccount = VirtualAccount(
      id: uuid.v4(),
      userId: userId,
      realAccountId: realAccountId,
      name: "Solde Engagé",
      balance: 0.0,
      type: VirtualAccountType.systemCommitted,
      icon: "lock_clock",
    );

    await repository.createVirtualAccount(userId, freeAccount);
    await repository.createVirtualAccount(userId, committedAccount);
  }

  /// Streams all external entities (RealAccountType.external or externalGeneric)
  Stream<List<RealAccount>> watchExternalEntities() {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return Stream.value([]);

    return ref
        .read(accountRepositoryProvider)
        .watchRealAccounts(user.uid)
        .map(
          (accounts) => accounts
              .where(
                (a) =>
                    a.type == RealAccountType.external ||
                    a.type == RealAccountType.externalGeneric,
              )
              .toList(),
        );
  }

  /// Creates a new specific external entity (e.g., "Amazon", "Employeur")
  Future<RealAccount> createExternalEntity(String name) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(accountRepositoryProvider);
    final uuid = const Uuid();

    final entity = RealAccount(
      id: uuid.v4(),
      ownerId: user.uid,
      name: name,
      bankName: "Exterieur",
      initialBalance: 0.0,
      balance: 0.0,
      type: RealAccountType.external,
    );

    await repository.createRealAccount(user.uid, entity);
    await _createExternalSystemAccounts(user.uid, entity.id);
    return entity;
  }

  /// Creates a new real bank account with associated system virtual accounts.
  ///
  /// This method:
  /// 1. Validates no duplicate account names exist
  /// 2. Creates the real account with the given [initialBalance]
  /// 3. Creates three system virtual accounts (Libre, Solde Engagé, À Distribuer)
  ///
  /// Throws [Exception] if:
  /// - User is not authenticated
  /// - An account with the same name (case-insensitive) already exists
  Future<void> createRealAccount({
    required String name,
    required String bankName,
    required double initialBalance,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }

    final repository = ref.read(accountRepositoryProvider);
    final uuid = const Uuid();

    // Check for duplicate account name
    final existingAccounts = await repository.getRealAccounts(user.uid);
    if (existingAccounts.any(
      (a) => a.name.toLowerCase() == name.toLowerCase(),
    )) {
      throw Exception("Un compte avec ce nom existe déjà.");
    }

    // 1. Create Real Account
    final realAccount = RealAccount(
      id: uuid.v4(),
      ownerId: user.uid,
      name: name,
      bankName: bankName,
      initialBalance: initialBalance,
      balance: 0.0, // Will be set to initialBalance by the initialization transaction
    );

    // 2. Create System Virtual Accounts

    // A. "Libre" (Free)
    final freeAccount = VirtualAccount(
      id: uuid.v4(),
      userId: user.uid,
      realAccountId: realAccount.id,
      name: "Libre",
      balance: 0.0, // Will be set to initialBalance by the initialization transaction
      type: VirtualAccountType.systemFree,
      icon: "savings",
    );

    // B. "Solde Engagé" (Committed) - Starts at 0
    final committedAccount = VirtualAccount(
      id: uuid.v4(),
      userId: user.uid,
      realAccountId: realAccount.id,
      name: "Solde Engagé",
      balance: 0.0,
      type: VirtualAccountType.systemCommitted,
      icon: "lock_clock",
    );

    // C. "À Distribuer" (Flow) - Starts at 0
    final flowAccount = VirtualAccount(
      id: uuid.v4(),
      userId: user.uid,
      realAccountId: realAccount.id,
      name: "À Distribuer",
      balance: 0.0,
      type: VirtualAccountType.flowToDistribute,
      icon: "input",
    );

    // Save all (Ideally transactional)
    await repository.createRealAccount(user.uid, realAccount);
    await repository.createVirtualAccount(user.uid, freeAccount);
    await repository.createVirtualAccount(user.uid, committedAccount);
    await repository.createVirtualAccount(user.uid, flowAccount);

    // Create the initialization transaction if initialBalance is not zero
    if (initialBalance != 0.0) {
      final txId = uuid.v4();
      final initTx = TransactionModel(
        id: txId,
        ownerId: user.uid,
        realAccountId: realAccount.id,
        amount: initialBalance,
        label: "Solde initial",
        type: TransactionType.credit,
        step: TransactionStep.completed,
        status: TransactionStatus.none,
        transactionDate: DateTime.now(),
        splits: [
          TransactionSplit(
            virtualAccountId: freeAccount.id,
            amount: initialBalance,
          ),
          TransactionSplit(
            virtualAccountId: SystemAccounts.external,
            amount: -initialBalance,
          ),
        ],
      );

      final transactionRepo = ref.read(transactionRepositoryProvider);
      await transactionRepo.createTransaction(user.uid, initTx);
    }
  }

  /// Creates a new user budget envelope (virtual account).
  ///
  /// [realAccountId] - The parent real account ID
  /// [name] - Display name for the envelope
  /// [type] - Defaults to [VirtualAccountType.userBudget]
  ///
  /// New envelopes start with a balance of 0.
  Future<VirtualAccount> createVirtualAccount({
    required String realAccountId,
    required String name,
    VirtualAccountType type = VirtualAccountType.userBudget,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }

    final repository = ref.read(accountRepositoryProvider);
    final uuid = const Uuid();

    final virtualAccount = VirtualAccount(
      id: uuid.v4(),
      userId: user.uid,
      realAccountId: realAccountId,
      name: name,
      balance: 0.0,
      type: type,
      icon: "folder", // Default icon
    );

    await repository.createVirtualAccount(user.uid, virtualAccount);
    return virtualAccount;
  }

  /// Deletes a user-created virtual account.
  /// Remaining balance is moved to the "Libre" (systemFree) account.
  Future<void> deleteVirtualAccount(VirtualAccount virtualAccount) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    // 1. Prevent deleting system accounts
    if (virtualAccount.type != VirtualAccountType.userBudget) {
      throw Exception("Impossible de supprimer un compte système.");
    }

    final repository = ref.read(accountRepositoryProvider);

    // 2. Find the "Libre" account for this Real Account
    // We assume the repository has a way to fetch by RealAccountId,
    // or we fetch all and filter. Since we don't have a direct query in the interface shown,
    // we'll rely on fetching all virtual accounts for the user (cached or stream)
    // or we assume the UI passes the list or we add a fetch method.
    // For MVP efficiency, let's fetch all (usually small number).
    final allVirtualAccounts = await repository
        .watchAllVirtualAccounts(user.uid)
        .first;

    final freeAccount = allVirtualAccounts.firstWhere(
      (acc) =>
          acc.realAccountId == virtualAccount.realAccountId &&
          acc.type == VirtualAccountType.systemFree,
      orElse: () => throw Exception("Compte Libre introuvable."),
    );

    // 3. Move Balance to Free Account
    // If the deleted account has 100€, we add 100€ to Libre.
    // If it has -50€, we subtract 50€ from Libre.
    if (virtualAccount.balance != 0) {
      final newFreeBalance = freeAccount.balance + virtualAccount.balance;

      // Update Free Account locally
      final updatedFreeAccount = VirtualAccount(
        id: freeAccount.id,
        userId: user.uid,
        realAccountId: freeAccount.realAccountId,
        name: freeAccount.name,
        balance: newFreeBalance,
        type: freeAccount.type,
        icon: freeAccount.icon,
      );

      // Save Free Account
      await repository.updateVirtualAccount(user.uid, updatedFreeAccount);
    }

    // 4. Delete the target account
    await repository.deleteVirtualAccountWithIds(
      user.uid,
      virtualAccount.realAccountId,
      virtualAccount.id,
    );
  }

  /// Updates metadata for a real account.
  ///
  /// Only provided fields are updated; null values leave the field unchanged.
  /// Balance and type cannot be modified through this method.
  Future<void> updateRealAccountMetadata({
    required RealAccount account,
    String? name,
    String? bankName,
    DateTime? openingDate,
    String? accountNumber,
    String? officialName,
    String? iban,
    String? bic,
    String? swift,
    bool? isPrincipal,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(accountRepositoryProvider);

    final updatedAccount = RealAccount(
      id: account.id,
      ownerId: account.ownerId,
      name: name ?? account.name,
      bankName: bankName ?? account.bankName,
      initialBalance: account.initialBalance,
      balance: account.balance,
      type: account.type,
      isPrincipal: isPrincipal ?? account.isPrincipal,
      openingDate: openingDate ?? account.openingDate,
      accountNumber: accountNumber ?? account.accountNumber,
      officialName: officialName ?? account.officialName,
      iban: iban ?? account.iban,
      bic: bic ?? account.bic,
      swift: swift ?? account.swift,
    );

    await repository.updateRealAccount(user.uid, updatedAccount);
  }

  /// Convenience method to rename a real account.
  ///
  /// Equivalent to calling [updateRealAccountMetadata] with only the name.
  Future<void> renameRealAccount(RealAccount account, String newName) async {
    await updateRealAccountMetadata(account: account, name: newName);
  }

  /// Shares a real account with another user by their email address.
  Future<void> shareRealAccount(RealAccount account, String email) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    if (account.ownerId != user.uid) {
      throw Exception("Seul le propriétaire peut partager ce compte.");
    }

    final userRepo = ref.read(userRepositoryProvider);
    final profile = await userRepo.findUserByEmail(email);

    if (profile == null) {
      throw Exception("Aucun utilisateur trouvé avec cet e-mail.");
    }

    if (account.ownerId == profile.uid) {
      throw Exception("Vous ne pouvez pas partager le compte avec vous-même.");
    }

    if (account.sharedWithUserIds.contains(profile.uid)) {
      throw Exception("Le compte est déjà partagé avec cet utilisateur.");
    }

    final repository = ref.read(accountRepositoryProvider);
    final updatedAccount = RealAccount(
      id: account.id,
      ownerId: account.ownerId,
      name: account.name,
      bankName: account.bankName,
      initialBalance: account.initialBalance,
      balance: account.balance,
      type: account.type,
      sharedWithUserIds: [...account.sharedWithUserIds, profile.uid],
      openingDate: account.openingDate,
      accountNumber: account.accountNumber,
      officialName: account.officialName,
      iban: account.iban,
      bic: account.bic,
      swift: account.swift,
    );

    await repository.updateRealAccount(account.ownerId, updatedAccount);
  }

  Future<Map<String, int>> repairData() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    // 1. Run standard repair logic (fixes user IDs, creates missing system accounts)
    final repairResult = await ref
        .read(accountRepositoryProvider)
        .repairVirtualAccounts(user.uid);

    // 2. Cleanup Orphaned Virtual Accounts
    final repository = ref.read(accountRepositoryProvider);
    final allRealAccounts = await repository.getRealAccounts(user.uid);
    final validRealAccountIds = allRealAccounts.map((a) => a.id).toSet();

    final allVirtualAccounts = await repository
        .watchAllVirtualAccounts(user.uid)
        .first;

    int orphanedDeleted = 0;

    for (final virtualAcc in allVirtualAccounts) {
      if (!validRealAccountIds.contains(virtualAcc.realAccountId)) {
        // Attempt to delete the orphaned account.
        // Note: Normally deleteVirtualAccountWithIds expects the real account to exist,
        // but the collection path just needs the ID in the URL.
        try {
          await repository.deleteVirtualAccountWithIds(
            user.uid,
            virtualAcc.realAccountId,
            virtualAcc.id,
          );
          orphanedDeleted++;
        } catch (e) {
          // Ignore if deletion fails (e.g. permission denied because parent doesn't exist)
          // though our rules allow delete if virtualAccount.userId matches.
        }
      }
    }

    repairResult['orphanedDeleted'] = orphanedDeleted;

    return repairResult;
  }

  /// Checks every internal real account and auto-repairs any Libre balance
  /// discrepancy (sum of virtual envelopes ≠ RealAccount.balance).
  ///
  /// This is called automatically on app load so that CSV imports or other
  /// book-keeping gaps are transparently healed without user action.
  ///
  /// Returns the number of accounts that were repaired.
  Future<int> repairAllLibreBalances() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return 0;

    final repository = ref.read(accountRepositoryProvider);
    final allReal = await repository.getRealAccounts(user.uid);
    final internalAccounts = allReal
        .where((a) => a.type == RealAccountType.internal)
        .toList();

    int repaired = 0;
    for (final realAcc in internalAccounts) {
      final virtuals = await repository
          .watchVirtualAccounts(user.uid, realAcc.id)
          .first;

      final wasRepaired = await repository.repairLibreBalanceIfNeeded(
        userId: user.uid,
        realAccountId: realAcc.id,
        virtualAccounts: virtuals,
        realBalance: realAcc.balance,
      );
      if (wasRepaired) repaired++;
    }
    return repaired;
  }

  Future<void> renameVirtualAccount(
    VirtualAccount account,
    String newName,
  ) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    // 1. Prevent renaming system accounts
    if (account.type != VirtualAccountType.userBudget) {
      throw Exception("Impossible de renommer un compte système.");
    }

    final repository = ref.read(accountRepositoryProvider);

    final updatedAccount = VirtualAccount(
      id: account.id,
      userId: user.uid,
      realAccountId: account.realAccountId,
      name: newName,
      balance: account.balance,
      type: account.type,
      icon: account.icon,
    );

    await repository.updateVirtualAccount(user.uid, updatedAccount);
  }

  /// Deletes a real account and all its associated data (virtual accounts, transactions).
  Future<void> deleteRealAccount(RealAccount account) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    // 1. Delete all transactions associated with this account
    final txService = ref.read(transactionServiceProvider);
    final txRepo = ref.read(transactionRepositoryProvider);

    final transactions = await txRepo.getTransactionsByRealAccount(
      user.uid,
      account.id,
    );
    for (final tx in transactions) {
      await txService.deleteTransaction(transaction: tx);
    }

    // 2. Delete all virtual accounts
    final repository = ref.read(accountRepositoryProvider);
    final virtuals = await repository
        .watchVirtualAccounts(user.uid, account.id)
        .first;
    for (final v in virtuals) {
      await repository.deleteVirtualAccountWithIds(user.uid, account.id, v.id);
    }

    // 3. Delete the real account
    await repository.deleteRealAccount(user.uid, account.id);
  }

  /// Sets the specified account as the principal account and unsets all others.
  Future<void> setPrincipalAccount(String accountId) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repository = ref.read(accountRepositoryProvider);
    final allAccounts = await repository.getRealAccounts(user.uid);

    for (final account in allAccounts) {
      final shouldBePrincipal = account.id == accountId;
      if (account.isPrincipal != shouldBePrincipal) {
        final updatedAccount = RealAccount(
          id: account.id,
          ownerId: account.ownerId,
          name: account.name,
          bankName: account.bankName,
          initialBalance: account.initialBalance,
          balance: account.balance,
          type: account.type,
          isPrincipal: shouldBePrincipal,
          sharedWithUserIds: account.sharedWithUserIds,
          openingDate: account.openingDate,
          accountNumber: account.accountNumber,
          officialName: account.officialName,
          iban: account.iban,
          bic: account.bic,
          swift: account.swift,
        );
        await repository.updateRealAccount(user.uid, updatedAccount);
      }
    }
  }
}
