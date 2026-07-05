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

import '../../transactions/presentation/projected_balance_provider.dart';
import '../../transactions/presentation/widgets/provision_dialog.dart';
import '../../transactions/presentation/recurrence_list_page.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Sync logic will be added later
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
                  icon: const Icon(Icons.calendar_month),
                  tooltip: "Récurrences",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RecurrenceListPage(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.account_circle),
                  onPressed: () => context.push('/profile'),
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: () => context.push('/import'),
                ),
              ],
            ),
      body: realAccountsAsync.when(
        data: (accounts) {
          final allVirtualsAsync = ref.watch(allVirtualAccountsProvider);
          return allVirtualsAsync.when(
            data: (virtuals) {
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

              // Separate internal from external accounts
              final internalAccounts = accounts
                  .where((a) => a.type == RealAccountType.internal)
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));
              final externalAccounts = accounts
                  .where(
                    (a) =>
                        a.type == RealAccountType.external ||
                        a.type == RealAccountType.externalGeneric,
                  )
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));

              final globalRealBalance = internalAccounts.fold(
                0.0,
                (sum, acc) => sum + acc.balance,
              );

              final globalEngage = virtuals
                  .where((v) => v.type == VirtualAccountType.systemCommitted)
                  .fold(0.0, (sum, v) => sum + v.balance);

              final globalDisponible = globalRealBalance - globalEngage;

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
                          color: Colors.blue.withValues(alpha: 0.3),
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
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: isDesktop ? 18 : 14,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${globalDisponible.toStringAsFixed(2)} €",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 48 : 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              "Solde Réel : ${globalRealBalance.toStringAsFixed(2)} €",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: isDesktop ? 16 : 14,
                              ),
                            ),
                            if (globalEngage != 0) ...[
                              const SizedBox(width: 16),
                              Text(
                                "Engagé : ${globalEngage.toStringAsFixed(2)} €",
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: isDesktop ? 16 : 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (context, ref, child) {
                            final projectedAsync = ref.watch(
                              projectedBalanceProvider,
                            );
                            return projectedAsync.when(
                              data: (balance) => Text(
                                "Projeté (Fin de mois) : ${balance.toStringAsFixed(2)} €",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: isDesktop ? 16 : 14,
                                ),
                              ),
                              loading: () => SizedBox(
                                height: 20,
                                width: 100,
                                child: LinearProgressIndicator(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                              error: (e, s) => Text(
                                "Erreur projection",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _buildQuickActionHub(context),

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
                                icon: const Icon(
                                  Icons.create_new_folder_outlined,
                                ),
                                label: const Text("Enveloppe"),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () =>
                                    _showAddAccountDialog(context, ref),
                                icon: const Icon(Icons.add),
                                label: const Text("Compte"),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => context.push('/import'),
                                icon: const Icon(Icons.upload_file),
                                label: const Text("Importer CSV"),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
                    child: Column(
                      children: internalAccounts.map((acc) => _buildAccountRow(context, ref, acc)).toList(),
                    ),
                  ),

                  // External Accounts grouped section
                  if (externalAccounts.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        leading: const Icon(Icons.public, color: Colors.teal),
                        title: const Text(
                          "Monde Extérieur",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${externalAccounts.length} entité${externalAccounts.length > 1 ? 's' : ''}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        initiallyExpanded: false,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              children: externalAccounts
                                  .map((acc) => _buildAccountRow(context, ref, acc))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Flux récents",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.push('/transactions'),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Voir tout'),
                        ),
                      ],
                    ),
                  ),

                  _buildTransactionList(ref, isDesktop),
                  Consumer(
                    builder: (context, ref, child) {
                      final packageInfoAsync = ref.watch(packageInfoProvider);
                      return packageInfoAsync.when(
                        data: (info) => Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 8),
                          child: Center(
                            child: Text(
                              'v${info.version} (${info.buildNumber})',
                              style: TextStyle(
                                color: Colors.grey.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      );
                    },
                  ),
                  const SizedBox(height: 100), // Padding for FAB/BottomNav
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erreur: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildAccountRow(
    BuildContext context,
    WidgetRef ref,
    RealAccount account,
  ) {
    return InkWell(
      onTap: () => context.push('/account/${account.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Text(
              account.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: DashedLine(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.8),
                  dashWidth: 2,
                  dashSpace: 3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "${account.balance.toStringAsFixed(2)} €",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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

            final displayCount = transactions.length > 3 ? 3 : transactions.length;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: displayCount,
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
                                backgroundColor: color.withValues(alpha: 0.1),
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
                    initialValue: selectedAccount,
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
      error: (_, _) {},
    );
  }

  Widget _buildQuickActionHub(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final actions = [
      _QuickActionItem(
        label: "Dépense",
        icon: Icons.outbound_outlined,
        color: Colors.red.shade600,
        backgroundColor: Colors.red.shade50.withValues(alpha: 0.1),
        onTap: () => context.push('/add-transaction?type=debit'),
      ),
      _QuickActionItem(
        label: "Revenu",
        icon: Icons.move_to_inbox_outlined,
        color: Colors.green.shade600,
        backgroundColor: Colors.green.shade50.withValues(alpha: 0.1),
        onTap: () => context.push('/add-transaction?type=credit'),
      ),
      _QuickActionItem(
        label: "Provision",
        icon: Icons.savings_outlined,
        color: Colors.teal.shade600,
        backgroundColor: Colors.teal.shade50.withValues(alpha: 0.1),
        onTap: () => showDialog(
          context: context,
          builder: (context) => const ProvisionDialog(),
        ),
      ),
      _QuickActionItem(
        label: "Virement",
        icon: Icons.swap_horiz_outlined,
        color: Colors.blue.shade600,
        backgroundColor: Colors.blue.shade50.withValues(alpha: 0.1),
        onTap: () => context.push('/add-transaction?type=transfer'),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Actions Rapides",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isDesktop ? 2.5 : 1.6,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final item = actions[index];
              return Card(
                elevation: 0,
                color: item.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: item.color.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: item.color.withValues(alpha: 0.12),
                          child: Icon(item.icon, color: item.color, size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  _QuickActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });
}
