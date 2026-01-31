import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_manager_2026/core/providers.dart';
import 'package:finance_manager_2026/app.dart';
import 'package:finance_manager_2026/features/dashboard/presentation/dashboard_screen.dart';

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Integration: Real Login and Dashboard Access', (tester) async {
    // 1. Start the app (this will show the AuthGate/SignInScreen)
    await tester.pumpWidget(const ProviderScope(child: FinanceManagerApp()));
    await tester.pumpAndSettle();

    // 2. Find Login Fields (Firebase UI uses specific Types/Keys)
    // Looking for Email field
    final emailField = find.descendant(
      of: find.byType(TextField),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText?.contains('Email') == true,
      ),
    );

    // If simple find fails, try by type index (0 is email, 1 is password usually)
    await tester.enterText(
      find.byType(TextField).at(0),
      'comptetechnique001@stanworld.org',
    );
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.enterText(find.byType(TextField).at(1), 'Tester=2026');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // 3. Tap Sign In button
    // Firebase UI button usually has 'Sign in' or 'Se connecter' text.
    final signInButton = find.text('Sign in'); // Try English first
    final signInButtonFr = find.text('Se connecter');

    if (signInButton.evaluate().isNotEmpty) {
      await tester.tap(signInButton);
    } else if (signInButtonFr.evaluate().isNotEmpty) {
      await tester.tap(signInButtonFr);
    } else {
      // Fallback: try to find any ElevatedButton or FilledButton
      await tester.tap(find.byType(ElevatedButton).first);
    }

    // Wait for auth to complete and navigation to happen
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 4. Verify Dashboard
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Tableau de Bord'), findsOneWidget);

    // 5. Navigate to Admin to seed if needed (Bonus flow)
    // Assuming there's a way to get to admin dashboard
  });
}
