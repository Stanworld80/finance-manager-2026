import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../accounts/data/account_providers.dart';
import '../application/recurring_transaction_service.dart';

part 'projected_balance_provider.g.dart';

@riverpod
Future<double> projectedBalance(Ref ref) async {
  // 1. Get current actual balance from all Real Accounts
  final accounts = await ref.watch(realAccountsProvider.future);
  final currentBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);

  // 2. Define projection period (End of current month)
  final now = DateTime.now();
  // If we are late in the month (e.g. > 25th), maybe project to next month?
  // For now, let's strictly stick to "End of Current Month" as a safe default.
  final endOfMonth = DateTime(now.year, now.month + 1, 0);

  // 3. Generate future occurrences
  final service = ref.read(recurringTransactionServiceProvider);
  final occurrences = await service.generateOccurrences(endOfMonth);

  // 4. Sum up the impact of these occurrences
  // Note: recurring transactions in the system are typically stored as positive/negative based on type
  // TransactionModel.amount is signed based on Debit/Credit.
  final notificationSum = occurrences.fold(0.0, (sum, tx) => sum + tx.amount);

  return currentBalance + notificationSum;
}
