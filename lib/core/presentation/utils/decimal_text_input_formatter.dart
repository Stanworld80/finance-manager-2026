import 'package:flutter/services.dart';

/// A [TextInputFormatter] that handles flexible number inputs.
///
/// It performs the following operations:
/// 1. Replaces commas (',') with dots ('.') to normalize decimal separators.
/// 2. Removes spaces to handle formats like "1 000".
/// 3. Sanitizes input to remove any non-digit characters (except the decimal point).
/// 4. Ensures only one decimal point exists.
/// 5. Restricts the number of decimal places to [decimalRange] (default is 2).
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalTextInputFormatter({this.decimalRange = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;

    // 1. Replace commas with dots
    newText = newText.replaceAll(',', '.');

    // 2. Remove spaces (allow flexible spacing like "1 000")
    newText = newText.replaceAll(' ', '');

    // 3. Sanitize: Remove any character that is not a digit or a dot
    newText = newText.replaceAll(RegExp(r'[^0-9.]'), '');

    // 4. Prevent multiple dots
    int dotCount = '.'.allMatches(newText).length;
    if (dotCount > 1) {
      // If adding a second dot, ignore the new input if it caused the second dot
      // This is a simplistic approach; a better one attempts to keep the first dot.
      // But typically, just stripping extra dots or reverting is safer.
      // Let's try to keep the first dot and remove subsequent ones.
      int firstDotIndex = newText.indexOf('.');
      String before = newText.substring(0, firstDotIndex + 1);
      String after = newText.substring(firstDotIndex + 1).replaceAll('.', '');
      newText = before + after;
    }

    // 5. Restrict decimal places
    if (newText.contains('.')) {
      int dotIndex = newText.indexOf('.');
      if (dotIndex + 1 + decimalRange < newText.length) {
        newText = newText.substring(0, dotIndex + 1 + decimalRange);
      }
    }

    // Calculate new cursor position
    // This is tricky because we modified the text length (removed spaces, etc).
    // A simple robust strategy for non-complex inputs: position at end if generic,
    // or try to maintain relative position.
    // For now, let's try to preserve relative cursor position closer to the end if we added chars,
    // or correct if we removed chars.

    // Simplest usable behavior:
    // If text didn't change (only format), try to keep cursor.
    // However, since we might replace ',' with '.' or remove spaces, the index map changes.

    // Let's return the simplified text with the cursor at the end for consistency,
    // OR try to map proper offset.
    // Standard approach: allow user to type, we sanitize.

    final selectionIndex = newText.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
