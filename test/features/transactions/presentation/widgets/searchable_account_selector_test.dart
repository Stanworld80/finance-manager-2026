import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_manager_2026/features/transactions/presentation/widgets/searchable_account_selector.dart';
import 'package:finance_manager_2026/features/transactions/presentation/add_transaction_page.dart';
import 'package:finance_manager_2026/features/transactions/presentation/models/transaction_ui_models.dart';


void main() {
  final items = [
    SelectableAccount(id: "1", name: "Groceries", realAccountName: "Bank A"),
    SelectableAccount(id: "2", name: "Rent", realAccountName: "Bank B"),
    SelectableAccount(id: "3", name: "Salary", realAccountName: "Bank A"),
  ];

  testWidgets('SearchableAccountSelector shows selected account name', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchableAccountSelector(
            label: "Test Label",
            selectedAccount: items[0],
            items: items,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text("Groceries (Bank A)"), findsOneWidget);
  });

  testWidgets('SearchableAccountSelector opens search sheet and filters', (
    tester,
  ) async {
    SelectableAccount? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchableAccountSelector(
            label: "Test Label",
            selectedAccount: null,
            items: items,
            onChanged: (val) => selected = val,
          ),
        ),
      ),
    );

    // Tap to open search
    await tester.tap(find.text("Sélectionnez..."));
    await tester.pumpAndSettle();

    // Verify search sheet is open
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(ListTile, "Groceries"), findsOneWidget);
    expect(find.widgetWithText(ListTile, "Rent"), findsOneWidget);

    // Filter
    await tester.enterText(find.byType(TextField), "Rent");
    await tester.pumpAndSettle();

    expect(find.text("Groceries"), findsNothing);
    expect(find.widgetWithText(ListTile, "Rent"), findsOneWidget);

    // Select
    await tester.tap(find.widgetWithText(ListTile, "Rent"));
    await tester.pumpAndSettle();

    expect(selected?.name, "Rent");
  });
}
