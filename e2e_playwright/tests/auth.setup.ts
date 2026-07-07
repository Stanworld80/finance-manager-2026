import { test as setup, expect } from '@playwright/test';

const authFile = 'playwright/.auth/user.json';

setup('authenticate', async ({ page }) => {
    setup.setTimeout(90000);
    const email = process.env.TEST_USER_EMAIL || 'comptetechnique001@stanworld.org';
    const password = process.env.TEST_USER_PASSWORD || 'Tester=2026';
    const baseUrl = process.env.BASE_URL || 'https://finance-manager-2026-stg.web.app';

    console.log(`Checking authentication on ${baseUrl}`);
    await page.goto(baseUrl);

    // Give it a moment to load and check if we are already logged in
    await page.waitForTimeout(3000);
    
    // Wait for the Flutter Web bootstrapper to attach the placeholder to the DOM
    const placeholder = page.locator('flt-semantics-placeholder');
    try {
        console.log('Waiting for Flutter Web to bootstrap (placeholder)...');
        await placeholder.waitFor({ state: 'attached', timeout: 30000 });
        console.log('Enabling Flutter Web accessibility tree...');
        await placeholder.dispatchEvent('click');
        await page.waitForTimeout(3000);
    } catch (e) {
        console.log('Flutter placeholder not found within timeout. Proceeding...');
    }
    
    // Check if we are already logged in. 
    // On CanvasKit, getByText works once semantics are enabled.
    const isDashboardVisible = await page.getByText('Résumé (Statistiques des Enveloppes)', { exact: false }).isVisible() ||
                               await page.locator('flt-semantics-host').getByText('Résumé', { exact: false }).isVisible();
    
    if (isDashboardVisible) {
        console.log('Already logged in, skipping authentication steps.');
    } else {
        console.log(`Authenticating with ${email}...`);
        
        // Wait for the login form inputs to appear
        const emailSelector = 'input#email, input[name="email"], input[aria-label="Email"]';
        const passwordSelector = 'input#current-password, input[type="password"], input[aria-label="Password"]';
        
        await Promise.race([
            page.waitForSelector(emailSelector, { timeout: 15000 }),
            page.waitForSelector('flt-semantics-host input', { timeout: 15000 }),
            page.waitForSelector('text=Résumé', { timeout: 15000 })
        ]).catch(() => {});

        const emailInput = page.locator(emailSelector).first();
        const passwordInput = page.locator(passwordSelector).first();

        if (await emailInput.count() > 0) {
            console.log('Filling email...');
            await emailInput.click();
            await emailInput.fill(email);
            
            console.log('Filling password...');
            await passwordInput.click();
            await passwordInput.fill(password);
            
            console.log('Submitting login form...');
            // Find and click the Sign in button
            const signInButton = page.locator('button:has-text("Sign in"), button:has-text("Se connecter"), flt-semantics[role="button"]:has-text("Sign in"), flt-semantics[role="button"]:has-text("Se connecter"), [aria-label="Sign in"]').first();
            if (await signInButton.count() > 0) {
                await signInButton.click();
            } else {
                await page.keyboard.press('Enter');
            }
            await page.waitForTimeout(5000);
        }
    }

    // Wait until the dashboard loads (either via getByText or in the semantics tree)
    await expect(async () => {
        // Re-enable accessibility if it got reset after login/navigation
        if (await placeholder.count() > 0) {
            await placeholder.dispatchEvent('click');
            await page.waitForTimeout(1000);
        }
        const visible = await page.getByText('Solde Total Disponible', { exact: false }).isVisible() ||
                        await page.locator('flt-semantics-host').getByText('Solde Total Disponible', { exact: false }).isVisible() ||
                        await page.getByText('Actions Rapides', { exact: false }).isVisible() ||
                        await page.locator('flt-semantics-host').getByText('Actions Rapides', { exact: false }).isVisible();
        expect(visible).toBe(true);
    }).toPass({ timeout: 25000 });

    console.log('Authentication successful.');
    await page.context().storageState({ path: authFile });
});
