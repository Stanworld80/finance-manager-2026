import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/build_info.dart';
import '../../help/presentation/help_screen.dart';

class LegalScreen extends StatefulWidget {
  final String initialSection;

  const LegalScreen({
    super.key,
    this.initialSection = 'mentions',
  });

  static int indexFromSection(String? section) {
    switch (section) {
      case 'accessibility':
        return 0;
      case 'mentions':
        return 1;
      case 'privacy':
        return 2;
      case 'cgu':
        return 3;
      default:
        return 1;
    }
  }

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: LegalScreen.indexFromSection(widget.initialSection),
    );
  }

  @override
  void didUpdateWidget(covariant LegalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      final newIndex = LegalScreen.indexFromSection(widget.initialSection);
      if (_tabController.index != newIndex) {
        _tabController.animateTo(newIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations Légales & Annexes'),
        actions: [
          TextButton.icon(
            onPressed: () {
              final router = GoRouter.maybeOf(context);
              if (router != null) {
                context.go('/help');
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                );
              }
            },
            icon: const Icon(Icons.help_outline, size: 18),
            label: const Text("Centre d'Aide"),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.accessibility_new_outlined),
              text: 'Accessibilité',
            ),
            Tab(
              icon: Icon(Icons.gavel_outlined),
              text: 'Mentions légales',
            ),
            Tab(
              icon: Icon(Icons.privacy_tip_outlined),
              text: 'Politique de confidentialité',
            ),
            Tab(
              icon: Icon(Icons.description_outlined),
              text: 'CGU',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccessibilityTab(context),
          _buildMentionsLegalesTab(context),
          _buildPrivacyTab(context),
          _buildCguTab(context),
        ],
      ),
    );
  }

  Widget _buildAccessibilityTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, "Déclaration d'accessibilité"),
          _buildCard(
            context,
            title: 'État de conformité : Non conforme',
            icon: Icons.info_outline,
            content:
                "${BuildInfo.copyrightHolder} s'engage à rendre son application "
                "Finance Manager 2026 accessible conformément à l'article 47 de la loi "
                "n° 2005-102 du 11 février 2005.\n\n"
                "L'application est actuellement déclarée « non conforme » en l'absence "
                "d'un audit complet de conformité RGAA (Référentiel Général d'Amélioration "
                "de l'Accessibilité).",
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: 'Aménagements et fonctionnalités disponibles',
            icon: Icons.tune_outlined,
            content:
                "• Thèmes visuels adaptatifs (Clair, Sombre, Banque, Ciel, Pastel) permettant d'ajuster les contrastes.\n"
                "• Interface responsive compatible ordinateur (Web), tablette et mobile (Android).\n"
                "• Navigation structurée par onglets et raccourcis d'actions rapides.\n"
                "• Compatibilité avec le redimensionnement des polices système.",
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: 'Retour d’information et contact',
            icon: Icons.contact_support_outlined,
            content:
                "Si vous n'arrivez pas à accéder à un contenu ou à un service de "
                "Finance Manager 2026, vous pouvez contacter l'équipe de "
                "${BuildInfo.copyrightHolder} afin d'être orienté vers une alternative accessible.",
          ),
        ],
      ),
    );
  }

  Widget _buildMentionsLegalesTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Mentions légales'),
          _buildCard(
            context,
            title: "Éditeur de l'application",
            icon: Icons.business_outlined,
            content:
                "Application : Finance Manager 2026\n"
                "Éditeur : ${BuildInfo.copyrightHolder}\n"
                "Direction de la publication : Stanislas Selle\n"
                "Copyright : ©2026 ${BuildInfo.copyrightHolder} - Tous droits réservés.",
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: 'Hébergement & Infrastructure',
            icon: Icons.cloud_outlined,
            content:
                "L'application Web et les bases de données associées sont hébergées sur "
                "la plateforme Google Firebase (Google Cloud Platform / Google Ireland Limited, "
                "Gordon House, Barrow Street, Dublin 4, Irlande).",
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: 'Propriété intellectuelle',
            icon: Icons.copyright_outlined,
            content:
                "L'ensemble de ce site et de l'application (architecture, code source, "
                "interface graphique, textes et logos) relève de la législation sur le droit "
                "d'auteur et la propriété intellectuelle. Toute reproduction totale ou partielle "
                "sans autorisation expresse de ${BuildInfo.copyrightHolder} est interdite.",
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Politique de confidentialité (RGPD)'),
          _buildCard(
            context,
            title: 'Données collectées',
            icon: Icons.folder_shared_outlined,
            content:
                "Finance Manager 2026 collecte uniquement les données strictement nécessaires "
                "à votre gestion budgétaire :\n"
                "• Données d'authentification (adresse e-mail, identifiant Firebase Auth).\n"
                "• Données financières saisies ou importées par l'utilisateur (comptes réels, "
                "enveloppes budgétaires, transactions, échéanciers et projets).",
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: 'Finalité et sécurité des données',
            icon: Icons.lock_outline,
            content:
                "• Vos données sont isolées par utilisateur via des règles de sécurité Cloud Firestore strictes.\n"
                "• Les échanges réseau sont chiffrés via HTTPS/TLS.\n"
                "• Aucune donnée personnelle ou financière n'est vendue ou cédée à des tiers.",
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: 'Vos droits (Accès, Export, Suppression)',
            icon: Icons.verified_user_outlined,
            content:
                "Conformément au Règlement Général sur la Protection des Données (RGPD), "
                "vous disposez d'un droit d'accès, de rectification, de portabilité (export CSV/PDF "
                "disponible dans l'application) et de suppression de vos données auprès de "
                "${BuildInfo.copyrightHolder}.",
          ),
        ],
      ),
    );
  }

  Widget _buildCguTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, "Conditions Générales d'Utilisation"),
          _buildCard(
            context,
            title: 'Objet du service',
            icon: Icons.account_balance_wallet_outlined,
            content:
                "Finance Manager 2026 est un outil d'aide à la gestion budgétaire personnelle "
                "et familiale reposant sur la méthode des enveloppes et la comptabilité en partie double.",
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: 'Limitation de responsabilité',
            icon: Icons.warning_amber_outlined,
            content:
                "Les informations, projections de soldes et suggestions fournies par l'application "
                "(y compris via le Coach Financier IA) sont données à titre purement indicatif "
                "et ne constituent en aucun cas un conseil financier, bancaire, fiscal ou juridique réglementé. "
                "${BuildInfo.copyrightHolder} ne saurait être tenu responsable des décisions financières "
                "prises sur la base des données affichées.",
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

