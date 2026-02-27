import 'package:flutter/material.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../../transactions/data/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
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
  final double endBalance;
  final VirtualAccountType accountType;

  EnvelopeStat({
    required this.virtualAccountId,
    required this.envelopeName,
    required this.realAccountName,
    required this.realAccountId,
    required this.startBalance,
    required this.income,
    required this.expense,
    required this.endBalance,
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
  final List<EnvelopeStat> envelopeStats; // user envelopes only
  final List<EnvelopeStat> systemEnvelopeStats; // system envelopes
  final List<AccountStat> accountStats;

  ResumeData({
    required this.envelopeStats,
    required this.systemEnvelopeStats,
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
      accountStats: [],
    );
  }

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
  final Map<String, AccountStat> accountStatsMap = {};

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

    for (final tx in allTransactions) {
      double impact = 0;
      for (final split in tx.splits) {
        if (split.virtualAccountId == virtualAcc.id) {
          impact += split.amount;
        }
      }

      if (impact == 0) continue;

      if (tx.transactionDate.isAfter(period.end)) {
        endBalance -= impact;
      } else if (tx.transactionDate.isAfter(period.start) ||
          tx.transactionDate.isAtSameMomentAs(period.start)) {
        if (impact > 0) {
          periodIncome += impact;
        } else {
          periodExpense += impact;
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
      accountType: virtualAcc.type,
    );

    // Separate system vs user envelopes
    if (stat.isSystem) {
      systemEnvelopeStats.add(stat);
    } else {
      envelopeStats.add(stat);
    }

    // Aggregate into account stats
    final existingAccountStat = accountStatsMap[realAccountId];
    if (existingAccountStat == null) {
      accountStatsMap[realAccountId] = AccountStat(
        accountId: realAccountId,
        accountName: realAccountName,
        startBalance: startBalance,
        income: periodIncome,
        expense: periodExpense,
        endBalance: endBalance,
      );
    } else {
      accountStatsMap[realAccountId] = AccountStat(
        accountId: realAccountId,
        accountName: realAccountName,
        startBalance: existingAccountStat.startBalance + startBalance,
        income: existingAccountStat.income + periodIncome,
        expense: existingAccountStat.expense + periodExpense,
        endBalance: existingAccountStat.endBalance + endBalance,
      );
    }
  }

  return ResumeData(
    envelopeStats: envelopeStats
      ..sort((a, b) => a.realAccountName.compareTo(b.realAccountName)),
    systemEnvelopeStats: systemEnvelopeStats
      ..sort((a, b) => a.realAccountName.compareTo(b.realAccountName)),
    accountStats: accountStatsMap.values.toList()
      ..sort((a, b) => a.accountName.compareTo(b.accountName)),
  );
});
