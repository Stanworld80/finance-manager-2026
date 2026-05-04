// ignore_for_file: avoid_print
import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  var file = "d:\\development\\FinanceManager2026\\CA20260206_064918.xlsx";
  var bytes = File(file).readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);

  for (var table in excel.tables.keys) {
    print("Table: $table");
    // print("maxCols: ${excel.tables[table]?.maxColumns}");
    // print("maxRows: ${excel.tables[table]?.maxRows}");
    for (var row in excel.tables[table]!.rows.take(5)) {
      print(row.map((e) {
        if (e == null) return "null";
        final val = e.value; // CellValue?
        // inspect properties using reflection or toString
        return "RuntimeType: ${e.runtimeType}, ValueType: ${val.runtimeType}, Value: $val";
      }).toList());
    }
  }
}
