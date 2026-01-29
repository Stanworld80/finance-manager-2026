# Spécifications Fonctionnelles - FinanceManager2026

## 1. Vision du Produit
FinanceManager2026 est une application intelligente de gestion de finances personnelles qui utilise l'IA générative pour transformer la corvée de la saisie comptable en une analyse proactive de la santé financière.

## 2. Utilisateurs Cibles
- Particuliers souhaitant suivre leurs dépenses.
- Utilisateurs multi-comptes (comptes courants, livrets).
- Profils techniques appréciant l'automatisation et la privacy.

## 3. Fonctionnalités Clés (MVP)

### A. Authentification & Onboarding
- Connexion sécurisée via Compte Google (Google Auth).
- Configuration initiale (Devise par défaut, solde initial).

### B. Gestion des Transactions (Le Cœur)
- **Vue Liste :** Affichage chronologique des dépenses/revenus.
- **CRUD :** Créer, Lire, Mettre à jour, Supprimer une transaction.
- **Champs :** Montant, Date, Tiers (Payee), Catégorie, Note, Photo du justificatif.
- **Filtres :** Par date, par catégorie, par compte.

### C. Tableaux de Bord (Dashboard)
- Solde actuel global et par compte.
- Graphique : Dépenses vs Revenus sur le mois en cours (Pie chart / Bar chart).
- "Reste à vivre" estimé.

### D. Intégration IA (Gemini Features)
- **Auto-catégorisation :** À la saisie d'un libellé (ex: "Carrefour"), l'IA propose la catégorie ("Alimentation") et une icône.
- **Analyse de reçu :** L'utilisateur prend une photo d'un ticket, Gemini extrait le montant, la date et le commerçant.
- **Assistant "Coach Financier" :** Chat interface pour poser des questions ("Combien ai-je dépensé en restaurants le mois dernier ?").

### E. Planification
- Gestion des opérations récurrentes (loyers, abonnements).
- Projection du solde à fin de mois.

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