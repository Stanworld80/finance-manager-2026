import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../data/bank_sync_providers.dart';
import '../domain/bank_sync_models.dart';

class LinkBankScreen extends ConsumerStatefulWidget {
  final String? initialAuthCode;
  final String? initialAuthError;

  const LinkBankScreen({
    super.key,
    this.initialAuthCode,
    this.initialAuthError,
  });

  @override
  ConsumerState<LinkBankScreen> createState() => _LinkBankScreenState();
}

class _LinkBankScreenState extends ConsumerState<LinkBankScreen> {
  String _searchQuery = '';
  bool _isProcessingCallback = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAuthCode != null &&
        widget.initialAuthCode!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleIncomingAuthCode(widget.initialAuthCode!.trim());
      });
    } else if (widget.initialAuthError != null &&
        widget.initialAuthError!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Autorisation bancaire refusée : ${widget.initialAuthError}',
            ),
          ),
        );
      });
    }
  }

  Future<void> _handleIncomingAuthCode(
    String codeOrUrl, {
    String? bankName,
    String? country,
  }) async {
    if (_isProcessingCallback) return;
    setState(() => _isProcessingCallback = true);

    try {
      final extractedCode = _extractCodeFromInput(codeOrUrl);
      String userId = 'local_user';
      try {
        userId =
            ref.read(firebaseAuthProvider).currentUser?.uid ?? 'local_user';
      } catch (_) {
        // Fallback when Firebase Auth is not initialized in unit tests
      }

      final repo = ref.read(bankSyncRepositoryProvider);
      final session = await repo.completeBankAuthorization(
        code: extractedCode,
        userId: userId,
        bankName: bankName,
        country: country,
      );

      ref.invalidate(enableBankingSessionsProvider);
      ref.invalidate(realAccountsProvider);
      ref.invalidate(allVirtualAccountsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connexion réussie à ${session.aspspName} '
            '(${session.accounts.length} compte(s) détecté(s)).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la liaison bancaire : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingCallback = false);
      }
    }
  }

  String _extractCodeFromInput(String rawInput) {
    final trimmed = rawInput.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.containsKey('code')) {
      return uri.queryParameters['code']!;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(enableBankingSessionsProvider);
    final sessionCount = sessionsAsync.valueOrNull?.length ?? 0;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Connecter une Banque'),
          bottom: TabBar(
            tabs: [
              const Tab(
                icon: Icon(Icons.account_balance),
                text: 'Banques (ASPSP)',
              ),
              Tab(
                icon: const Icon(Icons.sync),
                text: 'Comptes reliés ($sessionCount)',
              ),
              const Tab(
                icon: Icon(Icons.vpn_key_outlined),
                text: 'Configuration API',
              ),
            ],
          ),
        ),
        body: _isProcessingCallback
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Échange du code DSP2 avec Enable Banking...'),
                  ],
                ),
              )
            : TabBarView(
                children: [
                  _BanksCatalogTab(
                    searchQuery: _searchQuery,
                    onSearchChanged: (value) =>
                        setState(() => _searchQuery = value),
                    onCompleteCode: _handleIncomingAuthCode,
                  ),
                  _ConnectedSessionsTab(
                    onCompleteCode: _handleIncomingAuthCode,
                  ),
                  const _EnableBankingConfigTab(),
                ],
              ),
      ),
    );
  }
}

class _BanksCatalogTab extends ConsumerWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function(
    String code, {
    String? bankName,
    String? country,
  }) onCompleteCode;

  const _BanksCatalogTab({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onCompleteCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banksAsync = ref.watch(availableBanksProvider);
    final configAsync = ref.watch(enableBankingConfigProvider);
    final selectedCountry = ref.watch(selectedBankCountryProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        configAsync.when(
          data: (config) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  config.useSimulationMode
                      ? Icons.science_outlined
                      : Icons.verified_user_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    config.useSimulationMode
                        ? 'Mode Simulation Enable Banking actif : testez la connexion et la synchronisation de comptes en 1 clic sans clé API.'
                        : 'Mode API Enable Banking (${config.environment.name.toUpperCase()}) actif.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText:
                        'Rechercher une banque (Crédit Agricole, BoursoBank, BNP...)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: selectedCountry,
                items: const [
                  DropdownMenuItem(value: 'FR', child: Text('🇫🇷 FR')),
                  DropdownMenuItem(value: 'BE', child: Text('🇧🇪 BE')),
                  DropdownMenuItem(value: 'DE', child: Text('🇩🇪 DE')),
                  DropdownMenuItem(value: 'ES', child: Text('🇪🇸 ES')),
                  DropdownMenuItem(value: 'IT', child: Text('🇮🇹 IT')),
                  DropdownMenuItem(value: 'FI', child: Text('🇫🇮 FI')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(selectedBankCountryProvider.notifier).state = val;
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: banksAsync.when(
            data: (banks) {
              final filtered = banks.where((b) {
                if (searchQuery.trim().isEmpty) return true;
                final q = searchQuery.toLowerCase();
                return b.name.toLowerCase().contains(q) ||
                    (b.bic?.toLowerCase().contains(q) ?? false);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('Aucune banque trouvée pour cette recherche.'),
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final bank = filtered[index];
                  return ListTile(
                    leading: const Icon(Icons.account_balance),
                    title: Text(bank.name),
                    subtitle: Text(
                      '${bank.country}${bank.bic != null ? ' • BIC: ${bank.bic}' : ''} '
                      '• Consentement max: ${bank.maxConsentDays} j',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _startBankFlow(context, ref, bank),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Erreur: $err',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(availableBanksProvider),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startBankFlow(
    BuildContext context,
    WidgetRef ref,
    BankInstitution bank,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Initialisation de la connexion à ${bank.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final repo = ref.read(bankSyncRepositoryProvider);
      final authResponse = await repo.startBankAuthorization(bank);

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => _AuthorizationFlowDialog(
          bank: bank,
          authResponse: authResponse,
          onConfirmCode: (code) async {
            Navigator.of(dialogContext).pop();
            await onCompleteCode(
              code,
              bankName: bank.name,
              country: bank.country,
            );
          },
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur Enable Banking : $e')),
      );
    }
  }
}

class _AuthorizationFlowDialog extends StatefulWidget {
  final BankInstitution bank;
  final StartAuthorizationResponse authResponse;
  final Future<void> Function(String code) onConfirmCode;

  const _AuthorizationFlowDialog({
    required this.bank,
    required this.authResponse,
    required this.onConfirmCode,
  });

  @override
  State<_AuthorizationFlowDialog> createState() =>
      _AuthorizationFlowDialogState();
}

class _AuthorizationFlowDialogState extends State<_AuthorizationFlowDialog> {
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.authResponse.simulatedAuthCode ?? '',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSim = widget.authResponse.isSimulated;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Autorisation DSP2 - ${widget.bank.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSim
                  ? 'Simulation du parcours d\'authentification forte (SCA) Enable Banking :'
                  : '1. Ouvrez l\'URL d\'autorisation Enable Banking ci-dessous dans votre navigateur pour valider l\'accès auprès de votre banque.\n'
                      '2. Une fois redirigé, collez l\'URL de retour ou le paramètre ?code=... ci-dessous.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.authResponse.url,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copier l\'URL',
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.authResponse.url),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL d\'autorisation copiée !'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: isSim
                    ? 'Code d\'autorisation simulé (pré-rempli)'
                    : 'Code OAuth ou URL de redirection (?code=...)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: Text(
            isSim
                ? 'Simuler la validation bancaire'
                : 'Valider le code et lier les comptes',
          ),
          onPressed: () {
            final code = _codeController.text.trim();
            if (code.isEmpty) return;
            widget.onConfirmCode(code);
          },
        ),
      ],
    );
  }
}

class _ConnectedSessionsTab extends ConsumerWidget {
  final Future<void> Function(
    String code, {
    String? bankName,
    String? country,
  }) onCompleteCode;

  const _ConnectedSessionsTab({required this.onCompleteCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(enableBankingSessionsProvider);
    final realAccountsAsync = ref.watch(realAccountsProvider);
    final theme = Theme.of(context);

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link_off,
                    size: 56,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune session bancaire active.',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sélectionnez une banque dans le premier onglet pour démarrer un essai.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final realAccounts = (realAccountsAsync.valueOrNull ?? const [])
            .where((a) => a.type == RealAccountType.internal)
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _SessionCard(
              session: session,
              realAccounts: realAccounts,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur : $err')),
    );
  }
}

class _SessionCard extends ConsumerStatefulWidget {
  final EnableBankingSession session;
  final List<RealAccount> realAccounts;

  const _SessionCard({
    required this.session,
    required this.realAccounts,
  });

  @override
  ConsumerState<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<_SessionCard> {
  bool _isSyncing = false;

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      String userId = 'local_user';
      try {
        userId =
            ref.read(firebaseAuthProvider).currentUser?.uid ?? 'local_user';
      } catch (_) {}

      final repo = ref.read(bankSyncRepositoryProvider);
      final result = await repo.syncSession(
        userId: userId,
        sessionId: widget.session.sessionId,
        userInitiated: true,
      );

      ref.invalidate(enableBankingSessionsProvider);
      ref.invalidate(realAccountsProvider);
      ref.invalidate(allVirtualAccountsProvider);

      if (!mounted) return;
      final warningText =
          result.warnings.isNotEmpty ? '\n⚠️ ${result.warnings.join('\n')}' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synchronisation terminée : ${result.importedTransactions} nouvelle(s) '
            'transaction(s) importée(s), ${result.skippedDuplicates} doublon(s) ignoré(s).$warningText',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de synchronisation : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _revokeSession() async {
    final repo = ref.read(bankSyncRepositoryProvider);
    await repo.disconnectSession(widget.session.sessionId);
    ref.invalidate(enableBankingSessionsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session ${widget.session.aspspName} déconnectée.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final theme = Theme.of(context);
    final daysLeft = session.daysRemaining();
    final autoSyncsLeft = session.remainingAutoSyncsToday();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${session.aspspName} (${session.aspspCountry})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Consentement DSP2 : $daysLeft j restants (max 180 j) • '
                        'Quota sync auto : $autoSyncsLeft/4 aujourd\'hui',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(session.isSimulated ? 'Simulation' : 'Live API'),
                ),
              ],
            ),
            const Divider(height: 24),
            ...session.accounts.map((remoteAcc) {
              final linkedExists = widget.realAccounts.any(
                (r) => r.id == remoteAcc.linkedRealAccountId,
              );
              final currentLinkedId =
                  linkedExists ? remoteAcc.linkedRealAccountId : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            remoteAcc.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${remoteAcc.iban ?? 'IBAN masqué'} • '
                            'Solde banque : ${remoteAcc.balance != null ? '${remoteAcc.balance!.toStringAsFixed(2)} ${remoteAcc.currency}' : 'Non lu'}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String?>(
                        initialValue: currentLinkedId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Compte FinanceManager lié',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Non lié (ignorer)'),
                          ),
                          ...widget.realAccounts.map(
                            (realAcc) => DropdownMenuItem<String?>(
                              value: realAcc.id,
                              child: Text(
                                realAcc.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (newRealId) async {
                          await ref
                              .read(bankSyncRepositoryProvider)
                              .linkRemoteAccountToRealAccount(
                                sessionId: session.sessionId,
                                remoteAccountUid: remoteAcc.uid,
                                realAccountId: newRealId,
                              );
                          ref.invalidate(enableBankingSessionsProvider);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _isSyncing ? null : _revokeSession,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Déconnecter'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSyncing ? null : _syncNow,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                    _isSyncing
                        ? 'Synchronisation...'
                        : 'Synchroniser les transactions',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EnableBankingConfigTab extends ConsumerStatefulWidget {
  const _EnableBankingConfigTab();

  @override
  ConsumerState<_EnableBankingConfigTab> createState() =>
      _EnableBankingConfigTabState();
}

class _EnableBankingConfigTabState
    extends ConsumerState<_EnableBankingConfigTab> {
  final _appIdController = TextEditingController();
  final _redirectUrlController = TextEditingController();
  final _proxyUrlController = TextEditingController();
  final _privateKeyController = TextEditingController();

  EnableBankingEnvironment _environment = EnableBankingEnvironment.sandbox;
  String _psuType = 'personal';
  bool _useSimulationMode = true;
  bool _initialized = false;
  String? _statusMessage;

  @override
  void dispose() {
    _appIdController.dispose();
    _redirectUrlController.dispose();
    _proxyUrlController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  void _populateFromConfig(EnableBankingConfig config) {
    if (_initialized) return;
    _appIdController.text = config.appId;
    _redirectUrlController.text = config.redirectUrl;
    _proxyUrlController.text = config.proxyUrl ?? '';
    _privateKeyController.text = config.privateKeyPem;
    _environment = config.environment;
    _psuType = config.psuType;
    _useSimulationMode = config.useSimulationMode;
    _initialized = true;
  }

  EnableBankingConfig _buildCurrentConfig() {
    return EnableBankingConfig(
      appId: _appIdController.text.trim(),
      privateKeyPem: _privateKeyController.text.trim(),
      environment: _environment,
      redirectUrl: _redirectUrlController.text.trim().isEmpty
          ? 'http://localhost:5000/link-bank'
          : _redirectUrlController.text.trim(),
      country: ref.read(selectedBankCountryProvider),
      psuType: _psuType,
      useSimulationMode: _useSimulationMode,
      proxyUrl: _proxyUrlController.text.trim().isEmpty
          ? null
          : _proxyUrlController.text.trim(),
    );
  }

  Future<void> _saveConfig() async {
    final config = _buildCurrentConfig();
    await ref.read(bankSyncRepositoryProvider).saveConfig(config);
    ref.invalidate(enableBankingConfigProvider);
    ref.invalidate(availableBanksProvider);
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Configuration Enable Banking enregistrée.';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration enregistrée !')),
    );
  }

  Future<void> _testApiConnection() async {
    final config = _buildCurrentConfig();
    await ref.read(bankSyncRepositoryProvider).saveConfig(config);
    ref.invalidate(enableBankingConfigProvider);
    ref.invalidate(availableBanksProvider);

    try {
      final result =
          await ref.read(bankSyncRepositoryProvider).testConnection(config);
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Connexion OK : Application "${result['name']}" (${result['environment']}) active=${result['active']}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Échec du test API : $e';
      });
    }
  }

  Future<void> _pickPemFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes != null) {
      setState(() {
        _privateKeyController.text = utf8.decode(file.bytes!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(enableBankingConfigProvider);
    final theme = Theme.of(context);

    return configAsync.when(
      data: (config) {
        _populateFromConfig(config);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: SwitchListTile(
                title: const Text(
                  'Mode Simulation (Essai immédiat sans clé API)',
                ),
                subtitle: const Text(
                  'Permet de tester tout le flux Open Banking (connexion ASPSP, '
                  'création des comptes et import dédupliqué des transactions) sans compte Enable Banking.',
                ),
                value: _useSimulationMode,
                onChanged: (val) {
                  setState(() => _useSimulationMode = val);
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paramètres API Enable Banking (JWT RS256)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child:
                              DropdownButtonFormField<EnableBankingEnvironment>(
                            initialValue: _environment,
                            decoration: const InputDecoration(
                              labelText: 'Environnement',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: EnableBankingEnvironment.sandbox,
                                child: Text('SANDBOX (Banques de test)'),
                              ),
                              DropdownMenuItem(
                                value: EnableBankingEnvironment.production,
                                child: Text(
                                  'PRODUCTION (Restreinte - Mes comptes)',
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _environment = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _psuType,
                            decoration: const InputDecoration(
                              labelText: 'Type de compte (PSU)',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'personal',
                                child: Text('Particulier (personal)'),
                              ),
                              DropdownMenuItem(
                                value: 'business',
                                child: Text('Professionnel (business)'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _psuType = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _appIdController,
                      decoration: const InputDecoration(
                        labelText: 'Application ID (kid)',
                        hintText: 'ex: cf589be3-3755-465b-a8df-a90a16a31403',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _redirectUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Redirect URL autorisée',
                        hintText: 'http://localhost:5000/link-bank',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _proxyUrlController,
                      decoration: const InputDecoration(
                        labelText:
                            'Proxy CORS local (optionnel sur navigateur Web)',
                        hintText:
                            'http://localhost:8787 (lancez: dart run bin/enable_banking_proxy.dart)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Clé privée RSA (.pem / .key)',
                          style: theme.textTheme.labelLarge,
                        ),
                        TextButton.icon(
                          onPressed: _pickPemFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Importer un fichier .pem'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _privateKeyController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText:
                            '-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC...\n-----END PRIVATE KEY-----',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_statusMessage!),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _testApiConnection,
                          icon: const Icon(Icons.network_check),
                          label: const Text('Tester GET /application'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _saveConfig,
                          icon: const Icon(Icons.save),
                          label: const Text('Enregistrer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: ExpansionTile(
                leading: Icon(Icons.help_outline),
                title: Text(
                  'Guide rapide : Activer Enable Banking gratuitement (Restricted Mode)',
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: SelectableText(
                      '1. Créez un compte développeur sur https://enablebanking.com/cp/applications\n'
                      '2. Générez une clé RSA ou choisissez "Generate in browser" :\n'
                      '   openssl genrsa -out private.key 4096\n'
                      '   openssl req -new -x509 -days 365 -key private.key -out public.crt -subj "/C=FR/O=Personal/CN=localhost"\n'
                      '3. Enregistrez l\'application en environnement PRODUCTION (ou SANDBOX) avec Redirect URL = http://localhost:5000/link-bank\n'
                      '4. Dans le panneau Enable Banking, cliquez sur "Activate by linking accounts" pour autoriser gratuitement vos propres comptes bancaires.\n'
                      '5. Sur Flutter Web, lancez `dart run bin/enable_banking_proxy.dart` et renseignez `http://localhost:8787` comme Proxy CORS.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur : $err')),
    );
  }
}
