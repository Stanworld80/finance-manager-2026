import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';
import 'package:finance_manager_2026/features/accounts/data/account_providers.dart';
import 'package:finance_manager_2026/features/resume/presentation/resume_providers.dart';
import 'package:finance_manager_2026/features/transactions/data/transaction_repository.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_manager_2026/core/providers.dart';

import 'resume_providers_test.mocks.dart';

@GenerateMocks([TransactionRepository, FirebaseAuth, User])
void main() {
  late MockTransactionRepository mockTxRepo;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('user_123');
  });

  test(
    'resumeDataProvider calculates forecastedBalance and planned impacts properly',
    () async {
      final period = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );

      final realAccounts = [
        RealAccount(
          id: 'r1',
          ownerId: 'user_123',
          name: 'My Bank',
          balance: 500,
        ),
      ];

      final virtualAccounts = [
        VirtualAccount(
          id: 'v1',
          userId: 'user_123',
          realAccountId: 'r1',
          name: 'Groceries',
          balance: 100, // endBalance will be this
          type: VirtualAccountType.userBudget,
        ),
      ];

      final transactions = [
        // Completed Expense in period (-20)
        TransactionModel(
          id: 't1',
          ownerId: 'user_123',
          realAccountId: 'r1',
          amount: -20,
          type: TransactionType.debit,
          transactionDate: DateTime(2026, 1, 10),
          step: TransactionStep.completed,
          splits: [TransactionSplit(virtualAccountId: 'v1', amount: -20)],
        ),
        // Pending Income in period (+100)
        TransactionModel(
          id: 't2',
          ownerId: 'user_123',
          realAccountId: 'r1',
          amount: 100,
          type: TransactionType.credit,
          transactionDate: DateTime(2026, 1, 15),
          step: TransactionStep.pending,
          splits: [TransactionSplit(virtualAccountId: 'v1', amount: 100)],
        ),
        // Planned Expense in period (-50) -> Should affect plannedExpense
        TransactionModel(
          id: 't3',
          ownerId: 'user_123',
          realAccountId: 'r1',
          amount: -50,
          type: TransactionType.debit,
          transactionDate: DateTime(2026, 1, 20),
          step: TransactionStep.planned,
          splits: [TransactionSplit(virtualAccountId: 'v1', amount: -50)],
        ),
        // Scheduled Income in period (+200) -> Should affect plannedIncome
        TransactionModel(
          id: 't4',
          ownerId: 'user_123',
          realAccountId: 'r1',
          amount: 200,
          type: TransactionType.credit,
          transactionDate: DateTime(2026, 1, 25),
          step: TransactionStep.scheduled,
          splits: [TransactionSplit(virtualAccountId: 'v1', amount: 200)],
        ),
        // Out of period transaction - impacts start balance but not period tracking
        TransactionModel(
          id: 't5',
          ownerId: 'user_123',
          realAccountId: 'r1',
          amount: -30,
          type: TransactionType.debit,
          transactionDate: DateTime(2025, 12, 10),
          step: TransactionStep.completed,
          splits: [TransactionSplit(virtualAccountId: 'v1', amount: -30)],
        ),
      ];

      when(
        mockTxRepo.watchTransactions('user_123'),
      ).thenAnswer((_) => Stream.value(transactions));

      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
          transactionRepositoryProvider.overrideWithValue(mockTxRepo),
          realAccountsProvider.overrideWith(
            (ref) => Stream.value(realAccounts),
          ),
          allVirtualAccountsProvider.overrideWith(
            (ref) => Stream.value(virtualAccounts),
          ),
        ],
      );

      // Act
      final resumeData = await container.read(
        resumeDataProvider(period).future,
      );

      // Assert
      expect(resumeData.envelopeStats.length, 1);
      final stat = resumeData.envelopeStats.first;

      expect(stat.income, 100.0);
      expect(stat.expense, -20.0);
      expect(stat.plannedIncome, 200.0);
      expect(stat.plannedExpense, -50.0);

      // startBalance = endBalance(100) - (income + expense) = 100 - (80) = 20
      expect(stat.endBalance, 100.0);
      expect(stat.startBalance, 20.0);

      // forecasted = endBalance(100) + plannedIncome(200) + plannedExpense(-50) = 250
      expect(stat.forecastedBalance, 250.0);
    },
  );
}
