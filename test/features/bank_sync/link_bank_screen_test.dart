import 'package:finance_manager_2026/features/accounts/data/account_providers.dart';
import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';
import 'package:finance_manager_2026/features/bank_sync/data/bank_sync_providers.dart';
import 'package:finance_manager_2026/features/bank_sync/presentation/link_bank_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'LinkBankScreen displays Enable Banking ASPSP catalog and completes simulated auth flow',
      (WidgetTester tester) async {
    final testRepo = BankSyncRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bankSyncRepositoryProvider.overrideWithValue(testRepo),
          realAccountsProvider.overrideWith(
            (ref) => Stream.value(const <RealAccount>[]),
          ),
          allVirtualAccountsProvider.overrideWith(
            (ref) => Stream.value(const <VirtualAccount>[]),
          ),
        ],
        child: const MaterialApp(
          home: LinkBankScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title and tabs
    expect(find.text('Connecter une Banque'), findsOneWidget);
    expect(find.text('Banques (ASPSP)'), findsOneWidget);
    expect(find.text('Configuration API'), findsOneWidget);

    // Verify simulated French ASPSP list is displayed
    expect(find.text('Crédit Agricole'), findsOneWidget);
    expect(find.text('BoursoBank (ex Boursorama)'), findsOneWidget);

    // Tap on Crédit Agricole to start DSP2 authorization
    await tester.tap(find.text('Crédit Agricole'));
    await tester.pumpAndSettle();

    // Verify DSP2 Authorization dialog opens
    expect(
      find.text('Autorisation DSP2 - Crédit Agricole'),
      findsOneWidget,
    );
    expect(
      find.text('Simuler la validation bancaire'),
      findsOneWidget,
    );

    // Confirm simulated bank authentication
    await tester.tap(find.text('Simuler la validation bancaire'));
    await tester.pumpAndSettle();

    // Switch to "Comptes reliés (1)" tab
    await tester.tap(find.text('Comptes reliés (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Crédit Agricole (FR)'), findsOneWidget);
    expect(find.text('Compte Courant Crédit Agricole'), findsOneWidget);
    expect(find.text('Synchroniser les transactions'), findsOneWidget);
  });
}
