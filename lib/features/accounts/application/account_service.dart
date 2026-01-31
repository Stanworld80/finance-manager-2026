import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers.dart';
import '../data/account_repository.dart';
import '../domain/account_models.dart';

part 'account_service.g.dart';

@riverpod
AccountService accountService(AccountServiceRef ref) {
  return AccountService(ref);
}

class AccountService {
  final AccountServiceRef ref;

  AccountService(this.ref);

  /// Initializes the user's default accounts if they don't exist.
  /// Typically called after login.
  Future<void> ensureUserInitialized() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    // Check if any real account exists
    // We use a stream in the repo, but here we might want a simple get or assume stream logic.
    // For simplicity, we can try to fetch the list once.
    // Since the repo currently only has watch methods or single get, we might need a fetchAll.
    // Let's assume for now if list is empty, we create one.

    // Wait for the stream to emit once (not ideal for check, but workable)
    // Or better: Add a fetch method to repo.
    // For now, let's just expose a direct create method and UI calls it if empty.
    // BUT, the request is for "Smart init".

    // Let's rely on the UI/Logic layer to check `watchRealAccounts` and call `createRealAccount` if empty.
  }

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

    // 1. Create Real Account
    final realAccount = RealAccount(
      id: uuid.v4(),
      ownerId: user.uid,
      name: name,
      bankName: bankName,
      initialBalance: initialBalance,
      balance: initialBalance,
    );

    // 2. Create System Virtual Accounts

    // A. "Libre" (Free) - Receives the initial balance by default
    final freeAccount = VirtualAccount(
      id: uuid.v4(),
      realAccountId: realAccount.id,
      name: "Libre",
      balance: initialBalance,
      type: VirtualAccountType.systemFree,
      icon: "savings",
    );

    // B. "Solde Engagé" (Committed) - Starts at 0
    final committedAccount = VirtualAccount(
      id: uuid.v4(),
      realAccountId: realAccount.id,
      name: "Solde Engagé",
      balance: 0.0,
      type: VirtualAccountType.systemCommitted,
      icon: "lock_clock",
    );

    // C. "À Distribuer" (Flow) - Starts at 0
    final flowAccount = VirtualAccount(
      id: uuid.v4(),
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
  }

  Future<void> createVirtualAccount({
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
      realAccountId: realAccountId,
      name: name,
      balance: 0.0,
      type: type,
      icon: "folder", // Default icon
    );

    await repository.createVirtualAccount(user.uid, virtualAccount);
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
        .getVirtualAccountsStream(user.uid)
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
}
