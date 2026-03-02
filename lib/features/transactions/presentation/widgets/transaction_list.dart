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
        final isPlanned =
            tx.step == TransactionStep.planned ||
            tx.step == TransactionStep.scheduled;
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(left: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "En attente",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isPlanned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(left: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Planifié",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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
              color: isPending
                  ? Colors.orange
                  : (isPlanned ? Colors.grey : amountColor),
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
            key: Key('pending-${tx.id}'),
            direction: DismissDirection.startToEnd,
            background: Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.only(left: 16.0),
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Pointer",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              try {
                await ref
                    .read(transactionServiceProvider)
                    .confirmTransaction(tx);
                return false; // Don't remove from list, it just updates step
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

        if (isPlanned) {
          return Dismissible(
            key: Key('planned-${tx.id}'),
            direction: DismissDirection.startToEnd,
            background: Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.only(left: 16.0),
              decoration: BoxDecoration(
                color: Colors.orange.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Provisionner",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              try {
                await ref
                    .read(transactionServiceProvider)
                    .provisionTransaction(tx);
                return false; // Don't remove from list
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
