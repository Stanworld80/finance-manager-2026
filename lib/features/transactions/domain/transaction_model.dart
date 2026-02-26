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
  cancelled, // Cancelled / Rejetée
}

class SystemAccounts {
  static const String external = 'system:external';
  static const String externalAdjustment = 'system:external-adjustment';

  static bool isSystem(String id) => id.startsWith('system:');
}

class TransactionSplit {
  /// The ID of the virtual account affected.
  /// Can be a real UUID or a system ID (e.g. 'system:external').
  final String virtualAccountId;
  final double
  amount; // Negative for debit (Source), Positive for credit (Target)

  TransactionSplit({required this.virtualAccountId, required this.amount});

  bool get isSystem => SystemAccounts.isSystem(virtualAccountId);

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

  // Import Dedup
  final String? importHash;

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
    this.importHash,
  });

  /// A transaction is balanced if the sum of all splits is 0.
  /// This is the core principle of double-entry accounting.
  bool get isBalanced {
    if (splits.isEmpty) return false;
    final sum = splits.fold(0.0, (prev, element) => prev + element.amount);
    return (sum.abs() < 0.001);
  }

  /// Calculates the total movement for a specific account in this transaction.
  double getImpactFor(String virtualAccountId) {
    return splits
        .where((s) => s.virtualAccountId == virtualAccountId)
        .fold(0.0, (prev, s) => prev + s.amount);
  }

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
      'importHash': importHash,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    // 1. Handle Type Migration (expense/income -> debit/credit)
    String typeStr = (map['type'] as String?) ?? 'debit';
    if (typeStr == 'expense') typeStr = 'debit';
    if (typeStr == 'income') typeStr = 'credit';

    final type = TransactionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => TransactionType.debit,
    );

    // 2. Handle Date Migration (date -> transactionDate)
    String? transactionDateStr = map['transactionDate'] as String?;
    transactionDateStr ??= map['date'] as String?;
    // Default to 'now' if absolutely nothing found to prevent crash
    final transactionDate = transactionDateStr != null
        ? DateTime.parse(transactionDateStr)
        : DateTime.now();

    return TransactionModel(
      id: map['id']?.toString() ?? '',
      ownerId: map['ownerId']?.toString() ?? '',
      realAccountId: map['realAccountId']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      label: map['label'] as String?,
      note: map['note'] as String?,
      payee: map['payee'] as String?,
      category: map['category'] as String?,
      type: type,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.none,
      ),
      step: TransactionStep.values.firstWhere(
        (e) => e.name == map['step'],
        orElse: () => TransactionStep.completed,
      ),
      externalEntityId: map['externalEntityId'] as String?,
      transactionDate: transactionDate,
      valueDate: map['valueDate'] != null
          ? DateTime.tryParse(map['valueDate'] as String)
          : null,
      visibilityDate: map['visibilityDate'] != null
          ? DateTime.tryParse(map['visibilityDate'] as String)
          : null,
      syncDate: map['syncDate'] != null
          ? DateTime.tryParse(map['syncDate'] as String)
          : null,
      provisionDate: map['provisionDate'] != null
          ? DateTime.tryParse(map['provisionDate'] as String)
          : null,
      splits: List<TransactionSplit>.from(
        (map['splits'] as List<dynamic>? ?? []).map<TransactionSplit>(
          (x) => TransactionSplit.fromMap(x as Map<String, dynamic>),
        ),
      ),
      importHash: map['importHash'] as String?,
    );
  }
}
