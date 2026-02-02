import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../accounts/application/account_service.dart';
import '../../accounts/data/account_providers.dart';
import '../../transactions/data/transaction_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../../../core/presentation/ui_utils.dart';
import '../../../core/presentation/dashed_line.dart';
import '../../../core/providers.dart';

import '../../transactions/application/recurring_transaction_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Sync recurring transactions when entering the dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recurringTransactionServiceProvider).syncRecurringTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final realAccountsAsync = ref.watch(realAccountsProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Finance Manager'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => context.push('/help'),
                ),
                IconButton(
                  icon: const Icon(Icons.account_circle),
                  onPressed: () => context.push('/profile'),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => ref.read(firebaseAuthProvider).signOut(),
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

          final globalBalance = accounts.fold(
            0.0,
            (sum, acc) => sum + acc.balance,
          );

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // 1. Balance Header Card (Hero section)
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(isDesktop ? 24 : 16),
                padding: EdgeInsets.all(isDesktop ? 40 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Solde Total Disponible",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: isDesktop ? 18 : 14,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${globalBalance.toStringAsFixed(2)} €",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 48 : 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Real Accounts Section
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Mes Comptes Bancaires",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isDesktop)
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                _showAddEnvelopeDialog(context, ref),
                            icon: const Icon(Icons.create_new_folder_outlined),
                            label: const Text("Enveloppe"),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () =>
                                _showAddAccountDialog(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text("Compte"),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              if (isDesktop)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) =>
                      _buildAccountCard(context, ref, accounts[index]),
                )
              else
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) =>
                        _buildAccountCard(context, ref, accounts[index]),
                  ),
                ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(
                  "Flux récents",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              _buildTransactionList(ref, isDesktop),
              const SizedBox(height: 100), // Padding for FAB/BottomNav
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              onPressed: () => context.push('/add-transaction'),
              child: const Icon(Icons.add),
              tooltip: "Nouvelle transaction",
            )
          : FloatingActionButton.extended(
              onPressed: () => context.push('/add-transaction'),
              icon: const Icon(Icons.add),
              label: const Text("Transaction"),
            ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    WidgetRef ref,
    RealAccount account,
  ) {
    return GestureDetector(
      onTap: () => context.push('/account/${account.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    account.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              account.bankName ?? "Banque",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Text(
              "${account.balance.toStringAsFixed(2)} €",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... _buildTransactionList ...

  Widget _buildTransactionList(WidgetRef ref, bool isDesktop) {
    return Consumer(
      builder: (context, ref, child) {
        final transactionsAsync = ref.watch(recentTransactionsProvider);
        return transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Center(child: Text("Aucune transaction récente"));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final date = tx.transactionDate.toLocal();
                final dateStr = "${date.day}/${date.month}/${date.year}";

                bool showHeader = false;
                if (index == 0) {
                  showHeader = true;
                } else {
                  final prevDate = transactions[index - 1].transactionDate
                      .toLocal();
                  final prevDateStr =
                      "${prevDate.day}/${prevDate.month}/${prevDate.year}";
                  if (dateStr != prevDateStr) showHeader = true;
                }

                final color = UiUtils.getTransactionColor(
                  tx.type,
                  brightness: Theme.of(context).brightness,
                );
                final icon = UiUtils.getTransactionIcon(tx.type);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          dateStr,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      child: InkWell(
                        onTap: () => context.push('/transaction/${tx.id}'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            12.0,
                          ), // Use Padding instead of ListTile for custom layout
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: color.withOpacity(0.1),
                                child: Icon(icon, color: color),
                              ),
                              const SizedBox(width: 16),
                              if (isDesktop) ...[
                                Text(
                                  tx.label ?? "Transaction",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DashedLine(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  "${tx.amount > 0 ? '+' : ''}${tx.amount.toStringAsFixed(2)} €",
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ] else ...[
                                Expanded(
                                  child: Text(
                                    tx.label ?? "Transaction",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "${tx.amount > 0 ? '+' : ''}${tx.amount.toStringAsFixed(2)} €",
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text("Erreur: $e")),
        );
      },
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
              decoration: const InputDecoration(labelText: "Nom"),
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
              if (nameController.text.isNotEmpty) {
                await ref
                    .read(accountServiceProvider)
                    .createRealAccount(
                      name: nameController.text,
                      bankName: "Banque",
                      initialBalance:
                          double.tryParse(balanceController.text) ?? 0.0,
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
    final accountsAsync = ref.read(realAccountsProvider);

    accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) return;
        RealAccount selectedAccount = accounts.first;
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text("Nouvelle Enveloppe"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<RealAccount>(
                    value: selectedAccount,
                    items: accounts
                        .map(
                          (acc) => DropdownMenuItem(
                            value: acc,
                            child: Text(acc.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedAccount = val);
                    },
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Nom"),
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
                    if (nameController.text.isNotEmpty) {
                      await ref
                          .read(accountServiceProvider)
                          .createVirtualAccount(
                            realAccountId: selectedAccount.id,
                            name: nameController.text,
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text("Créer"),
                ),
              ],
            ),
          ),
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }
}
