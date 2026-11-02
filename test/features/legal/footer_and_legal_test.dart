import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:finance_manager_2026/core/providers.dart';
import 'package:finance_manager_2026/core/presentation/widgets/app_footer.dart';
import 'package:finance_manager_2026/features/legal/presentation/legal_screen.dart';

void main() {
  testWidgets('AppFooter displays version, build date, links and copyright', (
    WidgetTester tester,
  ) async {
    final fakePackageInfo = PackageInfo(
      appName: 'Finance Manager 2026',
      packageName: 'com.stanislasselle.financemanager2026',
      version: '1.1.4',
      buildNumber: '458',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packageInfoProvider.overrideWith((ref) => Future.value(fakePackageInfo)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(),
            bottomNavigationBar: AppFooter(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Version: v1.1.4#458'), findsOneWidget);
    expect(find.text('Aide'), findsOneWidget);
    expect(find.text('Accessibilité : non conforme'), findsOneWidget);
    expect(find.text('Mentions légales'), findsOneWidget);
    expect(find.text('Politique de confidentialité'), findsOneWidget);
    expect(
      find.text('©2026 Stanislas Selle Informatique'),
      findsOneWidget,
    );

    // Tap Mentions légales link and verify navigation
    await tester.tap(find.text('Mentions légales'));
    await tester.pumpAndSettle();

    expect(find.text('Informations Légales & Annexes'), findsOneWidget);
    expect(find.text("Éditeur de l'application"), findsOneWidget);
  });

  testWidgets('LegalScreen displays all legal tabs and content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LegalScreen(initialSection: 'accessibility'),
      ),
    );

    // Initial tab: Accessibilité
    expect(find.text("Déclaration d'accessibilité"), findsOneWidget);
    expect(find.text('État de conformité : Non conforme'), findsOneWidget);

    // Switch to Politique de confidentialité
    await tester.tap(find.text('Politique de confidentialité'));
    await tester.pumpAndSettle();
    expect(
      find.text('Politique de confidentialité (RGPD)'),
      findsOneWidget,
    );

    // Switch to CGU
    await tester.tap(find.text('CGU'));
    await tester.pumpAndSettle();
    expect(
      find.text("Conditions Générales d'Utilisation"),
      findsOneWidget,
    );
  });
}

