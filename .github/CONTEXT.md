# FinanceManager2026 Context

## Project Overview
FinanceManager2026 is a personal finance management application built with **Flutter** for **Android** and **Web**.
It aims to help users track expenses, manage budgets (envelope method), and gain insights into their financial health.

## Technology Stack
- **Frontend**: Flutter (Mobile & Web).
- **Language**: Dart.
- **State Management**: Riverpod.
- **Navigation**: GoRouter.
- **Backend/Infrastructure**: Firebase (Auth, Firestore, Hosting, Functions, App Distribution).
- **AI Integration**: Gemini (via Vertex AI) for receipt processing and categorization.

## Environment & Architecture

### Flavors
The project uses Flutter Flavors to separate environments:
1.  **Development (Staging)**
    - **Flavor**: `dev`
    - **Entry Point**: `lib/main_dev.dart`
    - **Firebase Project**: `finance-manager-2026-stg`
    - **App ID (Android)**: `fr.stanislasselleinformatique.finance_manager_2026.stg`
    - **Features**: Includes "Admin Playground" (`/admin`) for testing components and data.

2.  **Production**
    - **Flavor**: `prod`
    - **Entry Point**: `lib/main.dart`
    - **Firebase Project**: `finance-manager-2026`
    - **App ID (Android)**: `fr.stanislasselleinformatique.finance_manager_2026`
    - **Features**: Consumer-facing app.

### CI/CD & Scripts
- **Build Script**: `build_deploy.ps1` (PowerShell) handling:
    - Version Bumping (`pubspec.yaml`).
    - Testing (`flutter test`).
    - Building (Web & Android APK/AAB).
    - Deployment (Firebase Hosting & App Distribution).
- **Commands**:
    - Deploy Staging: `./build_deploy.ps1 -Environment dev`
    - Deploy Prod: `./build_deploy.ps1 -Environment prod`

## Key Directories
- `lib/core/`: Shared utilities, theme, environment config.
- `lib/features/`: Feature-based modules (clean architecture).
- `lib/features/admin/`: Developer tools and playground (Dev only).
- `.github/`: Context and documentation for AI assistants.

## Current Status (Jan 2026)
- Infrastructure initialized.
- Multi-environment setup complete (Firebase projects linked).
- Package renamed to `fr.stanislasselleinformatique`.
- Basic scaffold and navigation implemented.
- CI/CD script `build_deploy.ps1` operational.
