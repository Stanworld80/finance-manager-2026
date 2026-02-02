import 'package:file_picker/file_picker.dart';
import 'package:finance_manager_2026/features/import/application/import_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  List<List<dynamic>>? _csvData;
  bool _isLoading = false;
  String? _fileName;

  Future<void> _pickFile() async {
    try {
      setState(() => _isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true, // Needed for Web
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Transactions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _fileName ?? 'No file selected',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select CSV'),
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          if (_csvData != null)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: _csvData!.first
                        .map((e) => DataColumn(label: Text(e.toString())))
                        .toList(),
                    rows: _csvData!
                        .skip(1)
                        .take(50) // Show first 50 rows preview
                        .map(
                          (row) => DataRow(
                            cells: row
                                .map((e) => DataCell(Text(e.toString())))
                                .toList(),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
