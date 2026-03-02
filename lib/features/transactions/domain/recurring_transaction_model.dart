import 'transaction_model.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

class RecurringTransaction {
  final String id;
  final String ownerId;

  // Recurrence Settings
  final RecurrenceFrequency frequency;
  final int interval; // e.g. every 2 months
  final DateTime startDate;
  final DateTime? endDate; // Optional end date
  final DateTime nextOccurrence; // Computed field, stored for query efficiency
  final DateTime? lastOccurrence; // Last time it generated a transaction

  // Transaction Template Data
  final String realAccountId;
  final double amount;
  final String label;
  final String? note;
  final TransactionType type;
  final String? externalEntityId;

  // Template for splits (to support complex recurrences)
  final List<TransactionSplit> splits;

  RecurringTransaction({
    required this.id,
    required this.ownerId,
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    required this.nextOccurrence,
    this.lastOccurrence,
    required this.realAccountId,
    required this.amount,
    required this.label,
    this.note,
    required this.type,
    this.splits = const [],
    this.externalEntityId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'frequency': frequency.name,
      'interval': interval,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'nextOccurrence': nextOccurrence.toIso8601String(),
      'lastOccurrence': lastOccurrence?.toIso8601String(),
      'realAccountId': realAccountId,
      'amount': amount,
      'label': label,
      'note': note,
      'type': type.name,
      'splits': splits.map((x) => x.toMap()).toList(),
      'externalEntityId': externalEntityId,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String,
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      interval: (map['interval'] as num?)?.toInt() ?? 1,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      nextOccurrence: DateTime.parse(map['nextOccurrence'] as String),
      lastOccurrence: map['lastOccurrence'] != null
          ? DateTime.parse(map['lastOccurrence'] as String)
          : null,
      realAccountId: map['realAccountId'] as String,
      amount: (map['amount'] as num).toDouble(),
      label: map['label'] as String,
      note: map['note'] as String?,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.debit,
      ),
      splits: List<TransactionSplit>.from(
        (map['splits'] as List<dynamic>? ?? []).map<TransactionSplit>(
          (x) => TransactionSplit.fromMap(x as Map<String, dynamic>),
        ),
      ),
      externalEntityId: map['externalEntityId'] as String?,
    );
  }

  /// Calculates the next occurrence based on a reference date.
  /// This logic handles simple frequency addition.
  DateTime calculateNextOccurrence(DateTime afterDate) {
    DateTime candidate = startDate;
    // Fast forward to afterDate
    while (candidate.isBefore(afterDate) ||
        candidate.isAtSameMomentAs(afterDate)) {
      switch (frequency) {
        case RecurrenceFrequency.daily:
          candidate = candidate.add(Duration(days: interval));
          break;
        case RecurrenceFrequency.weekly:
          candidate = candidate.add(Duration(days: 7 * interval));
          break;
        case RecurrenceFrequency.monthly:
          // Handle month overflow logic carefully if needed, but simple add is:
          // DateTime(year, month + interval, day)
          // Dart handles overflow (month 13 -> year + 1 month 1).
          // But careful with day 31 -> day 1/2/3 of skipped month.
          // Standard logic often snaps to last day of month if overflow.
          int newMonth = candidate.month + interval;
          int newYear = candidate.year + (newMonth - 1) ~/ 12;
          newMonth = (newMonth - 1) % 12 + 1;

          int newDay = candidate.day;
          final daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
          if (newDay > daysInNewMonth) newDay = daysInNewMonth;

          candidate = DateTime(
            newYear,
            newMonth,
            newDay,
            candidate.hour,
            candidate.minute,
          );
          break;
        case RecurrenceFrequency.yearly:
          candidate = DateTime(
            candidate.year + interval,
            candidate.month,
            candidate.day,
            candidate.hour,
            candidate.minute,
          );
          // Handle leap year Feb 29 -> Feb 28 or Mar 1? Dart handles it (usually Mar 1 or errors?)
          // DateTime(2025, 2, 29) -> March 1.
          break;
      }
    }
    return candidate;
  }
}
