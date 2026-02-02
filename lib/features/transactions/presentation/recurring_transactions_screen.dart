import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/recurring_transaction_repository.dart';
import '../domain/recurring_transaction.dart';
import '../../../../core/providers.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    if (user == null) return const Center(child: Text("Non connecté"));

    final recurringAsync = ref
        .watch(recurringTransactionRepositoryProvider)
        .watchRecurringTransactions(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Échéanciers"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/recurring/add'),
          ),
        ],
      ),
      body: StreamBuilder<List<RecurringTransaction>>(
        stream: recurringAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text("Aucun échéancier configuré"));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.label),
                subtitle: Text(
                  "${item.amount.toStringAsFixed(2)} € - ${item.frequency.name} (x${item.interval})",
                ),
                trailing: Text(
                  "Prochain: ${item.nextDueDate.toLocal().toString().split(' ')[0]}",
                ),
                onLongPress: () =>
                    _confirmDelete(context, ref, user.uid, item.id),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer l'échéancier ?"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(recurringTransactionRepositoryProvider)
                  .deleteRecurringTransaction(userId, id);
              Navigator.pop(context);
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
