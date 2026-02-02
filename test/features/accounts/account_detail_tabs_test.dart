import 'package:finance_manager_2026/features/accounts/presentation/account_detail_screen.dart';
import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';
import 'package:finance_manager_2026/features/accounts/data/account_providers.dart';
import 'package:finance_manager_2026/features/transactions/data/transaction_repository.dart';
import 'package:finance_manager_2026/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock dependencies if needed, or use overrides with fake data.
// Since AccountDetailScreen uses AsyncValue, we can override providers.

void main() {
  testWidgets('AccountDetailScreen shows Envelopes and Transactions tabs', (
    tester,
  ) async {
    final accountId = 'acc1';
    final account = RealAccount(
      id: accountId,
      ownerId: 'u1',
      name: 'Test Account',
      balance: 100,
    );

    // Override providers
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          realAccountsProvider.overrideWith((ref) => Stream.value([account])),
          virtualAccountsProvider(
            accountId,
          ).overrideWith((ref) => Stream.value([])),
          accountTransactionsProvider(
            accountId,
          ).overrideWith((ref) async => []),
          // We need to override auth provider or ensure it doesn't crash?
          // The screen might need it for some checks, but typically providers handle the logic.
          // However, the providers use ref.read(firebaseAuthProvider), so we might need to mock it if they are instantiated.
          // But here we override the *result* providers (Stream/Future), so the body shouldn't call the service/repo logic that uses auth.
        ],
        child: MaterialApp(home: AccountDetailScreen(accountId: accountId)),
      ),
    );

    // Initial load
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: 100),
    ); // Allow AsyncValues to settle

    // Verify Tabs
    expect(find.text('Enveloppes'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);

    // Verify default tab (Envelopes) content
    expect(find.text('Aucune enveloppe créée'), findsOneWidget);

    // Switch tab
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();

    // Verify Transactions tab content (empty list)
    expect(find.text('Aucune transaction'), findsOneWidget);
  });
}
