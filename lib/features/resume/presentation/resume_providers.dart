import 'package:flutter/material.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../../transactions/data/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../transactions/domain/transaction_model.dart';
import '../application/resume_export_service.dart';

final resumeExportServiceProvider = Provider<ResumeExportService>((ref) {
  return ResumeExportService();
});

class EnvelopeStat {
  final String virtualAccountId;
  final String envelopeName;
  final String realAccountName;
  final String realAccountId; // Added for aggregation
  final double startBalance;
  final double income;
  final double expense;
  final double endBalance; // Current actual balance
  final double plannedIncome;
  final double plannedExpense;
  final VirtualAccountType accountType;

  double get forecastedBalance => endBalance + plannedIncome + plannedExpense;

  EnvelopeStat({
    required this.virtualAccountId,
    required this.envelopeName,
    required this.realAccountName,
    required this.realAccountId,
    required this.startBalance,
    required this.income,
    required this.expense,
    required this.endBalance,
    this.plannedIncome = 0.0,
    this.plannedExpense = 0.0,
    this.accountType = VirtualAccountType.userBudget,
  });

  bool get isSystem =>
      accountType == VirtualAccountType.systemFree ||
      accountType == VirtualAccountType.systemCommitted ||
      accountType == VirtualAccountType.flowToDistribute;
}

class AccountStat {
  final String accountId;
  final String accountName;
  final double startBalance;
  final double income;
  final double expense;
  final double endBalance;

  AccountStat({
    required this.accountId,
    required this.accountName,
    required this.startBalance,
    required this.income,
    required this.expense,
    required this.endBalance,
  });
}

class ResumeData {
  final List<EnvelopeStat>
  envelopeStats; // user envelopes only (internal accounts)
  final List<EnvelopeStat>
  systemEnvelopeStats; // system envelopes (internal accounts)
  final List<EnvelopeStat>
  externalEnvelopeStats; // all envelopes from external accounts
  final List<AccountStat> accountStats;

  ResumeData({
    required this.envelopeStats,
    required this.systemEnvelopeStats,
    required this.externalEnvelopeStats,
    required this.accountStats,
  });
}

final resumeDataProvider = FutureProvider.family<ResumeData, DateTimeRange>((
  ref,
  period,
) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) {
    return ResumeData(
      envelopeStats: [],
      systemEnvelopeStats: [],
      externalEnvelopeStats: [],
      accountStats: [],
    );
  }

  // Normalize period boundaries to full days so same-day transactions
  // are never misclassified as "after" the period (period.end was midnight).
  final periodStart = DateTime(
    period.start.year,
    period.start.month,
    period.start.day,
  );
  final periodEnd = DateTime(
    period.end.year,
    period.end.month,
    period.end.day,
    23,
    59,
    59,
    999,
  );

  // 1. Fetch all accessible real accounts
  final realAccountsList = await ref.watch(realAccountsProvider.future);
  final realAccountNames = {for (var acc in realAccountsList) acc.id: acc.name};

  // 2. Fetch all virtual accounts
  final virtualAccountsList = await ref.watch(
    allVirtualAccountsProvider.future,
  );

  // 3. Fetch all transactions
  final txRepo = ref.watch(transactionRepositoryProvider);
  final allTxStream = txRepo.watchTransactions(user.uid);
  final allTransactions = await allTxStream.first;

  final List<EnvelopeStat> envelopeStats = [];
  final List<EnvelopeStat> systemEnvelopeStats = [];
  final List<EnvelopeStat> externalEnvelopeStats = [];
  final Map<String, AccountStat> accountStatsMap = {};

  // Build a fast lookup for external account IDs
  final externalAccountIds = realAccountsList
      .where(
        (a) =>
            a.type == RealAccountType.external ||
            a.type == RealAccountType.externalGeneric,
      )
      .map((a) => a.id)
      .toSet();

  for (final virtualAcc in virtualAccountsList) {
    if (!realAccountNames.containsKey(virtualAcc.realAccountId)) {
      continue;
    }

    double currentBalance = virtualAcc.balance;
    String realAccountName = realAccountNames[virtualAcc.realAccountId]!;
    String realAccountId = virtualAcc.realAccountId;

    double endBalance = currentBalance;
    double periodIncome = 0;
    double periodExpense = 0;
    double periodPlannedIncome = 0;
    double periodPlannedExpense = 0;

    for (final tx in allTransactions) {
      double impact = 0;
      for (final split in tx.splits) {
        if (split.virtualAccountId == virtualAcc.id) {
          impact += split.amount;
        }
      }

      if (impact == 0) continue;

      // completed: booked in both RealAccount.balance AND virtualAcc.balance
      // pending:   booked only in virtualAcc.balance (committed envelope)
      // planned/scheduled/toSchedule: not booked yet
      final bool isCompleted = tx.step == TransactionStep.completed;
      final bool isPending = tx.step == TransactionStep.pending;
      final bool isPlanned =
          tx.step == TransactionStep.planned ||
          tx.step == TransactionStep.scheduled ||
          tx.step == TransactionStep.toSchedule;

      if (tx.transactionDate.isAfter(periodEnd)) {
        // Post-period: rewind from virtualAcc.balance to reach period-end balance.
        // Both completed and pending update virtualAcc.balance immediately in Firestore,
        // so both must be rewound here to match what the balance WAS at period.end.
        if (isCompleted || isPending) endBalance -= impact;
      } else if (!tx.transactionDate.isBefore(periodStart)) {
        // In-period transaction
        if (isCompleted) {
          if (impact > 0) {
            periodIncome += impact;
          } else {
            periodExpense += impact;
          }
        } else if (isPending || isPlanned) {
          if (impact > 0) {
            periodPlannedIncome += impact;
          } else {
            periodPlannedExpense += impact;
          }
        }
      }
    }

    double startBalance = endBalance - (periodIncome + periodExpense);

    final stat = EnvelopeStat(
      virtualAccountId: virtualAcc.id,
      envelopeName: virtualAcc.name,
      realAccountName: realAccountName,
      realAccountId: realAccountId,
      startBalance: startBalance,
      income: periodIncome,
      expense: periodExpense,
      endBalance: endBalance,
      plannedIncome: periodPlannedIncome,
      plannedExpense: periodPlannedExpense,
      accountType: virtualAcc.type,
    );

    // Route to correct bucket — no AccountStat aggregation here (done below)
    if (externalAccountIds.contains(realAccountId)) {
      externalEnvelopeStats.add(stat);
    } else if (stat.isSystem) {
      systemEnvelopeStats.add(stat);
    } else {
      envelopeStats.add(stat);
    }
  }

  // ── AccountStat: computed directly from RealAccount.balance ──────────────
  // This ensures the "Solde fin" in the account-totals table always matches
  // the dashboard even when virtual accounts are out of sync with the real
  // account (e.g. initial balance, untracked CSV imports, etc.)
  for (final realAcc in realAccountsList) {
    if (externalAccountIds.contains(realAcc.id))
      continue; // external shown elsewhere

    double endBalance =
        realAcc.balance; // ground truth (completed only, same as dashboard)
    double periodIncome = 0;
    double periodExpense = 0;

    for (final tx in allTransactions) {
      if (tx.realAccountId != realAcc.id) continue;
      if (tx.step != TransactionStep.completed) continue;

      final double impact = tx.amount;

      if (tx.transactionDate.isAfter(periodEnd)) {
        // Post-period: rewind from current balance to get period-end balance
        endBalance -= impact;
      } else if (!tx.transactionDate.isBefore(periodStart)) {
        // In-period completed transaction
        if (impact > 0) {
          periodIncome += impact;
        } else {
          periodExpense += impact;
        }
      }
    }

    final double startBalance = endBalance - (periodIncome + periodExpense);
    accountStatsMap[realAcc.id] = AccountStat(
      accountId: realAcc.id,
      accountName: realAcc.name,
      startBalance: startBalance,
      income: periodIncome,
      expense: periodExpense,
      endBalance: endBalance,
    );
  }

  return ResumeData(
    envelopeStats: envelopeStats
      ..sort((a, b) => a.realAccountName.compareTo(b.realAccountName)),
    systemEnvelopeStats: systemEnvelopeStats
      ..sort((a, b) => a.realAccountName.compareTo(b.realAccountName)),
    externalEnvelopeStats: externalEnvelopeStats
      ..sort((a, b) => a.realAccountName.compareTo(b.realAccountName)),
    accountStats: accountStatsMap.values.toList()
      ..sort((a, b) => a.accountName.compareTo(b.accountName)),
  );
});
