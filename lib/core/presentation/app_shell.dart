import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  final String currentLocation;

  const AppShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context, ref),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: !isDesktop ? _buildBottomNav(context) : null,
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.05),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.account_balance_wallet,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(height: 10),
                Text(
                  'Finance Manager',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 40),
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  isSelected: currentLocation == '/',
                  onTap: () => context.go('/'),
                ),
                _SidebarItem(
                  icon: Icons.account_balance_outlined,
                  label: 'Comptes',
                  isSelected: currentLocation.contains('/account'),
                  onTap: () {}, // Future feature
                ),
                _SidebarItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Échéanciers',
                  isSelected: currentLocation == '/recurring',
                  onTap: () => context.go('/recurring'),
                ),
                _SidebarItem(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin',
                  isSelected: currentLocation.contains('/admin'),
                  onTap: () => context.go('/admin'),
                ),
                const Spacer(),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: 'Paramètres',
                  isSelected: currentLocation == '/preferences',
                  onTap: () => context.go('/preferences'),
                ),
                const Divider(color: Colors.white10),
                _SidebarItem(
                  icon: Icons.logout,
                  label: 'Déconnexion',
                  isSelected: false,
                  onTap: () => ref.read(firebaseAuthProvider).signOut(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final items = [
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Admin',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Prefs'),
    ];

    int currentIndex = 0;
    if (currentLocation.contains('/admin')) currentIndex = 1;
    if (currentLocation == '/preferences') currentIndex = 2;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 0) context.go('/');
        if (index == 1) context.go('/admin');
        if (index == 2) context.go('/preferences');
      },
      items: items,
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.blue : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
