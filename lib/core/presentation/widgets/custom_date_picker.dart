import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastUsedDateTracker {
  static const String _prefKey = 'last_used_datepicker_date';
  static DateTime? _inMemoryCache;

  static Future<DateTime?> getLastUsedDate() async {
    if (_inMemoryCache != null) {
      return _inMemoryCache;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final isoString = prefs.getString(_prefKey);
      if (isoString != null) {
        _inMemoryCache = DateTime.parse(isoString);
        return _inMemoryCache;
      }
    } catch (e) {
      debugPrint('Error reading last used date: $e');
    }
    return null;
  }

  static Future<void> saveLastUsedDate(DateTime date) async {
    _inMemoryCache = date;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, date.toIso8601String());
    } catch (e) {
      debugPrint('Error saving last used date: $e');
    }
  }
}

class CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? helpText;
  final String? cancelText;
  final String? confirmText;

  const CustomDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.helpText,
    this.cancelText,
    this.confirmText,
  });

  @override
  State<CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog> {
  late DateTime _selectedDate;
  DateTime? _lastUsedDate;
  bool _isLoadingLastUsed = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _loadLastUsedDate();
  }

  Future<void> _loadLastUsedDate() async {
    final date = await LastUsedDateTracker.getLastUsedDate();
    if (mounted) {
      setState(() {
        _lastUsedDate = date;
        _isLoadingLastUsed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    
    final headerDateText = DateFormat('EEE d MMM', locale.toString()).format(_selectedDate);
    final headerYearText = DateFormat('yyyy', locale.toString()).format(_selectedDate);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28.0),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      child: Container(
        width: 328,
        color: theme.colorScheme.surface,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Beautiful Header (Material style)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                color: theme.colorScheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.helpText ?? "SÉLECTIONNER LA DATE",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      headerYearText,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      headerDateText,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Calendar picker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: SizedBox(
                  height: 300,
                  child: CalendarDatePicker(
                    key: ValueKey(_selectedDate),
                    initialDate: _selectedDate,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Last used date button on the bottom left
                    if (!_isLoadingLastUsed && _lastUsedDate != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          // Make sure last used date is within firstDate and lastDate range
                          DateTime targetDate = _lastUsedDate!;
                          if (targetDate.isBefore(widget.firstDate)) {
                            targetDate = widget.firstDate;
                          } else if (targetDate.isAfter(widget.lastDate)) {
                            targetDate = widget.lastDate;
                          }
                          setState(() {
                            _selectedDate = targetDate;
                          });
                        },
                        icon: const Icon(Icons.history, size: 16),
                        label: Text(
                          DateFormat('dd/MM/yyyy').format(_lastUsedDate!),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    
                    // Cancel & OK buttons on the right
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: Text(widget.cancelText ?? "Annuler"),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            LastUsedDateTracker.saveLastUsedDate(_selectedDate);
                            Navigator.pop(context, _selectedDate);
                          },
                          child: Text(widget.confirmText ?? "OK"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
}) async {
  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return CustomDatePickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: helpText,
        cancelText: cancelText,
        confirmText: confirmText,
      );
    },
  );
}
