import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../accounts/application/account_service.dart';

class DataManagementPage extends ConsumerStatefulWidget {
  const DataManagementPage({super.key});

  @override
  ConsumerState<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends ConsumerState<DataManagementPage> {
  bool _isLoading = false;

  Future<void> _handleAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _isLoading = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final seed = ref.watch(seedServiceProvider);
    final accountService = ref.watch(accountServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Data Management')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: user == null
                        ? null
                        : () => _handleAction(
                            () => seed.seedTechnicalAccount(user.uid),
                            'Données de test injectées !',
                          ),
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Seed Test Data'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: user == null
                        ? null
                        : () async {
                            _handleAction(() async {
                              final stats = await accountService.repairData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${stats['totalAccounts']} comptes analysés, '
                                      '${stats['repaired']} enveloppes réparées, '
                                      '${stats['created']} créées',
                                    ),
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            }, 'Migration terminée');
                          },
                    icon: const Icon(Icons.build),
                    label: const Text('Repair Virtual Accounts (userId)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: user == null
                        ? null
                        : () => _confirmReset(context, seed, user.uid),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Reset All Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    dynamic
    seedService, // using dynamic to avoid import if not handy, but we have it in build
    String userId,
  ) async {
    // 1st Confirmation
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Réinitialiser TOUTES les données ?"),
        content: const Text(
          "Attention, cette action effacera tous les comptes, transactions et enveloppes.\n\n"
          "Voulez-vous continuer ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Continuer"),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    if (!context.mounted) return;

    // 2nd Confirmation
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmation Finale"),
        content: const Text(
          "Êtes-vous ABSOLUMENT certain ?\n"
          "Cette action est irréversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("NON, Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("OUI, TOUT EFFACER"),
          ),
        ],
      ),
    );

    if (confirm2 == true) {
      _handleAction(
        () => seedService.clearAllData(userId),
        'Base de données réinitialisée !',
      );
    }
  }
}
