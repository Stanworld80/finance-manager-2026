import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers.dart';
import '../data/recurring_transaction_repository.dart';
import '../domain/recurring_transaction_model.dart';

part 'recurring_transaction_providers.g.dart';

@riverpod
Stream<List<RecurringTransaction>> recurringTransactions(
  Ref ref,
) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);

  return ref
      .watch(recurringTransactionRepositoryProvider)
      .watchRecurringTransactions(user.uid);
}
