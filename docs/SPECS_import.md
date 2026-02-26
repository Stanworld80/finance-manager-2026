# Spécifications Fonctionnelles - Import de Données Bancaires (Excel)

## 1. Objectif
Permettre à l'utilisateur d'importer un fichier Excel exporté depuis son site bancaire (ex: Crédit Agricole) pour créer en masse des transactions dans l'application, avec une assistance au catégorisation (enveloppes).

## 2. Format du Fichier Source (Analyse de `CA20260206_064918.xlsx`)
Le fichier analysé présente la structure suivante :
- **Lignes d'en-tête** : Les premières lignes contiennent des informations de compte (ex: "Compte de chèques", "Solde au ..."). Le tableau réel commence souvent après quelques lignes vides ou d'en-tête contextuel.
- **Colonnes probables** :
  - Date
  - Libellé / Opération
  - Débit (Montant négatif ou colonne dédiée)
  - Crédit (Montant positif ou colonne dédiée)
  - Détail (optionnel)

*Note : L'importateur doit être capable de détecter la ligne d'en-tête du tableau de données.*

## 3. Workflow d'Import

### A. Sélection du Fichier & Compte Cible
1.  L'utilisateur accède à un écran "Import de Transactions".
2.  Il sélectionne le compte réel cible (ex: "Compte Courant Perso").
3.  Il upload le fichier Excel (`.xlsx`).

### B. Parsing & Prévisualisation
1.  L'application lit le fichier.
2.  **Détection automatique** :
    - Ignore les premières lignes de métadonnées.
    - Identifie la ligne d'en-tête (cherche mots clés "Date", "Libellé", "Montant", "Débit", "Crédit").
3.  **Mapping des colonnes** (si non standard) :
    - L'utilisateur confirme ou ajuste la correspondance des colonnes (ex: Colonne A -> Date, Colonne B -> Libellé, etc.).

### C. Réconciliation & Catégorisation (Règles Métier)
Pour chaque ligne importée :
1.  **Vérification de doublon** :
    - Si une transaction avec la même date, même montant et libellé similaire existe déjà -> Marquer comme "Doublon potentiel" (à ignorer par défaut).
2.  **Devinette de l'Enveloppe (Guessing)** :
    - **Recherche exacte** : Si un libellé identique a déjà été catégorisé dans le passé, proposer la même enveloppe.
    - **Recherche Mots-clés** : Si le libellé contient "EDF" -> "Electricité", "Carrefour" -> "Alimentation". (Besoin d'une table de correspondance ou IA simple).
    - **Défaut** : Si aucune correspondance, proposer l'enveloppe "Libre" (à catégoriser plus tard) ou demander à l'utilisateur.

### D. Interface de validation (Review)
Tableau affichant les transactions prêtes à importer :
- **Ligne** : Date | Libellé | Montant | **Enveloppe (Dropdown)** | **Compte Tiers (Dropdown)**
- **Actions en masse** : Cocher/Décocher.
- **Assistance Utilisateur** :
  - L'utilisateur peut renseigner manuellement l'enveloppe pour une ligne.
  - S'il change l'enveloppe pour "Uber", le système peut proposer d'appliquer ce choix à toutes les lignes "Uber" importées.
  - "Tips" : L'utilisateur peut dire "Tout ce qui contient 'Péage' va dans 'Transport'".

### E. Exécution
1.  Création des transactions validées.
2.  Mise à jour des soldes.
3.  Feedback : "X transactions importées avec succès".

## 4. Implémentation Technique (Flutter)

### Dépendances
- `excel`: Pour lire le fichier .xlsx. (Déjà ajouté)
- `file_picker`: Pour sélectionner le fichier.

### Architecture
1.  **`BankImportService`** :
    - `parseExcel(File file) -> List<RawTransaction>`
    - `detectDuplicates(List<RawTransaction> imports, List<Transaction> existing)`
    - `guessEnvelopes(List<RawTransaction> imports)`
2.  **`ImportTransactionScreen`** :
    - UI de sélection et validation.
    - Gestion d'état locale pour les modifications de l'utilisateur avant commit.

## 5. Modèle de Données (Extension)
Pas de changement majeur en BDD, mais besoin de structures temporaires en mémoire pour le flux d'import.
Peut-être ajouter une table `ImportRules` (Pattern -> EnvelopeId) pour améliorer l'auto-catégorisation future.

