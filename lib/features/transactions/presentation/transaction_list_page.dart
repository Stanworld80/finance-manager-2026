import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../accounts/data/account_providers.dart';
import '../application/transaction_service.dart';
import '../data/filtered_transactions_provider.dart';
import '../domain/transaction_model.dart';

class TransactionListPage extends ConsumerStatefulWidget {
  const TransactionListPage({super.key});

  @override
  ConsumerState<TransactionListPage> createState() =>
      _TransactionListPageState();
}

class _TransactionListPageState extends ConsumerState<TransactionListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final filters = ref.watch(transactionFilterProvider);
    final accountsAsync = ref.watch(realAccountsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Historique'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exporter (Coming Soon)',
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher transaction...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                    onChanged: (value) {
                      ref
                          .read(transactionFilterProvider.notifier)
                          .setSearch(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Filters Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Date Range Filter
                        ActionChip(
                          avatar: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            filters.startDate != null && filters.endDate != null
                                ? '${DateFormat('dd/MM').format(filters.startDate!)} - ${DateFormat('dd/MM').format(filters.endDate!)}'
                                : 'Toutes les dates',
                          ),
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              initialDateRange:
                                  filters.startDate != null &&
                                      filters.endDate != null
                                  ? DateTimeRange(
                                      start: filters.startDate!,
                                      end: filters.endDate!,
                                    )
                                  : null,
                            );
                            if (picked != null) {
                              ref
                                  .read(transactionFilterProvider.notifier)
                                  .setDateRange(picked.start, picked.end);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Account Filter
                        accountsAsync.when(
                          data: (accounts) {
                            final selectedAccount = accounts
                                .where((a) => a.id == filters.realAccountId)
                                .firstOrNull;
                            return ActionChip(
                              avatar: const Icon(
                                Icons.account_balance,
                                size: 16,
                              ),
                              label: Text(
                                selectedAccount?.name ?? 'Tous les comptes',
                              ),
                              onPressed: () {
                                _showAccountPicker(
                                  context,
                                  accounts,
                                  filters.realAccountId,
                                );
                              },
                            );
                          },
                          loading: () =>
                              const CircularProgressIndicator.adaptive(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        if (filters.searchQuery != null ||
                            filters.realAccountId != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(transactionFilterProvider.notifier)
                                    .clearFilters();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Aucune transaction trouvée.')),
                );
              }

              // Group by Date
              final grouped = <DateTime, List<TransactionModel>>{};
              for (var tx in transactions) {
                final date = DateTime(
                  tx.transactionDate.year,
                  tx.transactionDate.month,
                  tx.transactionDate.day,
                );
                grouped.putIfAbsent(date, () => []).add(tx);
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final date = grouped.keys.elementAt(index);
                  final txs = grouped[date]!;
                  return _buildDateGroup(context, date, txs);
                }, childCount: grouped.keys.length),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('Erreur: $err'))),
          ),
        ],
      ),
    );
  }

  void _showAccountPicker(
    BuildContext context,
    List<dynamic> accounts,
    String? currentId,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Tous les comptes'),
              selected: currentId == null,
              onTap: () {
                ref.read(transactionFilterProvider.notifier).setAccount(null);
                Navigator.pop(ctx);
              },
            ),
            ...accounts.map(
              (acc) => ListTile(
                title: Text(acc.name),
                selected: acc.id == currentId,
                onTap: () {
                  ref
                      .read(transactionFilterProvider.notifier)
                      .setAccount(acc.id);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateGroup(
    BuildContext context,
    DateTime date,
    List<TransactionModel> txs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...txs.map((tx) => _buildTransactionTile(context, tx)),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionModel tx) {
    final isExpense = tx.amount < 0;
    final isPending = tx.step == TransactionStep.pending;
    final isPlanned =
        tx.step == TransactionStep.planned ||
        tx.step == TransactionStep.scheduled;
    final amountColor = isExpense ? Colors.red : Colors.green;

    final card = ListTile(
      onTap: () => context.push('/transaction/${tx.id}'),
      leading: CircleAvatar(
        backgroundColor: isExpense
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          isExpense ? Icons.arrow_downward : Icons.arrow_upward,
          color: isExpense
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          size: 16,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              tx.payee ?? tx.label ?? 'Sans libellé',
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "En attente",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isPlanned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "Planifié",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(tx.label ?? ''),
      trailing: Text(
        CurrencyFormatter.format(tx.amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isPending
              ? Colors.orange
              : (isPlanned ? Colors.grey : amountColor),
        ),
      ),
    );

    if (isPending) {
      return Dismissible(
        key: Key('pending-${tx.id}'),
        direction: DismissDirection.startToEnd,
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 16.0),
          color: Colors.green.shade400,
          child: const Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Pointer",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          try {
            await ref.read(transactionServiceProvider).confirmTransaction(tx);
            return false;
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Action échouée: $e")));
            }
            return false;
          }
        },
        child: card,
      );
    }

    if (isPlanned) {
      return Dismissible(
        key: Key('planned-${tx.id}'),
        direction: DismissDirection.startToEnd,
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 16.0),
          color: Colors.orange.shade400,
          child: const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Provisionner",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          try {
            await ref.read(transactionServiceProvider).provisionTransaction(tx);
            return false;
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Action échouée: $e")));
            }
            return false;
          }
        },
        child: card,
      );
    }

    return card;
  }
}
