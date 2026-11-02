import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../build_info.dart';
import '../../providers.dart';
import '../../../features/help/presentation/help_screen.dart';
import '../../../features/legal/presentation/legal_screen.dart';

class AppFooter extends ConsumerWidget {
  const AppFooter({super.key});

  void _navigateTo(
    BuildContext context,
    String route,
    Widget fallbackScreen,
  ) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      final location = router.routeInformationProvider.value.uri.path;
      if (location != '/login') {
        context.go(route);
        return;
      }
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => fallbackScreen),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packageInfoAsync = ref.watch(packageInfoProvider);

    final versionString = packageInfoAsync.maybeWhen(
      data: (info) => BuildInfo.formatVersion(
        packageVersion: info.version,
        packageBuildNumber: info.buildNumber,
      ),
      orElse: () => BuildInfo.formatVersion(),
    );

    final textColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65) ??
            theme.hintColor;
    final textStyle = theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: textColor,
        ) ??
        TextStyle(fontSize: 11, color: textColor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          Text(
            'Version: $versionString',
            style: textStyle,
          ),
          _buildSeparator(textStyle),
          _FooterLink(
            label: 'Aide',
            style: textStyle,
            onTap: () => _navigateTo(
              context,
              '/help',
              const HelpScreen(),
            ),
          ),
          _buildSeparator(textStyle),
          _FooterLink(
            label: 'Accessibilité : non conforme',
            style: textStyle,
            onTap: () => _navigateTo(
              context,
              '/legal?section=accessibility',
              const LegalScreen(initialSection: 'accessibility'),
            ),
          ),
          _buildSeparator(textStyle),
          _FooterLink(
            label: 'Mentions légales',
            style: textStyle,
            onTap: () => _navigateTo(
              context,
              '/legal?section=mentions',
              const LegalScreen(initialSection: 'mentions'),
            ),
          ),
          _buildSeparator(textStyle),
          _FooterLink(
            label: 'Politique de confidentialité',
            style: textStyle,
            onTap: () => _navigateTo(
              context,
              '/legal?section=privacy',
              const LegalScreen(initialSection: 'privacy'),
            ),
          ),
          _buildSeparator(textStyle),
          Text(
            '©2026 ${BuildInfo.copyrightHolder}',
            style: textStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator(TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text('•', style: style),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  const _FooterLink({
    required this.label,
    required this.style,
    required this.onTap,
  });

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: widget.style.copyWith(
            color: _isHovered ? primaryColor : widget.style.color,
            decoration:
                _isHovered ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

