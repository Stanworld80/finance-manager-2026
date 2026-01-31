import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers.dart';
import '../domain/transaction_model.dart';
import 'transaction_repository.dart';

part 'transaction_providers.g.dart';

@riverpod
Stream<List<TransactionModel>> recentTransactions(RecentTransactionsRef ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(transactionRepositoryProvider).watchTransactions(user.uid);
}

@riverpod
Stream<TransactionModel?> transactionById(TransactionByIdRef ref, String id) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value(null);
  return ref
      .watch(transactionRepositoryProvider)
      .watchTransaction(user.uid, id);
}
