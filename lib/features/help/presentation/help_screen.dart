import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aide & Concepts")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, "Bienvenue sur Finance Manager 2026"),
            const Text(
              "Cette application utilise une méthode de gestion budgétaire précise basée sur des enveloppes virtuelles et un suivi rigoureux des flux bancaires.",
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(context, "1. Comptes Réels vs Virtuels"),
            _buildSubsection(
              "Comptes Réels",
              "Ce sont vos comptes bancaires physiques (BNP, Crédit Agricole, PayPal). Ils reflètent la réalité de votre banque.",
            ),
            _buildSubsection(
              "Comptes Virtuels (Enveloppes)",
              "Chaque compte réel est divisé en plusieurs enveloppes. C'est votre budget. La somme de vos enveloppes est toujours égale au solde de votre compte réel.\n\n"
                  "• 🟦 Compte Libre : L'argent non attribué.\n"
                  "• 🟩 Budgets : Vos catégories de dépenses (Alimentation, Loisirs).\n"
                  "• 🟨 Solde Engagé : L'argent qui a quitté votre budget mais pas encore la banque (ou inversement pour le suivi).",
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(context, "2. Cycle de Vie d'une Transaction"),
            const Text(
              "Une transaction passe par plusieurs états pour coller à la réalité bancaire :",
            ),
            const SizedBox(height: 8),
            _buildStep("Prévu", "La dépense est connue mais pas encore faite."),
            _buildStep("A Programmer", "Vous devez faire le virement."),
            _buildStep("Programmé", "L'ordre est donné à la banque."),
            _buildStep(
              "En Cours",
              "Visible sur le site de la banque (souvent en grisé).",
            ),
            _buildStep("Effectué", "Débité définitivement."),

            const SizedBox(height: 24),
            _buildSectionTitle(context, "3. Les Dates Clés"),
            _buildDateDef(
              "Date d'Opération",
              "Le jour où vous faites l'achat.",
            ),
            _buildDateDef(
              "Date de Valeur",
              "La date prise en compte pour les agios/intérêts.",
            ),
            _buildDateDef(
              "Date de Vision",
              "Quand vous l'avez vue sur votre relevé.",
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSubsection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildStep(String name, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: "$name : ",
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

  Widget _buildDateDef(String name, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text(" : "),
          Expanded(child: Text(desc)),
        ],
      ),
    );
  }
}
