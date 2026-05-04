import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/account_providers.dart';
import '../domain/account_models.dart';
import '../application/account_service.dart';
import '../../transactions/data/transaction_providers.dart';
import '../../transactions/domain/transaction_model.dart';

class ExternalEntitiesScreen extends ConsumerWidget {
  const ExternalEntitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realAccountsAsync = ref.watch(realAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Monde Extérieur")),
      body: realAccountsAsync.when(
        data: (accounts) {
          final externalEntities = accounts
              .where(
                (a) =>
                    a.type == RealAccountType.external ||
                    a.type == RealAccountType.externalGeneric,
              )
              .toList();

          if (externalEntities.isEmpty) {
            return const Center(child: Text("Aucune entité externe définie."));
          }

          return ListView.builder(
            itemCount: externalEntities.length,
            itemBuilder: (context, index) {
              final entity = externalEntities[index];
              return _EntityTile(entity: entity);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Erreur: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEntityDialog(context, ref),
        tooltip: "Nouvelle entité",
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateEntityDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouvel Établissement / Entité"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Nom (ex: McDo, Entreprise, Ami...)",
            hintText: "Entrez le nom de l'entité",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref
                    .read(accountServiceProvider)
                    .createExternalEntity(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }
}

class _EntityTile extends ConsumerWidget {
  final RealAccount entity;

  const _EntityTile({required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final virtualAccountsAsync = ref.watch(virtualAccountsProvider(entity.id));
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return ExpansionTile(
      leading: Icon(
        entity.type == RealAccountType.externalGeneric
            ? Icons.public
            : Icons.store,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        entity.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: virtualAccountsAsync.when(
        data: (virtuals) {
          final total = virtuals.fold(0.0, (sum, v) => sum + v.balance);
          return Text("Solde total: ${currencyFormat.format(total)}");
        },
        loading: () => const Text("Chargement solde..."),
        error: (_, _) => const Text("Erreur solde"),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: "Nouvelle enveloppe",
        onPressed: () => _showCreateEnvelopeDialog(context, ref),
      ),
      children: [
        virtualAccountsAsync.when(
          data: (virtuals) {
            if (virtuals.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Aucune enveloppe pour cette entité."),
              );
            }
            return Column(
              children: [
                ...virtuals.map(
                  (v) => ListTile(
                    dense: true,
                    leading: Icon(_getIconForType(v.type), size: 20),
                    title: Text(v.name),
                    trailing: Text(
                      currencyFormat.format(v.balance),
                      style: TextStyle(
                        color: v.balance < 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onLongPress: v.type == VirtualAccountType.userBudget
                        ? () => _confirmDeleteEnvelope(context, ref, v)
                        : null,
                  ),
                ),
                const Divider(),
                _TransactionHistory(externalEntityId: entity.id),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (err, _) => Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Erreur: $err"),
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(VirtualAccountType type) {
    switch (type) {
      case VirtualAccountType.systemFree:
        return Icons.savings_outlined;
      case VirtualAccountType.systemCommitted:
        return Icons.lock_clock_outlined;
      case VirtualAccountType.flowToDistribute:
        return Icons.input_outlined;
      case VirtualAccountType.userBudget:
        return Icons.folder_outlined;
    }
  }

  Future<void> _showCreateEnvelopeDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Nouvelle enveloppe pour ${entity.name}"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Nom de l'enveloppe",
            hintText: "ex: Crédit Client, Dette...",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref
                    .read(accountServiceProvider)
                    .createVirtualAccount(
                      realAccountId: entity.id,
                      name: controller.text,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteEnvelope(
    BuildContext context,
    WidgetRef ref,
    VirtualAccount v,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer l'enveloppe ?"),
        content: Text(
          "Voulez-vous supprimer l'enveloppe '${v.name}' ? Son solde sera transféré vers 'Libre'.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(accountServiceProvider).deleteVirtualAccount(v);
    }
  }
}

class _TransactionHistory extends ConsumerWidget {
  final String externalEntityId;

  const _TransactionHistory({required this.externalEntityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Importing externalTransactionsProvider from transactions feature
    // We might need to ensure imports are correct.
    // Assuming externalTransactionsProvider is available.
    final transactionsAsync = ref.watch(
      externalTransactionsProvider(externalEntityId),
    );
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final dateFormat = DateFormat('dd/MM/yy');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Flux récents",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          transactionsAsync.when(
            data: (txs) {
              if (txs.isEmpty) {
                return const Text("Aucun flux enregistré.");
              }
              final displayTxs = txs.take(5).toList();
              return Column(
                children: displayTxs.map((tx) {
                  final isIncome = tx.type == TransactionType.credit;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Text(
                          dateFormat.format(tx.transactionDate),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tx.label ?? tx.payee ?? "Sans libellé",
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          currencyFormat.format(tx.amount),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isIncome ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, _) => Text("Erreur flux: $err"),
          ),
        ],
      ),
    );
  }
}
