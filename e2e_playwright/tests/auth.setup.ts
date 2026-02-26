import { test as setup, expect } from '@playwright/test';

const authFile = 'playwright/.auth/user.json';

setup('authenticate', async ({ page }) => {
    // Try using environment variables for credentials, fallback to defaults for testing
    const email = process.env.TEST_USER_EMAIL || 'test@test.com';
    const password = process.env.TEST_USER_PASSWORD || 'password123';

    console.log(`Authenticating with ${email} on ${process.env.BASE_URL || 'https://finance-manager-2026-stg.web.app'}`);
    await page.goto(process.env.BASE_URL || 'https://finance-manager-2026-stg.web.app');

    // Wait for the Firebase Auth fields to render in the DOM (Flutter inserts them as transparent overlays)
    await page.waitForSelector('input[name="email"]', { timeout: 10000 });

    // Fill in email
    await page.fill('input[name="email"]', email);
    await page.keyboard.press('Enter');

    // Wait for password field
    await page.waitForSelector('input[type="password"]', { timeout: 10000 });

    // Fill in password
    await page.fill('input[type="password"]', password);

    // Submit via Enter
    await page.keyboard.press('Enter');

    // Wait until the dashboard loads (e.g., waiting for the Resume text or a known dashboard element)
    await page.waitForURL('**/');

    // Wait for the Dashboard widget to be visible
    await expect(page.getByText('Résumé (Statistiques des Enveloppes)', { exact: false })).toBeVisible({ timeout: 15000 });

    // End of authentication steps.
    await page.context().storageState({ path: authFile });
});
