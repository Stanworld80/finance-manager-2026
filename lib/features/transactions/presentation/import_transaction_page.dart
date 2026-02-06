import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../application/csv_import_service.dart';
import '../application/transaction_service.dart';
import '../domain/transaction_model.dart';

class ImportTransactionPage extends ConsumerStatefulWidget {
  const ImportTransactionPage({super.key});

  @override
  ConsumerState<ImportTransactionPage> createState() =>
      _ImportTransactionPageState();
}

class _ImportTransactionPageState extends ConsumerState<ImportTransactionPage> {
  List<ParsedTransaction> _previewTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  RealAccount? _selectedRealAccount;
  VirtualAccount? _targetVirtualAccount; // Default target for valid rows

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _previewTransactions = [];
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        final service = ref.read(csvImportServiceProvider);
        final rawRows = service.parseCsv(content);
        final analysis = service.analyzeCsv(rawRows);

        if (analysis.dateColumnIndex == -1 ||
            analysis.amountColumnIndex == -1) {
          setState(() {
            _errorMessage =
                "Impossible de détecter les colonnes Date et Montant automatiquement.";
            _isLoading = false;
          });
          return;
        }

        final parsed = service.extractTransactions(
          rawRows, // pass raw rows, extractTransactions handles logic
          dateIdx: analysis.dateColumnIndex,
          amountIdx: analysis.amountColumnIndex,
          labelIdx: analysis.labelColumnIndex != -1
              ? analysis.labelColumnIndex
              : 2, // Fallback
        );

        setState(() {
          _previewTransactions = parsed;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur lors de la lecture du fichier: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _importTransactions() async {
    if (_selectedRealAccount == null || _targetVirtualAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner les comptes cibles."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(transactionServiceProvider);
      int count = 0;

      for (var pTx in _previewTransactions) {
        // Determine Type based on Amount Sign
        // If amount < 0 => Debit (Expense)
        // If amount > 0 => Credit (Income)
        final type = pTx.amount < 0
            ? TransactionType.debit
            : TransactionType.credit;
        // For addTransaction, amount must be absolute
        final amountAbs = pTx.amount.abs();

        await service.addTransaction(
          amount: amountAbs,
          type: type,
          label: pTx.label,
          date: pTx.date,
          realAccount: _selectedRealAccount!,
          targetVirtualAccount: _targetVirtualAccount!,
          note: pTx.note ?? "Import CSV",
        );
        count++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$count transactions importées avec succès !"),
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur lors de l'import: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(realAccountsProvider);
    final virtualsAsync = ref.watch(allVirtualAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Importer CSV")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Account Selectors
            Row(
              children: [
                Expanded(
                  child: accountsAsync.when(
                    data: (accounts) {
                      if (accounts.isEmpty) {
                        return const Text("Aucun compte réel");
                      }
                      return DropdownButtonFormField<RealAccount>(
                        decoration: const InputDecoration(
                          labelText: "Compte Réel Cible",
                        ),
                        initialValue: _selectedRealAccount,
                        items: accounts.map((acc) {
                          return DropdownMenuItem(
                            value: acc,
                            child: Text(acc.name),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedRealAccount = v),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text("Erreur: $e"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: virtualsAsync.when(
                    data: (virtuals) {
                      // Filter only user money bugets? For now all.
                      if (virtuals.isEmpty) {
                        return const Text("Aucun compte virtuel");
                      }
                      return DropdownButtonFormField<VirtualAccount>(
                        decoration: const InputDecoration(
                          labelText: "Budget par défaut",
                        ),
                        initialValue: _targetVirtualAccount,
                        items: virtuals.map((v) {
                          return DropdownMenuItem(
                            value: v,
                            child: Text(v.name),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _targetVirtualAccount = v),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text("Erreur: $e"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // File Picker
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text("Choisir un fichier CSV"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: _isLoading ? null : _pickFile,
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 20),

            // Preview List
            Expanded(
              child: _previewTransactions.isEmpty
                  ? Center(
                      child: Text(
                        "Aucune transaction à afficher.\nSélectionnez un fichier.",
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Aperçu (${_previewTransactions.length})",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Card(
                            child: ListView.separated(
                              itemCount: _previewTransactions.length,
                              separatorBuilder: (c, i) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final tx = _previewTransactions[index];
                                final isCredit = tx.amount >= 0;
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    isCredit
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isCredit ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  title: Text(
                                    tx.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    DateFormat('dd/MM/yyyy').format(tx.date),
                                  ),
                                  trailing: Text(
                                    "${tx.amount.toStringAsFixed(2)} €",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCredit
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _previewTransactions.isEmpty || _isLoading
                    ? null
                    : _importTransactions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text("IMPORTER CES TRANSACTIONS"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
