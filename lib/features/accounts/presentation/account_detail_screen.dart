import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../../accounts/application/account_service.dart';
import '../../../core/presentation/ui_utils.dart';
import '../../transactions/presentation/widgets/transaction_list.dart';
import 'envelope_detail_screen.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../../core/providers.dart';

final accountTransactionsProvider =
    FutureProvider.family<List<TransactionModel>, String>((ref, realAccountId) {
      final repository = ref.read(transactionRepositoryProvider);
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) return [];
      return repository.getTransactionsByRealAccount(user.uid, realAccountId);
    });

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
            icon: const Icon(Icons.create_new_folder),
            tooltip: 'Nouvelle Enveloppe',
            onPressed: () => _showAddEnvelopeDialog(context, ref, accountId),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier le compte',
            onPressed: () {
              final accountsAsync = ref.read(realAccountsProvider);
              accountsAsync.whenData((accounts) {
                final account = accounts.firstWhere((a) => a.id == accountId);
                _showEditAccountDialog(context, ref, account);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            color: Colors.red.shade300,
            tooltip: 'Supprimer le compte',
            onPressed: () {
              final accountsAsync = ref.read(realAccountsProvider);
              accountsAsync.whenData((accounts) {
                final account = accounts.firstWhere(
                  (a) => a.id == accountId,
                  orElse: () => RealAccount(
                    id: 'not-found',
                    ownerId: '',
                    name: '',
                    balance: 0,
                  ),
                );
                if (account.id != 'not-found') {
                  _confirmDeleteAccount(context, ref, account);
                }
              });
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: realAccountsAsync.when(
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
                      if (account.iban != null && account.iban!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "IBAN: ${account.iban}",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontFamily: 'monospace',
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      virtualAccountsAsync.when(
                        data: (virtuals) {
                          final committedAccount = virtuals
                              .where(
                                (v) =>
                                    v.type ==
                                    VirtualAccountType.systemCommitted,
                              )
                              .firstOrNull;
                          final soldeEngage = committedAccount?.balance ?? 0.0;
                          final soldeDisponible = account.balance - soldeEngage;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "${soldeDisponible.toStringAsFixed(2)} €",
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text("Solde Disponible"),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "${account.balance.toStringAsFixed(2)} €",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "Solde Réel",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 32),
                                  Column(
                                    children: [
                                      Text(
                                        "${soldeEngage.toStringAsFixed(2)} €",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      Text(
                                        "Solde Engagé",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                const TabBar(
                  tabs: [
                    Tab(text: "Enveloppes"),
                    Tab(text: "Transactions"),
                  ],
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    children: [
                      // -- TAB 1: Envelopes List --
                      virtualAccountsAsync.when(
                        data: (virtuals) {
                          if (virtuals.isEmpty) {
                            return const Center(
                              child: Text("Aucune enveloppe créée"),
                            );
                          }

                          final sortedVirtuals = List<VirtualAccount>.from(
                            virtuals,
                          );
                          sortedVirtuals.sort((a, b) {
                            final priorityA = _getPriority(a.type);
                            final priorityB = _getPriority(b.type);
                            if (priorityA != priorityB) {
                              return priorityA.compareTo(priorityB);
                            }
                            return a.name.compareTo(b.name);
                          });

                          return ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: sortedVirtuals.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final v = sortedVirtuals[index];
                              final color = UiUtils.getVirtualAccountColor(
                                v.type,
                                brightness: Theme.of(context).brightness,
                              );
                              final icon = UiUtils.getVirtualAccountIcon(
                                v.type,
                              );

                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: color.withOpacity(0.3),
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) =>
                                            EnvelopeDetailScreen(envelope: v),
                                      ),
                                    );
                                  },
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
                                      const Icon(Icons.chevron_right),
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

                      // -- TAB 2: Transactions --
                      Consumer(
                        builder: (context, ref, child) {
                          final transactionsAsync = ref.watch(
                            accountTransactionsProvider(accountId),
                          );
                          return transactionsAsync.when(
                            data: (transactions) =>
                                TransactionList(transactions: transactions),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, s) => Center(child: Text("Erreur: $e")),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Erreur: $e")),
        ),
      ),
    );
  }

  void _showEditAccountDialog(
    BuildContext context,
    WidgetRef ref,
    RealAccount account,
  ) {
    final nameController = TextEditingController(text: account.name);
    final bankController = TextEditingController(text: account.bankName ?? '');
    final ibanController = TextEditingController(text: account.iban ?? '');
    final bicController = TextEditingController(text: account.bic ?? '');
    final officialNameController = TextEditingController(
      text: account.officialName ?? '',
    );
    final accountNumberController = TextEditingController(
      text: account.accountNumber ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Modifier le compte"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nom d'affichage *",
                ),
              ),
              TextField(
                controller: bankController,
                decoration: const InputDecoration(labelText: "Banque"),
              ),
              TextField(
                controller: officialNameController,
                decoration: const InputDecoration(
                  labelText: "Dénomination officielle",
                ),
              ),
              TextField(
                controller: accountNumberController,
                decoration: const InputDecoration(
                  labelText: "Numéro de compte",
                ),
              ),
              TextField(
                controller: ibanController,
                decoration: const InputDecoration(labelText: "IBAN"),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              TextField(
                controller: bicController,
                decoration: const InputDecoration(labelText: "BIC / SWIFT"),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Compte Principal"),
                subtitle: const Text(
                  "Utilisé par défaut pour les nouvelles transactions",
                ),
                value: account.isPrincipal,
                onChanged: (value) async {
                  if (value) {
                    await ref
                        .read(accountServiceProvider)
                        .setPrincipalAccount(account.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } else {
                    // Logic to unset principal if needed,
                    // but usually you just set another one as principal.
                    // For now, let's just allow setting it to true.
                    // If they want to unset, they set another account.
                  }
                },
              ),
            ],
          ),
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
                    .updateRealAccountMetadata(
                      account: account,
                      name: nameController.text,
                      bankName: bankController.text,
                      iban: ibanController.text,
                      bic: bicController.text,
                      officialName: officialNameController.text,
                      accountNumber: accountNumberController.text,
                    );
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

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
    RealAccount account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Supprimer ${account.name} ?"),
        content: const Text(
          "ATTENTION: Cette action supprimera définitivement le compte, "
          "toutes ses enveloppes et toutes ses transactions associées.\n\n"
          "Cette action est irréversible.",
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
            child: const Text("Supprimer définitivement"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
        // Show loading or verify?
        // We'll just execute.
        try {
          // Go back first to avoid error when page rebuilds with missing data
          Navigator.pop(context);

          await ref.read(accountServiceProvider).deleteRealAccount(account);
        } catch (e) {
          // If we popped, we might need a gobal scaffold messenger or show dialog again?
          // Since we popped, we are back on Dashboard.
          // Ideally we stay and show loading, but handling "deleted state" in this screen
          // requires complex logic because StreamBuilder will error out or return empty.
          // Popping is safest. We can show a snackbar on the previous screen (Dashboard).
        }
      }
    }
  }
}
