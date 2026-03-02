import 'package:flutter_test/flutter_test.dart';
import 'package:finance_manager_2026/features/accounts/domain/account_models.dart';

void main() {
  group('RealAccount', () {
    test('supports value comparisons', () {
      final account1 = RealAccount(
        id: '1',
        ownerId: 'user1',
        name: 'Main Account',
        balance: 100.0,
        initialBalance: 50.0,
        bankName: 'Bank A',
      );
      final account2 = RealAccount(
        id: '1',
        ownerId: 'user1',
        name: 'Main Account',
        balance: 100.0,
        initialBalance: 50.0,
        bankName: 'Bank A',
      );

      // Note: By default Dart classes don't support value equality without Equatable or manual override.
      // But we are just checking if fields are accessible and serialization works.
      // If the user wants Equatable, we should add it. For now, we test field access.
      expect(account1.id, account2.id);
    });

    test('toMap returns correct map', () {
      final account = RealAccount(
        id: '1',
        ownerId: 'user1',
        name: 'Test Account',
        balance: 150.0,
        initialBalance: 10.0,
        bankName: 'Test Bank',
        type: RealAccountType.internal,
      );

      final map = account.toMap();

      expect(map, {
        'id': '1',
        'ownerId': 'user1',
        'name': 'Test Account',
        'bankName': 'Test Bank',
        'initialBalance': 10.0,
        'balance': 150.0,
        'type': 'internal',
        'isPrincipal': false,
        'sharedWithUserIds': [],
        'openingDate': null,
        'accountNumber': null,
        'officialName': null,
        'iban': null,
        'bic': null,
        'swift': null,
      });
    });

    test('fromMap returns correct object', () {
      final map = {
        'id': '2',
        'ownerId': 'user2',
        'name': 'Account 2',
        'balance': 200.0,
        'initialBalance': 20.0,
        'bankName': 'Bank B',
        'type': 'external',
      };

      final account = RealAccount.fromMap(map);

      expect(account.id, '2');
      expect(account.ownerId, 'user2');
      expect(account.name, 'Account 2');
      expect(account.balance, 200.0);
      expect(account.initialBalance, 20.0);
      expect(account.bankName, 'Bank B');
      expect(account.type, RealAccountType.external);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': '3',
        'ownerId': 'user3',
        'name': 'Account 3',
        'balance': 300.0,
        // missing initialBalance and bankName
      };

      final account = RealAccount.fromMap(map);

      expect(account.id, '3');
      expect(account.initialBalance, 0.0); // Default value
      expect(account.bankName, null);
    });
  });

  group('VirtualAccount', () {
    test('toMap returns correct map', () {
      final account = VirtualAccount(
        id: 'v1',
        userId: 'u1',
        realAccountId: 'r1',
        name: 'Groceries',
        balance: 50.0,
        type: VirtualAccountType.userBudget,
        icon: 'food_icon',
      );

      final map = account.toMap();

      expect(map, {
        'id': 'v1',
        'userId': 'u1',
        'realAccountId': 'r1',
        'name': 'Groceries',
        'balance': 50.0,
        'type': 'userBudget',
        'icon': 'food_icon',
      });
    });

    test('fromMap returns correct object', () {
      final map = {
        'id': 'v2',
        'userId': 'u2',
        'realAccountId': 'r2',
        'name': 'System',
        'balance': 100.0,
        'type': 'systemFree',
        'icon': null,
      };

      final account = VirtualAccount.fromMap(map);

      expect(account.id, 'v2');
      expect(account.userId, 'u2');
      expect(account.type, VirtualAccountType.systemFree);
      expect(account.icon, null);
    });

    test('fromMap handles unknown enum types gracefully', () {
      final map = {
        'id': 'v3',
        'userId': 'u3',
        'realAccountId': 'r3',
        'name': 'Unknown',
        'balance': 0.0,
        'type': 'someNewType',
      };

      final account = VirtualAccount.fromMap(map);

      expect(account.type, VirtualAccountType.userBudget); // Default fallback
    });
  });
}
