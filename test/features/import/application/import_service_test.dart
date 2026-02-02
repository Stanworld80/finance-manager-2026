import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:finance_manager_2026/features/import/application/import_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('csv_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('parseCsv reading from file (VM) works', () async {
    final container = ProviderContainer();
    final service = container.read(importServiceProvider.notifier);

    final csvFile = File(p.join(tempDir.path, 'data.csv'));
    await csvFile.writeAsString(
      'Date,Amount,Description\n2026-01-01,100.0,Test Transaction',
    );

    final platformFile = PlatformFile(
      name: 'data.csv',
      size: 100,
      path: csvFile.path,
    );

    final result = await service.parseCsv(platformFile);

    expect(result.length, 2); // Header + 1 row
    expect(result[0], ['Date', 'Amount', 'Description']);
    expect(result[1], ['2026-01-01', 100.0, 'Test Transaction']);
  });
}
