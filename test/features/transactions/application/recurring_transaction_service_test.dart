import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_manager_2026/core/providers.dart';
import 'package:finance_manager_2026/features/transactions/application/recurring_transaction_service.dart';
import 'package:finance_manager_2026/features/transactions/data/recurring_transaction_repository.dart';
import 'package:finance_manager_2026/features/transactions/domain/recurring_transaction_model.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'recurring_transaction_service_test.mocks.dart';

@GenerateMocks([RecurringTransactionRepository, FirebaseAuth, User])
void main() {
  late MockRecurringTransactionRepository mockRepo;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late ProviderContainer container;
  late RecurringTransactionService service;

  setUp(() {
    mockRepo = MockRecurringTransactionRepository();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('user1');

    container = ProviderContainer(
      overrides: [
        recurringTransactionRepositoryProvider.overrideWith((ref) => mockRepo),
        firebaseAuthProvider.overrideWith((ref) => mockAuth),
      ],
    );

    service = container.read(recurringTransactionServiceProvider);
  });

  tearDown(() {
    container.dispose();
  });

  group('generateOccurrences', () {
    test('Generates monthly occurrences correctly', () async {
      final startDate = DateTime(2026, 1, 1);
      final recurrence = RecurringTransaction(
        id: 'rec1',
        ownerId: 'user1',
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: startDate,
        nextOccurrence: startDate, // First one is due
        realAccountId: 'real1',
        amount: 50.0,
        label: 'Monthly Sub',
        type: TransactionType.debit,
      );

      when(
        mockRepo.getRecurringTransactions('user1'),
      ).thenAnswer((_) async => [recurrence]);

      // Project for 3 months
      final untilDate = DateTime(2026, 3, 15);
      final projections = await service.generateOccurrences(untilDate);

      expect(projections.length, 3);

      // 1st: Jan 1
      expect(projections[0].transactionDate, DateTime(2026, 1, 1));
      expect(projections[0].amount, 50.0);

      // 2nd: Feb 1
      expect(projections[1].transactionDate, DateTime(2026, 2, 1));

      // 3rd: Mar 1
      expect(projections[2].transactionDate, DateTime(2026, 3, 1));
    });

    test('Stops at endDate', () async {
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 2, 1); // Only Jan and Feb
      final recurrence = RecurringTransaction(
        id: 'rec1',
        ownerId: 'user1',
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: startDate,
        endDate: endDate,
        nextOccurrence: startDate,
        realAccountId: 'real1',
        amount: 50.0,
        label: 'Limited Sub',
        type: TransactionType.debit,
      );

      when(
        mockRepo.getRecurringTransactions('user1'),
      ).thenAnswer((_) async => [recurrence]);

      final untilDate = DateTime(2026, 5, 1);
      final projections = await service.generateOccurrences(untilDate);

      expect(projections.length, 2); // Jan 1, Feb 1
      expect(projections.last.transactionDate, endDate);
    });

    test('Respects nextOccurrence (skips past)', () async {
      final startDate = DateTime(2026, 1, 1);
      // Let's say we already processed Jan and Feb, so next is Mar 1
      final nextOccurrence = DateTime(2026, 3, 1);

      final recurrence = RecurringTransaction(
        id: 'rec1',
        ownerId: 'user1',
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: startDate,
        nextOccurrence: nextOccurrence,
        realAccountId: 'real1',
        amount: 50.0,
        label: 'Existing Sub',
        type: TransactionType.debit,
      );

      when(
        mockRepo.getRecurringTransactions('user1'),
      ).thenAnswer((_) async => [recurrence]);

      final untilDate = DateTime(2026, 4, 15);
      final projections = await service.generateOccurrences(untilDate);

      // Should generate Mar 1, Apr 1
      expect(projections.length, 2);
      expect(projections[0].transactionDate, DateTime(2026, 3, 1));
      expect(projections[1].transactionDate, DateTime(2026, 4, 1));
    });
  });
}
