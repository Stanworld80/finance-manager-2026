import { test as setup, expect } from '@playwright/test';

const authFile = 'playwright/.auth/user.json';

setup('authenticate', async ({ page }) => {
    const email = process.env.TEST_USER_EMAIL || 'test@test.com';
    const password = process.env.TEST_USER_PASSWORD || 'password123';
    const baseUrl = process.env.BASE_URL || 'https://finance-manager-2026-stg.web.app';

    console.log(`Checking authentication on ${baseUrl}`);
    await page.goto(baseUrl);

    // Give it a moment to load and check if we are already logged in
    await page.waitForTimeout(3000);
    
    const isDashboardVisible = await page.getByText('Résumé (Statistiques des Enveloppes)', { exact: false }).isVisible();
    
    if (isDashboardVisible) {
        console.log('Already logged in, skipping authentication steps.');
    } else {
        console.log(`Authenticating with ${email}...`);
        
        // Wait for either the login form or the dashboard (in case it slow-loaded)
        await Promise.race([
            page.waitForSelector('input#email', { timeout: 15000 }),
            page.waitForSelector('input[name="email"]', { timeout: 15000 }),
            page.waitForSelector('text=Résumé', { timeout: 15000 })
        ]).catch(() => {});

        if (await page.locator('input#email').isVisible() || await page.locator('input[name="email"]').isVisible()) {
            const emailInput = page.locator('input#email').first();
            const emailSelector = (await emailInput.isVisible()) ? 'input#email' : 'input[name="email"]';
            
            await page.click(emailSelector);
            await page.type(emailSelector, email, { delay: 100 });
            await page.keyboard.press('Enter');

            // Wait for password field
            const passwordSelector = 'input#current-password';
            await page.waitForSelector(passwordSelector, { timeout: 10000 });
            await page.click(passwordSelector);
            await page.type(passwordSelector, password, { delay: 100 });
            await page.keyboard.press('Enter');
        }
    }

    // Wait until the dashboard loads
    await expect(page.getByText('Résumé (Statistiques des Enveloppes)', { exact: false })).toBeVisible({ timeout: 20000 });

    console.log('Authentication successful.');
    await page.context().storageState({ path: authFile });
});
