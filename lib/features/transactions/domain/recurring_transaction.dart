import 'package:uuid/uuid.dart';
import 'transaction_model.dart';

enum RecurringFrequency { daily, weekly, monthly, yearly }

class RecurringTransaction {
  final String id;
  final String ownerId;
  final String realAccountId;

  // Template Data
  final double amount;
  final String label;
  final String? category;
  final String? note;
  final String? payee;
  final TransactionType type;

  /// The specific budget account this template targets.
  /// For splits, this might be null and use the 'splits' list instead.
  final String? targetVirtualAccountId;

  /// Detailed splits for ventilation templates.
  final List<TransactionSplit> splits;

  // Scheduling
  final RecurringFrequency frequency;
  final int interval; // e.g., every 2 (interval) months (frequency)
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastGeneratedDate;
  final DateTime nextDueDate;

  // Metadata
  final DateTime createdAt;
  final bool isActive;

  RecurringTransaction({
    required this.id,
    required this.ownerId,
    required this.realAccountId,
    required this.amount,
    required this.label,
    this.category,
    this.note,
    this.payee,
    required this.type,
    this.targetVirtualAccountId,
    this.splits = const [],
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    this.lastGeneratedDate,
    required this.nextDueDate,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'realAccountId': realAccountId,
      'amount': amount,
      'label': label,
      'category': category,
      'note': note,
      'payee': payee,
      'type': type.name,
      'targetVirtualAccountId': targetVirtualAccountId,
      'splits': splits.map((x) => x.toMap()).toList(),
      'frequency': frequency.name,
      'interval': interval,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String,
      realAccountId: map['realAccountId'] as String,
      amount: (map['amount'] as num).toDouble(),
      label: map['label'] as String,
      category: map['category'] as String?,
      note: map['note'] as String?,
      payee: map['payee'] as String?,
      type: TransactionType.values.firstWhere((e) => e.name == map['type']),
      targetVirtualAccountId: map['targetVirtualAccountId'] as String?,
      splits: List<TransactionSplit>.from(
        (map['splits'] as List<dynamic>? ?? []).map<TransactionSplit>(
          (x) => TransactionSplit.fromMap(x as Map<String, dynamic>),
        ),
      ),
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
      ),
      interval: map['interval'] as int? ?? 1,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      lastGeneratedDate: map['lastGeneratedDate'] != null
          ? DateTime.parse(map['lastGeneratedDate'] as String)
          : null,
      nextDueDate: DateTime.parse(map['nextDueDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  /// Creates a Planned transaction from this template.
  TransactionModel toPlannedTransaction(DateTime date) {
    final uuid = const Uuid();

    // If we have detailed splits, use them.
    // Otherwise, create the standard internal/external split.
    List<TransactionSplit> finalSplits;
    if (splits.isNotEmpty) {
      finalSplits = splits
          .map(
            (s) => TransactionSplit(
              virtualAccountId: s.virtualAccountId,
              amount: s.amount,
            ),
          )
          .toList();

      // Ensure it has an external pole if it's a Debit/Credit
      final double totalSum = finalSplits.fold(0.0, (p, s) => p + s.amount);
      if (totalSum.abs() > 0.001) {
        finalSplits.add(
          TransactionSplit(
            virtualAccountId: SystemAccounts.external,
            amount: -totalSum,
          ),
        );
      }
    } else {
      // Simple split based on targetVirtualAccountId
      finalSplits = [
        TransactionSplit(
          virtualAccountId: targetVirtualAccountId!,
          amount: amount,
        ),
        TransactionSplit(
          virtualAccountId: SystemAccounts.external,
          amount: -amount,
        ),
      ];
    }

    return TransactionModel(
      id: uuid.v4(),
      ownerId: ownerId,
      realAccountId: realAccountId,
      amount: amount,
      label: label,
      category: category,
      note: note,
      payee: payee,
      type: type,
      status: TransactionStatus.none,
      step: TransactionStep.planned, // Crucial: This is a planned entry
      transactionDate: date,
      splits: finalSplits,
    );
  }
}
