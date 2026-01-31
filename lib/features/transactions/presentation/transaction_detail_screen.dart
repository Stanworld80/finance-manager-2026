import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/ui_utils.dart';
import '../../transactions/data/transaction_providers.dart';
import '../../transactions/application/transaction_service.dart';
import '../../transactions/domain/transaction_model.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionByIdProvider(transactionId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Détails de la transaction'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          transactionAsync.maybeWhen(
            data: (transaction) => transaction != null
                ? IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.blueGrey,
                    ),
                    onPressed: () => _confirmDelete(context, ref, transaction),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: transactionAsync.when(
        data: (transaction) {
          if (transaction == null) {
            return const Center(child: Text("Transaction introuvable"));
          }
          return _buildContent(context, transaction);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TransactionModel tx) {
    final color = UiUtils.getTransactionColor(tx.type);
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Répartition",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tx.splits.length,
              itemBuilder: (context, index) {
                final split = tx.splits[index];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.pie_chart_outline),
                    title: Text(
                      "Compte Virtuel ID: ${split.virtualAccountId.substring(0, 4)}...",
                    ), // Placeholder for Name
                    trailing: Text(
                      "${split.amount > 0 ? '+' : ''}${split.amount.toStringAsFixed(2)} €",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: split.amount >= 0 ? Colors.green : Colors.red,
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
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey.shade600),
        title: Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
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
