import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../../accounts/application/account_service.dart';

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
              Expanded(
                child: virtualAccountsAsync.when(
                  data: (virtuals) {
                    if (virtuals.isEmpty) {
                      return const Center(
                        child: Text("Aucune enveloppe créée"),
                      );
                    }

                    // Sort: Income -> User -> System
                    // Or customized logic.
                    // For now, simple list.
                    return ListView.builder(
                      itemCount: virtuals.length,
                      itemBuilder: (context, index) {
                        final v = virtuals[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Icon(_getIconForType(v.type)),
                          ),
                          title: Text(v.name),
                          subtitle: Text(_getLabelForType(v.type)),
                          trailing: Text(
                            "${v.balance.toStringAsFixed(2)} €",
                            style: const TextStyle(fontWeight: FontWeight.bold),
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

  IconData _getIconForType(VirtualAccountType type) {
    switch (type) {
      case VirtualAccountType.systemFree:
        return Icons.savings_outlined;
      case VirtualAccountType.systemCommitted:
        return Icons.lock_clock_outlined;
      case VirtualAccountType.flowToDistribute:
        return Icons.input;
      case VirtualAccountType.userBudget:
        return Icons.folder_open;
    }
  }

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
