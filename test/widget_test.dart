import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_manager_2026/app.dart';
import 'package:finance_manager_2026/core/environment.dart';
import 'package:finance_manager_2026/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';

// Generate a MockFirebaseAuth class
@GenerateNiceMocks([MockSpec<FirebaseAuth>(), MockSpec<User>()])
import 'widget_test.mocks.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize Environment for test
    Environment.init(AppFlavor.dev);

    final mockAuth = MockFirebaseAuth();

    // Stub authStateChanges to return an empty stream (not logged in)
    when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));
    when(mockAuth.currentUser).thenReturn(null);

    // Build our app and trigger a frame.
    // We override the firebaseAuthProvider to return our mock
    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseAuthProvider.overrideWithValue(mockAuth)],
        child: const FinanceManagerApp(),
      ),
    );

    // Just verify the MaterialApp is there.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
