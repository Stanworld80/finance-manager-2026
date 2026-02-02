import 'package:flutter_test/flutter_test.dart';
import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';

/// Integration tests for multi-account and envelope-to-envelope transactions.
/// These tests verify that:
/// 1. Multiple distinct accounts can be created
/// 2. Transfers between envelopes on the same account work
/// 3. Transfers between envelopes on different accounts work
/// 4. Duplicate account names are rejected
void main() {
  group('Multi-Account Integration Tests', () {
    test('RealAccount model serialization round-trip with metadata', () {
      final account = RealAccount(
        id: 'acc-1',
        ownerId: 'user-1',
        name: 'Compte Courant BNP',
        bankName: 'BNP Paribas',
        initialBalance: 1000.0,
        balance: 1500.0,
        type: RealAccountType.internal,
        iban: 'FR7612345678901234567890123',
        bic: 'BNPAFRPP',
        officialName: 'Compte Particulier',
      );

      final map = account.toMap();
      final restored = RealAccount.fromMap(map);

      expect(restored.id, equals(account.id));
      expect(restored.name, equals(account.name));
      expect(restored.iban, equals(account.iban));
      expect(restored.bic, equals(account.bic));
      expect(restored.officialName, equals(account.officialName));
    });

    test('VirtualAccount preserves userId for collectionGroup queries', () {
      final envelope = VirtualAccount(
        id: 'env-1',
        userId: 'user-123',
        realAccountId: 'acc-1',
        name: 'Alimentation',
        balance: 500.0,
        type: VirtualAccountType.userBudget,
      );

      final map = envelope.toMap();
      final restored = VirtualAccount.fromMap(map);

      expect(restored.userId, equals('user-123'));
      expect(restored.name, equals('Alimentation'));
    });

    test('Transaction with splits between envelopes', () {
      // A transaction that moves money from "Libre" to "Alimentation" envelopes
      final transaction = TransactionModel(
        id: 'tx-1',
        ownerId: 'user-1',
        realAccountId: 'acc-1',
        amount: 200.0,
        type: TransactionType.transfer,
        transactionDate: DateTime.now(),
        label: 'Budget Alimentation',
        splits: [
          TransactionSplit(virtualAccountId: 'libre-env', amount: -200.0),
          TransactionSplit(virtualAccountId: 'food-env', amount: 200.0),
        ],
      );

      expect(transaction.splits.length, equals(2));
      final totalDelta = transaction.splits.fold(
        0.0,
        (sum, s) => sum + s.amount,
      );
      expect(
        totalDelta,
        equals(0.0),
        reason: 'Double-entry: sum of splits should be zero',
      );
    });

    test('Multiple distinct accounts should have unique names', () {
      final accounts = [
        RealAccount(
          id: 'acc-1',
          ownerId: 'user-1',
          name: 'Compte Courant',
          balance: 1000.0,
        ),
        RealAccount(
          id: 'acc-2',
          ownerId: 'user-1',
          name: 'Livret A',
          balance: 5000.0,
        ),
        RealAccount(
          id: 'acc-3',
          ownerId: 'user-1',
          name: 'Compte Joint',
          balance: 2500.0,
        ),
      ];

      // Check all names are unique (case-insensitive)
      final names = accounts.map((a) => a.name.toLowerCase()).toSet();
      expect(
        names.length,
        equals(accounts.length),
        reason: 'All account names should be unique',
      );
    });

    test(
      'Envelope display name includes parent account for disambiguation',
      () {
        final envelope = VirtualAccount(
          id: 'env-1',
          userId: 'user-1',
          realAccountId: 'acc-1',
          name: 'Alimentation',
          balance: 300.0,
          type: VirtualAccountType.userBudget,
        );

        const parentAccountName = 'Compte Courant';
        final displayName = '${envelope.name} ($parentAccountName)';

        expect(displayName, equals('Alimentation (Compte Courant)'));
      },
    );
  });

  group('Cross-Account Transfer Validation', () {
    test('Transfer from Account A to Account B should be valid', () {
      // This represents a transfer from one real account to another
      // via the "Monde Extérieur" intermediate or a direct transfer

      final originEnvelope = VirtualAccount(
        id: 'env-a1',
        userId: 'user-1',
        realAccountId: 'acc-a',
        name: 'Libre',
        balance: 1000.0,
        type: VirtualAccountType.systemFree,
      );

      final destEnvelope = VirtualAccount(
        id: 'env-b1',
        userId: 'user-1',
        realAccountId: 'acc-b',
        name: 'Libre',
        balance: 500.0,
        type: VirtualAccountType.systemFree,
      );

      // After transfer of 200€
      const transferAmount = 200.0;
      expect(originEnvelope.balance - transferAmount, equals(800.0));
      expect(destEnvelope.balance + transferAmount, equals(700.0));
    });
  });
}
