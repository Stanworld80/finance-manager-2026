import 'package:flutter_test/flutter_test.dart';
import 'package:finance_manager_2026/core/build_info.dart';
import 'package:finance_manager_2026/features/legal/presentation/legal_screen.dart';

void main() {
  group('BuildInfo Unit Tests', () {
    test('formatVersion uses provided version, buildNumber and date', () {
      final formatted = BuildInfo.formatVersion(
        packageVersion: '1.1.4',
        packageBuildNumber: '458',
        buildDateOverride: '15/10/2026 14:54',
      );
      expect(formatted, 'v1.1.4#458 (15/10/2026 14:54)');
    });

    test('formatVersion falls back to defaults when parameters are null', () {
      final formatted = BuildInfo.formatVersion();
      expect(formatted, contains('v1.0.9#'));
      expect(formatted, contains('('));
    });

    test('copyrightHolder is Stanislas Selle Informatique', () {
      expect(BuildInfo.copyrightHolder, 'Stanislas Selle Informatique');
    });

    test('LegalScreen.indexFromSection maps sections to tab indices', () {
      expect(LegalScreen.indexFromSection('accessibility'), 0);
      expect(LegalScreen.indexFromSection('mentions'), 1);
      expect(LegalScreen.indexFromSection('privacy'), 2);
      expect(LegalScreen.indexFromSection('cgu'), 3);
      expect(LegalScreen.indexFromSection('unknown'), 1);
    });
  });
}

