import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Centre d'Aide"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.lightbulb_outline), text: "Concepts"),
              Tab(icon: Icon(Icons.menu_book), text: "Guide"),
              Tab(icon: Icon(Icons.account_balance), text: "Méthode"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildConceptsTab(context),
            _buildGuideTab(context),
            _buildMethodTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            context,
            "Comptes Réels",
            "La réalité physique de votre argent : BNP, Revolut, Cash, etc.",
            Icons.account_balance_wallet,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            "Enveloppes (Comptes Virtuels)",
            "Votre organisation logique. Un budget 'Courses' n'existe que dans l'app, pas à la banque.",
            Icons.label_outline,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            "Solde Engagé",
            "L'argent qui est 'parti' de votre budget (car vous avez payé) mais qui n'a pas encore été débité par la banque.",
            Icons.hourglass_empty,
            Colors.purple,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, "États d'une Transaction"),
          _buildStatusRow(
            context,
            "Prévu",
            "Anticipé, n'affecte pas encore les soldes.",
            Icons.calendar_today,
            Colors.grey,
          ),
          _buildStatusRow(
            context,
            "Effectué",
            "La transaction est confirmée et traitée.",
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatusRow(
            context,
            "En Cours",
            "Visible en banque mais pas encore débité.",
            Icons.sync,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildGuideStep(
          context,
          "1. Ajouter un Revenu",
          "Cliquez sur 'Revenu'. Choisissez le compte réel qui reçoit l'argent et l'enveloppe à remplir (souvent 'À Distribuer').",
          Icons.add_circle_outline,
        ),
        _buildGuideStep(
          context,
          "2. Faire une Dépense",
          "Cliquez sur 'Dépense'. Sélectionnez l'enveloppe qui paie. L'argent ira dans le solde 'Engagé' jusqu'à validation.",
          Icons.remove_circle_outline,
        ),
        _buildGuideStep(
          context,
          "3. Réorganiser ses Budgets",
          "Utilisez 'Virement' pour déplacer de l'argent entre deux enveloppes sans toucher à la banque.",
          Icons.swap_horiz,
        ),
        _buildGuideStep(
          context,
          "4. Importer ses relevés",
          "Allez dans 'Import CSV' pour traiter massivement vos lignes bancaires et les mapper sur vos enveloppes.",
          Icons.upload_file,
        ),
      ],
    );
  }

  Widget _buildMethodTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, "La Méthode des Enveloppes"),
          const Text(
            "C'est la base de Finance Manager 2026. Au lieu de regarder votre solde bancaire global, vous regardez ce qu'il reste dans chaque enveloppe spécifique.",
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Column(
              children: [
                Text(
                  "Équation de Confiance",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  "💰 Solde Banque = 📂 Somme des Enveloppes",
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, "Exemple Pratique"),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _ExampleRow(
                    label: "Salaire reçu",
                    value: "+2000€",
                    color: Colors.green,
                  ),
                  Divider(),
                  _ExampleRow(label: "Vers Enveloppe 'Loyer'", value: "800€"),
                  _ExampleRow(label: "Vers Enveloppe 'Courses'", value: "400€"),
                  _ExampleRow(label: "Reste en 'Libre'", value: "800€"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const ExpansionTile(
            title: Text("Que faire en cas d'imprévu ?"),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Si une dépense n'était pas prévue (ex: réparation voiture), piochez dans votre enveloppe 'Libre' ou faites un virement interne depuis une autre enveloppe moins prioritaire (ex: 'Loisirs').",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
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

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 13,
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

  Widget _buildStatusRow(
    BuildContext context,
    String label,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: "$label : ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _ExampleRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
