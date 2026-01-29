import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'features/admin/presentation/admin_dashboard_screen.dart';
import 'features/admin/presentation/pages/data_management_page.dart';
import 'features/admin/presentation/pages/api_lab_page.dart';
import 'features/admin/presentation/pages/design_system_page.dart';
import 'core/environment.dart';

// Placeholder for Home/Login screens
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance Manager 2026')),
      body: const Center(child: Text('Coming Soon: Dashboard')),
      floatingActionButton: Environment.isDev
          ? FloatingActionButton(
              onPressed: () => context.push('/admin'),
              backgroundColor: Colors.red,
              child: const Icon(Icons.build),
            )
          : null,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
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
  ],
);

class FinanceManagerApp extends ConsumerWidget {
  const FinanceManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Finance Manager 2026',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode
          .system, // Default to system, can be overridden by user pref later
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
