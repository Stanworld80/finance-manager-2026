# Spécifications Fonctionnelles - FinanceManager2026

## 1. Vision du Produit
FinanceManager2026 est une application intelligente de gestion de finances personnelles qui utilise l'IA générative pour transformer la corvée de la saisie comptable en une analyse proactive de la santé financière.

## 2. Utilisateurs Cibles
- Particuliers souhaitant suivre leurs dépenses.
- Utilisateurs multi-comptes (comptes courants, livrets).
- Profils techniques appréciant l'automatisation et la privacy.

## 3. Fonctionnalités Clés (MVP)

### A. Authentification & Onboarding
- **Authentification Hybride :** Connexion via Compte Google (Google Auth) OU Email / Mot de passe.
- Configuration initiale (Devise par défaut, solde initial).

### B. Gestion des Transactions (Le Cœur)
#### 1. Acquisition des Données (Entrées Réelles)
- **Saisie Manuelle :** Formulaire optimisé pour une saisie rapide.
- **Import de Fichiers :** Support des exports bancaires (CSV, PDF, OFX) issus des sites de banques.
- **Synchronisation Bancaire (Bank Sync) :**
  - Connexion sécurisée aux banques réelles (API Open Banking / DSP2).
  - Cibles prioritaires : **Crédit Agricole**, **La Banque Postale**, **PayPal**.
  - Objectif : Comparer les soldes théoriques (app) avec la réalité bancaire et synchroniser les transactions manquantes.
  - Fonctionnalité "Live Watcher" pour détecter les nouveaux mouvements.
- **Connexion Commerçants (Factures) :**
  - Intégration API fournisseurs (Amazon, EDF, Opérateurs, etc.) pour récupérer les factures et le détail des commandes.

#### 2. Manipulation & Visualisation
- **Vue Liste :** Affichage chronologique des dépenses/revenus.
- **CRUD :** Créer, Lire, Mettre à jour, Supprimer une transaction.
- **Champs :** Montant, Date, Tiers (Payee), Catégorie, Note, Photo du justificatif.
- **Ventilation (Splits) :** Possibilité d'affecter une dépense unique à plusieurs enveloppes budgétaires (ex: Ticket de supermarché = 50€ Alimentation + 20€ Maison).
- **Filtres :** Par date, par catégorie, par compte.

### C. Tableaux de Bord & Analyse (Analytics)
- **Vue Synthétique (Dashboard) :** Solde global, par compte, et "Reste à vivre" instantané.
- **Rapports Historiques (Bilans) :**
  - Comparatif mensuel/annuel des entrées/sorties.
  - Ventilation par catégorie sur des périodes personnalisées.
- **Analyse Prédictive :**
  - Identification des tendances de dépenses (ex: augmentation progressive des courses).
  - Projection des soldes futurs basés sur l'historique et le récurrent.

### D. Intégration IA (Gemini Features)
- **Auto-catégorisation :** À la saisie d'un libellé (ex: "Carrefour"), l'IA propose la catégorie ("Alimentation") et une icône.
- **Analyse de reçu :** L'utilisateur prend une photo d'un ticket, Gemini extrait le montant, la date et le commerçant.
- **Assistant "Coach Financier" :** Chat interface pour poser des questions ("Combien ai-je dépensé en restaurants le mois dernier ?").

### E. Planification & Projets de Vie
- **Gestion des Récurrences & Échéanciers :**
  - Définition précise des revenus et dépenses fixes (Loyer, Impôts, Abonnements, Salaires).
  - Paramétrage flexible : Date de début, Date de fin, Fréquence (Mensuel, Annuel, Hebdomadaire, Personnalisé).
  - Génération automatique des transactions futures dans la vue prévisionnelle.
- **Dépenses Futures Ponctuelles :**
  - Programmation de transactions unitaires futures connues (ex: "Révision voiture dans 3 mois").
- **Projets de Financement (Épargne Ciblée) :**
  - Création de "Cagnottes" ou objectifs d'épargne (ex: "Voyage Japon", "Achat Maison").
  - Suivi de la progression vers l'objectif (Montant cible, Date butoir).
  - *Lien avec Comptes Virtuels :* Un projet peut être un Compte Virtuel dédié qu'on alimente progressivement.

#### 4. Projets Financiers Complexes (Événements)
- **Concept :** Gestion d'un micro-budget pour un événement spécifique (Mariage, Fête, Rénovation).
- **Structure :** Une "Super-Enveloppe" ou un groupe d'enveloppes.
- **Fonctionnalités :**
  - **Budget Prévisionnel :** Liste des postes de dépenses (Décoration, Salle, Traiteur) et des revenus (Cagnotte, Apport).
  - **Suivi Réalisé vs Prévisionnel :** Écart en temps réel.
  - **Flux dédiés :** Entrées et sorties taguées pour ce projet.

### F. Système Budgétaire (Comptes Virtuels)
Ce système implémente une gestion par "enveloppes" directement liée aux comptes réels.

#### 1. Concepts & Structure
- **Typologie des Comptes Réels :**
  - **Comptes Internes :** Comptes dont l'utilisateur est propriétaire ou gestionnaire (Comptes courants, Livrets, PayPal).
  - **Comptes Externes :** Représentent les tiers (Commerçants, Amis, Employeurs).
  - **Compte Réel** : Identifie un compte bancaire physique. Contient :
    - Nom personnalisé (ex: "Compte Courant Bourso")
    - Nom de la banque (ex: "Boursorama")
    - Solde initial et solde actuel
    - Métadonnées (optionnelles) : IBAN, BIC, SWIFT, Numéro de compte, Nom officiel, Date d'ouverture.
- **Compte Virtuel (Enveloppe)** : Subdivision logique d'un compte réel Interne.
  - **Règle d'Or (Double Entrée) :** Toute transaction est un mouvement de fonds entre deux pôles (Origine -> Destination). La somme des variations de solde de tous les comptes impliqués dans une transaction doit toujours être égale à zéro.
  - **Équation de Solde :** `Solde Réel Actuel = Somme(Comptes Virtuels du compte)`.
  - **Comptes Systèmes :**
    - `external-adjustment` : Utilisé comme contrepartie pour les corrections de solde (origines inconnues).
    - `external-pole` : Représente le monde extérieur pour les dépenses (Debit) et revenus (Credit).

#### 2. Typologie des Transactions & Cycle de Vie
L'application gère des statuts et des étapes précises pour chaque flux.

**Types de Transactions :**
1.  **Débit :** Sortie d'argent d'un compte interne vers un compte externe.
2.  **Crédit :** Entrée d'argent depuis un compte externe vers un compte interne.
3.  **Provision :** Transfert technique d'une enveloppe budgétaire vers l'enveloppe "Solde Engagé" pour couvrir (sécuriser) une dépense à venir.
4.  **Transfert :** Mouvement de fonds d'une enveloppe à une autre (réallocation).

**Workflow & Étapes (Le Flux) :**
Représente l'avancement temporel et l'exécution bancaire.
- **Prévu :** Transaction anticipée (récurrence ou planification).
- **A Programmer :** Action requise de l'utilisateur (virement à faire).
- **Programmé :** L'ordre de virement est passé.
- **En Cours :** Transaction visible côté banque mais non finalisée (pending).
- **Effectué :** Transaction validée et débitée/créditée réellement.

**Gestion Avancée des Dates (Temporalité) :**
Pour gérer les délais bancaires (décalage opération/valeur, chèques, cartes à débit différé), chaque transaction porte plusieurs dates clés :
- **Date d'Opération (Transaction Date) :** Date de l'achat ou de l'initiation de l'ordre.
- **Date de Valeur (Value Date) :** Date effective de prise en compte par la banque pour le calcul des intérêts/soldes.
- **Date d'Apparition (Visibility Date) :** Moment où la ligne apparaît sur le relevé en ligne (souvent en "En Cours").
- **Date de Pointage/Synchro :** Date de validation finale par rapprochement bancaire.
- **Date de Provision :** Moment où l'enveloppe budgétaire a été affectée.

**Statuts Budgétaires (Le Contrôle) :**
Représente l'état de couverture de la transaction.
- **A Provisionner :** Dépense prévue mais l'enveloppe cible n'a pas encore les fonds.
- **Provisionné :** Les fonds sont sécurisés dans "Solde Engagé".
- **A Distribuer :** Pour un Crédit (Revenu) arrivé dans le sas, attendant d'être ventilé.
- **A Transférer :** Fonds en attente de mouvement.
- **A Corriger / Corrigé :** Gestion des erreurs de rapprochement.

#### 3. Typologie des Comptes Virtuels

1.  **Compte "Libre" (Système) :**
    - Créé automatiquement pour chaque Compte Réel.
    - Reçoit tout le solde non attribué à des budgets spécifiques.
    - Sert de tampon de sécurité.
2.  **Comptes Budgétaires (Utilisateur) :**
    - Ex: "Alimentation", "Logement", "Loisirs".
    - Représentent le "Reste à dépenser" pour cette catégorie.
3.  **Compte "Solde Engagé" (Système) :**
    - Compte technique recevant la contrepartie des dépenses réelles.
    - Une dépense réelle diminue le solde réel mais ne modifie pas le total des fonds virtuels, elle déplace juste des fonds d'un budget vers "Engagé".
4.  **Zone "À Distribuer" (Flux) :**
    - Sas d'entrée temporaire pour les revenus entrants avant qu'ils ne soient alloués.

#### 4. Workflows
- **Traitement des Revenus (Entrées) :**
  - Une rentrée d'argent sur le Compte Réel arrive dans la zone "À Distribuer".
  - **Action :** L'utilisateur répartit ce montant (manuellement ou via Templates automatiques) vers les différents Comptes Virtuels ("Libre", "Loyer", etc.).
  
- **Traitement des Dépenses (Sorties & Provisionnement) :**
  - Une dépense sur le Compte Réel doit être "Provisionnée" (avant ou après l'acte d'achat).
  - **Action :** Provisionner consiste à créer une transaction virtuelle :
    `Débit: Compte Virtuel (ex: "Alimentation")` -> `Crédit: Compte Virtuel "Solde Engagé"`.
  - Cela diminue le disponible du budget concerné.

- **Consultation & Interface (UI) :**
  - **Détail Compte Réel :** L'écran de détail d'un compte réel est divisé en deux onglets :
    1.  **Enveloppes :** Liste des comptes virtuels (budgets) avec leurs soldes.
    2.  **Transactions :** Liste chronologique de toutes les opérations affectant ce compte réel.
  - **Détail Enveloppe :** Un écran dédié pour chaque compte virtuel affiche :
    - Son solde actuel.
    - L'historique des transactions filtré spécifiquement pour cette enveloppe (Dépenses, Provisions, Transferts).
  - L'application permet de voir les soldes "Réels" (Banque), "Actuels" (Dans les enveloppes), et "Prévisionnels" (Basés sur les budgets restants).

### G. Automatisation & Actions Bancaires
- **Smart Matching (Réconciliation) :**
  - L'algorithme détecte automatiquement si une transaction bancaire importée correspond à une dépense planifiée ou récurrente pour éviter les doublons.
- **Moteur de Suggestions (Auto-Pilot) :**
  - Proposition automatique de virements de répartition lors de la réception d'un salaire (selon règles définies).
  - Alerte et proposition de rééquilibrage si un compte va passer à découvert alors qu'un autre a des fonds.
- **Initiation de Paiement (DSP2 / PISP) :**
  - Capacité technique de demander l'exécution d'un virement inter-comptes réels directement depuis l'interface (nécessite validation forte côté banque).

### H. Gestion Technique & Sécurité
- **Atomicité & Double-Entrée :** Toutes les opérations modifiant les soldes (Réel ou Virtuel) doivent être exécutées dans une Transaction Firestore. Chaque mouvement (Split) doit être équilibré par une contrepartie (From/To), garantissant qu'aucune valeur ne se perd ou ne se crée ex-nihilo.
- **Traçabilité des Ajustements :** Les écarts de rapprochement ne sont pas de simples "updates" de solde, mais des transactions vers le compte système `external-adjustment`.
- **Suppression Logique :** La suppression d'une transaction doit inverser exactement ses écritures comptables.

## 4. Exigences Non-Fonctionnelles
- **Performance :** Lancement de l'app en < 2 secondes.
- **Offline First :** L'application doit fonctionner sans réseau (Firestore cache) et synchroniser au retour de la connexion.
- **Responsive :** L'interface Web doit être adaptée au Desktop, l'interface Android au Mobile.
- **Sécurité :** Données chiffrées au repos et en transit.

## 5. Roadmap
- **Phase 1 (Setup) :** Infra Firebase, Hello World Flutter, CI/CD.
- **Phase 2 (Core) :** Auth, CRUD Transactions basique.
- **Phase 3 (IA) :** Connexion Vertex AI, Auto-catégorisation.
- **Phase 4 (Release) :** Tests Lab, Déploiement Web public.

## 6. Environnement de Développement (Flavor: DEV)
L'application doit disposer d'une variante de build "Development" qui inclut un accès privilégié à un module d'Administration/Playground.

### A. Accès
- Accessible uniquement dans la version `dev`.
- Bouton flottant ou entrée dans le menu latéral, visible seulement si `Environment.isDev == true`.

### B. Fonctionnalités du Dashboard Admin
1. **Design System Playground :**
   - Page affichant tous les composants UI (Boutons, Cartes, Inputs, Typographie) pour valider le rendu visuel.
   - Test des modes Clair/Sombre.
2. **API Lab (Backend PoC) :**
   - Interface brute pour tester les Cloud Functions (ex: déclencher une analyse Gemini sur un texte arbitraire).
   - Visualiseur de logs Firestore en temps réel.
3. **Gestion des données :**
   - Bouton "Reset Data" pour vider le compte de test.
   - Bouton "Seed Data" pour injecter des fausses transactions.