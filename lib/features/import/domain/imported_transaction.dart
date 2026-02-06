enum ImportStatus { ready, duplicate, error }

class ImportedTransaction {
  final DateTime date;
  final String label;
  final double amount;
  final String? originalRaw;

  // Mutable state for the review process
  String? targetEnvelopeId;
  String? targetEnvelopeName; // For UI display if needed
  ImportStatus status;
  bool selected;

  ImportedTransaction({
    required this.date,
    required this.label,
    required this.amount,
    this.originalRaw,
    this.targetEnvelopeId,
    this.targetEnvelopeName,
    this.status = ImportStatus.ready,
    this.selected = true,
  });

  ImportedTransaction copyWith({
    DateTime? date,
    String? label,
    double? amount,
    String? originalRaw,
    String? targetEnvelopeId,
    String? targetEnvelopeName,
    ImportStatus? status,
    bool? selected,
  }) {
    return ImportedTransaction(
      date: date ?? this.date,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      originalRaw: originalRaw ?? this.originalRaw,
      targetEnvelopeId: targetEnvelopeId ?? this.targetEnvelopeId,
      targetEnvelopeName: targetEnvelopeName ?? this.targetEnvelopeName,
      status: status ?? this.status,
      selected: selected ?? this.selected,
    );
  }
}
