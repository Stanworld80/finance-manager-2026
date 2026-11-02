import 'dart:convert';
import 'dart:typed_data';
import 'package:finance_manager_2026/features/accounts/data/account_repository.dart';
import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';
import 'package:finance_manager_2026/features/bank_sync/data/bank_sync_providers.dart';
import 'package:finance_manager_2026/features/bank_sync/data/enable_banking_jwt_signer.dart';
import 'package:finance_manager_2026/features/transactions/data/transaction_repository.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAccountRepository extends Fake implements AccountRepository {
  final List<RealAccount> realAccounts = [];
  final List<VirtualAccount> virtualAccounts = [];

  @override
  Future<List<RealAccount>> getRealAccounts(String userId) async {
    return List.unmodifiable(realAccounts);
  }

  @override
  Future<void> createRealAccount(String userId, RealAccount account) async {
    realAccounts.add(account);
  }

  @override
  Future<void> createVirtualAccount(
    String userId,
    VirtualAccount account,
  ) async {
    virtualAccounts.add(account);
  }

  @override
  Future<VirtualAccount?> getVirtualAccountByType(
    String userId,
    String realAccountId,
    VirtualAccountType type,
  ) async {
    for (final v in virtualAccounts) {
      if (v.realAccountId == realAccountId && v.type == type) {
        return v;
      }
    }
    return null;
  }
}

class FakeTransactionRepository extends Fake implements TransactionRepository {
  final List<TransactionModel> transactions = [];

  @override
  Future<List<TransactionModel>> getTransactionsByRealAccount(
    String userId,
    String realAccountId,
  ) async {
    return transactions
        .where((t) => t.realAccountId == realAccountId)
        .toList();
  }

  @override
  Future<int> addBatch(
    String userId,
    List<TransactionModel> newTransactions,
  ) async {
    transactions.addAll(newTransactions);
    return newTransactions.length;
  }
}

/// Builds a valid PKCS#1 PEM RSA private key using Mersenne primes M_521 and M_607.
String _buildTestPkcs1Pem() {
  final p = (BigInt.one << 521) - BigInt.one;
  final q = (BigInt.one << 607) - BigInt.one;
  final n = p * q;
  final e = BigInt.from(65537);
  final phi = (p - BigInt.one) * (q - BigInt.one);
  final d = e.modInverse(phi);

  List<int> encodeInt(BigInt val) {
    final hex = val.toRadixString(16);
    final paddedHex = hex.length.isOdd ? '0$hex' : hex;
    final bytes = <int>[];
    for (var i = 0; i < paddedHex.length; i += 2) {
      bytes.add(int.parse(paddedHex.substring(i, i + 2), radix: 16));
    }
    if (bytes.isNotEmpty && (bytes.first & 0x80) != 0) {
      bytes.insert(0, 0x00);
    }
    return [0x02, ..._encodeLength(bytes.length), ...bytes];
  }

  final body = <int>[
    ...encodeInt(BigInt.zero), // version
    ...encodeInt(n),
    ...encodeInt(e),
    ...encodeInt(d),
  ];
  final seq = <int>[0x30, ..._encodeLength(body.length), ...body];
  final b64 = base64Encode(seq);
  return '-----BEGIN RSA PRIVATE KEY-----\n$b64\n-----END RSA PRIVATE KEY-----';
}

List<int> _encodeLength(int len) {
  if (len < 128) return [len];
  if (len < 256) return [0x81, len];
  return [0x82, (len >> 8) & 0xFF, len & 0xFF];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EnableBankingJwtSigner (RS256)', () {
    test('creates valid RS256 JWT with kid, iss, aud and verifiable signature',
        () {
      final pem = _buildTestPkcs1Pem();
      const appId = 'cf589be3-3755-465b-a8df-a90a16a31403';
      final issuedAt = DateTime.utc(2026, 11, 2, 20, 0, 0);

      final jwt = EnableBankingJwtSigner.createJwt(
        appId: appId,
        privateKeyPem: pem,
        issuedAt: issuedAt,
        ttlSeconds: 3600,
      );

      final parts = jwt.split('.');
      expect(parts.length, 3);

      final headerJson = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
      ) as Map<String, dynamic>;
      expect(headerJson['typ'], 'JWT');
      expect(headerJson['alg'], 'RS256');
      expect(headerJson['kid'], appId);

      final payloadJson = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      expect(payloadJson['iss'], 'enablebanking.com');
      expect(payloadJson['aud'], 'api.enablebanking.com');
      expect(
        payloadJson['exp'] - payloadJson['iat'],
        3600,
      );

      // Verify cryptographic RS256 signature
      final keyParams = EnableBankingJwtSigner.parsePrivateKeyFromPem(pem);
      final signingInputBytes =
          Uint8List.fromList(utf8.encode('${parts[0]}.${parts[1]}'));
      final signatureBytes =
          Uint8List.fromList(base64Url.decode(base64Url.normalize(parts[2])));

      final isValid = EnableBankingJwtSigner.verifyRs256(
        signingInputBytes,
        signatureBytes,
        keyParams,
      );
      expect(isValid, isTrue);
    });

    test('rejects TTL > 86400 seconds per Enable Banking specification', () {
      final pem = _buildTestPkcs1Pem();
      expect(
        () => EnableBankingJwtSigner.createJwt(
          appId: 'test-app',
          privateKeyPem: pem,
          ttlSeconds: 90000,
        ),
        throwsArgumentError,
      );
    });
  });

  group('BankSyncRepository & Enable Banking Sync Flow', () {
    test(
        'completes simulated authorization, creates accounts, imports balanced transactions, and deduplicates',
        () async {
      final fakeAccountRepo = FakeAccountRepository();
      final fakeTxRepo = FakeTransactionRepository();
      final repo = BankSyncRepository(
        accountRepository: fakeAccountRepo,
        transactionRepository: fakeTxRepo,
      );

      // 1. Start & complete authorization for Crédit Agricole
      final session = await repo.completeBankAuthorization(
        code: 'eb_sim_credit_agricole_fr',
        userId: 'user_123',
        bankName: 'Crédit Agricole',
        country: 'FR',
      );

      expect(session.aspspName, 'Crédit Agricole');
      expect(session.accounts.length, 2);
      expect(session.daysRemaining(), greaterThanOrEqualTo(179));
      expect(fakeAccountRepo.realAccounts.length, 2);
      // 3 system virtual accounts per RealAccount (Libre, Solde Engagé, À Distribuer)
      expect(fakeAccountRepo.virtualAccounts.length, 6);

      // 2. First sync imports transactions with double-entry balance
      final firstSync = await repo.syncSession(
        userId: 'user_123',
        sessionId: session.sessionId,
        userInitiated: true,
      );

      expect(firstSync.syncedAccounts, 2);
      expect(firstSync.importedTransactions, 7); // 5 checking + 2 savings
      expect(firstSync.skippedDuplicates, 0);
      expect(fakeTxRepo.transactions.length, 7);

      // Verify strict double-entry accounting (sum of splits == 0 for every transaction)
      for (final tx in fakeTxRepo.transactions) {
        final splitSum =
            tx.splits.fold<double>(0.0, (sum, s) => sum + s.amount);
        expect(splitSum, closeTo(0.0, 0.0001));
        expect(tx.importHash, isNotNull);
        expect(tx.importHash, startsWith('eb_'));
      }

      // 3. Second sync deduplicates all existing transactions
      final secondSync = await repo.syncSession(
        userId: 'user_123',
        sessionId: session.sessionId,
        userInitiated: true,
      );

      expect(secondSync.importedTransactions, 0);
      expect(secondSync.skippedDuplicates, 7);
      expect(fakeTxRepo.transactions.length, 7);
    });

    test('enforces DSP2 4 unattended syncs/day quota while allowing manual sync',
        () async {
      final fakeAccountRepo = FakeAccountRepository();
      final fakeTxRepo = FakeTransactionRepository();
      final repo = BankSyncRepository(
        accountRepository: fakeAccountRepo,
        transactionRepository: fakeTxRepo,
      );

      final session = await repo.completeBankAuthorization(
        code: 'eb_sim_bourso_fr',
        userId: 'user_123',
        bankName: 'BoursoBank',
        country: 'FR',
      );

      // Perform 4 unattended background syncs
      for (var i = 0; i < 4; i++) {
        final res = await repo.syncSession(
          userId: 'user_123',
          sessionId: session.sessionId,
          userInitiated: false,
        );
        expect(res.warnings, isEmpty);
      }

      // 5th unattended sync on the same day is blocked with a DSP2 warning
      final fifthUnattended = await repo.syncSession(
        userId: 'user_123',
        sessionId: session.sessionId,
        userInitiated: false,
      );
      expect(fifthUnattended.syncedAccounts, 0);
      expect(fifthUnattended.warnings, isNotEmpty);
      expect(fifthUnattended.warnings.first, contains('Quota DSP2 atteint'));

      // Manual sync (userInitiated: true) still works!
      final manualSync = await repo.syncSession(
        userId: 'user_123',
        sessionId: session.sessionId,
        userInitiated: true,
      );
      expect(manualSync.syncedAccounts, 2);
      expect(manualSync.warnings, isEmpty);
    });
  });
}
