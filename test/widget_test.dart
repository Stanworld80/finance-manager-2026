import 'package:flutter_test/flutter_test.dart';
import 'package:finance_manager_2026/app.dart';
import 'package:finance_manager_2026/core/environment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize Environment for test
    Environment.init(AppFlavor.dev);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: FinanceManagerApp()));

    // Verify that our title is present.
    expect(find.text('Finance Manager 2026'), findsOneWidget);
    expect(find.text('Coming Soon: Dashboard'), findsOneWidget);
  });
}
