import 'package:finance_manager_2026/features/accounts/data/account_repository.dart';
import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';
import 'package:finance_manager_2026/features/transactions/application/transaction_service.dart';
import 'package:finance_manager_2026/features/transactions/data/transaction_repository.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_manager_2026/core/providers.dart';

import 'transaction_service_provision_test.mocks.dart';

@GenerateMocks([TransactionRepository, AccountRepository, FirebaseAuth, User])
void main() {
  late MockTransactionRepository mockRepository;
  late MockAccountRepository mockAccountRepo;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late ProviderContainer container;

  final committedAccount = VirtualAccount(
    id: 'committed_1',
    userId: 'user_123',
    realAccountId: 'real_1',
    name: 'Solde Engagé',
    type: VirtualAccountType.systemCommitted,
    balance: 0,
  );

  setUp(() {
    mockRepository = MockTransactionRepository();
    mockAccountRepo = MockAccountRepository();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('user_123');
    when(
      mockAccountRepo.getVirtualAccountByType(
        any,
        any,
        VirtualAccountType.systemCommitted,
      ),
    ).thenAnswer((_) async => committedAccount);
    when(
      mockRepository.updateTransaction(any, any, any),
    ).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepository),
        firebaseAuthProvider.overrideWithValue(mockAuth),
        accountRepositoryProvider.overrideWithValue(mockAccountRepo),
      ],
    );
  });

  test(
    'provisionTransaction changes step to pending and swaps counterparty',
    () async {
      final service = container.read(transactionServiceProvider);

      // Initial transaction (planned)
      final originalTx = TransactionModel(
        id: 'tx_1',
        ownerId: 'user_123',
        realAccountId: 'real_1',
        amount: -50.0,
        type: TransactionType.debit,
        transactionDate: DateTime.now(),
        label: 'Planned Expense',
        status: TransactionStatus.none,
        step: TransactionStep.planned, // PLANNED
        splits: [
          TransactionSplit(virtualAccountId: 'virt_1', amount: -50.0),
          TransactionSplit(
            virtualAccountId: SystemAccounts.external,
            amount: 50.0,
          ),
        ],
      );

      // Act
      await service.provisionTransaction(originalTx);

      // Assert
      final captured = verify(
        mockRepository.updateTransaction(any, any, captureAny),
      ).captured;
      final updatedTx = captured.first as TransactionModel;

      expect(updatedTx.step, TransactionStep.pending);
      expect(updatedTx.provisionDate, isNotNull);

      // external split should be gone
      final externalSplit = updatedTx.splits.where(
        (s) => s.virtualAccountId == SystemAccounts.external,
      );
      expect(externalSplit.isEmpty, true);

      // committed split should now exist
      final committedSplit = updatedTx.splits.firstWhere(
        (s) => s.virtualAccountId == 'committed_1',
      );
      expect(committedSplit.amount, 50.0);

      // envelope split unchanged
      final envelopeSplit = updatedTx.splits.firstWhere(
        (s) => s.virtualAccountId == 'virt_1',
      );
      expect(envelopeSplit.amount, -50.0);

      expect(updatedTx.isBalanced, true);
    },
  );

  test(
    'confirmTransaction changes step to completed and swaps counterparty back',
    () async {
      final service = container.read(transactionServiceProvider);

      // Initial transaction (pending, already provisioned)
      final originalTx = TransactionModel(
        id: 'tx_2',
        ownerId: 'user_123',
        realAccountId: 'real_1',
        amount: -50.0,
        type: TransactionType.debit,
        transactionDate: DateTime.now(),
        label: 'Pending Expense',
        status: TransactionStatus.none,
        step: TransactionStep.pending,
        splits: [
          TransactionSplit(virtualAccountId: 'virt_1', amount: -50.0),
          TransactionSplit(virtualAccountId: 'committed_1', amount: 50.0),
        ],
      );

      // Act
      await service.confirmTransaction(originalTx);

      // Assert
      final captured = verify(
        mockRepository.updateTransaction(any, any, captureAny),
      ).captured;
      final updatedTx = captured.first as TransactionModel;

      expect(updatedTx.step, TransactionStep.completed);

      // external split should appear
      final externalSplit = updatedTx.splits.firstWhere(
        (s) => s.virtualAccountId == SystemAccounts.external,
      );
      expect(externalSplit.amount, 50.0);

      // committed split should disappear
      final committedSplit = updatedTx.splits.where(
        (s) => s.virtualAccountId == 'committed_1',
      );
      expect(committedSplit.isEmpty, true);

      // envelope unchanged
      final envelopeSplit = updatedTx.splits.firstWhere(
        (s) => s.virtualAccountId == 'virt_1',
      );
      expect(envelopeSplit.amount, -50.0);

      expect(updatedTx.isBalanced, true);
    },
  );

  test(
    'provisionTransaction does nothing if transaction is not planned/scheduled',
    () async {
      final service = container.read(transactionServiceProvider);

      final originalTx = TransactionModel(
        id: 'tx_3',
        ownerId: 'user_123',
        realAccountId: 'real_1',
        amount: -50.0,
        type: TransactionType.debit,
        transactionDate: DateTime.now(),
        step: TransactionStep.completed, // Already completed
        splits: [],
      );

      await service.provisionTransaction(originalTx);

      // updateTransaction should NOT be called
      verifyNever(mockRepository.updateTransaction(any, any, any));
    },
  );

  test(
    'confirmTransaction does nothing if transaction is not pending',
    () async {
      final service = container.read(transactionServiceProvider);

      final originalTx = TransactionModel(
        id: 'tx_4',
        ownerId: 'user_123',
        realAccountId: 'real_1',
        amount: -50.0,
        type: TransactionType.debit,
        transactionDate: DateTime.now(),
        step: TransactionStep.completed, // Not pending
        splits: [],
      );

      await service.confirmTransaction(originalTx);

      verifyNever(mockRepository.updateTransaction(any, any, any));
    },
  );
}
