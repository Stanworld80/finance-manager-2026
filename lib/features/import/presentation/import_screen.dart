import 'package:file_picker/file_picker.dart';
import 'package:finance_manager_2026/features/accounts/data/account_repository.dart';
import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';
import 'package:finance_manager_2026/core/providers.dart';
import 'package:finance_manager_2026/features/import/application/import_service.dart';
import 'package:finance_manager_2026/features/import/domain/import_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  List<List<dynamic>>? _csvData;
  List<Map<String, dynamic>>? _parsedTransactions;
  bool _isLoading = false;
  String? _fileName;
  final Map<int, TransactionField> _columnMapping = {};
  String _dateFormat = 'yyyy-MM-dd';
  String? _selectedRealAccountId;

  Future<void> _pickFile() async {
    try {
      setState(() => _isLoading = true);
      _columnMapping.clear();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        final data = await ref
            .read(importServiceProvider.notifier)
            .parseCsv(file);

        setState(() {
          _csvData = data;
          _fileName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing file: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateMapping(int index, TransactionField? field) {
    setState(() {
      if (field == null || field == TransactionField.skip) {
        _columnMapping.remove(index);
      } else {
        _columnMapping[index] = field;
      }
    });
  }

  void _processImport() async {
    if (_csvData == null || _columnMapping.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please map at least one column')),
      );
      return;
    }

    if (_selectedRealAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target account')),
      );
      return;
    }

    final mapping = ImportMapping(
      columnMapping: _columnMapping,
      dateFormat: _dateFormat,
    );

    setState(() => _isLoading = true);

    try {
      final transactions = await ref
          .read(importServiceProvider.notifier)
          .mapRows(_csvData!, mapping);

      setState(() {
        _parsedTransactions = transactions;
        _isLoading = false;
      });

      if (mounted) {
        _showConfirmDialog(transactions.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing: $e')));
      }
    }
  }

  void _showConfirmDialog(int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Import'),
        content: Text('Ready to import $count transactions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveToDatabase();
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToDatabase() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null ||
        _selectedRealAccountId == null ||
        _parsedTransactions == null)
      return;

    setState(() => _isLoading = true);

    try {
      final virtuals = await ref
          .read(accountRepositoryProvider)
          .watchVirtualAccounts(user.uid, _selectedRealAccountId!)
          .first;
      final defaultVirtual = virtuals.firstWhere(
        (v) => v.type == VirtualAccountType.systemFree,
        orElse: () => throw Exception('No default virtual account found'),
      );

      final count = await ref
          .read(importServiceProvider.notifier)
          .saveTransactions(
            rawTransactions: _parsedTransactions!,
            realAccountId: _selectedRealAccountId!,
            targetVirtualAccountId: defaultVirtual.id,
            userId: user.uid,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $count transactions!')),
        );
        setState(() {
          _csvData = null;
          _parsedTransactions = null;
          _columnMapping.clear();
          _fileName = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Transactions'),
        actions: [
          if (_csvData != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _processImport,
              tooltip: 'Process Import',
            ),
        ],
      ),
      body: Column(
        children: [
          _FileSelector(
            fileName: _fileName,
            isLoading: _isLoading,
            onPick: _pickFile,
          ),

          AccountSelector(
            selectedAccountId: _selectedRealAccountId,
            onChanged: (val) => setState(() => _selectedRealAccountId = val),
          ),

          if (_isLoading) const LinearProgressIndicator(),

          if (_csvData != null) ...[
            _DateFormatSelector(
              currentFormat: _dateFormat,
              onChanged: (v) => setState(() => _dateFormat = v!),
            ),
            Expanded(
              child: MappingTable(
                csvData: _csvData!,
                columnMapping: _columnMapping,
                onUpdateMapping: _updateMapping,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FileSelector extends StatelessWidget {
  final String? fileName;
  final bool isLoading;
  final VoidCallback onPick;

  const _FileSelector({
    required this.fileName,
    required this.isLoading,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fileName ?? 'No file selected',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          ElevatedButton.icon(
            onPressed: isLoading ? null : onPick,
            icon: const Icon(Icons.upload_file),
            label: const Text('Select CSV'),
          ),
        ],
      ),
    );
  }
}

class AccountSelector extends ConsumerWidget {
  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;

  const AccountSelector({
    super.key,
    required this.selectedAccountId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StreamBuilder<List<RealAccount>>(
        stream: ref
            .watch(accountRepositoryProvider)
            .watchRealAccounts(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final accounts = snapshot.data!;

          return DropdownButtonFormField<String>(
            value: selectedAccountId,
            decoration: const InputDecoration(labelText: 'Target Account'),
            items: accounts.map((acc) {
              return DropdownMenuItem(value: acc.id, child: Text(acc.name));
            }).toList(),
            onChanged: onChanged,
          );
        },
      ),
    );
  }
}

class _DateFormatSelector extends StatelessWidget {
  final String currentFormat;
  final ValueChanged<String?> onChanged;

  const _DateFormatSelector({
    required this.currentFormat,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Date Format: '),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: currentFormat,
            items: const [
              DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('YYYY-MM-DD')),
              DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('DD/MM/YYYY')),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class MappingTable extends StatelessWidget {
  final List<List<dynamic>> csvData;
  final Map<int, TransactionField> columnMapping;
  final Function(int, TransactionField?) onUpdateMapping;

  const MappingTable({
    super.key,
    required this.csvData,
    required this.columnMapping,
    required this.onUpdateMapping,
  });

  @override
  Widget build(BuildContext context) {
    if (csvData.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: List.generate(csvData.first.length, (index) {
            final header = csvData.first[index].toString();
            return DataColumn(
              label: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<TransactionField>(
                    value: columnMapping[index] ?? TransactionField.skip,
                    items: TransactionField.values.map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Text(f.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) => onUpdateMapping(index, val),
                  ),
                  Text(
                    header,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
          rows: csvData
              .skip(1)
              .take(50)
              .map(
                (row) => DataRow(
                  cells: row.map((e) => DataCell(Text(e.toString()))).toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
