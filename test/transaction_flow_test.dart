import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_manager_2026/app.dart';
import 'package:finance_manager_2026/core/providers.dart';
import 'package:finance_manager_2026/features/dashboard/presentation/dashboard_screen.dart';
import 'package:finance_manager_2026/features/transactions/data/transaction_providers.dart';
import 'package:finance_manager_2026/features/accounts/data/account_providers.dart';
import 'package:finance_manager_2026/features/transactions/domain/transaction_model.dart';
import 'package:finance_manager_2026/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --------------------------------------------------------------------------
// Mocks
// --------------------------------------------------------------------------

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => FakeUser();

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(FakeUser());
  }
}

class FakeUser extends Fake implements User {
  @override
  String get uid => 'test_user_id';

  @override
  String get displayName => 'Test User';
}

final mockTx = TransactionModel(
  id: 'tx_123',
  ownerId: 'test_user_id',
  realAccountId: 'acc_123',
  amount: -50.0,
  label: 'Groceries',
  type: TransactionType.debit, // Using 'debit' as 'expense'
  status: TransactionStatus.completed,
  transactionDate: DateTime.now(),
  category: 'Food',
  note: 'Weekly shopping',
);

// --------------------------------------------------------------------------
// Integration Test
// --------------------------------------------------------------------------
void main() {
  testWidgets('Transaction Flow: View Detail', (tester) async {
    // 0. Setup SharedPrefs
    SharedPreferences.setMockInitialValues({});

    // 1. Pump the App
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(FakeFirebaseAuth()),
          realAccountsProvider.overrideWith((ref) => Stream.value([])),
          recentTransactionsProvider.overrideWith(
            (ref) => Stream.value([mockTx]),
          ),
          transactionByIdProvider(
            'tx_123',
          ).overrideWith((ref) => Stream.value(mockTx)),
        ],
        child: const FinanceManagerApp(),
      ),
    );

    // 2. Wait for app to load
    await tester.pumpAndSettle();

    // 3. Verify Dashboard shows the transaction
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('-50.00 €'), findsOneWidget);

    // 4. Tap the transaction
    await tester.tap(find.text('Groceries'));

    // 5. Wait for navigation
    await tester.pumpAndSettle();

    // 6. Verify Detail Screen matches
    expect(find.byType(TransactionDetailScreen), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Weekly shopping'), findsOneWidget); // Note
    expect(find.text('Food'), findsOneWidget); // Category
    expect(find.text('-50.00 €'), findsOneWidget);

    // 7. Verify Delete Button exists
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}
