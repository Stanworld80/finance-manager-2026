import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../projects/data/project_providers.dart';
import '../../projects/domain/financial_project_model.dart';
import 'package:intl/intl.dart';
import '../application/project_service.dart';
import '../../../core/presentation/widgets/custom_date_picker.dart';

class ProjectsDashboardScreen extends ConsumerWidget {
  const ProjectsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Projets"),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Nouveau Projet",
            onPressed: () => _showAddProjectDialog(context, ref),
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Aucun projet pour le moment",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddProjectDialog(context, ref),
                    child: const Text("Créer un projet"),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _ProjectCard(project: project);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Erreur: $err")),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context, WidgetRef ref) {
    // Basic dialog to create a project
    // In a real app, this might be a full screen or a more complex form
    showDialog(context: context, builder: (context) => _CreateProjectDialog());
  }
}

class _ProjectCard extends StatelessWidget {
  final FinancialProject project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    // Calculate progress (placeholder logic for now, assumes 0 realized)
    // To get real progress, we'd need to fetch linked envelopes and sum balances.
    // For the list view, maybe we just show budget.

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/projects/${project.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (project.targetDate != null)
                    Chip(
                      label: Text(
                        DateFormat('dd/MM/yyyy').format(project.targetDate!),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      labelPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Budget Cible"),
                  Text(
                    "${project.targetBudget.toStringAsFixed(2)} €",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Placeholder progress bar
              LinearProgressIndicator(
                value: 0.0, // TODO: Compute realized / target
                backgroundColor: Theme.of(context).dividerColor,
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateProjectDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateProjectDialog> createState() =>
      _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<_CreateProjectDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _targetDate;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nouveau Projet"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nom du projet"),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: "Description (Optionnel)",
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: "Budget Cible (€)",
                suffixText: "€",
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                _targetDate == null
                    ? "Définir une date cible"
                    : "Cible : ${DateFormat('dd/MM/yyyy').format(_targetDate!)}",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showCustomDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (picked != null) {
                  setState(() => _targetDate = picked);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createProject,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Créer"),
        ),
      ],
    );
  }

  Future<void> _createProject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final budget =
        double.tryParse(_budgetController.text.replaceAll(',', '.')) ?? 0.0;

    setState(() => _isLoading = true);

    try {
      // Need provider to be exported or imported.
      // Assuming import is correct above.
      // Need to find the ProjectService provider definition location.
      // It was in project_service.dart. importing relative.

      // We need to import project_service.dart
      // But we only imported project_providers and model.
      // Let's fix imports if needed.

      await ref
          .read(projectServiceProvider)
          .createProject(
            name: name,
            description: _descController.text.trim(),
            targetBudget: budget,
            targetDate: _targetDate,
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
