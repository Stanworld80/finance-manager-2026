import 'package:flutter/material.dart';

/// In-memory state tracking to prevent repetitive today-date alerts
class DateWarningSessionState {
  static bool hasWarnedForToday = false;

  /// Checks if the warning dialog should be shown for the selected date.
  static bool shouldWarn(DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (target.isAtSameMomentAs(today)) {
      return !hasWarnedForToday;
    }
    return false;
  }

  /// Registers a date selection to update the today warning state.
  static void registerDateSelection(DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (target.isAtSameMomentAs(today)) {
      hasWarnedForToday = true;
    } else {
      // Reset if user selects a different date
      hasWarnedForToday = false;
    }
  }
}

/// Shows a confirmation dialog if the selected date is today.
/// Returns true if confirmed or if the date is not today.
Future<bool> showDateConfirmationDialog({
  required BuildContext context,
  required DateTime selectedDate,
  String title = "Confirmer la date",
  String message = "La date de la transaction est fixée à AUJOURD'HUI. Est-ce correct ?",
  String confirmLabel = "Confirmer",
  String cancelLabel = "Changer la date",
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final transactionDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

  if (transactionDate.isAtSameMomentAs(today)) {
    if (!DateWarningSessionState.shouldWarn(selectedDate)) {
      return true; // Already confirmed today's date in this session
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirm == true) {
      DateWarningSessionState.registerDateSelection(selectedDate);
      return true;
    }
    return false;
  }
  return true;
}
