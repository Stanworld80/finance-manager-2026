import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../domain/bank_sync_models.dart';
import 'enable_banking_jwt_signer.dart';

class EnableBankingApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;

  const EnableBankingApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
  });

  bool get isRateLimitExceeded =>
      statusCode == 429 || errorCode == 'ASPSP_RATE_LIMIT_EXCEEDED';

  @override
  String toString() {
    if (isRateLimitExceeded) {
      return 'Limite DSP2 atteinte (429 ASPSP_RATE_LIMIT_EXCEEDED) : '
          'la banque limite les synchronisations automatiques à ~4 par jour.';
    }
    return 'Erreur Enable Banking ($statusCode${errorCode != null ? ' - $errorCode' : ''}): $message';
  }
}

class EnableBankingApiClient {
  final http.Client _httpClient;
  final Uuid _uuid = const Uuid();

  EnableBankingApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Map<String, String> _buildHeaders(
    EnableBankingConfig config, {
    bool userInitiated = false,
  }) {
    final jwt = EnableBankingJwtSigner.createJwt(
      appId: config.appId,
      privateKeyPem: config.privateKeyPem,
    );
    return {
      'Authorization': 'Bearer $jwt',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (userInitiated) 'Psu-Ip-Address': '127.0.0.1',
    };
  }

  /// Verifies the application credentials against `GET /application`.
  Future<Map<String, dynamic>> getApplication(
    EnableBankingConfig config,
  ) async {
    if (config.useSimulationMode) {
      return {
        'name': 'FinanceManager2026 (Simulation)',
        'environment': config.environment.name.toUpperCase(),
        'kid': config.appId.isEmpty ? 'sim-app-id-2026' : config.appId,
        'active': true,
        'redirect_urls': [config.redirectUrl],
        'countries': [config.country],
        'services': ['AIS'],
        'simulated': true,
      };
    }

    final uri = Uri.parse('${config.effectiveBaseUrl}/application');
    final response = await _httpClient.get(
      uri,
      headers: _buildHeaders(config),
    );
    return _decodeResponse(response);
  }

  /// Fetches available banks (ASPSPs) from `GET /aspsps`.
  Future<List<BankInstitution>> getAspsps(
    EnableBankingConfig config, {
    String? country,
  }) async {
    final targetCountry = (country ?? config.country).toUpperCase();

    if (config.useSimulationMode) {
      return _getSimulatedBanks(targetCountry);
    }

    final uri = Uri.parse('${config.effectiveBaseUrl}/aspsps').replace(
      queryParameters: {
        'country': targetCountry,
        'service': 'AIS',
      },
    );

    final response = await _httpClient.get(
      uri,
      headers: _buildHeaders(config),
    );
    final data = _decodeResponse(response);
    final rawList = data['aspsps'] as List<dynamic>? ?? [];
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(BankInstitution.fromEnableBankingAspsp)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Initiates bank consent flow via `POST /auth`.
  Future<StartAuthorizationResponse> startAuthorization(
    EnableBankingConfig config, {
    required String aspspName,
    required String aspspCountry,
    String? state,
    int consentDays = 180,
  }) async {
    final authState = state ?? _uuid.v4();
    final validUntil = DateTime.now()
        .toUtc()
        .add(Duration(days: consentDays.clamp(1, 180)))
        .toIso8601String();

    if (config.useSimulationMode) {
      final authId = _uuid.v4();
      final slug = aspspName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      final simCode = 'eb_sim_${slug}_${aspspCountry.toLowerCase()}';
      return StartAuthorizationResponse(
        url:
            'https://auth.enablebanking.com/ais/start?sessionid=$authId&simulated=true',
        authorizationId: authId,
        state: authState,
        aspspName: aspspName,
        aspspCountry: aspspCountry,
        isSimulated: true,
        simulatedAuthCode: simCode,
      );
    }

    final uri = Uri.parse('${config.effectiveBaseUrl}/auth');
    final body = {
      'access': {
        'valid_until': validUntil,
      },
      'aspsp': {
        'name': aspspName,
        'country': aspspCountry,
      },
      'state': authState,
      'redirect_url': config.redirectUrl,
      'psu_type': config.psuType,
      'language': 'fr',
    };

    final response = await _httpClient.post(
      uri,
      headers: _buildHeaders(config, userInitiated: true),
      body: jsonEncode(body),
    );
    final data = _decodeResponse(response);
    return StartAuthorizationResponse(
      url: data['url'] as String? ?? '',
      authorizationId: data['authorization_id'] as String? ?? '',
      state: authState,
      aspspName: aspspName,
      aspspCountry: aspspCountry,
      isSimulated: false,
    );
  }

  /// Exchanges the callback `code` for an authorized session via `POST /sessions`.
  Future<EnableBankingSession> authorizeSession(
    EnableBankingConfig config, {
    required String code,
    String? fallbackBankName,
    String? fallbackCountry,
  }) async {
    if (config.useSimulationMode || code.startsWith('eb_sim_')) {
      return _createSimulatedSession(
        code: code,
        bankName: fallbackBankName,
        country: fallbackCountry ?? config.country,
      );
    }

    final uri = Uri.parse('${config.effectiveBaseUrl}/sessions');
    final response = await _httpClient.post(
      uri,
      headers: _buildHeaders(config, userInitiated: true),
      body: jsonEncode({'code': code.trim()}),
    );
    final data = _decodeResponse(response);
    return EnableBankingSession.fromApiMap(data, isSimulated: false);
  }

  /// Deletes/revokes a session via `DELETE /sessions/{session_id}`.
  Future<void> deleteSession(
    EnableBankingConfig config,
    EnableBankingSession session,
  ) async {
    if (config.useSimulationMode || session.isSimulated) {
      return;
    }

    final uri = Uri.parse(
      '${config.effectiveBaseUrl}/sessions/${session.sessionId}',
    );
    final response = await _httpClient.delete(
      uri,
      headers: _buildHeaders(config, userInitiated: true),
    );
    _decodeResponse(response);
  }

  /// Fetches the latest balance for an account via `GET /accounts/{account_id}/balances`.
  Future<double?> getAccountBalance(
    EnableBankingConfig config,
    String accountUid, {
    bool isSimulated = false,
    bool userInitiated = true,
  }) async {
    if (config.useSimulationMode || isSimulated || accountUid.startsWith('sim_')) {
      if (accountUid.contains('savings')) {
        return 8500.00;
      }
      return 2450.75;
    }

    final uri = Uri.parse(
      '${config.effectiveBaseUrl}/accounts/$accountUid/balances',
    );
    final response = await _httpClient.get(
      uri,
      headers: _buildHeaders(config, userInitiated: userInitiated),
    );
    final data = _decodeResponse(response);
    final balances = data['balances'] as List<dynamic>? ?? [];
    if (balances.isEmpty) return null;

    // Prefer CLAV (Closing Available), XPCD (Expected), ITAV (Interim Available), or first balance
    Map<String, dynamic>? preferred;
    const priorityTypes = ['CLAV', 'ITAV', 'XPCD', 'CLBD', 'ITBD'];
    for (final pType in priorityTypes) {
      for (final item in balances) {
        if (item is Map<String, dynamic> && item['balance_type'] == pType) {
          preferred = item;
          break;
        }
      }
      if (preferred != null) break;
    }
    preferred ??= balances.first as Map<String, dynamic>?;
    final amountMap = preferred?['balance_amount'] as Map<String, dynamic>?;
    final amountStr = amountMap?['amount']?.toString();
    if (amountStr == null) return null;
    return double.tryParse(amountStr.replaceAll(',', '.'));
  }

  /// Fetches transactions for an account via `GET /accounts/{account_id}/transactions`.
  Future<List<EnableBankingTransaction>> getAccountTransactions(
    EnableBankingConfig config,
    String accountUid, {
    DateTime? dateFrom,
    DateTime? dateTo,
    bool isSimulated = false,
    bool userInitiated = true,
  }) async {
    if (config.useSimulationMode || isSimulated || accountUid.startsWith('sim_')) {
      return _getSimulatedTransactions(accountUid);
    }

    final allTransactions = <EnableBankingTransaction>[];
    String? continuationKey;
    var pageCount = 0;

    do {
      final queryParams = <String, String>{};
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T').first;
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T').first;
      }
      if (continuationKey != null && continuationKey.isNotEmpty) {
        queryParams['continuation_key'] = continuationKey;
      }

      final uri = Uri.parse(
        '${config.effectiveBaseUrl}/accounts/$accountUid/transactions',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _httpClient.get(
        uri,
        headers: _buildHeaders(config, userInitiated: userInitiated),
      );
      final data = _decodeResponse(response);
      final rawTxs = data['transactions'] as List<dynamic>? ?? [];
      for (final raw in rawTxs) {
        if (raw is Map<String, dynamic>) {
          allTransactions.add(EnableBankingTransaction.fromApiMap(raw));
        }
      }

      continuationKey = data['continuation_key'] as String?;
      pageCount++;
    } while (
        continuationKey != null && continuationKey.isNotEmpty && pageCount < 10);

    return allTransactions;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> decoded = {};
    if (response.body.isNotEmpty) {
      try {
        final dynamic parsed = jsonDecode(utf8.decode(response.bodyBytes));
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        }
      } catch (_) {
        // Non-JSON body
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final errorCode =
        decoded['error']?.toString() ?? decoded['code']?.toString();
    final message = decoded['message']?.toString() ??
        decoded['error_description']?.toString() ??
        (response.body.isNotEmpty
            ? response.body
            : 'HTTP ${response.statusCode}');

    throw EnableBankingApiException(
      statusCode: response.statusCode,
      message: message,
      errorCode: errorCode,
    );
  }

  List<BankInstitution> _getSimulatedBanks(String country) {
    final frBanks = <BankInstitution>[
      const BankInstitution(
        id: 'FR_Credit_Agricole',
        name: 'Crédit Agricole',
        logoUrl: 'https://enablebanking.com/brands/FR/Credit%20Agricole/',
        providerType: BankProviderType.enableBanking,
        country: 'FR',
        bic: 'AGRIFRPP',
        maximumConsentValidity: 15552000,
        psuTypes: ['personal', 'business'],
      ),
      const BankInstitution(
        id: 'FR_BoursoBank',
        name: 'BoursoBank (ex Boursorama)',
        logoUrl: 'https://enablebanking.com/brands/FR/Boursorama/',
        providerType: BankProviderType.enableBanking,
        country: 'FR',
        bic: 'BOUSFRPP',
        maximumConsentValidity: 15552000,
        psuTypes: ['personal'],
      ),
      const BankInstitution(
        id: 'FR_BNP_Paribas',
        name: 'BNP Paribas',
        logoUrl: 'https://enablebanking.com/brands/FR/BNP%20Paribas/',
        providerType: BankProviderType.enableBanking,
        country: 'FR',
        bic: 'BNPAFRPP',
        maximumConsentValidity: 15552000,
        psuTypes: ['personal', 'business'],
      ),
      const BankInstitution(
        id: 'FR_Societe_Generale',
        name: 'Société Générale',
        logoUrl: 'https://enablebanking.com/brands/FR/Societe%20Generale/',
        providerType: BankProviderType.enableBanking,
        country: 'FR',
        bic: 'SOGEFRPP',
        maximumConsentValidity: 15552000,
        psuTypes: ['personal', 'business'],
      ),
      const BankInstitution(
        id: 'FR_La_Banque_Postale',
        name: 'La Banque Postale',
        logoUrl: 'https://enablebanking.com/brands/FR/La%20Banque%20Postale/',
        providerType: BankProviderType.enableBanking,
        country: 'FR',
        bic: 'PSSTFRPP',
        maximumConsentValidity: 15552000,
        psuTypes: ['personal'],
      ),
      const BankInstitution(
        id: 'FR_Caisse_Epargne',
        name: "Caisse d'Épargne",
        logoUrl: 'https://enablebanking.com/brands/FR/Caisse%20d%27Epargne/',
        providerType: BankProviderType.enableBanking,
        country: 'FR',
        bic: 'CEPAFRPP',
        maximumConsentValidity: 15552000,
        psuTypes: ['personal', 'business'],
      ),
      const BankInstitution(
        id: 'FR_Banque_Populaire',
        name: 'Banque Populaire',
        logoUrl: 'https://enablebanking.com/brands/FR/Banque%20Populaire/',
        providerType: BankProviderType.enableBanking,
        country: 'FR',
        bic: 'CCBPFRPP',
        maximumConsentValidity: 15552000,
        psuTypes: ['personal', 'business'],
      ),
      const BankInstitution(
        id: 'FR_Credit_Mutuel',
        name: 'Crédit Mutuel',
        logoUrl: 'https://enablebanking.com/brands/FR/Credit%20Mutuel/',
        providerType: BankProviderType.enableBanking,
        country: 'FR',
        bic: 'CMCIFRPP',
        maximumConsentValidity: 15552000,
        psuTypes: ['personal', 'business'],
      ),
      const BankInstitution(
        id: 'FR_LCL',
        name: 'LCL',
        logoUrl: 'https://enablebanking.com/brands/FR/LCL/',
        providerType: BankProviderType.enableBanking,
        country: 'FR',
        bic: 'CRLYFRPP',
        maximumConsentValidity: 15552000,
        psuTypes: ['personal', 'business'],
      ),
      const BankInstitution(
        id: 'FR_Fortuneo',
        name: 'Fortuneo',
        logoUrl: 'https://enablebanking.com/brands/FR/Fortuneo/',
        providerType: BankProviderType.enableBanking,
        country: 'FR',
        bic: 'FTNOFRP1',
        maximumConsentValidity: 15552000,
        psuTypes: ['personal'],
      ),
      const BankInstitution(
        id: 'FR_Revolut',
        name: 'Revolut',
        logoUrl: 'https://enablebanking.com/brands/FR/Revolut/',
        providerType: BankProviderType.enableBanking,
        country: 'FR',
        bic: 'REVOFRP2',
        maximumConsentValidity: 15552000,
        psuTypes: ['personal', 'business'],
      ),
    ];

    if (country == 'FR') return frBanks;
    return [
      BankInstitution(
        id: '${country}_Mock_Bank',
        name: 'Enable Banking Sandbox ASPSP ($country)',
        logoUrl: '',
        providerType: BankProviderType.enableBanking,
        country: country,
        bic: 'MOCK${country}PP',
        maximumConsentValidity: 15552000,
        psuTypes: const ['personal', 'business'],
      ),
      ...frBanks,
    ];
  }

  EnableBankingSession _createSimulatedSession({
    required String code,
    String? bankName,
    required String country,
  }) {
    final now = DateTime.now();
    final resolvedBankName = bankName ?? _extractBankNameFromCode(code);
    final slug = resolvedBankName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '')
        .padRight(6, '0')
        .substring(0, 6);

    return EnableBankingSession(
      sessionId: 'sim_sess_$slug',
      aspspName: resolvedBankName,
      aspspCountry: country,
      psuType: 'personal',
      validUntil: now.add(const Duration(days: 180)),
      createdAt: now,
      isSimulated: true,
      accounts: [
        EnableBankingRemoteAccount(
          uid: 'sim_acc_checking_$slug',
          name: 'Compte Courant $resolvedBankName',
          iban: 'FR7630004000031234567890143',
          bic: 'AGRIFRPP',
          currency: 'EUR',
          cashAccountType: 'CACC',
          product: 'Compte de dépôt',
          balance: 2450.75,
        ),
        EnableBankingRemoteAccount(
          uid: 'sim_acc_savings_$slug',
          name: 'Livret A $resolvedBankName',
          iban: 'FR7630004000039876543210987',
          bic: 'AGRIFRPP',
          currency: 'EUR',
          cashAccountType: 'SVGS',
          product: 'Épargne réglementée',
          balance: 8500.00,
        ),
      ],
    );
  }

  String _extractBankNameFromCode(String code) {
    if (code.contains('bourso')) return 'BoursoBank';
    if (code.contains('bnp')) return 'BNP Paribas';
    if (code.contains('societe')) return 'Société Générale';
    if (code.contains('postale')) return 'La Banque Postale';
    if (code.contains('revolut')) return 'Revolut';
    return 'Crédit Agricole';
  }

  List<EnableBankingTransaction> _getSimulatedTransactions(String accountUid) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (accountUid.contains('savings')) {
      return [
        EnableBankingTransaction(
          transactionId: '${accountUid}_tx_001',
          entryReference: '${accountUid}_ref_001',
          bookingDate: today.subtract(const Duration(days: 5)),
          valueDate: today.subtract(const Duration(days: 5)),
          amount: 300.00,
          currency: 'EUR',
          creditDebitIndicator: 'CRDT',
          status: 'BOOK',
          remittanceInformation: const ['Virement Épargne Mensuelle'],
          debtorName: 'Compte Courant Principal',
        ),
        EnableBankingTransaction(
          transactionId: '${accountUid}_tx_002',
          entryReference: '${accountUid}_ref_002',
          bookingDate: today.subtract(const Duration(days: 30)),
          valueDate: today.subtract(const Duration(days: 30)),
          amount: 142.50,
          currency: 'EUR',
          creditDebitIndicator: 'CRDT',
          status: 'BOOK',
          remittanceInformation: const ['Intérêts annuels Livret A'],
          debtorName: 'Banque',
        ),
      ];
    }

    return [
      EnableBankingTransaction(
        transactionId: '${accountUid}_tx_101',
        entryReference: '${accountUid}_ref_101',
        bookingDate: today.subtract(const Duration(days: 1)),
        valueDate: today.subtract(const Duration(days: 1)),
        amount: -64.80,
        currency: 'EUR',
        creditDebitIndicator: 'DBIT',
        status: 'BOOK',
        remittanceInformation: const ['CARTE CARREFOUR MARKET'],
        creditorName: 'Carrefour Market',
        merchantCategoryCode: '5411',
      ),
      EnableBankingTransaction(
        transactionId: '${accountUid}_tx_102',
        entryReference: '${accountUid}_ref_102',
        bookingDate: today.subtract(const Duration(days: 2)),
        valueDate: today.subtract(const Duration(days: 2)),
        amount: -89.00,
        currency: 'EUR',
        creditDebitIndicator: 'DBIT',
        status: 'BOOK',
        remittanceInformation: const ['PRLV SEPA EDF ENERGIE'],
        creditorName: 'EDF Clients Particuliers',
        merchantCategoryCode: '4900',
      ),
      EnableBankingTransaction(
        transactionId: '${accountUid}_tx_103',
        entryReference: '${accountUid}_ref_103',
        bookingDate: today.subtract(const Duration(days: 3)),
        valueDate: today.subtract(const Duration(days: 3)),
        amount: -34.99,
        currency: 'EUR',
        creditDebitIndicator: 'DBIT',
        status: 'BOOK',
        remittanceInformation: const ['PRLV SEPA ORANGE FIBRE'],
        creditorName: 'Orange SA',
      ),
      EnableBankingTransaction(
        transactionId: '${accountUid}_tx_104',
        entryReference: '${accountUid}_ref_104',
        bookingDate: today.subtract(const Duration(days: 5)),
        valueDate: today.subtract(const Duration(days: 5)),
        amount: 2650.00,
        currency: 'EUR',
        creditDebitIndicator: 'CRDT',
        status: 'BOOK',
        remittanceInformation: const ['VIR SEPA SALAIRE MENSUEL'],
        debtorName: 'Entreprise SAS',
      ),
      EnableBankingTransaction(
        transactionId: '${accountUid}_tx_105',
        entryReference: '${accountUid}_ref_105',
        bookingDate: today,
        valueDate: today,
        amount: -19.90,
        currency: 'EUR',
        creditDebitIndicator: 'DBIT',
        status: 'PDNG',
        remittanceInformation: const ['CARTE SNCF CONNECT EN COURS'],
        creditorName: 'SNCF Connect',
      ),
    ];
  }
}
