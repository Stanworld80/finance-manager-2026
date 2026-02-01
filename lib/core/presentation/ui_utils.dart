import 'package:flutter/material.dart';
import '../../features/accounts/domain/account_models.dart';
import '../../features/transactions/domain/transaction_model.dart';

class UiUtils {
  // --- Virtual Account (Envelope) Styles ---

  static Color getVirtualAccountColor(
    VirtualAccountType type, {
    Brightness brightness = Brightness.light,
  }) {
    final isDark = brightness == Brightness.dark;
    switch (type) {
      case VirtualAccountType.systemFree:
        return isDark ? Colors.green.shade300 : Colors.green.shade700;
      case VirtualAccountType.flowToDistribute:
        return isDark ? Colors.orange.shade300 : Colors.orange.shade800;
      case VirtualAccountType.systemCommitted:
        return isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade700;
      case VirtualAccountType.userBudget:
        return isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    }
  }

  static IconData getVirtualAccountIcon(VirtualAccountType type) {
    switch (type) {
      case VirtualAccountType.systemFree:
        return Icons.savings_outlined;
      case VirtualAccountType.flowToDistribute:
        return Icons.input;
      case VirtualAccountType.systemCommitted:
        return Icons.lock_clock_outlined;
      case VirtualAccountType.userBudget:
        return Icons.account_balance_wallet_outlined;
    }
  }

  // --- Transaction Styles ---

  static Color getTransactionColor(
    TransactionType type, {
    Brightness brightness = Brightness.light,
  }) {
    final isDark = brightness == Brightness.dark;
    switch (type) {
      case TransactionType.debit:
        return isDark ? Colors.red.shade300 : Colors.red.shade700;
      case TransactionType.credit:
        return isDark ? Colors.green.shade300 : Colors.green.shade700;
      case TransactionType.transfer:
        return isDark ? Colors.indigo.shade300 : Colors.indigo.shade600;
      case TransactionType.provision:
        return isDark ? Colors.teal.shade300 : Colors.teal.shade700;
    }
  }

  static IconData getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.debit:
        return Icons.arrow_downward;
      case TransactionType.credit:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      case TransactionType.provision:
        return Icons.inventory_2_outlined;
    }
  }

  static Color getStatusColor(
    TransactionStatus status, {
    Brightness brightness = Brightness.light,
  }) {
    final isDark = brightness == Brightness.dark;
    switch (status) {
      case TransactionStatus.toCorrect:
        return isDark ? Colors.red.shade300 : Colors.redAccent;
      case TransactionStatus.toDistribute:
        return isDark ? Colors.orange.shade300 : Colors.orangeAccent;
      case TransactionStatus.provisioned:
        return isDark ? Colors.blue.shade300 : Colors.blueAccent;
      case TransactionStatus.transferred:
        return isDark ? Colors.grey.shade400 : Colors.grey;
      case TransactionStatus.none:
      default:
        return isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    }
  }
}
