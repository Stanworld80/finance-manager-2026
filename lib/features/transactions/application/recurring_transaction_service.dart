import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers.dart';
import '../data/recurring_transaction_repository.dart';
import '../data/transaction_repository.dart';
import '../domain/recurring_transaction.dart';
import '../domain/transaction_model.dart';

part 'recurring_transaction_service.g.dart';

@riverpod
RecurringTransactionService recurringTransactionService(
  RecurringTransactionServiceRef ref,
) {
  return RecurringTransactionService(ref);
}

class RecurringTransactionService {
  final RecurringTransactionServiceRef ref;

  RecurringTransactionService(this.ref);

  Future<void> createRecurringTransaction({
    required double amount,
    required String label,
    required RecurringFrequency frequency,
    required DateTime startDate,
    required String realAccountId,
    String? targetVirtualAccountId,
    List<TransactionSplit> splits = const [],
    int interval = 1,
    String? category,
    String? note,
    String? payee,
    TransactionType type = TransactionType.debit,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final repo = ref.read(recurringTransactionRepositoryProvider);
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final recurring = RecurringTransaction(
      id: id,
      ownerId: user.uid,
      realAccountId: realAccountId,
      amount: amount,
      label: label,
      category: category,
      note: note,
      payee: payee,
      type: type,
      targetVirtualAccountId: targetVirtualAccountId,
      splits: splits,
      frequency: frequency,
      interval: interval,
      startDate: startDate,
      nextDueDate: startDate, // First generation is on start date
      createdAt: DateTime.now(),
    );

    await repo.createRecurringTransaction(user.uid, recurring);
  }

  /// Checks all active recurring templates and generates transactions if due.
  Future<int> syncRecurringTransactions() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return 0;

    final repo = ref.read(recurringTransactionRepositoryProvider);
    final txRepo = ref.read(transactionRepositoryProvider);
    final now = DateTime.now();

    final actives = await repo.getActiveRecurringTransactions(user.uid);
    int generatedCount = 0;

    for (final template in actives) {
      if (template.nextDueDate.isBefore(now) ||
          template.nextDueDate.isAtSameMomentAs(now)) {
        // Generate the transaction
        final plannedTx = template.toPlannedTransaction(template.nextDueDate);

        // Save it (Atomic)
        await txRepo.createTransaction(user.uid, plannedTx);

        // Calculate next due date
        final nextDueDate = _calculateNextDate(
          template.nextDueDate,
          template.frequency,
          template.interval,
        );

        // Update template
        final updatedTemplate = RecurringTransaction(
          id: template.id,
          ownerId: template.ownerId,
          realAccountId: template.realAccountId,
          amount: template.amount,
          label: template.label,
          category: template.category,
          note: template.note,
          payee: template.payee,
          type: template.type,
          targetVirtualAccountId: template.targetVirtualAccountId,
          splits: template.splits,
          frequency: template.frequency,
          interval: template.interval,
          startDate: template.startDate,
          endDate: template.endDate,
          lastGeneratedDate: template.nextDueDate,
          nextDueDate: nextDueDate,
          createdAt: template.createdAt,
          isActive: template.endDate != null
              ? nextDueDate.isBefore(template.endDate!)
              : true,
        );

        await repo.updateRecurringTransaction(user.uid, updatedTemplate);
        generatedCount++;
      }
    }

    return generatedCount;
  }

  DateTime _calculateNextDate(
    DateTime current,
    RecurringFrequency frequency,
    int interval,
  ) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return current.add(Duration(days: interval));
      case RecurringFrequency.weekly:
        return current.add(Duration(days: 7 * interval));
      case RecurringFrequency.monthly:
        // Simple month addition (doesn't handle end-of-month perfectly but standard for now)
        return DateTime(current.year, current.month + interval, current.day);
      case RecurringFrequency.yearly:
        return DateTime(current.year + interval, current.month, current.day);
    }
  }
}
