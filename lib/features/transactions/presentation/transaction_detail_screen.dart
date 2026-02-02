import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/ui_utils.dart';
import '../../transactions/data/transaction_providers.dart';
import '../../transactions/application/transaction_service.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import 'add_transaction_page.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionByIdProvider(transactionId));
    final allVirtualsAsync = ref.watch(allVirtualAccountsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Détails"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              transactionAsync.whenData((tx) {
                if (tx != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          AddTransactionPage(transactionToEdit: tx),
                    ),
                  );
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              transactionAsync.whenData((tx) {
                if (tx != null) _confirmDelete(context, ref, tx);
              });
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: transactionAsync.when(
        data: (tx) {
          if (tx == null) {
            return const Center(child: Text("Transaction introuvable"));
          }
          return allVirtualsAsync.when(
            data: (virtuals) => _buildContent(context, tx, virtuals, ref),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text("Erreur comptes: $e")),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Erreur: $e")),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TransactionModel tx,
    List<VirtualAccount> virtuals,
    WidgetRef ref,
  ) {
    final color = UiUtils.getTransactionColor(
      tx.type,
      brightness: Theme.of(context).brightness,
    );
    final icon = UiUtils.getTransactionIcon(tx.type);
    final dateStr = DateFormat(
      'dd MMM yyyy à HH:mm',
    ).format(tx.transactionDate.toLocal());

    // Calculate display amount (Expenses usually shown as negative in lists, but here we show magnitude with color)
    // Assuming tx.amount is signed or we rely on Type.
    // In Dashboard we did: `displayAmount = tx.amount` and handled prefix based on value.
    // Let's stick to showing the raw value but styled.
    final displayAmount = tx.amount.abs();
    final prefix = tx.amount < 0 ? '-' : '+';
    // Actually, if it's a transfer, amount might be 0 on the main tx, but splits have values.
    // If it's a simple expense/income, amount is set.
    final isTransfer = tx.type == TransactionType.transfer;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 100,
              bottom: 40,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  radius: 32,
                  child: Icon(icon, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  tx.label ?? (isTransfer ? "Virement" : "Sans libellé"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "$prefix${displayAmount.toStringAsFixed(2)} €",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (tx.status != TransactionStatus.none)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tx.status.toString().split('.').last,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Details List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildInfoTile(
                  context,
                  icon: Icons.calendar_today,
                  title: "Date",
                  value: dateStr,
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.category_outlined,
                  title: "Catégorie",
                  value: tx.category?.isNotEmpty == true
                      ? tx.category!
                      : "Non classé",
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.notes,
                  title: "Notes",
                  value: tx.note?.isNotEmpty == true ? tx.note! : "Aucune note",
                ),
              ],
            ),
          ),

          if (tx.splits.isNotEmpty) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Ventilation / Détails",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tx.splits.length,
              itemBuilder: (context, index) {
                final split = tx.splits[index];
                final vAccount = virtuals.firstWhere(
                  (v) => v.id == split.virtualAccountId,
                  orElse: () => VirtualAccount(
                    id: split.virtualAccountId,
                    userId: '',
                    realAccountId: '',
                    name: 'Inconnu (ID: ${split.virtualAccountId})',
                    balance: 0,
                    type: VirtualAccountType.userBudget,
                    icon: null,
                  ),
                );

                String displayName = vAccount.name;
                if (SystemAccounts.isSystem(split.virtualAccountId)) {
                  if (split.virtualAccountId == SystemAccounts.external)
                    displayName = "Monde Extérieur";
                }

                // Try to get real account name?
                // We'd need RealAccounts list. We can fetch it or just show Virtual Account Name.
                // Usually Virtual Account Name is enough (e.g. "Courses", "Loyer").
                // If we want "Compte Courant > Courses", we need RealAccount.
                // I'll stick to Virtual Account Name for now as it's much better than nothing.

                return Card(
                  elevation: 0,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.pie_chart_outline),
                    title: Text(displayName),
                    subtitle: SystemAccounts.isSystem(split.virtualAccountId)
                        ? const Text("Compte Système")
                        : null,
                    trailing: Text(
                      "${split.amount > 0 ? '+' : ''}${split.amount.toStringAsFixed(2)} €",
                      style: TextStyle(
                        color: split.amount >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
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
              if (ctx.mounted) {
                Navigator.pop(ctx); // Close Dialog
                context.pop(); // Go back to Dashboard
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }
}
