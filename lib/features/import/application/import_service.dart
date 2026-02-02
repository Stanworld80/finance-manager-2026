import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'import_service.g.dart';

@riverpod
class ImportService extends _$ImportService {
  @override
  void build() {
    return;
  }

  Future<List<List<dynamic>>> parseCsv(PlatformFile file) async {
    String csvContent;

    if (kIsWeb) {
      if (file.bytes == null) throw Exception('No bytes found in web file');
      csvContent = utf8.decode(file.bytes!);
    } else {
      if (file.path == null) throw Exception('No path found in file');
      final input = File(file.path!);
      csvContent = await input.readAsString();
    }

    // Detect delimiter (simple check, default to comma)
    final delimiter = csvContent.contains(';') ? ';' : ',';

    final List<List<dynamic>> rows = const CsvToListConverter().convert(
      csvContent,
      fieldDelimiter: delimiter,
      eol: '\n', // Handle mixed EOL? CsvToList usually handles it.
    );

    return rows;
  }
}
