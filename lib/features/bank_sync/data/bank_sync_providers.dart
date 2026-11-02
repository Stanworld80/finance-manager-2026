import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../accounts/application/account_service.dart';
import '../../accounts/data/account_repository.dart';
import '../../accounts/domain/account_models.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_model.dart';
import '../domain/bank_sync_models.dart';
import 'enable_banking_api_client.dart';

class BankSyncRepository {
  static const String _configPrefsKey = 'enable_banking_config_v1';
  static const String _sessionsPrefsKey = 'enable_banking_sessions_v1';

  final EnableBankingApiClient _apiClient;
  final AccountRepository? _accountRepository;
  final AccountService? _accountService;
  final TransactionRepository? _transactionRepository;
  final Uuid _uuid = const Uuid();

  EnableBankingConfig? _cachedConfig;
  List<EnableBankingSession>? _cachedSessions;

  BankSyncRepository({
    EnableBankingApiClient? apiClient,
    AccountRepository? accountRepository,
    AccountService? accountService,
    TransactionRepository? transactionRepository,
  })  : _apiClient = apiClient ?? EnableBankingApiClient(),
        _accountRepository = accountRepository,
        _accountService = accountService,
        _transactionRepository = transactionRepository;

  Future<EnableBankingConfig> loadConfig() async {
    if (_cachedConfig != null) return _cachedConfig!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_configPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _cachedConfig = EnableBankingConfig.fromMap(map);
        return _cachedConfig!;
      }
    } catch (_) {
      // Fallback to default config if SharedPreferences is unavailable in test
    }
    _cachedConfig = const EnableBankingConfig();
    return _cachedConfig!;
  }

  Future<void> saveConfig(EnableBankingConfig config) async {
    _cachedConfig = config;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_configPrefsKey, jsonEncode(config.toMap()));
    } catch (_) {
      // Keep in-memory cache in test environments
    }
  }

  Future<List<EnableBankingSession>> loadSessions() async {
    if (_cachedSessions != null) return List.unmodifiable(_cachedSessions!);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionsPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _cachedSessions = list
            .whereType<Map<String, dynamic>>()
            .map(EnableBankingSession.fromApiMap)
            .toList();
        return List.unmodifiable(_cachedSessions!);
      }
    } catch (_) {
      // Fallback to empty list in test environments
    }
    _cachedSessions = [];
    return const [];
  }

  Future<void> saveSessions(List<EnableBankingSession> sessions) async {
    _cachedSessions = List<EnableBankingSession>.from(sessions);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sessionsPrefsKey,
        jsonEncode(sessions.map((s) => s.toMap()).toList()),
      );
    } catch (_) {
      // Keep in-memory cache in test environments
    }
  }

  Future<Map<String, dynamic>> testConnection([
    EnableBankingConfig? customConfig,
  ]) async {
    final config = customConfig ?? await loadConfig();
    return _apiClient.getApplication(config);
  }

  Future<List<BankInstitution>> getAvailableInstitutions({
    String? country,
  }) async {
    final config = await loadConfig();
    return _apiClient.getAspsps(config, country: country);
  }

  Future<StartAuthorizationResponse> startBankAuthorization(
    BankInstitution institution,
  ) async {
    final config = await loadConfig();
    return _apiClient.startAuthorization(
      config,
      aspspName: institution.name,
      aspspCountry: institution.country,
      consentDays: institution.maxConsentDays,
    );
  }

  /// Legacy method kept for backward compatibility; starts and completes a simulated connection.
  Future<void> connectInstitution(String userId, String institutionId) async {
    final banks = await getAvailableInstitutions();
    final bank = banks.firstWhere(
      (b) => b.id == institutionId,
      orElse: () => BankInstitution(
        id: institutionId,
        name: institutionId,
        logoUrl: '',
        providerType: BankProviderType.enableBanking,
      ),
    );
    final authResp = await startBankAuthorization(bank);
    if (authResp.simulatedAuthCode != null) {
      await completeBankAuthorization(
        code: authResp.simulatedAuthCode!,
        userId: userId,
        bankName: bank.name,
        country: bank.country,
      );
    }
  }

  /// Exchanges the OAuth2 `code` from Enable Banking callback for a session and optionally
  /// matches or creates local `RealAccount`s.
  Future<EnableBankingSession> completeBankAuthorization({
    required String code,
    required String userId,
    String? bankName,
    String? country,
    bool autoCreateRealAccounts = true,
  }) async {
    final config = await loadConfig();
    var session = await _apiClient.authorizeSession(
      config,
      code: code,
      fallbackBankName: bankName,
      fallbackCountry: country ?? config.country,
    );

    if (_accountRepository != null && userId.isNotEmpty) {
      final existingRealAccounts =
          await _accountRepository.getRealAccounts(userId);
      final updatedRemoteAccounts = <EnableBankingRemoteAccount>[];

      for (final remoteAcc in session.accounts) {
        // 1. Try matching by IBAN or name
        RealAccount? matched = existingRealAccounts.cast<RealAccount?>().firstWhere(
              (a) =>
                  a != null &&
                  a.type == RealAccountType.internal &&
                  ((remoteAcc.iban != null &&
                          remoteAcc.iban!.isNotEmpty &&
                          _normalizeIban(a.iban) ==
                              _normalizeIban(remoteAcc.iban)) ||
                      a.name.toLowerCase() == remoteAcc.name.toLowerCase()),
              orElse: () => null,
            );

        // 2. Auto-create if requested and not matched
        if (matched == null && autoCreateRealAccounts) {
          matched = await _createRealAccountForRemote(
            userId: userId,
            bankName: session.aspspName,
            remoteAccount: remoteAcc,
          );
        }

        updatedRemoteAccounts.add(
          remoteAcc.copyWith(linkedRealAccountId: matched?.id),
        );
      }

      session = session.copyWith(accounts: updatedRemoteAccounts);
    }

    final currentSessions = List<EnableBankingSession>.from(
      await loadSessions(),
    );
    final existingIdx = currentSessions.indexWhere(
      (s) => s.sessionId == session.sessionId,
    );
    if (existingIdx >= 0) {
      currentSessions[existingIdx] = session;
    } else {
      currentSessions.insert(0, session);
    }
    await saveSessions(currentSessions);
    return session;
  }

  Future<RealAccount?> _createRealAccountForRemote({
    required String userId,
    required String bankName,
    required EnableBankingRemoteAccount remoteAccount,
  }) async {
    final accountRepo = _accountRepository;
    if (accountRepo == null) return null;

    var accountName = remoteAccount.name;
    final existing = await accountRepo.getRealAccounts(userId);
    if (existing.any((a) => a.name.toLowerCase() == accountName.toLowerCase())) {
      final suffix = remoteAccount.iban != null && remoteAccount.iban!.length >= 4
          ? remoteAccount.iban!.substring(remoteAccount.iban!.length - 4)
          : remoteAccount.uid.substring(0, 4);
      accountName = '$accountName ($suffix)';
    }

    if (_accountService != null) {
      await _accountService.createRealAccount(
        name: accountName,
        bankName: bankName,
        initialBalance: 0.0,
      );
      final afterCreate = await accountRepo.getRealAccounts(userId);
      final created = afterCreate.cast<RealAccount?>().firstWhere(
            (a) => a != null && a.name.toLowerCase() == accountName.toLowerCase(),
            orElse: () => null,
          );
      if (created != null) {
        await _accountService.updateRealAccountMetadata(
          account: created,
          iban: remoteAccount.iban,
          bic: remoteAccount.bic,
          officialName: remoteAccount.product ?? remoteAccount.name,
        );
        return accountRepo.getRealAccount(userId, created.id);
      }
      return null;
    } else {
      final realAcc = RealAccount(
        id: _uuid.v4(),
        ownerId: userId,
        name: accountName,
        bankName: bankName,
        initialBalance: 0.0,
        balance: 0.0,
        iban: remoteAccount.iban,
        bic: remoteAccount.bic,
        officialName: remoteAccount.product ?? remoteAccount.name,
      );
      await accountRepo.createRealAccount(userId, realAcc);
      await accountRepo.createVirtualAccount(
        userId,
        VirtualAccount(
          id: _uuid.v4(),
          userId: userId,
          realAccountId: realAcc.id,
          name: 'Libre',
          balance: 0.0,
          type: VirtualAccountType.systemFree,
          icon: 'savings',
        ),
      );
      await accountRepo.createVirtualAccount(
        userId,
        VirtualAccount(
          id: _uuid.v4(),
          userId: userId,
          realAccountId: realAcc.id,
          name: 'Solde Engagé',
          balance: 0.0,
          type: VirtualAccountType.systemCommitted,
          icon: 'lock_clock',
        ),
      );
      await accountRepo.createVirtualAccount(
        userId,
        VirtualAccount(
          id: _uuid.v4(),
          userId: userId,
          realAccountId: realAcc.id,
          name: 'À Distribuer',
          balance: 0.0,
          type: VirtualAccountType.flowToDistribute,
          icon: 'input',
        ),
      );
      return realAcc;
    }
  }

  Future<EnableBankingSession?> linkRemoteAccountToRealAccount({
    required String sessionId,
    required String remoteAccountUid,
    required String? realAccountId,
  }) async {
    final sessions = List<EnableBankingSession>.from(await loadSessions());
    final idx = sessions.indexWhere((s) => s.sessionId == sessionId);
    if (idx < 0) return null;

    final session = sessions[idx];
    final updatedAccounts = session.accounts.map((acc) {
      if (acc.uid == remoteAccountUid) {
        return acc.copyWith(
          linkedRealAccountId: realAccountId,
          clearLinkedAccount: realAccountId == null,
        );
      }
      return acc;
    }).toList();

    final updatedSession = session.copyWith(accounts: updatedAccounts);
    sessions[idx] = updatedSession;
    await saveSessions(sessions);
    return updatedSession;
  }

  /// Synchronizes balances and transactions for a given `EnableBankingSession`.
  ///
  /// Enforces:
  /// - 180-day consent expiration check
  /// - DSP2 ~4/day unattended background sync limit
  /// - `importHash` deduplication (`eb_<accountUid>_<entryRefOrTxId>`)
  /// - Double-entry accounting splits (`Libre` / `Solde Engagé` <-> `SystemAccounts.external`)
  Future<BankSyncResult> syncSession({
    required String userId,
    required String sessionId,
    bool userInitiated = true,
    DateTime? dateFrom,
  }) async {
    final config = await loadConfig();
    final sessions = List<EnableBankingSession>.from(await loadSessions());
    final idx = sessions.indexWhere((s) => s.sessionId == sessionId);
    if (idx < 0) {
      throw Exception('Session bancaire introuvable: $sessionId');
    }

    var session = sessions[idx];
    if (session.isExpired()) {
      throw Exception(
        'Le consentement DSP2 de 180 jours pour ${session.aspspName} a expiré. '
        'Veuillez reconnecter votre banque.',
      );
    }

    final warnings = <String>[];
    if (!userInitiated && session.remainingAutoSyncsToday() <= 0) {
      return BankSyncResult(
        syncedAccounts: 0,
        importedTransactions: 0,
        skippedDuplicates: 0,
        updatedBalances: const {},
        syncedAt: DateTime.now(),
        warnings: [
          'Quota DSP2 atteint (4/4 synchronisations automatiques aujourd\'hui pour ${session.aspspName}). '
              'Utilisez le rafraîchissement manuel si nécessaire.',
        ],
      );
    }

    var syncedAccountsCount = 0;
    var importedTxCount = 0;
    var skippedDuplicatesCount = 0;
    final updatedBalances = <String, double>{};
    final updatedRemoteAccounts = <EnableBankingRemoteAccount>[];

    for (final remoteAcc in session.accounts) {
      final fetchedBalance = await _apiClient.getAccountBalance(
        config,
        remoteAcc.uid,
        isSimulated: session.isSimulated,
        userInitiated: userInitiated,
      );

      final updatedAcc = remoteAcc.copyWith(
        balance: fetchedBalance ?? remoteAcc.balance,
      );
      updatedRemoteAccounts.add(updatedAcc);

      if (fetchedBalance != null) {
        updatedBalances[remoteAcc.uid] = fetchedBalance;
      }

      final targetRealAccountId = updatedAcc.linkedRealAccountId;
      if (targetRealAccountId == null ||
          _transactionRepository == null ||
          _accountRepository == null) {
        continue;
      }

      syncedAccountsCount++;

      // Fetch remote transactions
      final remoteTransactions = await _apiClient.getAccountTransactions(
        config,
        remoteAcc.uid,
        dateFrom: dateFrom,
        isSimulated: session.isSimulated,
        userInitiated: userInitiated,
      );

      // Load existing local transactions to deduplicate by importHash
      final existingLocalTxs = await _transactionRepository
          .getTransactionsByRealAccount(userId, targetRealAccountId);
      final existingHashes = existingLocalTxs
          .map((t) => t.importHash)
          .whereType<String>()
          .toSet();

      // Lookup virtual accounts for double-entry splits
      final freeVirtual = await _accountRepository.getVirtualAccountByType(
        userId,
        targetRealAccountId,
        VirtualAccountType.systemFree,
      );
      final committedVirtual = await _accountRepository.getVirtualAccountByType(
        userId,
        targetRealAccountId,
        VirtualAccountType.systemCommitted,
      );

      if (freeVirtual == null) {
        warnings.add(
          'Compte virtuel "Libre" introuvable pour le compte ${updatedAcc.name}.',
        );
        continue;
      }

      final newTransactionsToInsert = <TransactionModel>[];

      for (final ebTx in remoteTransactions) {
        final hash = ebTx.buildImportHash(remoteAcc.uid);
        if (existingHashes.contains(hash)) {
          skippedDuplicatesCount++;
          continue;
        }
        existingHashes.add(hash);

        final absAmount = ebTx.amount.abs();
        final txType =
            ebTx.isCredit ? TransactionType.credit : TransactionType.debit;
        final txStep = ebTx.isPending
            ? TransactionStep.pending
            : TransactionStep.completed;

        final targetVirtualId =
            (ebTx.isPending && !ebTx.isCredit && committedVirtual != null)
                ? committedVirtual.id
                : freeVirtual.id;

        final splits = <TransactionSplit>[
          if (txType == TransactionType.credit) ...[
            TransactionSplit(
              virtualAccountId: targetVirtualId,
              amount: absAmount,
            ),
            TransactionSplit(
              virtualAccountId: SystemAccounts.external,
              amount: -absAmount,
            ),
          ] else ...[
            TransactionSplit(
              virtualAccountId: targetVirtualId,
              amount: -absAmount,
            ),
            TransactionSplit(
              virtualAccountId: SystemAccounts.external,
              amount: absAmount,
            ),
          ],
        ];

        newTransactionsToInsert.add(
          TransactionModel(
            id: _uuid.v4(),
            ownerId: userId,
            realAccountId: targetRealAccountId,
            amount: ebTx.amount,
            type: txType,
            transactionDate: ebTx.bookingDate,
            valueDate: ebTx.valueDate,
            syncDate: DateTime.now(),
            label: ebTx.displayLabel,
            payee: ebTx.counterpartyName,
            note: ebTx.note ?? 'Synchronisé via Enable Banking',
            status: TransactionStatus.none,
            step: txStep,
            splits: splits,
            importHash: hash,
          ),
        );
      }

      if (newTransactionsToInsert.isNotEmpty) {
        final count = await _transactionRepository.addBatch(
          userId,
          newTransactionsToInsert,
        );
        importedTxCount += count;
      }
    }

    final now = DateTime.now();
    session = session.recordSync(
      syncedAt: now,
      isUnattended: !userInitiated,
      updatedAccounts: updatedRemoteAccounts,
    );
    sessions[idx] = session;
    await saveSessions(sessions);

    return BankSyncResult(
      syncedAccounts: syncedAccountsCount,
      importedTransactions: importedTxCount,
      skippedDuplicates: skippedDuplicatesCount,
      updatedBalances: updatedBalances,
      syncedAt: now,
      warnings: warnings,
    );
  }

  Future<void> disconnectSession(String sessionId) async {
    final config = await loadConfig();
    final sessions = List<EnableBankingSession>.from(await loadSessions());
    final idx = sessions.indexWhere((s) => s.sessionId == sessionId);
    if (idx < 0) return;

    final session = sessions[idx];
    await _apiClient.deleteSession(config, session);
    sessions.removeAt(idx);
    await saveSessions(sessions);
  }

  String _normalizeIban(String? iban) {
    if (iban == null) return '';
    return iban.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }
}

final enableBankingApiClientProvider = Provider<EnableBankingApiClient>((ref) {
  return EnableBankingApiClient();
});

final bankSyncRepositoryProvider = Provider<BankSyncRepository>((ref) {
  return BankSyncRepository(
    apiClient: ref.watch(enableBankingApiClientProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    accountService: ref.watch(accountServiceProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
});

final enableBankingConfigProvider =
    FutureProvider<EnableBankingConfig>((ref) async {
  return ref.watch(bankSyncRepositoryProvider).loadConfig();
});

final enableBankingSessionsProvider =
    FutureProvider<List<EnableBankingSession>>((ref) async {
  return ref.watch(bankSyncRepositoryProvider).loadSessions();
});

final selectedBankCountryProvider = StateProvider<String>((ref) => 'FR');

final availableBanksProvider = FutureProvider<List<BankInstitution>>((ref) {
  final country = ref.watch(selectedBankCountryProvider);
  // Also watch config so toggling simulation mode refreshes the bank list
  ref.watch(enableBankingConfigProvider);
  return ref
      .watch(bankSyncRepositoryProvider)
      .getAvailableInstitutions(country: country);
});
