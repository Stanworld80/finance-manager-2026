# Playwright E2E Tests for Finance Manager 2026

This directory contains end-to-end tests for the Finance Manager application written with Playwright.

## Running Tests

By default, the tests point to the Staging environment:
`https://finance-manager-2026-stg.web.app`

To run the tests:

```bash
cd e2e_playwright
npx playwright test
```

### Important Note on Flutter Web

Because Finance Manager 2026 is built with Flutter Web, the UI is primarily rendered onto a `<canvas>` element (CanvasKit). This means standard HTML elements don't exist by default in the DOM for Playwright to click on.

Playwright relies on **Semantics** or the **HTML Renderer**.

**Option 1: Test against a local build (Recommended for reliable E2E)**
To ensure maximum reliability when testing text inputs and button clicks, run the app locally using the HTML renderer:
```bash
# From the root of your project:
flutter run -d web-server --web-hostname localhost --web-port 3000 --web-renderer html --dart-define=APP_ENV=staging
```
Then run the tests targeting `localhost`:
```bash
cd e2e_playwright
BASE_URL=http://localhost:3000 npx playwright test
```

**Option 2: Test against deployed environments**
The authentication setup handles the transparent overlay injected by Firebase Auth. However, tests like `transactions.spec.ts` that attempt to parse the Flutter layout using standard `getByText` or `getByRole` may fail on deployed versions if CanvasKit is used without `--web-renderer html`. If you wish to test heavily on deployed CanvasKit apps, consider migrating to Flutter's native `integration_test` package.

### Configuration
- `playwright/.auth/user.json`: Stores the session state after the `auth.setup.ts` script runs.
- `playwright.config.ts`: Configuration file including base URL and environment setups.

### Tests Included
1. `auth.setup.ts`: Logs into the app with default credentials. Set `TEST_USER_EMAIL` and `TEST_USER_PASSWORD` to override.
2. `transactions.spec.ts`: End-to-end flow testing the creation, modification, and deletion of a transaction based on text labels and general interactive roles.
