import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../core/presentation/ui_utils.dart';
import '../../accounts/domain/account_models.dart';
import '../../accounts/application/account_service.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/widgets/transaction_list.dart';
import '../../analytics/application/analytics_providers.dart';

class EnvelopeDetailScreen extends ConsumerWidget {
  final VirtualAccount envelope;

  const EnvelopeDetailScreen({super.key, required this.envelope});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We fetch transactions for this envelope
    // Since we don't have a provider for this specific query yet, we can use a FutureBuilder
    // or create a provider. For simplicity/MVP, FutureBuilder.
    // Or better: use a FutureProvider.autoDispose family.

    final transactionsFuture = ref.watch(
      envelopeTransactionsProvider(envelope),
    );
    final color = UiUtils.getVirtualAccountColor(
      envelope.type,
      brightness: Theme.of(context).brightness,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(envelope.name),
        actions: [
          if (envelope.type == VirtualAccountType.userBudget)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showRenameDialog(context, ref),
            ),
          if (envelope.type == VirtualAccountType.userBudget)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: color.withOpacity(0.1),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(
                      UiUtils.getVirtualAccountIcon(envelope.type),
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${envelope.balance.toStringAsFixed(2)} €",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: envelope.balance < 0 ? Colors.red : null,
                    ),
                  ),
                  Text(
                    "Solde Actuel",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: "Transactions"),
                Tab(text: "Provenance des fonds"),
              ],
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  // -- TAB 1: Transactions --
                  transactionsFuture.when(
                    data: (transactions) =>
                        TransactionList(transactions: transactions),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text("Erreur: $e")),
                  ),
                  // -- TAB 2: Provenance --
                  Consumer(
                    builder: (context, ref, child) {
                      final sourcesAsync = ref.watch(
                        envelopeFundSourcesProvider(envelope.id),
                      );
                      return sourcesAsync.when(
                        data: (sources) {
                          if (sources.isEmpty) {
                            return const Center(
                              child: Text(
                                "Aucune donnée de provenance disponible.",
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sources.length,
                            itemBuilder: (context, index) {
                              final s = sources[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text("${index + 1}"),
                                ),
                                title: Text(s.name),
                                subtitle: LinearProgressIndicator(
                                  value: s.percentage / 100,
                                  backgroundColor: Colors.grey.shade200,
                                ),
                                trailing: Text(
                                  "${s.percentage.toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(child: Text("Erreur: $e")),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: envelope.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Renommer"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Nouveau nom"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ref
                    .read(accountServiceProvider)
                    .renameVirtualAccount(envelope, nameController.text);
                if (context.mounted) Navigator.pop(ctx);
                // Note: The screen might not update immediately if we passed 'envelope' object directly
                // and it's immutable. We should specificially watch the envelope or pop back.
                // Ideally, we depend on a stream of the envelope.
                // For now, let's pop back as simplest UX or force refresh?
                // Popping back is consistent with Edit Account flow.
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Supprimer ${envelope.name} ?"),
        content: Text(
          "Le solde restant (${envelope.balance.toStringAsFixed(2)} €) sera reversé dans le compte 'Libre'.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(accountServiceProvider).deleteVirtualAccount(envelope);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}

final envelopeTransactionsProvider =
    FutureProvider.family<List<TransactionModel>, VirtualAccount>((
      ref,
      envelope,
    ) {
      final repository = ref.read(transactionRepositoryProvider);
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) return [];
      return repository.getTransactionsByVirtualAccount(user.uid, envelope.id);
    });
