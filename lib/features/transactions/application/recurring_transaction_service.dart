import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers.dart';
import '../data/recurring_transaction_repository.dart';
import '../data/transaction_repository.dart';
import '../domain/recurring_transaction_model.dart';
import '../domain/transaction_model.dart'; // Needed for TransactionModel output

part 'recurring_transaction_service.g.dart';

@riverpod
RecurringTransactionService recurringTransactionService(
  Ref ref,
) {
  return RecurringTransactionService(ref);
}

class RecurringTransactionService {
  final Ref ref;

  RecurringTransactionService(this.ref);

  Future<void> addRecurringTransaction({
    required RecurrenceFrequency frequency,
    int interval = 1,
    required DateTime startDate,
    DateTime? endDate,
    required String realAccountId,
    required double amount,
    required String label,
    String? note,
    required TransactionType type,
    List<TransactionSplit> splits = const [],
    String? externalEntityId,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final uuid = const Uuid();
    final repository = ref.read(recurringTransactionRepositoryProvider);

    // Initial calculation of next occurrence
    // If startDate is in the future, next is startDate.
    // If startDate is today, next is today.
    // If startDate is past, we might want to catch up or just start from 'now' or 'startDate' logic?
    // Let's assume startDate is the first occurrence.
    // However, we should check if startDate is already "passed" in terms of "should have run".
    // But for "Planning", we usually define start date.

    // For now, nextOccurrence is startDate.
    final recurring = RecurringTransaction(
      id: uuid.v4(),
      ownerId: user.uid,
      frequency: frequency,
      interval: interval,
      startDate: startDate,
      endDate: endDate,
      nextOccurrence: startDate, // First occurrence is start date
      realAccountId: realAccountId,
      amount: amount,
      label: label,
      note: note,
      type: type,
      splits: splits,
      externalEntityId: externalEntityId,
    );

    await repository.createRecurringTransaction(user.uid, recurring);
  }

  Future<void> deleteRecurringTransaction(String id) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    await ref
        .read(recurringTransactionRepositoryProvider)
        .deleteRecurringTransaction(user.uid, id);
  }

  /// Generates a list of future transaction occurrences up to [untilDate].
  /// These are temporary `TransactionModel` objects (id generated but not saved).
  Future<List<TransactionModel>> generateOccurrences(DateTime untilDate) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return [];

    final repository = ref.read(recurringTransactionRepositoryProvider);
    final rules = await repository.getRecurringTransactions(user.uid);

    final List<TransactionModel> projections = [];
    final uuid = const Uuid();

    for (final rule in rules) {
      DateTime candidate = rule.nextOccurrence;

      // Safety break to prevent infinite loops if interval is 0 or logic fails
      if (rule.interval <= 0) continue;

      while (candidate.isBefore(untilDate) ||
          candidate.isAtSameMomentAs(untilDate)) {
        if (rule.endDate != null && candidate.isAfter(rule.endDate!)) break;

        // Create projection
        projections.add(
          TransactionModel(
            id: "proj-${uuid.v4()}", // Temporary ID
            ownerId: rule.ownerId,
            realAccountId: rule.realAccountId,
            amount: rule.amount,
            label: "${rule.label} (Prévu)",
            note: rule.note,
            transactionDate: candidate,
            type: rule.type,
            status: TransactionStatus.none, // Planned?
            step: TransactionStep.planned,
            splits: rule.splits,
          ),
        );

        // Calculate next candidate locally
        candidate = _calculateNext(rule, candidate);
      }
    }

    // Sort by date
    projections.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    return projections;
  }

  DateTime _calculateNext(RecurringTransaction rule, DateTime current) {
    // Re-use the logic from model or here.
    // Since model method 'calculateNextOccurrence' takes 'afterDate', it fast forwards.
    // Here we want Step-by-Step.
    // We can expose a static helper or just implement simple step here.

    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return current.add(Duration(days: rule.interval));
      case RecurrenceFrequency.weekly:
        return current.add(Duration(days: 7 * rule.interval));
      case RecurrenceFrequency.monthly:
        int newMonth = current.month + rule.interval;
        int newYear = current.year + (newMonth - 1) ~/ 12;
        newMonth = (newMonth - 1) % 12 + 1;

        int newDay = current.day;
        // Ideally stick to original start day, but current simplification uses previous date.
        // To be precise, we should track 'originalDay' but model implies startDate IS original.
        // Let's rely on startDate day if we want consistency, but here 'current' might have shifted?
        // For simple "Add interval", using current is fine.
        final daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
        if (newDay > daysInNewMonth) newDay = daysInNewMonth;

        return DateTime(
          newYear,
          newMonth,
          newDay,
          current.hour,
          current.minute,
        );
      case RecurrenceFrequency.yearly:
        return DateTime(
          current.year + rule.interval,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
    }
  }

  /// Processes upcoming recurrences and saves them to the database as PLANNED transactions.
  /// Typically called on app launch or via a background job.
  Future<void> processUpcomingRecurrences({DateTime? upToDate}) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    final txRepo = ref.read(transactionRepositoryProvider);
    final recRepo = ref.read(recurringTransactionRepositoryProvider);

    // Default lookahead is 30 days
    final targetDate = upToDate ?? DateTime.now().add(const Duration(days: 30));
    final rules = await recRepo.getRecurringTransactions(user.uid);

    for (final rule in rules) {
      if (rule.interval <= 0) continue;

      DateTime candidate = rule.nextOccurrence;
      bool hasUpdates = false;

      while (candidate.isBefore(targetDate) ||
          candidate.isAtSameMomentAs(targetDate)) {
        if (rule.endDate != null && candidate.isAfter(rule.endDate!)) break;

        final uuid = const Uuid();
        final newTx = TransactionModel(
          id: uuid.v4(),
          ownerId: rule.ownerId,
          realAccountId: rule.realAccountId,
          amount: rule.amount,
          label: rule.label, // Or add " (Planifié)" ?
          note: rule.note,
          transactionDate: candidate,
          type: rule.type,
          status: TransactionStatus.none,
          step: TransactionStep.planned,
          splits: rule.splits,
          recurringTransactionId: rule.id,
          externalEntityId: rule.externalEntityId,
        );

        await txRepo.createTransaction(user.uid, newTx);

        candidate = _calculateNext(rule, candidate);
        hasUpdates = true;
      }

      if (hasUpdates) {
        final updatedRule = RecurringTransaction(
          id: rule.id,
          ownerId: rule.ownerId,
          frequency: rule.frequency,
          interval: rule.interval,
          startDate: rule.startDate,
          endDate: rule.endDate,
          nextOccurrence: candidate,
          lastOccurrence: rule.lastOccurrence,
          realAccountId: rule.realAccountId,
          amount: rule.amount,
          label: rule.label,
          note: rule.note,
          type: rule.type,
          splits: rule.splits,
          externalEntityId: rule.externalEntityId,
        );
        await recRepo.updateRecurringTransaction(user.uid, updatedRule);
      }
    }
  }
}
