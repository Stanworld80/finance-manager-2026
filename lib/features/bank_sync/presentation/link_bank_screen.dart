import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/bank_sync_providers.dart';

class LinkBankScreen extends ConsumerWidget {
  const LinkBankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banksAsync = ref.watch(availableBanksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Connecter une Banque")),
      body: banksAsync.when(
        data: (banks) => ListView.builder(
          itemCount: banks.length,
          itemBuilder: (context, index) {
            final bank = banks[index];
            return ListTile(
              leading: const Icon(
                Icons.account_balance,
              ), // Placeholder for logo
              title: Text(bank.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Launch auth flow
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Simulation de connexion à ${bank.name}..."),
                  ),
                );
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Erreur: $err")),
      ),
    );
  }
}
