import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers.dart';
import '../application/account_service.dart';
import '../domain/account_models.dart';
import 'account_repository.dart';

part 'account_providers.g.dart';

@riverpod
Stream<List<RealAccount>> realAccounts(RealAccountsRef ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(accountRepositoryProvider).watchRealAccounts(user.uid);
}

@riverpod
Stream<List<VirtualAccount>> virtualAccounts(
  VirtualAccountsRef ref,
  String realAccountId,
) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref
      .watch(accountRepositoryProvider)
      .watchVirtualAccounts(user.uid, realAccountId);
}

@riverpod
Stream<List<VirtualAccount>> allVirtualAccounts(AllVirtualAccountsRef ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(accountRepositoryProvider).watchAllVirtualAccounts(user.uid);
}

/// Automatically repairs Libre balance discrepancies whenever accounts load.
///
/// This provider watches `realAccountsProvider` (which already streams from
/// Firestore) and triggers a background repair pass the first time a non-empty
/// list arrives.  Each account's Libre envelope is patched silently if:
///   sum(all other envelopes) + Libre ≠ RealAccount.balance
///
/// The result (number of accounts repaired) is logged in debug builds but is
/// otherwise invisible to the user.
@riverpod
Future<int> autoRepairLibre(AutoRepairLibreRef ref) async {
  // Wait until at least one real account is available before running
  final accounts = await ref.watch(realAccountsProvider.future);
  if (accounts.isEmpty) return 0;

  // Run repair — this is idempotent and fast (skips accounts where gap < 0.01)
  final service = ref.read(accountServiceProvider);
  final repaired = await service.repairAllLibreBalances();

  if (repaired > 0) {
    // ignore: avoid_print
    print('[AutoRepair] Libre balance repaired on $repaired account(s).');
  }
  return repaired;
}
