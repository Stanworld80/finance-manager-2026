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

  RealAccount({
    required this.id,
    required this.ownerId,
    required this.name,
    this.bankName,
    this.initialBalance = 0.0,
    required this.balance,
    this.type = RealAccountType.internal,
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
    );
  }
}

class VirtualAccount {
  final String id;
  final String realAccountId;
  final String name;
  final double balance;
  final VirtualAccountType type;
  final String? icon;

  VirtualAccount({
    required this.id,
    required this.realAccountId,
    required this.name,
    required this.balance,
    required this.type,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
