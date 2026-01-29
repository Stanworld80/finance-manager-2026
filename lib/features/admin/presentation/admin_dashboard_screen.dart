import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Playground'),
        backgroundColor: Colors.red.withOpacity(0.8),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminCard(
            title: 'Design System',
            icon: Icons.palette,
            description: 'Test UI components, typography, and themes.',
            onTap: () => context.push('/admin/design'),
          ),
          const SizedBox(height: 16),
          _AdminCard(
            title: 'Data Management',
            icon: Icons.storage,
            description: 'Seed or Reset database data.',
            onTap: () => context.push('/admin/data'),
          ),
          const SizedBox(height: 16),
          _AdminCard(
            title: 'API Lab',
            icon: Icons.science,
            description: 'Test Cloud Functions and Gemini integration.',
            onTap: () => context.push('/admin/api'),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const _AdminCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
