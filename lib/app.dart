import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme_provider.dart';
import 'features/admin/presentation/admin_dashboard_screen.dart';
import 'features/admin/presentation/pages/data_management_page.dart';
import 'features/admin/presentation/pages/api_lab_page.dart';
import 'features/admin/presentation/pages/design_system_page.dart';
import 'features/preferences/presentation/preferences_screen.dart';

import 'dart:async';

import 'package:finance_manager_2026/features/auth/presentation/auth_gate.dart';

import 'features/auth/presentation/profile_page.dart';
import 'features/auth/data/auth_providers.dart';

import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/transactions/presentation/add_transaction_page.dart';
import 'features/transactions/presentation/transaction_detail_screen.dart';
import 'features/bank_sync/presentation/link_bank_screen.dart';
import 'features/help/presentation/help_screen.dart';
import 'features/accounts/presentation/account_detail_screen.dart';
import 'features/projects/presentation/projects_dashboard_screen.dart';
import 'features/projects/presentation/project_detail_screen.dart';
import 'features/resume/presentation/resume_screen.dart';
import 'features/transactions/presentation/recurrence_list_page.dart';
import 'features/transactions/presentation/add_recurrence_page.dart';
import 'features/ai/presentation/ai_chat_screen.dart';
import 'features/import/presentation/import_screen.dart';
import 'features/transactions/presentation/transaction_list_page.dart';

import 'core/providers.dart';

import 'core/presentation/app_shell.dart';

//...

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
    redirect: (context, state) {
      final isLoggedIn = auth.currentUser != null;
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
      GoRoute(path: '/login', builder: (context, state) => const AuthGate()),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(currentLocation: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const UserProfilePage(),
          ),
          GoRoute(
            path: '/add-transaction',
            builder: (context, state) {
              final typeParam = state.uri.queryParameters['type'];
              final accountIdParam = state.uri.queryParameters['accountId'];
              return AddTransactionPage(
                initialType: typeParam,
                initialRealAccountId: accountIdParam,
              );
            },
          ),
          GoRoute(
            path: '/recurring',
            builder: (context, state) => const RecurrenceListPage(),
          ),
          GoRoute(
            path: '/recurring/add',
            builder: (context, state) => const AddRecurrencePage(),
          ),
          GoRoute(
            path: '/transaction/:id',
            builder: (context, state) => TransactionDetailScreen(
              transactionId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/account/:id',
            builder: (context, state) =>
                AccountDetailScreen(accountId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectsDashboardScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ProjectDetailScreen(projectId: state.pathParameters['id']!),
              ),
            ],
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
              GoRoute(
                path: 'api',
                builder: (context, state) => const ApiLabPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/link-bank',
            builder: (context, state) => const LinkBankScreen(),
          ),
          GoRoute(
            path: '/help',
            builder: (context, state) => const HelpScreen(),
          ),
          GoRoute(
            path: '/preferences',
            builder: (context, state) => const PreferencesScreen(),
          ),
          GoRoute(
            path: '/ai',
            builder: (context, state) => const AiChatScreen(),
          ),
          GoRoute(
            path: '/import',
            builder: (context, state) => const ImportScreen(),
          ),
          GoRoute(
            path: '/resume',
            builder: (context, state) => const ResumeScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionListPage(),
          ),
        ],
      ),
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
    // Start syncing the user profile once authenticated
    ref.watch(userProfileSyncProvider);

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);

    return MaterialApp.router(
      title: 'Finance Manager 2026',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
