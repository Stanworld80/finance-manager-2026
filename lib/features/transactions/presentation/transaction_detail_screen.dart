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
    final allRealAccountsAsync = ref.watch(realAccountsProvider);

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
            icon: const Icon(Icons.cancel_outlined),
            tooltip: "Annuler la transaction",
            onPressed: () {
              transactionAsync.whenData((tx) {
                if (tx != null && tx.step != TransactionStep.cancelled) {
                  _confirmCancel(context, ref, tx);
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
          if (transactionAsync.value != null && transactionAsync.value!.linkedTransactionId != null)
            IconButton(
              icon: const Icon(Icons.link_off),
              tooltip: "Délier le virement",
              onPressed: () {
                _confirmUnlink(context, ref, transactionAsync.value!);
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
            data: (virtuals) {
              return allRealAccountsAsync.when(
                data: (realAccounts) =>
                    _buildContent(context, tx, virtuals, realAccounts, ref),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    Center(child: Text("Erreur comptes réels: $e")),
              );
            },
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
    List<RealAccount> realAccounts,
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
                if (tx.linkedTransactionId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TransactionDetailScreen(
                              transactionId: tx.linkedTransactionId!,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "Virement Lié",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
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
                "Flux Financiers",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            // Logic to separate Source (-ve) and Dest (+ve)
            // Just displaying them in a smarter way
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tx.splits.length,
              itemBuilder: (context, index) {
                // Sort by amount: Negative (=Source) first
                final sortedSplits = List<TransactionSplit>.from(tx.splits)
                  ..sort((a, b) => a.amount.compareTo(b.amount));

                final split = sortedSplits[index];

                // Name Resolution
                String displayName = "Inconnu";
                String? subtitle;

                if (SystemAccounts.isSystem(split.virtualAccountId)) {
                  if (split.virtualAccountId == SystemAccounts.external) {
                    displayName = "Monde Extérieur";
                    subtitle = "Contrepartie Système";
                  } else if (split.virtualAccountId ==
                      SystemAccounts.externalAdjustment) {
                    displayName = "Ajustement";
                    subtitle = "Correction de solde";
                  } else {
                    // Generic System Fallback
                    displayName = "Système";
                    subtitle = split.virtualAccountId;
                  }
                } else {
                  // Try to find in virtuals
                  try {
                    final vAccount = virtuals.firstWhere(
                      (v) => v.id == split.virtualAccountId,
                    );
                    displayName = vAccount.name;

                    try {
                      final realAccount = realAccounts.firstWhere(
                        (r) => r.id == vAccount.realAccountId,
                      );
                      displayName += " (${realAccount.name})";
                    } catch (_) {
                      // Real account not found, just ignore
                    }

                    // subtitle = "Compte Virtuel";
                  } catch (_) {
                    displayName = "Compte Inconnu";
                    subtitle = "ID: ${split.virtualAccountId}";
                  }
                }

                final isSource = split.amount < 0;
                final roleLabel = isSource ? "Source" : "Destination";

                return Card(
                  elevation: 0,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSource
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      child: Icon(
                        isSource ? Icons.upload : Icons.download,
                        color: isSource ? Colors.red : Colors.green,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subtitle != null) Text(subtitle),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            roleLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      "${split.amount > 0 ? '+' : ''}${split.amount.toStringAsFixed(2)} €",
                      style: TextStyle(
                        color: split.amount >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
              await ref.read(transactionServiceProvider).deleteTransaction(
                transaction: tx,
              );
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

  void _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Annuler la transaction ?"),
        content: const Text(
          "Cette action marquera la transaction comme 'Annulée' et remettra les compteurs de solde à leur état d'origine.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Retour"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(transactionServiceProvider).cancelTransaction(tx);
              if (ctx.mounted) {
                Navigator.pop(ctx); // Close Dialog
              }
            },
            child: const Text("Annuler l'opération"),
          ),
        ],
      ),
    );
  }

  void _confirmUnlink(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Délier le virement ?"),
        content: const Text(
          "Cette action va séparer les deux opérations liées. Elles redeviendront de simples dépenses/revenus.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(transactionServiceProvider).unlinkTransactions(transaction: tx);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text("Délier"),
          ),
        ],
      ),
    );
  }
}
