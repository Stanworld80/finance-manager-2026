import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_manager_2026/features/transactions/domain/recurring_transaction_model.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'recurring_transaction_providers.dart';
import 'add_recurrence_page.dart'; // Will be created next

class RecurrenceListPage extends ConsumerWidget {
  const RecurrenceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurrencesAsync = ref.watch(recurringTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Récurrences & Abonnements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Nouvelle Récurrence",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddRecurrencePage()),
              );
            },
          ),
        ],
      ),
      body: recurrencesAsync.when(
        data: (recurrences) {
          if (recurrences.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_repeat,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text("Aucune récurrence définie"),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: recurrences.length,
            itemBuilder: (context, index) {
              final recurrence = recurrences[index];
              return _RecurrenceTile(recurrence: recurrence);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _RecurrenceTile extends StatelessWidget {
  final RecurringTransaction recurrence;

  const _RecurrenceTile({required this.recurrence});

  @override
  Widget build(BuildContext context) {
    final color = recurrence.type == TransactionType.debit
        ? Colors.red
        : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.repeat, color: color),
        ),
        title: Text(
          recurrence.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_formatFrequency(recurrence)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${recurrence.amount.toStringAsFixed(2)} €",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              "Prochaine: ${_formatDate(recurrence.nextOccurrence)}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () {
          // Edit navigation logic will go here
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddRecurrencePage(recurrenceToEdit: recurrence),
            ),
          );
        },
      ),
    );
  }

  String _formatFrequency(RecurringTransaction r) {
    String freq;
    switch (r.frequency) {
      case RecurrenceFrequency.daily:
        freq = "Quotidien";
        break;
      case RecurrenceFrequency.weekly:
        freq = "Hebdomadaire";
        break;
      case RecurrenceFrequency.monthly:
        freq = "Mensuel";
        break;
      case RecurrenceFrequency.yearly:
        freq = "Annuel";
        break;
    }
    if (r.interval > 1) {
      return "$freq (tous les ${r.interval})";
    }
    return freq;
  }

  String _formatDate(DateTime d) {
    return "${d.day}/${d.month}/${d.year}";
  }
}
