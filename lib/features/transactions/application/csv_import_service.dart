import 'package:csv/csv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'csv_import_service.g.dart';

class ParsedTransaction {
  final DateTime date;
  final double amount;
  final String label;
  final String? note;

  ParsedTransaction({
    required this.date,
    required this.amount,
    required this.label,
    this.note,
  });
}

class CsvImportResult {
  final List<List<dynamic>> rows;
  final List<String> headers;
  final int dateColumnIndex;
  final int amountColumnIndex;
  final int labelColumnIndex;

  CsvImportResult({
    required this.rows,
    required this.headers,
    this.dateColumnIndex = -1,
    this.amountColumnIndex = -1,
    this.labelColumnIndex = -1,
  });
}

@riverpod
CsvImportService csvImportService(CsvImportServiceRef ref) {
  return CsvImportService();
}

class CsvImportService {
  String _detectDelimiter(String content) {
    int commaCount = ','.allMatches(content).length;
    int semicolonCount = ';'.allMatches(content).length;
    int tabCount = '\t'.allMatches(content).length;

    if (semicolonCount > commaCount && semicolonCount > tabCount) return ';';
    if (tabCount > commaCount && tabCount > semicolonCount) return '\t';
    return ','; // Default
  }

  List<List<dynamic>> parseCsv(String content) {
    final delimiter = _detectDelimiter(content);
    return CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
      shouldParseNumbers:
          false, // Parse everything as string first to handle different formats safely
    ).convert(content);
  }

  // Simple heuristic to guess columns
  CsvImportResult analyzeCsv(List<List<dynamic>> rawRows) {
    if (rawRows.isEmpty) return CsvImportResult(rows: [], headers: []);

    List<String> headers = rawRows.first.map((e) => e.toString()).toList();
    List<List<dynamic>> dataRows = rawRows.length > 1 ? rawRows.sublist(1) : [];

    int dateIdx = -1;
    int amountIdx = -1;
    int labelIdx = -1;

    // 1. Try to guess from Headers
    for (int i = 0; i < headers.length; i++) {
      String h = headers[i].toLowerCase();
      if (dateIdx == -1 && (h.contains('date') || h.contains('jour'))) {
        dateIdx = i;
      }
      if (amountIdx == -1 &&
          (h.contains('montant') ||
              h.contains('amount') ||
              h.contains('solde') ||
              h.contains('crédit') ||
              h.contains('débit'))) {
        // Note: Some banks separate Credit and Debit columns.
        // For MVP we look for a single signed Amount column or just "Montant".
        // "Solde" is usually Balance, not Transaction Amount.
        if (!h.contains('solde')) {
          amountIdx = i;
        }
      }
      if (labelIdx == -1 &&
          (h.contains('libell') ||
              h.contains('label') ||
              h.contains('description') ||
              h.contains('tiers'))) {
        labelIdx = i;
      }
    }

    return CsvImportResult(
      rows: dataRows,
      headers: headers,
      dateColumnIndex: dateIdx,
      amountColumnIndex: amountIdx,
      labelColumnIndex: labelIdx,
    );
  }

  // Extract candidate transactions based on mapping
  List<ParsedTransaction> extractTransactions(
    List<List<dynamic>> rows, {
    required int dateIdx,
    required int amountIdx,
    required int labelIdx,
    String dateFormat =
        'dd/MM/yyyy', // Simple default, realistically need more robust parsing
  }) {
    List<ParsedTransaction> transactions = [];

    for (var row in rows) {
      if (row.length <= dateIdx ||
          row.length <= amountIdx ||
          row.length <= labelIdx) {
        continue;
      }

      try {
        String dateStr = row[dateIdx].toString().trim();
        String amountStr = row[amountIdx].toString().trim();
        String labelStr = row[labelIdx].toString().trim();

        if (dateStr.isEmpty || amountStr.isEmpty) continue;

        // Parse Amount
        // Handle "1 234,56", "1.234,56", "-12.50"
        amountStr = amountStr.replaceAll(RegExp(r'\s+'), ''); // Remove spaces
        amountStr = amountStr.replaceAll(',', '.'); // Normalize decimal
        // Remove currency symbols if any?
        amountStr = amountStr.replaceAll('€', '').replaceAll('\$', '');

        double? amount = double.tryParse(amountStr);
        if (amount == null) continue;

        // Parse Date (Naive approach for mvp)
        DateTime? date;
        try {
          // Handle common formats manualy or use DateFormat (need intl package import in file)
          // Let's assume DD/MM/YYYY or YYYY-MM-DD
          if (dateStr.contains('/')) {
            var parts = dateStr.split('/');
            if (parts.length == 3) {
              // DD/MM/YYYY
              date = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          } else if (dateStr.contains('-')) {
            date = DateTime.parse(dateStr);
          }
        } catch (e) {
          // ignore date parse error
        }

        if (date != null) {
          transactions.add(
            ParsedTransaction(date: date, amount: amount, label: labelStr),
          );
        }
      } catch (e) {
        // Skip malformed row
      }
    }
    return transactions;
  }
}
