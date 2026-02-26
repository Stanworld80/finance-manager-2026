# Architecture & Infrastructure - FinanceManager2025

Ce document décrit l'architecture technique, l'infrastructure cloud et les flux de données pour le projet FinanceManager2025.

## 1. Vue d'ensemble (High-Level Design)

L'application suit une architecture **Serverless** s'appuyant fortement sur le Backend-as-a-Service (BaaS) de Firebase, couplé à Google Cloud pour les traitements IA avancés.

- **Frontend :** Application unique développée en **Flutter** (Dart).
- **Cibles de déploiement :** - **Android :** APK/AAB via Google Play Console (interne/alpha).
  - **Web :** PWA hébergée sur Firebase Hosting.
- **Backend :** Firebase (Firestore, Auth, Functions).
- **IA & ML :** Vertex AI (Gemini Pro) via Cloud Functions.

## 2. Stack Technique Détaillée

### A. Frontend (Client)
- **Framework :** Flutter (Dernière version stable).
- **Gestion d'état :** Riverpod ou Bloc (à définir selon préférence).
- **Architecture Code :** Clean Architecture (Presentation, Domain, Data layers).

### B. Backend & Données (Firebase)
- **Base de données :** **Cloud Firestore** (NoSQL).
- **Authentification :** **Firebase Authentication** (Google Sign-In, Email/Password).
- **Stockage Fichiers :** **Cloud Storage** (pour les justificatifs/factures).
- **Logique Serveur :** **Cloud Functions** (2nd Gen) en Python ou Node.js (pont vers Gemini).

### C. Intelligence Artificielle (Google Cloud)
- **Modèle :** Gemini Pro (via Vertex AI API).
- **Cas d'usage :**
  - Analyse automatique des libellés bancaires.
  - Suggestion de budgets.
  - Chatbot assistant financier ("Conseiller virtuel").

### D. DevOps & CI/CD
- **Repo :** GitHub.
- **CI/CD :** **GitHub Actions**.
- **Tests Automatisés :** - Tests unitaires/widget Flutter.
  - **Firebase Test Lab** pour les tests d'intégration sur appareils réels (Robo scripts).
- **Hosting Web :** Firebase Hosting (déploiement automatique sur merge `main`).

## 3. Modèle de Données (Firestore Schema - Draft)

- `users/{userId}`
  - `profile`: {name, email, preferences}
  - `accounts/{accountId}`: {name, type, balance, currency}
  - `transactions/{transactionId}`: {amount, date, category, status, ai_analysis_data}
  - `budgets/{budgetId}`: {category, limit, period}

## 4. Pipeline CI/CD (GitHub Actions)

1. **Trigger :** Push sur `main` ou Pull Request.
2. **Job Build :**
   - Installation Flutter.
   - `flutter analyze` & `flutter test`.
3. **Job Test Lab (Android) :**
   - Build de l'APK de debug.
   - Envoi vers Firebase Test Lab pour test sur matrix de devices (Pixel, Samsung, etc.).
4. **Job Deploy (Web) :**
   - Build Web (`flutter build web --release`).
   - Deploy vers Firebase Hosting.

## 5. Sécurité
- **Firestore Security Rules :** Strictes (seul le propriétaire des données peut lire/écrire).
- **App Check :** Activé pour protéger les appels API.
- **Secrets :** Gestion via GitHub Secrets et Google Cloud Secret Manager.