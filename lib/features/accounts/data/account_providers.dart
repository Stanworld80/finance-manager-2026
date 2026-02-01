import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers.dart';
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
