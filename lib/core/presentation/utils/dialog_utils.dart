import 'package:flutter/material.dart';

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
    return confirm == true;
  }
  return true;
}
