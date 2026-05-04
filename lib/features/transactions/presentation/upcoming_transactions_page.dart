import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_formatter.dart';
import '../data/transaction_providers.dart';
import '../domain/transaction_model.dart';
import '../application/transaction_service.dart';

class UpcomingTransactionsPage extends ConsumerWidget {
  const UpcomingTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Échéancier / À Venir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat),
            tooltip: 'Gérer les récurrences',
            onPressed: () => context.push('/recurring'),
          ),
        ],
      ),
      body: upcomingAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text("Aucune opération à venir."),
                ],
              ),
            );
          }

          // Group by Date
          final grouped = <DateTime, List<TransactionModel>>{};
          for (var tx in transactions) {
            final date = DateTime(
              tx.transactionDate.year,
              tx.transactionDate.month,
              tx.transactionDate.day,
            );
            grouped.putIfAbsent(date, () => []).add(tx);
          }

          final dates = grouped.keys.toList()..sort();

          return ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final txs = grouped[date]!;
              return _buildDateGroup(context, ref, date, txs);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildDateGroup(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    List<TransactionModel> txs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...txs.map((tx) => _buildTransactionTile(context, ref, tx)),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) {
    final isExpense = tx.amount < 0;
    final isPlanned =
        tx.step == TransactionStep.planned ||
        tx.step == TransactionStep.scheduled;
    final amountColor = isExpense ? Colors.red : Colors.green;

    final card = ListTile(
      onTap: () => context.push('/transaction/${tx.id}'),
      leading: CircleAvatar(
        backgroundColor: isExpense
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          isExpense ? Icons.arrow_downward : Icons.arrow_upward,
          color: isExpense
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          size: 16,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              tx.payee ?? tx.label ?? 'Sans libellé',
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPlanned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
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
      subtitle: Text(tx.label ?? ''),
      trailing: Text(
        CurrencyFormatter.format(tx.amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isPlanned ? Colors.grey : amountColor,
        ),
      ),
    );

    if (isPlanned) {
      return Dismissible(
        key: Key('upcoming-${tx.id}'),
        direction: DismissDirection.startToEnd,
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 16.0),
          color: Colors.orange.shade400,
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
            await ref.read(transactionServiceProvider).provisionTransaction(tx);
            return false;
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
  }
}
