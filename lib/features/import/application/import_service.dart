import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:finance_manager_2026/features/transactions/data/transaction_repository.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:uuid/uuid.dart';
import '../domain/import_models.dart';

part 'import_service.g.dart';

@riverpod
class ImportService extends _$ImportService {
  @override
  void build() {
    return;
  }

  Future<int> saveTransactions({
    required List<Map<String, dynamic>> rawTransactions,
    required String realAccountId,
    required String targetVirtualAccountId,
    required String userId,
  }) async {
    final transactions = <TransactionModel>[];
    final uuid = const Uuid();

    for (final raw in rawTransactions) {
      final amount = (raw['amount'] as num).toDouble();
      final type = amount >= 0 ? TransactionType.credit : TransactionType.debit;
      final absAmount = amount.abs();

      // Determine splits
      // Credit: Real increases, Target Virtual increases
      // Debit: Real decreases, Target Virtual decreases

      final splits = <TransactionSplit>[];

      if (type == TransactionType.credit) {
        splits.add(
          TransactionSplit(
            virtualAccountId: targetVirtualAccountId,
            amount: absAmount,
          ),
        );
        splits.add(
          TransactionSplit(
            virtualAccountId: SystemAccounts.external,
            amount: -absAmount,
          ),
        );
      } else {
        splits.add(
          TransactionSplit(
            virtualAccountId: targetVirtualAccountId,
            amount: -absAmount,
          ),
        );
        splits.add(
          TransactionSplit(
            virtualAccountId: SystemAccounts.external,
            amount: absAmount,
          ),
        );
      }

      final tx = TransactionModel(
        id: uuid.v4(),
        ownerId: userId,
        realAccountId: realAccountId,
        amount: amount, // Real Account movement
        type: type,
        transactionDate: raw['date'] as DateTime,
        label: raw['description'] as String?,
        payee: raw['beneficiary'] as String?,
        category: null, // Auto-categorize later?
        status: TransactionStatus.none,
        step: TransactionStep.completed,
        splits: splits,
        importHash: raw['importHash'] as String?,
      );

      transactions.add(tx);
    }

    // Batch insert
    return ref
        .read(transactionRepositoryProvider)
        .addBatch(userId, transactions);
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

  /// Maps raw CSV rows to Transaction objects based on mapping
  Future<List<Map<String, dynamic>>> mapRows(
    List<List<dynamic>> rows,
    ImportMapping mapping,
  ) async {
    final transactions = <Map<String, dynamic>>[];

    // offset 1 to skip header? Usually header is row 0.
    // We assume rows include header if it exists.
    // The UI should tell us if there's a header. For now, assume row 0 is header.

    // We'll iterate from index 1.
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final tx = <String, dynamic>{};

      for (var colIndex = 0; colIndex < row.length; colIndex++) {
        final field = mapping.columnMapping[colIndex];
        if (field == null || field == TransactionField.skip) continue;

        final val = row[colIndex];

        switch (field) {
          case TransactionField.amount:
            // Clean string amount
            if (val is num) {
              tx['amount'] = val.toDouble();
            } else if (val is String) {
              // Parse "1,234.56" or "1 234,56"
              // This is tricky without more config.
              // Simplest: remove all except numbers, dot, comma, minus.
              // Assume standard dot decimal for now or allow locale config.
              var clean = val.replaceAll(RegExp(r'[^0-9.,-]'), '');
              clean = clean.replaceAll(',', '.'); // Quick fix for EU?
              // But if 1.000,00 then 1.000.00 -> error.
              // Let's assume dot format for Cycle 12 or use tryParse.
              tx['amount'] = double.tryParse(clean) ?? 0.0;
            }
            break;
          case TransactionField.description:
            tx['description'] = val.toString();
            break;
          case TransactionField.date:
            // Parse Date
            // Uses mapping.dateFormat
            if (val is String) {
              try {
                // Basic parsing. Ideally use intl DateFormat.
                // For Cycle 12, simple YYYY-MM-DD or DD/MM/YYYY support.
                if (mapping.dateFormat == 'dd/MM/yyyy') {
                  final parts = val.split('/');
                  if (parts.length == 3) {
                    // dd, MM, yyyy
                    final day = int.parse(parts[0]);
                    final month = int.parse(parts[1]);
                    final year = int.parse(parts[2]);
                    tx['date'] = DateTime(year, month, day);
                  }
                } else {
                  tx['date'] = DateTime.tryParse(val);
                }
              } catch (e) {
                // ignore or flag error
              }
            }
            break;
          case TransactionField.payee:
            tx['beneficiary'] = val.toString();
            break;
          default:
            break;
        }
      }

      if (tx.isNotEmpty) {
        // Default fields
        tx['date'] ??= DateTime.now();
        tx['amount'] ??= 0.0;
        tx['description'] ??= 'Imported Transaction';

        // Generate simple hash for dedup
        // Hash = Date + Amount + Description (slug)
        final dateStr = (tx['date'] as DateTime)
            .toIso8601String()
            .split('T')
            .first;
        final amtStr = (tx['amount'] as double).toStringAsFixed(2);
        final descSlug = (tx['description'] as String).toLowerCase().replaceAll(
          RegExp(r'\s+'),
          '',
        );

        tx['importHash'] = '${dateStr}_${amtStr}_$descSlug';

        transactions.add(tx);
      }
    }
    return transactions;
  }
}
