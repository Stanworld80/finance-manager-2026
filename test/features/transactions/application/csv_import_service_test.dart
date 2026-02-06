import 'package:flutter_test/flutter_test.dart';
import 'package:finance_manager_2026/features/transactions/application/csv_import_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  late CsvImportService service;

  setUp(() {
    final container = ProviderContainer();
    service = container.read(csvImportServiceProvider);
  });

  group('CsvImportService', () {
    test('detects semicolon delimiter', () {
      const content = "Date;Montant;Libellé\n01/01/2026;-50,00;Courses";
      // We can't access private _detectDelimiter but parseCsv uses it.
      final rows = service.parseCsv(content);
      expect(rows.length, 2);
      expect(rows[0].length, 3);
    });

    test('detects comma delimiter', () {
      const content = "Date,Montant,Libellé\n01/01/2026,-50.00,Courses";
      final rows = service.parseCsv(content);
      expect(rows.length, 2);
      expect(rows[0].length, 3);
    });

    test('analyzeCsv finds headers correctly', () {
      final rows = [
        ["Date", "Libellé", "Montant", "Inutile"],
        ["01/01/2026", "Courses", "-50,00", "X"],
      ];
      final result = service.analyzeCsv(rows);

      expect(result.dateColumnIndex, 0);
      expect(result.labelColumnIndex, 1);
      expect(result.amountColumnIndex, 2);
    });

    test('extractTransactions parses French format correctly', () {
      final rows = [
        ["Date", "Libellé", "Montant"],
        ["03/02/2026", "Carrefour", "-1 234,56"], // Spaces and comma
        ["04/02/2026", "Salaire", "2500,00"],
      ];

      // Indices: Date=0, Label=1, Amount=2
      final txs = service.extractTransactions(
        rows,
        dateIdx: 0,
        amountIdx: 2,
        labelIdx: 1,
      );

      expect(txs.length, 2);

      expect(txs[0].amount, -1234.56);
      expect(txs[0].label, "Carrefour");
      expect(txs[0].date, DateTime(2026, 2, 3));

      expect(txs[1].amount, 2500.00);
      expect(txs[1].label, "Salaire");
    });

    test('extractTransactions handles YYYY-MM-DD format', () {
      final rows = [
        ["Date", "Label", "Amount"],
        ["2026-03-15", "Internet", "-29.99"],
      ];
      final txs = service.extractTransactions(
        rows,
        dateIdx: 0,
        amountIdx: 2,
        labelIdx: 1,
      );

      expect(txs.length, 1);
      expect(txs[0].date, DateTime(2026, 3, 15));
      expect(txs[0].amount, -29.99);
    });
  });
}
