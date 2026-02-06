import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:finance_manager_2026/features/import/data/bank_import_service.dart';
import 'package:finance_manager_2026/features/import/domain/imported_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error importing file: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeTransaction(int index) {
    setState(() {
      _transactions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Transactions')),
      body: Column(
        children: [
          // Header / Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_fileName ?? 'Select Excel File'),
                ),
                const Spacer(),
                if (_transactions.isNotEmpty)
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Commit to DB
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Importing ${_transactions.length} transactions... (Not Implemented Yet)',
                          ),
                        ),
                      );
                    },
                    child: const Text('Confirm Import'),
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
                          ), // TODO: Make editable
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
                                  t.targetEnvelopeName ?? 'Unassigned',
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
