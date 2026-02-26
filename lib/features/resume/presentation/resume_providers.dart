import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../accounts/data/account_providers.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../accounts/domain/account_models.dart';
import '../../../core/providers.dart';

class EnvelopeStat {
  final String virtualAccountId;
  final String envelopeName;
  final String realAccountName;
  final double startBalance;
  final double income;
  final double expense;
  final double endBalance;

  EnvelopeStat({
    required this.virtualAccountId,
    required this.envelopeName,
    required this.realAccountName,
    required this.startBalance,
    required this.income,
    required this.expense,
    required this.endBalance,
  });
}

final resumeDataProvider = FutureProvider.family<List<EnvelopeStat>, DateTimeRange>((
  ref,
  period,
) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) return [];

  // 1. Fetch all accessible real accounts to map IDs to Names
  final realAccountsList = await ref.watch(realAccountsProvider.future);
  final realAccountNames = {for (var acc in realAccountsList) acc.id: acc.name};

  // 2. Fetch all virtual accounts
  final virtualAccountsList = await ref.watch(
    allVirtualAccountsProvider.future,
  );

  // 3. Fetch all transactions for this user within the period.
  // Note: For a perfectly accurate "Start Balance", if the end of the period is NOT today,
  // we would also need transactions between the period end and today.
  // Assuming the user just looks back, current balance usually approximates end balance
  // unless period strictly ends in the past. To be fully accurate, we calculate backwards from current balance.

  final txRepo = ref.watch(transactionRepositoryProvider);

  // We fetch ALL transactions to perfectly trace back from *current* balance.
  // For scalable efficiency, in the future this should be delegated to a Cloud Function.
  // For MVP: Fetch all transactions involving user, order by date.
  final allTxStream = txRepo.watchTransactions(user.uid);
  final allTransactions = await allTxStream.first; // wait for first emit

  // Create a map to hold running stats per virtual account
  final Map<String, EnvelopeStat> statsMap = {};

  for (final virtualAcc in virtualAccountsList) {
    // Skip virtual accounts that have no associated real account (orphaned)
    if (!realAccountNames.containsKey(virtualAcc.realAccountId)) {
      continue;
    }

    // Current actual balance in the database
    double currentBalance = virtualAcc.balance;
    String realAccountName = realAccountNames[virtualAcc.realAccountId]!;

    // To find "End Balance" (at period.end):
    // currentBalance - (all transactions that occurred AFTER period.end)
    double endBalance = currentBalance;

    // To find "Start Balance" (at period.start):
    // endBalance - (all transactions that occurred DURING period)
    double startBalance = 0;

    double periodIncome = 0;
    double periodExpense = 0;

    for (final tx in allTransactions) {
      // Find the impact of this transaction on MUST THIS virtual account.
      // Splits contain the impact.
      double impact = 0;
      for (final split in tx.splits) {
        if (split.virtualAccountId == virtualAcc.id) {
          impact += split.amount;
        }
      }

      if (impact == 0) continue; // No impact, skip.

      // Check dates
      if (tx.transactionDate.isAfter(period.end)) {
        // This happened AFTER our period. Reverse its effect to find the balance at the end of the period.
        endBalance -= impact;
      } else if (tx.transactionDate.isAfter(period.start) ||
          tx.transactionDate.isAtSameMomentAs(period.start)) {
        // This happened DURING our period.
        if (impact > 0) {
          periodIncome += impact;
        } else {
          periodExpense += impact;
        }
      }
    }

    // Now calculate start balance
    startBalance = endBalance - (periodIncome + periodExpense);

    // Only show if it had activity or has a balance
    if (startBalance != 0 ||
        endBalance != 0 ||
        periodIncome != 0 ||
        periodExpense != 0) {
      statsMap[virtualAcc.id] = EnvelopeStat(
        virtualAccountId: virtualAcc.id,
        envelopeName: virtualAcc.name,
        realAccountName: realAccountName,
        startBalance: startBalance,
        income: periodIncome,
        expense: periodExpense,
        endBalance: endBalance,
      );
    }
  }

  return statsMap.values.toList()
    ..sort((a, b) => a.realAccountName.compareTo(b.realAccountName));
});
