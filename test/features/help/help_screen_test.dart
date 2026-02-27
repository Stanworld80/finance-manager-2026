import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_manager_2026/features/help/presentation/help_screen.dart';

void main() {
  testWidgets('HelpScreen should display tabs and content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpScreen()));

    // Verify AppBar Title
    expect(find.text("Centre d'Aide"), findsOneWidget);

    // Verify Tabs
    expect(find.text("Concepts"), findsOneWidget);
    expect(find.text("Guide"), findsOneWidget);
    expect(find.text("Méthode"), findsOneWidget);

    // Verify initial tab content (Concepts)
    expect(find.text("Comptes Réels"), findsOneWidget);
    expect(find.text("États d'une Transaction"), findsOneWidget);

    // Switch to Guide Tab
    await tester.tap(find.text("Guide"));
    await tester.pumpAndSettle();
    expect(find.text("1. Ajouter un Revenu"), findsOneWidget);

    // Switch to Méthode Tab
    await tester.tap(find.text("Méthode"));
    await tester.pumpAndSettle();
    expect(find.text("La Méthode des Enveloppes"), findsOneWidget);
    expect(
      find.text("💰 Solde Banque = 📂 Somme des Enveloppes"),
      findsOneWidget,
    );
  });
}
