import 'package:flutter/material.dart';
import '../../features/accounts/domain/account_models.dart';
import '../../features/transactions/domain/transaction_model.dart';

class UiUtils {
  // --- Virtual Account (Envelope) Styles ---

  static Color getVirtualAccountColor(VirtualAccountType type) {
    switch (type) {
      case VirtualAccountType.systemFree:
        return Colors.green.shade600; // Available/Free
      case VirtualAccountType.flowToDistribute:
        return Colors.orange.shade600; // Intake/Pending
      case VirtualAccountType.systemCommitted:
        return Colors.blueGrey.shade600; // Fixed/Committed
      case VirtualAccountType.userBudget:
        return Colors.blue.shade600; // User Discretionary
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
    bool isExpense = true,
  }) {
    switch (type) {
      case TransactionType.debit:
        return Colors.red.shade600;
      case TransactionType.credit:
        return Colors.green.shade600;
      case TransactionType.transfer:
        return Colors.indigo.shade400;
      case TransactionType.provision:
        return Colors.teal.shade600;
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
        return Icons
            .inventory_2_outlined; // Or something implying internal move
    }
  }

  static Color getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.toCorrect:
        return Colors.redAccent;
      case TransactionStatus.toDistribute:
        return Colors.orangeAccent;
      case TransactionStatus.provisioned:
        return Colors.blueAccent;
      case TransactionStatus.transferred:
        return Colors.grey;
      case TransactionStatus.none:
      default:
        return Colors.grey.shade400;
    }
  }
}
