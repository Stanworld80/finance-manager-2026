import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_manager_2026/main_dev.dart' as app;

const testEmail = 'comptetechnique001@stanworld.org';
const testPassword = 'Tester=2026';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Debug permissions', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final signInFinder = find.text('Sign in');
    final textFieldFinder = find.byType(TextField);

    if (signInFinder.evaluate().isNotEmpty ||
        textFieldFinder.evaluate().isNotEmpty) {
      final emailField = textFieldFinder.at(0);
      await tester.enterText(emailField, testEmail);
      await tester.pump();
      final passwordField = textFieldFinder.at(1);
      await tester.enterText(passwordField, testPassword);
      await tester.pump();
      await tester.tap(signInFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }

    final user = FirebaseAuth.instance.currentUser;
    print('USER UID: \${user?.uid}');
    if (user == null) {
      print('FAILED TO LOGIN');
      return;
    }

    try {
      print('Querying accounts collection for user \${user.uid}');
      final query = await FirebaseFirestore.instance
          .collection('accounts')
          .where('accessibleUserIds', arrayContains: user.uid)
          .get();
      print('SUCCESS: Found \${query.docs.length} accounts');
      for (var doc in query.docs) {
        print('- Account: \${doc.id} | data: \${doc.data()}');
      }
    } catch (e) {
      print('FAIL Accounts: \$e');
    }

    try {
      print('Querying virtual_accounts collection ...');
      final query = await FirebaseFirestore.instance
          .collectionGroup('virtual_accounts')
          .where('userId', isEqualTo: user.uid)
          .get();
      print('SUCCESS: Found \${query.docs.length} virtual accounts');
    } catch (e) {
      print('FAIL Virtual Accounts: \$e');
    }

    try {
      print('Querying transactions collectionGroup ...');
      final query = await FirebaseFirestore.instance
          .collectionGroup('transactions')
          .where('ownerId', isEqualTo: user.uid)
          .orderBy('transactionDate', descending: true)
          .get();
      print('SUCCESS: Found \${query.docs.length} transactions');
    } catch (e) {
      print('FAIL Transactions: \$e');
    }
  });
}
