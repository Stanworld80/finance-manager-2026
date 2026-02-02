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

import 'transaction_service_split_test.mocks.dart';

@GenerateMocks([TransactionRepository, FirebaseAuth, User])
void main() {
  late MockTransactionRepository mockRepository;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockTransactionRepository();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('user_123');

    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepository),
        firebaseAuthProvider.overrideWithValue(mockAuth),
      ],
    );
  });

  test('addSplitTransaction creates balanced debit transaction', () async {
    final service = container.read(transactionServiceProvider);

    final realAccount = RealAccount(
      id: 'real_1',
      name: 'Bank',
      ownerId: 'user_123',
      balance: 0.0,
    );
    final envelope1 = VirtualAccount(
      id: 'virt_1',
      userId: 'user_123',
      realAccountId: 'real_1',
      name: 'Food',
      type: VirtualAccountType.userBudget,
      balance: 0,
    );
    final envelope2 = VirtualAccount(
      id: 'virt_2',
      userId: 'user_123',
      realAccountId: 'real_1',
      name: 'Home',
      type: VirtualAccountType.userBudget,
      balance: 0,
    );

    // Act
    await service.addSplitTransaction(
      totalAmount: 100.0,
      type: TransactionType.debit,
      label: 'Supermarket',
      date: DateTime.now(),
      realAccount: realAccount,
      splits: [
        (account: envelope1, amount: 60.0),
        (account: envelope2, amount: 40.0),
      ],
    );

    // Assert
    final captured = verify(
      mockRepository.createTransaction(any, captureAny),
    ).captured;
    final tx = captured.first as TransactionModel;

    expect(tx.amount, -100.0);
    expect(tx.splits.length, 3); // 2 envelopes + 1 external

    // Check envelopes (Debit = negative)
    final split1 = tx.splits.firstWhere((s) => s.virtualAccountId == 'virt_1');
    expect(split1.amount, -60.0);

    final split2 = tx.splits.firstWhere((s) => s.virtualAccountId == 'virt_2');
    expect(split2.amount, -40.0);

    // Check external (Credit = positive)
    final splitExt = tx.splits.firstWhere(
      (s) => s.virtualAccountId == SystemAccounts.external,
    );
    expect(splitExt.amount, 100.0);

    expect(tx.isBalanced, true);
  });

  test('addSplitTransaction throws if sum does not match total', () async {
    final service = container.read(transactionServiceProvider);

    final realAccount = RealAccount(
      id: 'real_1',
      name: 'Bank',
      ownerId: 'user_123',
      balance: 0.0,
    );
    final envelope1 = VirtualAccount(
      id: 'virt_1',
      userId: 'user_123',
      realAccountId: 'real_1',
      name: 'Food',
      type: VirtualAccountType.userBudget,
      balance: 0,
    );

    expect(
      () => service.addSplitTransaction(
        totalAmount: 100.0,
        type: TransactionType.debit,
        label: 'Fail',
        date: DateTime.now(),
        realAccount: realAccount,
        splits: [
          (account: envelope1, amount: 50.0), // Only 50
        ],
      ),
      throwsException,
    );
  });
}
