import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/ui_utils.dart';
import '../../domain/transaction_model.dart';
import '../../presentation/transaction_detail_screen.dart';

class TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;

  const TransactionList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text("Aucune transaction"),
        ),
      );
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final amountColor = UiUtils.getTransactionColor(
          tx.type,
          brightness: Theme.of(context).brightness,
        );
        final dateStr = DateFormat('dd/MM/yyyy').format(tx.transactionDate);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TransactionDetailScreen(transactionId: tx.id),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: amountColor.withOpacity(0.1),
              child: Icon(
                UiUtils.getTransactionIcon(tx.type),
                color: amountColor,
                size: 20,
              ),
            ),
            title: Text(
              tx.label ?? 'Sans libellé',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "$dateStr ${tx.category != null ? '• ${tx.category}' : ''}",
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Text(
              "${tx.amount > 0 ? '+' : ''}${tx.amount.toStringAsFixed(2)} €",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: amountColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
