import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_manager_2026/app.dart';
import 'package:finance_manager_2026/core/environment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize Environment for test
    Environment.init(AppFlavor.dev);

    // Build our app and trigger a frame.
    // NOTE: We wrap in ProviderScope. Firebase is not mocked, so this might still fail if AuthGate tries to use it immediately.
    // Ideally we should override providers here.
    await tester.pumpWidget(const ProviderScope(child: FinanceManagerApp()));

    // Just verify the MaterialApp is there. Validating contents requires complex mocking.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
