import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:finance_manager_2026/features/import/data/bank_import_service.dart';
import 'package:finance_manager_2026/features/import/domain/imported_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../../transactions/application/transaction_service.dart';
import '../../transactions/domain/transaction_model.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final BankImportService _importService = BankImportService();
  List<ImportedTransaction> _transactions = [];
  bool _isLoading = false;
  String? _fileName;
  RealAccount? _selectedAccount;

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        _fileName = result.files.single.name;

        // Parse
        final raw = await _importService.parseExcel(file);
        // Guess
        final guessed = _importService.guessEnvelopes(raw);

        setState(() {
          _transactions = guessed;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing file: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeTransaction(int index) {
    setState(() {
      _transactions.removeAt(index);
    });
  }

  Future<void> _confirmImport() async {
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target account.')),
      );
      return;
    }

    // Fetch virtual accounts for the selected real account
    final allVirtual = await ref.read(allVirtualAccountsProvider.future);
    final accountEnvelopes = allVirtual
        .where((v) => v.realAccountId == _selectedAccount!.id)
        .toList();

    final defaultVirtual = accountEnvelopes.firstOrNull;

    if (defaultVirtual == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected account has no envelopes.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    int count = 0;
    try {
      final service = ref.read(transactionServiceProvider);
      for (final t in _transactions) {
        // Resolve Target Envelope
        VirtualAccount targetEnv = defaultVirtual;

        bool found = false;

        // 1. Try ID match
        if (t.targetEnvelopeId != null) {
          final matchId = accountEnvelopes
              .where((v) => v.id == t.targetEnvelopeId)
              .firstOrNull;
          if (matchId != null) {
            targetEnv = matchId;
            found = true;
          }
        }

        // 2. Try Name match (if not found by ID)
        if (!found && t.targetEnvelopeName != null) {
          final normalize = (String s) => s.trim().toLowerCase();
          final targetName = normalize(t.targetEnvelopeName!);

          final matchName = accountEnvelopes
              .where((v) => normalize(v.name) == targetName)
              .firstOrNull;
          if (matchName != null) {
            targetEnv = matchName;
          }
        }

        await service.addTransaction(
          amount: t.amount,
          type: t.amount < 0 ? TransactionType.debit : TransactionType.credit,
          label: t.label,
          date: t.date,
          realAccount: _selectedAccount!,
          targetVirtualAccount: targetEnv,
          note: "Imported from $_fileName",
        );
        count++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $count transactions.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transactions: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final realAccountsAsync = ref.watch(realAccountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Import Transactions')),
      body: Column(
        children: [
          // Header / Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: realAccountsAsync.when(
                        data: (accounts) =>
                            DropdownButtonFormField<RealAccount>(
                              decoration: const InputDecoration(
                                labelText: "Target Account",
                              ),
                              value: _selectedAccount,
                              items: accounts
                                  .map(
                                    (acc) => DropdownMenuItem(
                                      value: acc,
                                      child: Text(acc.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedAccount = val),
                            ),
                        loading: () => const LinearProgressIndicator(),
                        error: (e, s) => Text("Error loading accounts: $e"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_fileName ?? 'Select File'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_transactions.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _selectedAccount == null)
                          ? null
                          : _confirmImport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Text('Confirm Import (${_transactions.length})'),
                    ),
                  ),
              ],
            ),
          ),

          if (_isLoading) const LinearProgressIndicator(),

          // List / Table
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text('No transactions loaded.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Label')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(
                            label: Text('Envelope'),
                          ), // TODO: Make editable dropdown matching Account's envelopes
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _transactions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final t = entry.value;
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(DateFormat('dd/MM/yyyy').format(t.date)),
                              ),
                              DataCell(Text(t.label)),
                              DataCell(
                                Text(
                                  NumberFormat.currency(
                                    symbol: '€',
                                  ).format(t.amount),
                                  style: TextStyle(
                                    color: t.amount < 0
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  t.targetEnvelopeName ?? 'Default',
                                  style: TextStyle(
                                    color: t.targetEnvelopeName == null
                                        ? Colors.grey
                                        : Colors.black,
                                    fontStyle: t.targetEnvelopeName == null
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => _removeTransaction(index),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
