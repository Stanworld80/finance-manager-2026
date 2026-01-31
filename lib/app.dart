import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'features/admin/presentation/admin_dashboard_screen.dart';
import 'features/admin/presentation/pages/data_management_page.dart';
import 'features/admin/presentation/pages/api_lab_page.dart';
import 'features/admin/presentation/pages/design_system_page.dart';

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_manager_2026/features/auth/presentation/auth_gate.dart';

import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/transactions/presentation/add_transaction_page.dart';
import 'features/bank_sync/presentation/link_bank_screen.dart';
import 'features/help/presentation/help_screen.dart';
import 'features/accounts/presentation/account_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoggingIn = state.uri.path == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/login', builder: (context, state) => const AuthGate()),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) => const AddTransactionPage(),
      ),
      GoRoute(
        path: '/account/:id',
        builder: (context, state) =>
            AccountDetailScreen(accountId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'design',
            builder: (context, state) => const DesignSystemPage(),
          ),
          GoRoute(
            path: 'data',
            builder: (context, state) => const DataManagementPage(),
          ),
          GoRoute(path: 'api', builder: (context, state) => const ApiLabPage()),
        ],
      ),
      GoRoute(
        path: '/link-bank',
        builder: (context, state) => const LinkBankScreen(),
      ),
      GoRoute(path: '/help', builder: (context, state) => const HelpScreen()),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class FinanceManagerApp extends ConsumerWidget {
  const FinanceManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Finance Manager 2026',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
