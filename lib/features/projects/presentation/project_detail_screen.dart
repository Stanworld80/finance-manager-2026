import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../projects/data/project_providers.dart';
import '../../projects/domain/financial_project_model.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../application/project_service.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails du Projet"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: projectAsync.when(
        data: (project) {
          if (project == null) {
            return const Center(child: Text("Projet introuvable"));
          }
          return _ProjectContent(project: project);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Erreur: $err")),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer le projet ?"),
        content: const Text(
          "Cette action est irréversible. Les enveloppes ne seront pas supprimées, seulement le projet.",
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
      await ref.read(projectServiceProvider).deleteProject(projectId);
      if (context.mounted) context.pop();
    }
  }
}

class _ProjectContent extends ConsumerWidget {
  final FinancialProject project;

  const _ProjectContent({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine linked envelopes logic
    // We want to show the list of envelopes linked to this project
    // Fetch all virtual accounts first (or filter them)
    final allAccountsAsync = ref.watch(allVirtualAccountsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          Text(
            "Enveloppes Liées",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          allAccountsAsync.when(
            data: (allAccounts) {
              final linkedAccounts = allAccounts
                  .where((a) => project.linkedVirtualAccountIds.contains(a.id))
                  .toList();

              final double currentTotal = linkedAccounts.fold(
                0.0,
                (sum, a) => sum + a.balance,
              );

              return Column(
                children: [
                  _buildProgressSection(
                    context,
                    currentTotal,
                    project.targetBudget,
                  ),
                  const SizedBox(height: 24),
                  ...linkedAccounts.map(
                    (a) => Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(Icons.savings)),
                        title: Text(a.name),
                        subtitle: Text(
                          "Solde: ${a.balance.toStringAsFixed(2)} €",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.link_off),
                          onPressed: () => ref
                              .read(projectServiceProvider)
                              .removeEnvelopeFromProject(project, a.id),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text("Lier une enveloppe"),
                    onPressed: () =>
                        _showLinkDialog(context, ref, project, allAccounts),
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text("Erreur de chargement des comptes: $e"),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(project.description),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.flag, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Cible: ${project.targetBudget.toStringAsFixed(2)} €",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (project.targetDate != null) ...[
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(DateFormat('dd/MM/yyyy').format(project.targetDate!)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    double current,
    double target,
  ) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Progression Réalisée"),
            Text("${(progress * 100).toStringAsFixed(1)} %"),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
          backgroundColor: Theme.of(context).dividerColor,
          color: Colors.green.shade400,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "${current.toStringAsFixed(2)} € / ${target.toStringAsFixed(2)} €",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
      ],
    );
  }

  void _showLinkDialog(
    BuildContext context,
    WidgetRef ref,
    FinancialProject project,
    List<VirtualAccount> allAccounts,
  ) {
    // Filter out already linked
    final available = allAccounts
        .where((a) => !project.linkedVirtualAccountIds.contains(a.id))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Lier une enveloppe"),
        content: SizedBox(
          width: double.maxFinite,
          child: available.isEmpty
              ? const Text("Aucune autre enveloppe disponible.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (ctx, i) {
                    final acc = available[i];
                    return ListTile(
                      title: Text(acc.name),
                      subtitle: Text("${acc.balance.toStringAsFixed(2)} €"),
                      onTap: () async {
                        await ref
                            .read(projectServiceProvider)
                            .addEnvelopeToProject(project, acc.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }
}
