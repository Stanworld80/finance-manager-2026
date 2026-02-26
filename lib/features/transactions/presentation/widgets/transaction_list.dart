import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/ui_utils.dart';
import '../../domain/transaction_model.dart';
import '../../presentation/transaction_detail_screen.dart';
import '../../application/transaction_service.dart';

class TransactionList extends ConsumerWidget {
  final List<TransactionModel> transactions;

  const TransactionList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        final isPending = tx.step == TransactionStep.pending;
        final amountColor = UiUtils.getTransactionColor(
          tx.type,
          brightness: Theme.of(context).brightness,
        );
        final dateStr = DateFormat('dd/MM/yyyy').format(tx.transactionDate);

        Widget listTile = ListTile(
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
          title: Row(
            children: [
              Expanded(
                child: Text(
                  tx.label ?? 'Sans libellé',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPending)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.access_time_filled,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
            ],
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
              color: isPending ? Colors.orange : amountColor,
            ),
          ),
        );

        Widget card = Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: listTile,
        );

        if (isPending) {
          return Dismissible(
            key: Key(tx.id),
            direction: DismissDirection.startToEnd,
            background: Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.only(left: 16.0),
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              try {
                await ref
                    .read(transactionServiceProvider)
                    .confirmTransaction(tx);
                return true;
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Action échouée: $e")));
                }
                return false;
              }
            },
            child: card,
          );
        }

        return card;
      },
    );
  }
}
