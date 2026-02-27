# Finance Manager 2026 - Development & Test Process

This document outlines the workflows and standards for maintaining high-velocity development ("Vibe Coding") without sacrificing quality.

## 🛠️ Tech Stack
- **Frontend:** Flutter Web & Android
- **State Management:** Riverpod (with Code Generation)
- **Backend:** Firebase (Auth, Firestore, Cloud Functions)
- **Security:** Strict Firestore Rules by UserID

## 🚀 Local Infrastructure (The Vibe)
To avoid polluting production data and ensure fast feedback loops, we use **Firebase Emulators** and **Chromedriver**.

### Task Runner: `infra.ps1`
Use the PowerShell script `infra.ps1` to manage your local environment:

| Command | Description |
|---------|-------------|
| `.\infra.ps1 up` | Starts Firebase Emulators (Firestore, Auth) and Chromedriver (port 4444). |
| `.\infra.ps1 down` | Stops background processes. |
| `.\infra.ps1 test` | Runs Web Integration Tests using the `integration_test` package. |

## 🧪 Testing Strategy

### 1. Unit Tests
- **Focus:** Business logic, model serialization, services.
- **Location:** `test/features/...`
- **Command:** `flutter test`

### 2. Integration Tests (Web)
- **Focus:** User flows (Login -> Transaction -> Balance Verification).
- **Location:** `integration_test/app_test.dart`
- **Infrastructure:** Requires `chromedriver` running on port 4444.
- **Workflow:**
    1. Run `.\infra.ps1 up`
    2. Run `.\infra.ps1 test`

### 3. Human-Readable Integration Tests (BDD)
- **DSL:** `integration_test/gherkin/bdd_steps.dart` (Extensions on `WidgetTester`).
- **Feature Tests:** `integration_test/features/` (e.g., `recurring_flow_test.dart`).
- **Why?** To make complex flows understandable for both developers and QA, maintaining high velocity without imperative boilerplate.

## 💎 Coding Standards (.ai-rules)
Our context-aware rules prioritize:
- **Double-Entry Accounting:** Every balance change must be balanced (Firestore Transactions).
- **Vibe Coding Flow:** High velocity, but NO finalization without passing tests.
- **Responsive Design:** Premium UI that adapts to Web and Mobile.
- **Gherkin-ish Steps:** Use `given/when/then` naming for integration test steps.

## 📦 Deployment Flow
1. **Verify Logic:** Run `flutter test`.
2. **Build & Deploy:** Run `.\build_deploy.ps1 -Environment develop -Platform web -BuildMode release`.
   - **Versioning:** The script automatically calculates the build number based on the **Git commit count** (`git rev-list --count HEAD`).
   - **No Manual Bumps:** You only need to update the `version: x.y.z` (Version Name) in `pubspec.yaml` when making semantic releases. The build number (+N) is handled by the CI/CD script.
   - **Targets:** Handles cleaning, building, git tagging, and Firebase Hosting/App Distribution.

---
> [!TIP]
> Always run `.\infra.ps1 up` at the start of your session to enable local login and Firestore debugging without affecting live users.
