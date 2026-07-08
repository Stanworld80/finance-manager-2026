import { Page, expect } from '@playwright/test';

export async function ensureAuthenticated(page: Page) {
    const email = process.env.TEST_USER_EMAIL || 'comptetechnique001@stanworld.org';
    const password = process.env.TEST_USER_PASSWORD || 'Tester=2026';
    const baseUrl = process.env.BASE_URL || 'https://finance-manager-2026-stg.web.app';

    console.log(`Ensuring authentication on ${baseUrl}`);
    
    // Only navigate if we are not already on the site
    if (!page.url().startsWith(baseUrl)) {
        await page.goto(baseUrl);
    }

    // Wait for the Flutter Web bootstrapper to attach the placeholder to the DOM
    const placeholder = page.locator('flt-semantics-placeholder');
    try {
        await placeholder.waitFor({ state: 'attached', timeout: 20000 });
        await placeholder.dispatchEvent('click');
        await page.waitForTimeout(2000);
    } catch (e) {
        // Already loaded/enabled
    }

    // Check if we are on the dashboard
    const isDashboardVisible = await page.getByText('Solde Total Disponible', { exact: false }).isVisible() ||
                               await page.locator('flt-semantics-host').getByText('Solde Total Disponible', { exact: false }).isVisible() ||
                               await page.locator('flt-semantics-host').getByText('Actions Rapides', { exact: false }).isVisible();

    if (isDashboardVisible) {
        console.log('Already authenticated and on Dashboard.');
        return;
    }

    console.log('Not authenticated. Performing login...');
    
    // Wait for the login form inputs to appear
    const emailSelector = 'input#email, input[name="email"], input[aria-label="Email"]';
    const passwordSelector = 'input#current-password, input[type="password"], input[aria-label="Password"]';
    
    await Promise.race([
        page.waitForSelector(emailSelector, { timeout: 15000 }),
        page.waitForSelector('flt-semantics-host input', { timeout: 15000 })
    ]).catch(() => {});

    const emailInput = page.locator(emailSelector).first();
    const passwordInput = page.locator(passwordSelector).first();

    if (await emailInput.count() > 0) {
        await emailInput.click();
        await emailInput.fill(email);
        
        await passwordInput.click();
        await passwordInput.fill(password);
        
        const signInButton = page.locator('button:has-text("Sign in"), button:has-text("Se connecter"), flt-semantics[role="button"]:has-text("Sign in"), flt-semantics[role="button"]:has-text("Se connecter"), [aria-label="Sign in"]').first();
        if (await signInButton.count() > 0) {
            await signInButton.click();
        } else {
            await page.keyboard.press('Enter');
        }
        await page.waitForTimeout(4000);
    }

    // Wait until the dashboard loads
    await expect(async () => {
        if (await placeholder.count() > 0) {
            await placeholder.dispatchEvent('click');
            await page.waitForTimeout(1000);
        }
        const visible = await page.getByText('Solde Total Disponible', { exact: false }).isVisible() ||
                        await page.locator('flt-semantics-host').getByText('Solde Total Disponible', { exact: false }).isVisible() ||
                        await page.locator('flt-semantics-host').getByText('Actions Rapides', { exact: false }).isVisible();
        expect(visible).toBe(true);
    }).toPass({ timeout: 25000 });

    console.log('Authentication successful.');
}

export async function confirmDateIfDialogPresent(page: Page) {
    await page.waitForTimeout(1000); // Wait for the dialog animation
    const placeholder = page.locator('flt-semantics-placeholder');
    if (await placeholder.count() > 0) {
        await placeholder.dispatchEvent('click');
        await page.waitForTimeout(500);
    }
    const confirmButton = page.locator('button:has-text("Confirmer"), flt-semantics[role="button"]:has-text("Confirmer"), [aria-label="Confirmer"]').first();
    if (await confirmButton.count() > 0) {
        console.log('Date confirmation dialog detected. Clicking "Confirmer"...');
        await confirmButton.click().catch(() => confirmButton.dispatchEvent('click'));
        await page.waitForTimeout(2000);
        await enableAccessibility(page);
    }
}

export async function enableAccessibility(page: Page) {
    const placeholder = page.locator('flt-semantics-placeholder');
    try {
        await placeholder.waitFor({ state: 'attached', timeout: 10000 });
        await placeholder.dispatchEvent('click');
        await page.waitForTimeout(2000);
    } catch (e) {
        // Already enabled or html renderer
    }
}

export async function clickDetailActionButton(page: Page, action: 'edit' | 'delete') {
    const cancelBtn = page.getByRole('button', { name: 'Annuler la transaction' });
    const buttons = page.getByRole('button');
    const count = await buttons.count();
    let cancelIndex = -1;
    for (let i = 0; i < count; i++) {
        const name = await buttons.nth(i).getAttribute('aria-label') || await buttons.nth(i).innerText() || '';
        if (name.includes('Annuler la transaction')) {
            cancelIndex = i;
            break;
        }
    }
    if (cancelIndex !== -1) {
        if (action === 'edit') {
            console.log('Clicking Edit button on Details screen...');
            await buttons.nth(cancelIndex - 1).click();
        } else if (action === 'delete') {
            console.log('Clicking Delete button on Details screen...');
            await buttons.nth(cancelIndex + 1).click();
        }
    } else {
        console.error('Could not find "Annuler la transaction" button to position edit/delete clicks.');
        if (action === 'edit') {
            await page.locator('button').nth(1).click();
        } else {
            await page.locator('button').nth(3).click();
        }
    }
}
