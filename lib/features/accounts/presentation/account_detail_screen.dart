import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../../accounts/application/account_service.dart';
import '../../../core/presentation/ui_utils.dart';

class AccountDetailScreen extends ConsumerWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realAccountsAsync = ref.watch(realAccountsProvider);
    final virtualAccountsAsync = ref.watch(virtualAccountsProvider(accountId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du Compte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit account name/details
            },
          ),
        ],
      ),
      body: realAccountsAsync.when(
        data: (accounts) {
          final account = accounts.firstWhere(
            (a) => a.id == accountId,
            orElse: () => RealAccount(
              id: 'not-found',
              ownerId: '',
              name: 'Inconnu',
              balance: 0.0,
            ),
          );

          if (account.id == 'not-found') {
            return const Center(child: Text("Compte introuvable"));
          }

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Column(
                  children: [
                    Text(
                      account.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (account.bankName != null)
                      Text(
                        account.bankName!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      "${account.balance.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text("Solde Réel"),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Virtual Accounts List
              // Virtual Accounts List
              Expanded(
                child: virtualAccountsAsync.when(
                  data: (virtuals) {
                    if (virtuals.isEmpty) {
                      return const Center(
                        child: Text("Aucune enveloppe créée"),
                      );
                    }

                    // Sort Logic:
                    // 1. FlowToDistribute (Income)
                    // 2. SystemFree (Libre)
                    // 3. SystemCommitted (Fixed)
                    // 4. UserBudget (Envelopes)
                    final sortedVirtuals = List<VirtualAccount>.from(virtuals);
                    sortedVirtuals.sort((a, b) {
                      final priorityA = _getPriority(a.type);
                      final priorityB = _getPriority(b.type);
                      if (priorityA != priorityB)
                        return priorityA.compareTo(priorityB);
                      return a.name.compareTo(b.name);
                    });

                    return ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: sortedVirtuals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final v = sortedVirtuals[index];
                        final color = UiUtils.getVirtualAccountColor(
                          v.type,
                          brightness: Theme.of(context).brightness,
                        );
                        final icon = UiUtils.getVirtualAccountIcon(v.type);

                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: color.withOpacity(0.3)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(
                              v.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              _getLabelForType(v.type),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${v.balance.toStringAsFixed(2)} €",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: v.balance < 0
                                        ? Colors.red.shade400
                                        : null,
                                  ),
                                ),
                                if (v.type ==
                                    VirtualAccountType.userBudget) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: Colors.grey,
                                    onPressed: () => _showRenameEnvelopeDialog(
                                      context,
                                      ref,
                                      v,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    color: Colors.grey,
                                    onPressed: () =>
                                        _confirmDeleteEnvelope(context, ref, v),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Erreur: $e")),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Erreur: $e")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEnvelopeDialog(context, ref, accountId),
        icon: const Icon(Icons.create_new_folder),
        label: const Text("Nouvelle Enveloppe"),
      ),
    );
  }

  // ... (existing helper methods)

  void _showRenameEnvelopeDialog(
    BuildContext context,
    WidgetRef ref,
    VirtualAccount account,
  ) {
    final nameController = TextEditingController(text: account.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Renommer l'enveloppe"),
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
                    .renameVirtualAccount(account, nameController.text);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  int _getPriority(VirtualAccountType type) {
    switch (type) {
      case VirtualAccountType.flowToDistribute:
        return 1;
      case VirtualAccountType.systemFree:
        return 2;
      case VirtualAccountType.systemCommitted:
        return 3;
      case VirtualAccountType.userBudget:
        return 4;
    }
  }

  Future<void> _confirmDeleteEnvelope(
    BuildContext context,
    WidgetRef ref,
    VirtualAccount v,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Supprimer ${v.name} ?"),
        content: Text(
          "Le solde restant (${v.balance.toStringAsFixed(2)} €) sera reversé dans le compte 'Libre'.",
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

    if (confirmed == true) {
      try {
        await ref.read(accountServiceProvider).deleteVirtualAccount(v);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Enveloppe supprimée")));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
        }
      }
    }
  }

  // _getIconForType IS REPLACED BY UiUtils
  // _getLabelForType is kept for text

  String _getLabelForType(VirtualAccountType type) {
    switch (type) {
      case VirtualAccountType.systemFree:
        return "Non alloué (Libre)";
      case VirtualAccountType.systemCommitted:
        return "Engagé (Dépenses à venir)";
      case VirtualAccountType.flowToDistribute:
        return "À Distribuer";
      case VirtualAccountType.userBudget:
        return "Budget";
    }
  }

  void _showAddEnvelopeDialog(
    BuildContext context,
    WidgetRef ref,
    String accountId,
  ) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouvelle Enveloppe"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Nom"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text;
              if (name.isNotEmpty) {
                await ref
                    .read(accountServiceProvider)
                    .createVirtualAccount(realAccountId: accountId, name: name);
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
