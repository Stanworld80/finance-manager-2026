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
                        : () => _handleAction(
                            () => seed.clearAllData(user.uid),
                            'Base de données réinitialisée !',
                          ),
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
}
