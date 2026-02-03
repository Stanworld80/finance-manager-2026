import 'package:finance_manager_2026/features/import/application/import_service.dart';
import 'package:finance_manager_2026/features/import/domain/import_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapRows correctly maps columns to transaction fields', () async {
    final container = ProviderContainer();
    final service = container.read(importServiceProvider.notifier);

    final rows = [
      ['Date', 'Desc', 'Amt'], // Header
      ['2026-01-01', 'Groceries', '100.50'],
      ['2026-01-02', 'Salary', '5000.0'],
    ];

    final mapping = ImportMapping(
      columnMapping: {
        0: TransactionField.date,
        1: TransactionField.description,
        2: TransactionField.amount,
      },
      dateFormat: 'yyyy-MM-dd',
    );

    final result = await service.mapRows(rows, mapping);

    expect(result.length, 2);
    expect(result[0]['description'], 'Groceries');
    expect(result[0]['amount'], 100.50);
    expect(result[0]['date'], DateTime(2026, 1, 1));
    expect(result[1]['amount'], 5000.0);
  });

  test('mapRows handles French date format dd/MM/yyyy', () async {
    final container = ProviderContainer();
    final service = container.read(importServiceProvider.notifier);

    final rows = [
      ['Date', 'Desc'],
      ['31/12/2026', 'Party'],
    ];

    final mapping = ImportMapping(
      columnMapping: {
        0: TransactionField.date,
        1: TransactionField.description,
      },
      dateFormat: 'dd/MM/yyyy',
    );

    final result = await service.mapRows(rows, mapping);

    expect(result.length, 1);
    expect(result[0]['date'], DateTime(2026, 12, 31));
  });
}
