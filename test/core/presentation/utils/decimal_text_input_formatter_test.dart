import 'package:finance_manager_2026/core/presentation/utils/decimal_text_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DecimalTextInputFormatter', () {
    final formatter = DecimalTextInputFormatter();

    test('replaces comma with dot', () {
      const oldValue = TextEditingValue(text: '1');
      const newValue = TextEditingValue(text: '1,');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '1.');
    });

    test('removes spaces', () {
      const oldValue = TextEditingValue(text: '1');
      const newValue = TextEditingValue(text: '1 000');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '1000');
    });

    test('ignores non-numeric characters', () {
      const oldValue = TextEditingValue(text: '1');
      const newValue = TextEditingValue(text: '1a2b');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '12');
    });

    test('prevents multiple dots', () {
      const oldValue = TextEditingValue(text: '1.');
      const newValue = TextEditingValue(text: '1.2.');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '1.2');
    });

    test('limits decimal places', () {
      const oldValue = TextEditingValue(text: '1.2');
      const newValue = TextEditingValue(text: '1.234');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '1.23');
    });

    test('handles complex french input', () {
      // User types "1 234,56"
      // Step by step simulation not needed for unit test of final state if passed directly,
      // but strictly formatEditUpdate looks at transition.

      // Simulation of pasting "1 234,56"
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(text: '1 234,56');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '1234.56');
    });
  });
}
