enum TransactionType {
  debit, // Outgoing to External
  credit, // Incoming from External
  provision, // Internal: Budget -> Committed
  transfer, // Internal: Envelope A -> Envelope B
}

enum TransactionStatus {
  toProvision, // Debt exists, but not yet covered
  provisioned, // Covered in "Committed"
  toDistribute, // Income arrived, needs allocation
  toTransfer, // Internal move pending
  transferred, // Internal move done
  toCorrect, // Reconciliation issue
  corrected, // Resolved
  none, // Default/Not applicable
}

enum TransactionStep {
  planned, // Recurring or future
  toSchedule, // Action needed
  scheduled, // Bank order sent
  pending, // Visible on bank but transient
  completed, // Finalized
}

class TransactionSplit {
  final String virtualAccountId;
  final double amount; // Negative for debit, Positive for credit

  TransactionSplit({required this.virtualAccountId, required this.amount});

  Map<String, dynamic> toMap() {
    return {'virtualAccountId': virtualAccountId, 'amount': amount};
  }

  factory TransactionSplit.fromMap(Map<String, dynamic> map) {
    return TransactionSplit(
      virtualAccountId: map['virtualAccountId'] as String,
      amount: (map['amount'] as num).toDouble(),
    );
  }
}

class TransactionModel {
  final String id;
  final String ownerId;
  final String realAccountId;

  // Basic Info
  final double amount;
  final String? label;
  final String? note;
  final String? payee;
  final String? category;

  // Classification
  final TransactionType type;
  final TransactionStatus status;
  final TransactionStep step;

  // External Party (optional, for debit/credit)
  final String? externalEntityId;

  // Dates
  final DateTime transactionDate; // Operation Date
  final DateTime? valueDate; // Interest/Bank Date
  final DateTime? visibilityDate; // Saw on web
  final DateTime? syncDate; // Reconciled
  final DateTime? provisionDate; // Budget impact date

  // Internal Accounting
  final List<TransactionSplit> splits;

  TransactionModel({
    required this.id,
    required this.ownerId,
    required this.realAccountId,
    required this.amount,
    this.label,
    this.note,
    this.payee,
    this.category,
    required this.type,
    this.status = TransactionStatus.none,
    this.step = TransactionStep.completed,
    this.externalEntityId,
    required this.transactionDate,
    this.valueDate,
    this.visibilityDate,
    this.syncDate,
    this.provisionDate,
    this.splits = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'realAccountId': realAccountId,
      'amount': amount,
      'label': label,
      'note': note,
      'payee': payee,
      'category': category,
      'type': type.name,
      'status': status.name,
      'step': step.name,
      'externalEntityId': externalEntityId,
      'transactionDate': transactionDate.toIso8601String(),
      'valueDate': valueDate?.toIso8601String(),
      'visibilityDate': visibilityDate?.toIso8601String(),
      'syncDate': syncDate?.toIso8601String(),
      'provisionDate': provisionDate?.toIso8601String(),
      'splits': splits.map((x) => x.toMap()).toList(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String,
      realAccountId: map['realAccountId'] as String,
      amount: (map['amount'] as num).toDouble(),
      label: map['label'] as String?,
      note: map['note'] as String?,
      payee: map['payee'] as String?,
      category: map['category'] as String?,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.debit,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.none,
      ),
      step: TransactionStep.values.firstWhere(
        (e) => e.name == map['step'],
        orElse: () => TransactionStep.completed,
      ),
      externalEntityId: map['externalEntityId'] as String?,
      transactionDate: DateTime.parse(map['transactionDate'] as String),
      valueDate: map['valueDate'] != null
          ? DateTime.parse(map['valueDate'] as String)
          : null,
      visibilityDate: map['visibilityDate'] != null
          ? DateTime.parse(map['visibilityDate'] as String)
          : null,
      syncDate: map['syncDate'] != null
          ? DateTime.parse(map['syncDate'] as String)
          : null,
      provisionDate: map['provisionDate'] != null
          ? DateTime.parse(map['provisionDate'] as String)
          : null,
      splits: List<TransactionSplit>.from(
        (map['splits'] as List<dynamic>? ?? []).map<TransactionSplit>(
          (x) => TransactionSplit.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}
