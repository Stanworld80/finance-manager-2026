enum VirtualAccountType {
  /// "Compte Libre" (Système): Reçoit tout le solde non attribué.
  systemFree,

  /// "Compte Budgétaire" (Utilisateur): Ex: "Alimentation", "Loisirs".
  userBudget,

  /// "Solde Engagé" (Système): Reçoit la contrepartie des dépenses réelles.
  systemCommitted,

  /// "À Distribuer" (Flux): Sas d'entrée pour les revenus.
  flowToDistribute,
}

enum RealAccountType {
  internal, // User's own account
  external, // Merchant, Friend, etc.
  externalGeneric, // "Unknown" external party
}

class RealAccount {
  final String id;
  final String ownerId;
  final String name;
  final String? bankName;
  final double initialBalance;
  final double balance; // Current calculated balance
  final RealAccountType type;
  final List<String> sharedWithUserIds; // NEW for sharing

  // Metadata expansion
  final DateTime? openingDate;
  final String? accountNumber;
  final String? officialName;
  final String? iban;
  final String? bic;
  final String? swift;

  RealAccount({
    required this.id,
    required this.ownerId,
    required this.name,
    this.bankName,
    this.initialBalance = 0.0,
    required this.balance,
    this.type = RealAccountType.internal,
    this.sharedWithUserIds = const [], // Default empty
    this.openingDate,
    this.accountNumber,
    this.officialName,
    this.iban,
    this.bic,
    this.swift,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'bankName': bankName,
      'initialBalance': initialBalance,
      'balance': balance,
      'type': type.name,
      'sharedWithUserIds': sharedWithUserIds,
      'openingDate': openingDate?.toIso8601String(),
      'accountNumber': accountNumber,
      'officialName': officialName,
      'iban': iban,
      'bic': bic,
      'swift': swift,
    };
  }

  factory RealAccount.fromMap(Map<String, dynamic> map) {
    return RealAccount(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String,
      name: map['name'] as String,
      bankName: map['bankName'] as String?,
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      type: RealAccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RealAccountType.internal,
      ),
      sharedWithUserIds: List<String>.from(map['sharedWithUserIds'] ?? []),
      openingDate: map['openingDate'] != null
          ? DateTime.parse(map['openingDate'] as String)
          : null,
      accountNumber: map['accountNumber'] as String?,
      officialName: map['officialName'] as String?,
      iban: map['iban'] as String?,
      bic: map['bic'] as String?,
      swift: map['swift'] as String?,
    );
  }
}

class VirtualAccount {
  final String id;
  final String userId; // Added for easy CG queries
  final String realAccountId;
  final String name;
  final double balance;
  final VirtualAccountType type;
  final String? icon;

  VirtualAccount({
    required this.id,
    required this.userId,
    required this.realAccountId,
    required this.name,
    required this.balance,
    required this.type,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'realAccountId': realAccountId,
      'name': name,
      'balance': balance,
      'type': type.name, // Storing enum as string
      'icon': icon,
    };
  }

  factory VirtualAccount.fromMap(Map<String, dynamic> map) {
    return VirtualAccount(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '', // Handle legacy docs if any
      realAccountId: map['realAccountId'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      type: VirtualAccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => VirtualAccountType.userBudget,
      ),
      icon: map['icon'] as String?,
    );
  }
}
