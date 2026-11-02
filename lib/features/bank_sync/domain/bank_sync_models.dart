enum BankConnectionStatus {
  connected,
  disconnected,
  error,
  syncing,
  expired,
}

enum BankProviderType {
  manual,
  enableBanking,
  gocardless,
  mock,
}

enum EnableBankingEnvironment {
  sandbox,
  production,
}

class EnableBankingConfig {
  final String appId;
  final String privateKeyPem;
  final EnableBankingEnvironment environment;
  final String redirectUrl;
  final String country;
  final String psuType;
  final bool useSimulationMode;
  final String? proxyUrl;

  const EnableBankingConfig({
    this.appId = '',
    this.privateKeyPem = '',
    this.environment = EnableBankingEnvironment.sandbox,
    this.redirectUrl = 'http://localhost:5000/link-bank',
    this.country = 'FR',
    this.psuType = 'personal',
    this.useSimulationMode = true,
    this.proxyUrl,
  });

  bool get hasCredentials =>
      appId.trim().isNotEmpty &&
      privateKeyPem.contains('PRIVATE KEY') &&
      redirectUrl.trim().isNotEmpty;

  String get effectiveBaseUrl {
    final cleanedProxy = proxyUrl?.trim();
    if (cleanedProxy != null && cleanedProxy.isNotEmpty) {
      return cleanedProxy.endsWith('/')
          ? cleanedProxy.substring(0, cleanedProxy.length - 1)
          : cleanedProxy;
    }
    return 'https://api.enablebanking.com';
  }

  EnableBankingConfig copyWith({
    String? appId,
    String? privateKeyPem,
    EnableBankingEnvironment? environment,
    String? redirectUrl,
    String? country,
    String? psuType,
    bool? useSimulationMode,
    String? proxyUrl,
  }) {
    return EnableBankingConfig(
      appId: appId ?? this.appId,
      privateKeyPem: privateKeyPem ?? this.privateKeyPem,
      environment: environment ?? this.environment,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      country: country ?? this.country,
      psuType: psuType ?? this.psuType,
      useSimulationMode: useSimulationMode ?? this.useSimulationMode,
      proxyUrl: proxyUrl ?? this.proxyUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appId': appId,
      'privateKeyPem': privateKeyPem,
      'environment': environment.name,
      'redirectUrl': redirectUrl,
      'country': country,
      'psuType': psuType,
      'useSimulationMode': useSimulationMode,
      'proxyUrl': proxyUrl,
    };
  }

  factory EnableBankingConfig.fromMap(Map<String, dynamic> map) {
    return EnableBankingConfig(
      appId: map['appId'] as String? ?? '',
      privateKeyPem: map['privateKeyPem'] as String? ?? '',
      environment: EnableBankingEnvironment.values.firstWhere(
        (e) => e.name == map['environment'],
        orElse: () => EnableBankingEnvironment.sandbox,
      ),
      redirectUrl:
          map['redirectUrl'] as String? ?? 'http://localhost:5000/link-bank',
      country: map['country'] as String? ?? 'FR',
      psuType: map['psuType'] as String? ?? 'personal',
      useSimulationMode: map['useSimulationMode'] as bool? ?? true,
      proxyUrl: map['proxyUrl'] as String?,
    );
  }
}

class BankInstitution {
  final String id;
  final String name;
  final String logoUrl;
  final BankProviderType providerType;
  final String country;
  final String? bic;
  final int maximumConsentValidity;
  final List<String> psuTypes;
  final bool beta;

  const BankInstitution({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.providerType,
    this.country = 'FR',
    this.bic,
    this.maximumConsentValidity = 15552000, // 180 days in seconds
    this.psuTypes = const ['personal'],
    this.beta = false,
  });

  int get maxConsentDays => (maximumConsentValidity / 86400).round();

  factory BankInstitution.fromEnableBankingAspsp(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Unknown Bank';
    final country = json['country'] as String? ?? 'FR';
    final psuTypesRaw = json['psu_types'] as List<dynamic>?;
    return BankInstitution(
      id: '${country}_$name',
      name: name,
      logoUrl: json['logo'] as String? ?? '',
      providerType: BankProviderType.enableBanking,
      country: country,
      bic: json['bic'] as String?,
      maximumConsentValidity:
          (json['maximum_consent_validity'] as num?)?.toInt() ?? 15552000,
      psuTypes: psuTypesRaw != null
          ? psuTypesRaw.map((e) => e.toString()).toList()
          : const ['personal'],
      beta: json['beta'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'providerType': providerType.name,
      'country': country,
      'bic': bic,
      'maximumConsentValidity': maximumConsentValidity,
      'psuTypes': psuTypes,
      'beta': beta,
    };
  }
}

class BankConnection {
  final String id;
  final String userId;
  final String institutionId;
  final BankConnectionStatus status;
  final DateTime lastSync;
  final String? externalReferenceId; // ID in the aggregator system
  final DateTime? validUntil;

  const BankConnection({
    required this.id,
    required this.userId,
    required this.institutionId,
    required this.status,
    required this.lastSync,
    this.externalReferenceId,
    this.validUntil,
  });
}

class EnableBankingRemoteAccount {
  final String uid;
  final String name;
  final String? iban;
  final String? bic;
  final String currency;
  final String? cashAccountType;
  final String? product;
  final double? balance;
  final String? linkedRealAccountId;

  const EnableBankingRemoteAccount({
    required this.uid,
    required this.name,
    this.iban,
    this.bic,
    this.currency = 'EUR',
    this.cashAccountType,
    this.product,
    this.balance,
    this.linkedRealAccountId,
  });

  EnableBankingRemoteAccount copyWith({
    String? uid,
    String? name,
    String? iban,
    String? bic,
    String? currency,
    String? cashAccountType,
    String? product,
    double? balance,
    String? linkedRealAccountId,
    bool clearLinkedAccount = false,
  }) {
    return EnableBankingRemoteAccount(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      iban: iban ?? this.iban,
      bic: bic ?? this.bic,
      currency: currency ?? this.currency,
      cashAccountType: cashAccountType ?? this.cashAccountType,
      product: product ?? this.product,
      balance: balance ?? this.balance,
      linkedRealAccountId: clearLinkedAccount
          ? null
          : (linkedRealAccountId ?? this.linkedRealAccountId),
    );
  }

  factory EnableBankingRemoteAccount.fromApiMap(Map<String, dynamic> json) {
    final accountIdMap = json['account_id'] as Map<String, dynamic>?;
    final servicerMap = json['account_servicer'] as Map<String, dynamic>?;
    final iban = accountIdMap?['iban'] as String?;
    final rawName = json['name'] as String? ??
        json['product'] as String? ??
        json['details'] as String? ??
        'Compte Bancaire';
    return EnableBankingRemoteAccount(
      uid: json['uid'] as String? ?? '',
      name: rawName,
      iban: iban,
      bic: servicerMap?['bic_fi'] as String?,
      currency: json['currency'] as String? ?? 'EUR',
      cashAccountType: json['cash_account_type'] as String?,
      product: json['product'] as String?,
      balance: (json['balance'] as num?)?.toDouble(),
      linkedRealAccountId: json['linkedRealAccountId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'account_id': {'iban': iban},
      'account_servicer': {'bic_fi': bic},
      'currency': currency,
      'cash_account_type': cashAccountType,
      'product': product,
      'balance': balance,
      'linkedRealAccountId': linkedRealAccountId,
    };
  }
}

class EnableBankingSession {
  static const int maxUnattendedDailySyncs = 4;

  final String sessionId;
  final String aspspName;
  final String aspspCountry;
  final String psuType;
  final DateTime validUntil;
  final DateTime createdAt;
  final DateTime? lastSyncAt;
  final int dailySyncCount;
  final String? lastSyncDay; // YYYY-MM-DD
  final List<EnableBankingRemoteAccount> accounts;
  final bool isSimulated;

  const EnableBankingSession({
    required this.sessionId,
    required this.aspspName,
    required this.aspspCountry,
    this.psuType = 'personal',
    required this.validUntil,
    required this.createdAt,
    this.lastSyncAt,
    this.dailySyncCount = 0,
    this.lastSyncDay,
    this.accounts = const [],
    this.isSimulated = false,
  });

  bool isExpired([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return now.isAfter(validUntil);
  }

  int daysRemaining([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final diff = validUntil.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  int remainingAutoSyncsToday([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final todayKey = _dayKey(now);
    if (lastSyncDay != todayKey) {
      return maxUnattendedDailySyncs;
    }
    final remaining = maxUnattendedDailySyncs - dailySyncCount;
    return remaining < 0 ? 0 : remaining;
  }

  static String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  EnableBankingSession recordSync({
    DateTime? syncedAt,
    required bool isUnattended,
    List<EnableBankingRemoteAccount>? updatedAccounts,
  }) {
    final now = syncedAt ?? DateTime.now();
    final todayKey = _dayKey(now);
    final baseCount = lastSyncDay == todayKey ? dailySyncCount : 0;
    final nextCount = isUnattended ? baseCount + 1 : baseCount;
    return copyWith(
      lastSyncAt: now,
      dailySyncCount: nextCount,
      lastSyncDay: todayKey,
      accounts: updatedAccounts ?? accounts,
    );
  }

  EnableBankingSession copyWith({
    String? sessionId,
    String? aspspName,
    String? aspspCountry,
    String? psuType,
    DateTime? validUntil,
    DateTime? createdAt,
    DateTime? lastSyncAt,
    int? dailySyncCount,
    String? lastSyncDay,
    List<EnableBankingRemoteAccount>? accounts,
    bool? isSimulated,
  }) {
    return EnableBankingSession(
      sessionId: sessionId ?? this.sessionId,
      aspspName: aspspName ?? this.aspspName,
      aspspCountry: aspspCountry ?? this.aspspCountry,
      psuType: psuType ?? this.psuType,
      validUntil: validUntil ?? this.validUntil,
      createdAt: createdAt ?? this.createdAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      dailySyncCount: dailySyncCount ?? this.dailySyncCount,
      lastSyncDay: lastSyncDay ?? this.lastSyncDay,
      accounts: accounts ?? this.accounts,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }

  factory EnableBankingSession.fromApiMap(
    Map<String, dynamic> json, {
    bool isSimulated = false,
  }) {
    final aspsp = json['aspsp'] as Map<String, dynamic>? ?? {};
    final access = json['access'] as Map<String, dynamic>? ?? {};
    final validUntilRaw = access['valid_until'] as String?;
    final createdRaw = json['createdAt'] as String?;
    final lastSyncRaw = json['lastSyncAt'] as String?;
    final rawAccounts = json['accounts'] as List<dynamic>? ?? [];

    return EnableBankingSession(
      sessionId: json['session_id'] as String? ?? '',
      aspspName: aspsp['name'] as String? ?? 'Banque',
      aspspCountry: aspsp['country'] as String? ?? 'FR',
      psuType: json['psu_type'] as String? ?? 'personal',
      validUntil: validUntilRaw != null
          ? (DateTime.tryParse(validUntilRaw) ??
              DateTime.now().add(const Duration(days: 180)))
          : DateTime.now().add(const Duration(days: 180)),
      createdAt: createdRaw != null
          ? (DateTime.tryParse(createdRaw) ?? DateTime.now())
          : DateTime.now(),
      lastSyncAt: lastSyncRaw != null ? DateTime.tryParse(lastSyncRaw) : null,
      dailySyncCount: (json['dailySyncCount'] as num?)?.toInt() ?? 0,
      lastSyncDay: json['lastSyncDay'] as String?,
      isSimulated: json['isSimulated'] as bool? ?? isSimulated,
      accounts: rawAccounts
          .whereType<Map<String, dynamic>>()
          .map(EnableBankingRemoteAccount.fromApiMap)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'aspsp': {
        'name': aspspName,
        'country': aspspCountry,
      },
      'psu_type': psuType,
      'access': {
        'valid_until': validUntil.toIso8601String(),
      },
      'createdAt': createdAt.toIso8601String(),
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'dailySyncCount': dailySyncCount,
      'lastSyncDay': lastSyncDay,
      'isSimulated': isSimulated,
      'accounts': accounts.map((a) => a.toMap()).toList(),
    };
  }
}

class EnableBankingTransaction {
  final String transactionId;
  final String? entryReference;
  final DateTime bookingDate;
  final DateTime? valueDate;
  final DateTime? transactionDate;
  final double amount; // Signed: positive for CRDT, negative for DBIT
  final String currency;
  final String creditDebitIndicator; // CRDT or DBIT
  final String status; // BOOK or PDNG
  final List<String> remittanceInformation;
  final String? creditorName;
  final String? debtorName;
  final String? merchantCategoryCode;
  final String? note;

  const EnableBankingTransaction({
    required this.transactionId,
    this.entryReference,
    required this.bookingDate,
    this.valueDate,
    this.transactionDate,
    required this.amount,
    this.currency = 'EUR',
    required this.creditDebitIndicator,
    this.status = 'BOOK',
    this.remittanceInformation = const [],
    this.creditorName,
    this.debtorName,
    this.merchantCategoryCode,
    this.note,
  });

  bool get isCredit => creditDebitIndicator.toUpperCase() == 'CRDT';
  bool get isPending => status.toUpperCase() == 'PDNG';

  String get displayLabel {
    if (remittanceInformation.isNotEmpty) {
      return remittanceInformation.join(' - ').trim();
    }
    if (counterpartyName != null && counterpartyName!.isNotEmpty) {
      return counterpartyName!;
    }
    if (note != null && note!.isNotEmpty) {
      return note!;
    }
    return isCredit ? 'Virement reçu' : 'Paiement bancaire';
  }

  String? get counterpartyName {
    return isCredit ? debtorName : creditorName;
  }

  /// Generates a deterministic importHash for deduplication in SQLite/Firestore.
  String buildImportHash(String accountUid) {
    final refId = (entryReference != null && entryReference!.trim().isNotEmpty)
        ? entryReference!.trim()
        : transactionId.trim();
    if (refId.isNotEmpty) {
      return 'eb_${accountUid}_$refId';
    }
    final dateStr = bookingDate.toIso8601String().split('T').first;
    final amtStr = amount.toStringAsFixed(2);
    final slug = displayLabel.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return 'eb_${accountUid}_${dateStr}_${amtStr}_$slug';
  }

  factory EnableBankingTransaction.fromApiMap(Map<String, dynamic> json) {
    final txAmountMap =
        json['transaction_amount'] as Map<String, dynamic>? ?? {};
    final rawAmountStr = txAmountMap['amount']?.toString() ?? '0.0';
    final rawAmount =
        double.tryParse(rawAmountStr.replaceAll(',', '.'))?.abs() ?? 0.0;
    final currency = txAmountMap['currency'] as String? ?? 'EUR';
    final indicator =
        (json['credit_debit_indicator'] as String? ?? 'DBIT').toUpperCase();
    final signedAmount = indicator == 'CRDT' ? rawAmount : -rawAmount;

    final bookingDateStr = json['booking_date'] as String? ??
        json['transaction_date'] as String? ??
        json['value_date'] as String?;
    final bookingDate = bookingDateStr != null
        ? (DateTime.tryParse(bookingDateStr) ?? DateTime.now())
        : DateTime.now();

    final valueDateStr = json['value_date'] as String?;
    final txDateStr = json['transaction_date'] as String?;

    final remittanceRaw = json['remittance_information'];
    final List<String> remittanceList;
    if (remittanceRaw is List) {
      remittanceList = remittanceRaw.map((e) => e.toString()).toList();
    } else if (remittanceRaw is String && remittanceRaw.isNotEmpty) {
      remittanceList = [remittanceRaw];
    } else {
      remittanceList = const [];
    }

    final creditorMap = json['creditor'] as Map<String, dynamic>?;
    final debtorMap = json['debtor'] as Map<String, dynamic>?;

    final entryRef = json['entry_reference'] as String?;
    final txId = json['transaction_id'] as String? ?? entryRef ?? '';

    return EnableBankingTransaction(
      transactionId: txId,
      entryReference: entryRef,
      bookingDate: bookingDate,
      valueDate: valueDateStr != null ? DateTime.tryParse(valueDateStr) : null,
      transactionDate: txDateStr != null ? DateTime.tryParse(txDateStr) : null,
      amount: signedAmount,
      currency: currency,
      creditDebitIndicator: indicator,
      status: (json['status'] as String? ?? 'BOOK').toUpperCase(),
      remittanceInformation: remittanceList,
      creditorName: creditorMap?['name'] as String?,
      debtorName: debtorMap?['name'] as String?,
      merchantCategoryCode: json['merchant_category_code'] as String?,
      note: json['note'] as String?,
    );
  }
}

class StartAuthorizationResponse {
  final String url;
  final String authorizationId;
  final String state;
  final String aspspName;
  final String aspspCountry;
  final bool isSimulated;
  final String? simulatedAuthCode;

  const StartAuthorizationResponse({
    required this.url,
    required this.authorizationId,
    required this.state,
    required this.aspspName,
    required this.aspspCountry,
    this.isSimulated = false,
    this.simulatedAuthCode,
  });
}

class BankSyncResult {
  final int syncedAccounts;
  final int importedTransactions;
  final int skippedDuplicates;
  final Map<String, double> updatedBalances;
  final DateTime syncedAt;
  final List<String> warnings;

  const BankSyncResult({
    required this.syncedAccounts,
    required this.importedTransactions,
    required this.skippedDuplicates,
    required this.updatedBalances,
    required this.syncedAt,
    this.warnings = const [],
  });
}
