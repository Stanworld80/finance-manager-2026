import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/theme_provider.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStyle = ref.watch(themeStyleProvider);
    final currentMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Préférences & Apparence")),
      body: ListView(
        children: [
          _buildSectionHeader(context, "Thème"),
          RadioGroup<ThemeMode>(
            groupValue: currentMode,
            onChanged: (val) => ref
                .read(themeModeControllerProvider.notifier)
                .setMode(val!),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text("Système (Automatique)"),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: const Text("Clair (Light)"),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: const Text("Sombre (Dark)"),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),

          const Divider(),
          _buildSectionHeader(context, "Esthétique"),

          _buildStyleTile(
            context,
            ref,
            style: AppStyle.defaults,
            label: "Défaut (Bleu Standard)",
            color: Colors.blue,
            groupValue: currentStyle,
          ),
          _buildStyleTile(
            context,
            ref,
            style: AppStyle.banking,
            label: "Banque (Bleu Marine & Or)",
            color: const Color(0xFF0D47A1),
            groupValue: currentStyle,
          ),
          _buildStyleTile(
            context,
            ref,
            style: AppStyle.sky,
            label: "Ciel (Bleu clair & Cyan)",
            color: const Color(0xFF03A9F4),
            groupValue: currentStyle,
          ),
          _buildStyleTile(
            context,
            ref,
            style: AppStyle.pastel,
            label: "Pastel (Douceur)",
            color: const Color(0xFFF48FB1),
            groupValue: currentStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStyleTile(
    BuildContext context,
    WidgetRef ref, {
    required AppStyle style,
    required String label,
    required Color color,
    required AppStyle groupValue,
  }) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, radius: 12),
      title: Text(label),
      trailing: groupValue == style
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        ref.read(themeStyleProvider.notifier).setStyle(style);
      },
    );
  }
}
