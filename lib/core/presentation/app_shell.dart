import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../../features/accounts/data/account_providers.dart';
import '../../features/transactions/presentation/widgets/provision_dialog.dart';

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
    // Hook auto-repair so it runs silently in the background
    ref.watch(autoRepairLibreProvider);

    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Helper to safely extract current real account id from route
    String? currentAccountId;
    if (currentLocation.startsWith('/account/')) {
      final parts = currentLocation.split('/');
      if (parts.length > 2) {
        currentAccountId = parts[2];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDesktop ? '' : 'Finance Manager',
        ), // Sidebar has it on desktop
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          _buildShortcutButton(
            context: context,
            label: 'Revenu',
            icon: Icons.move_to_inbox,
            type: 'credit',
            color: Colors.green,
            accountId: currentAccountId,
          ),
          const SizedBox(width: 8),
          _buildShortcutButton(
            context: context,
            label: 'Dépense',
            icon: Icons.outbound,
            type: 'debit',
            color: Colors.red,
            accountId: currentAccountId,
          ),
          const SizedBox(width: 8),
          _buildShortcutButton(
            context: context,
            label: 'Virement',
            icon: Icons.swap_horiz,
            type: 'transfer',
            color: Colors.blue,
            accountId: currentAccountId,
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.savings_outlined, size: 16, color: Colors.purple),
            label: const Text('Provision'),
            surfaceTintColor: Colors.purple.withValues(alpha: 0.1),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ProvisionDialog(),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              if (isDesktop) _buildSidebar(context, ref),
              Expanded(child: child),
            ],
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop ? _buildBottomNav(context) : null,
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha: 0.05),
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
                  isSelected: currentLocation == '/upcoming',
                  onTap: () => context.go('/upcoming'),
                ),
                _SidebarItem(
                  icon: Icons.folder_special_outlined,
                  label: 'Projets',
                  isSelected: currentLocation.startsWith('/projects'),
                  onTap: () => context.go('/projects'),
                ),
                _SidebarItem(
                  icon: Icons.insights_outlined,
                  label: 'Résumé',
                  isSelected: currentLocation == '/resume',
                  onTap: () => context.go('/resume'),
                ),
                _SidebarItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Coach Financier',
                  isSelected: currentLocation == '/ai',
                  onTap: () => context.go('/ai'),
                ),
                _SidebarItem(
                  icon: Icons.public_outlined,
                  label: 'Exterieur',
                  isSelected: currentLocation == '/exterieur',
                  onTap: () => context.go('/exterieur'),
                ),
                _SidebarItem(
                  icon: Icons.upload_file,
                  label: 'Import CSV',
                  isSelected: currentLocation == '/import',
                  onTap: () => context.go('/import'),
                ),
                _SidebarItem(
                  icon: Icons.help_outline,
                  label: 'Aide',
                  isSelected: currentLocation == '/help',
                  onTap: () => context.go('/help'),
                ),
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
                const SizedBox(height: 10),
                ref
                    .watch(packageInfoProvider)
                    .when(
                      data: (info) => Text(
                        "v${info.version} (${info.buildNumber})",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                const SizedBox(height: 16),
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

  Widget _buildShortcutButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String type,
    required Color color,
    String? accountId,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      surfaceTintColor: color.withValues(alpha: 0.1),
      onPressed: () {
        final query = {'type': type};
        if (accountId != null) {
          query['accountId'] = accountId;
        }
        final uri = Uri(path: '/add-transaction', queryParameters: query);
        context.push(uri.toString());
      },
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
                ? Colors.blue.withValues(alpha: 0.1)
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
