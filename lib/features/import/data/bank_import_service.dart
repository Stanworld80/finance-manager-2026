import 'dart:io';
import 'package:excel/excel.dart';
import 'package:finance_manager_2026/features/import/domain/imported_transaction.dart';
import 'package:intl/intl.dart';

class BankImportService {
  Future<List<ImportedTransaction>> parseExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final List<ImportedTransaction> transactions = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      // Detect header row logic could be more complex,
      // for now assume specific CA format or try to find "Date" "Libellé" etc.
      int? dateColIdx;
      int? labelColIdx;
      int? debitColIdx;
      int? creditColIdx;
      int headerRowIdx = -1;

      // Simple heuristic to find header row
      for (int r = 0; r < sheet.maxRows; r++) {
        final row = sheet.rows[r];
        for (int c = 0; c < row.length; c++) {
          final val = row[c]?.value?.toString().toLowerCase() ?? '';
          if (val.contains("date")) dateColIdx = c;
          if (val.contains("libellé") ||
              val.contains("opération") ||
              val.contains("libelle")) {
            labelColIdx = c;
          }
          if (val.contains("débit") || val.contains("debit")) debitColIdx = c;
          if (val.contains("crédit") || val.contains("credit")) {
            creditColIdx = c;
          }
        }

        if (dateColIdx != null && labelColIdx != null) {
          headerRowIdx = r;
          break;
        }
      }

      if (headerRowIdx == -1) {
        // Fallback or specific hardcoded structure for CA if detection fails?
        // Let's log or return empty/error?
        // For MVP, if we can't find headers, we might fail.
        // But maybe the file provided has specific col indices?
        continue;
      }

      // Process rows after header
      for (int r = headerRowIdx + 1; r < sheet.maxRows; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        // Extract raw values
        final dateCell = row.elementAtOrNull(dateColIdx!)?.value;
        final labelCell = row.elementAtOrNull(labelColIdx!)?.value;

        if (dateCell == null || labelCell == null) continue;

        DateTime? parsedDate;
        // Handle various date formats from Excel
        if (dateCell is DateCellValue) {
          parsedDate = DateTime(dateCell.year, dateCell.month, dateCell.day);
        } else if (dateCell is TextCellValue) {
          try {
            // Common french formats
            parsedDate = DateFormat(
              "dd/MM/yyyy",
            ).parse(dateCell.value.toString());
          } catch (e) {
            // ignore
          }
        }

        if (parsedDate == null) continue;

        double amount = 0;

        // Handle Amount (Debit / Credit columns)
        if (debitColIdx != null && creditColIdx != null) {
          final debitVal = _parseAmount(
            row.elementAtOrNull(debitColIdx)?.value,
          );
          final creditVal = _parseAmount(
            row.elementAtOrNull(creditColIdx)?.value,
          );

          // Debit is negative, Credit is positive
          // CA export typically: Debits are positive numbers in "Debit" col? Or negative?
          // Usually Debit column has value, Credit is empty.
          if (debitVal != 0) {
            amount = -debitVal.abs(); // Ensure negative
          } else if (creditVal != 0) {
            amount = creditVal.abs(); // Ensure positive
          }
        } else {
          // Maybe single "Montant" column? Not handled yet.
        }

        final String labelStr = labelCell is TextCellValue
            ? labelCell.value.toString()
            : labelCell.toString();

        if (amount == 0 && labelStr.isEmpty) continue; // Skip empty rows

        transactions.add(
          ImportedTransaction(
            date: parsedDate,
            label: labelStr,
            amount: amount,
            originalRaw: row.map((e) => e?.value).join("|"),
          ),
        );
      }
    }

    return transactions;
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is DoubleCellValue) return value.value;
    if (value is IntCellValue) return value.value.toDouble();
    if (value is TextCellValue) {
      final cleaned = value.value
          .toString()
          .replaceAll(RegExp(r'[^0-9.,-]'), '')
          .replaceAll(',', '.');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  List<ImportedTransaction> guessEnvelopes(
    List<ImportedTransaction> transactions,
  ) {
    // TODO: Implement simple keyword mapping
    // For now just return as is
    return transactions.map((t) {
      // Simple example logic
      if (t.label.toUpperCase().contains("EDF")) {
        return t.copyWith(
          targetEnvelopeName: "Electricité",
          targetEnvelopeId: "dummy_id_edf",
        );
      }
      if (t.label.toUpperCase().contains("CARREFOUR")) {
        return t.copyWith(
          targetEnvelopeName: "Alimentation",
          targetEnvelopeId: "dummy_id_food",
        );
      }
      return t;
    }).toList();
  }
}

extension ListExtensions<E> on List<E> {
  E? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
