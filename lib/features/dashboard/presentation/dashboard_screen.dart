import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../accounts/application/account_service.dart';
import '../../accounts/data/account_providers.dart';
import '../../transactions/application/transaction_service.dart';
import '../../transactions/data/transaction_providers.dart';
import '../../accounts/domain/account_models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realAccountsAsync = ref.watch(realAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _showAddEnvelopeDialog(context, ref),
            tooltip: "Nouvelle Enveloppe",
          ),
          IconButton(
            icon: const Icon(Icons.add_home),
            onPressed: () => _showAddAccountDialog(context, ref),
            tooltip: "Nouveau Compte",
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.push('/help'),
            tooltip: "Aide & Concepts",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: "Se déconnecter",
          ),
        ],
      ),
      body: realAccountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text("Bienvenue ! Commencez par créer un compte."),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddAccountDialog(context, ref),
                    child: const Text("Créer mon premier compte"),
                  ),
                ],
              ),
            );
          }

          // Calculate Global Balance (Sum of all Real Accounts)
          final globalBalance = accounts.fold(
            0.0,
            (sum, acc) => sum + acc.balance,
          );

          return Column(
            children: [
              // 1. Balance Header Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Solde Actuel",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${globalBalance.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 1.5 Real Accounts List (Horizontal or Vertical)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Mes Comptes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Optional: "Add" button here too if we want shorter access
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 120, // Height for horizontal cards
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return GestureDetector(
                      onTap: () => context.push('/account/${account.id}'),
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              account.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              account.bankName ?? "Banque",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "${account.balance.toStringAsFixed(2)} €",
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Flux récents",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // 2. Recent Transactions List
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final transactionsAsync = ref.watch(
                      recentTransactionsProvider,
                    );
                    return transactionsAsync.when(
                      data: (transactions) {
                        if (transactions.isEmpty) {
                          return const Center(
                            child: Text("Aucune transaction récente"),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isExpense = tx.amount < 0;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              onLongPress: () =>
                                  _confirmDeleteTransaction(context, ref, tx),
                              leading: CircleAvatar(
                                backgroundColor: isExpense
                                    ? Colors.red.shade50
                                    : Colors.green.shade50,
                                child: Icon(
                                  isExpense
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isExpense ? Colors.red : Colors.green,
                                ),
                              ),
                              title: Text(
                                tx.label ?? "Sans libellé",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                tx.transactionDate.toLocal().toString().split(
                                  ' ',
                                )[0],
                              ),
                              trailing: Text(
                                "${tx.amount.toStringAsFixed(2)} €",
                                style: TextStyle(
                                  color: isExpense ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) =>
                          Center(child: Text("Erreur transactions: $e")),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        child: const Icon(Icons.add),
        tooltip: "Nouvelle transaction",
      ),
    );
  }

  void _confirmDeleteTransaction(
    BuildContext context,
    WidgetRef ref,
    dynamic tx,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer la transaction ?"),
        content: const Text(
          "Cette action est irréversible et mettra à jour vos soldes.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(transactionServiceProvider).deleteTransaction(tx);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouveau Compte Bancaire"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nom du compte (ex: BNP, Revolut)",
              ),
            ),
            TextField(
              controller: balanceController,
              decoration: const InputDecoration(labelText: "Solde initial"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text;
              final balance = double.tryParse(balanceController.text) ?? 0.0;
              if (name.isNotEmpty) {
                await ref
                    .read(accountServiceProvider)
                    .createRealAccount(
                      name: name,
                      bankName: "Banque",
                      initialBalance: balance,
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

  void _showAddEnvelopeDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    // We need to select a RealAccount
    // We can read the provider directly or watch it (but dialog context logic is tricky with watch).
    // Using ref.read for the initial data is okay if we assume it's loaded.
    final accountsAsync = ref.read(realAccountsProvider);

    accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Créez d'abord un compte bancaire !")),
          );
          return;
        }

        RealAccount selectedAccount = accounts.first;

        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text("Nouvelle Enveloppe"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<RealAccount>(
                      value: selectedAccount,
                      decoration: const InputDecoration(
                        labelText: "Rattachée au compte",
                      ),
                      items: accounts.map((acc) {
                        return DropdownMenuItem(
                          value: acc,
                          child: Text(acc.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedAccount = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nom de l'enveloppe (ex: Courses)",
                      ),
                    ),
                  ],
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
                            .createVirtualAccount(
                              realAccountId: selectedAccount.id,
                              name: name,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    child: const Text("Créer"),
                  ),
                ],
              );
            },
          ),
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }
}
