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

@riverpod
Stream<List<TransactionModel>> upcomingTransactions(
  UpcomingTransactionsRef ref,
) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);

  // Watch all and filter client side. In a real app we'd want a DB query
  return ref
      .watch(transactionRepositoryProvider)
      .watchTransactions(user.uid)
      .map(
        (txs) =>
            txs
                .where(
                  (tx) =>
                      tx.step == TransactionStep.planned ||
                      tx.step == TransactionStep.scheduled,
                )
                .toList()
              ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate)),
      );
}

@riverpod
Stream<List<TransactionModel>> externalTransactions(
  ExternalTransactionsRef ref,
  String externalEntityId,
) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);

  return ref
      .watch(transactionRepositoryProvider)
      .watchTransactions(user.uid)
      .map(
        (txs) =>
            txs.where((tx) => tx.externalEntityId == externalEntityId).toList()
              ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate)),
      );
}
