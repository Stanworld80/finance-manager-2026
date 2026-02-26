import { test, expect } from '@playwright/test';

test.describe('Transactions E2E', () => {

    test.beforeEach(async ({ page }) => {
        // Go to the dashboard
        await page.goto(process.env.BASE_URL || 'http://localhost:3000');
        // Wait for initial load
        await page.waitForTimeout(3000);
    });

    test('Create, Modify, and Delete Transaction', async ({ page }) => {
        // Note: This test relies on the app being run with HTML renderer:
        // flutter run -d web-server --web-hostname localhost --web-port 3000 --web-renderer html

        // --- CREATE TRANSACTION ---
        console.log('Creating a new transaction...');
        // In Flutter, floating action buttons usually have tooltip or readable text/icons
        // Using a generic approach. Adjust selector based on actual semantic output:
        // e.g. await page.getByRole('button', { name: "Nouvelle Transaction" }).click();
        // Assuming there's a button with text "Nouvelle Transaction" or a FAB icon.
        // We try to find a link or button that says 'Nouvelles Transactions' or similar.
        // If the FAB only has an icon, it should have a tooltip. Let's try to click New Transaction.
        const newTxButton = page.locator('button', { hasText: /Nouvelle|Transaction/i }).first();
        // Wait for it, fallback to the generic FAB wrapper if available
        await newTxButton.waitFor({ state: 'attached', timeout: 10000 }).catch(() => { });
        await newTxButton.click().catch(() => page.mouse.click(page.viewportSize()!.width - 50, page.viewportSize()!.height - 50));
        // Fallback: click bottom right if button not found (common FAB location)

        // Wait for the form to appear
        await page.waitForTimeout(2000);

        // Fill the transaction form
        // Amount
        await page.getByLabel('Montant', { exact: false }).fill('50.00').catch(() => page.locator('input[type="text"]').first().fill('50.00'));

        // Label/Title
        const uniqueLabel = `Playwright E2E Test ${Date.now()}`;
        await page.getByLabel('Titre', { exact: false }).fill(uniqueLabel).catch(() => page.locator('input[type="text"]').nth(1).fill(uniqueLabel));

        // Save
        await page.getByRole('button', { name: /Ajouter|Enregistrer|Save/i }).first().click();

        // Give time to save and return
        await page.waitForTimeout(3000);

        // Verify creation
        await expect(page.getByText(uniqueLabel)).toBeVisible({ timeout: 10000 });

        // --- MODIFY TRANSACTION ---
        console.log('Modifying the transaction...');
        // Click on the transaction we just created
        await page.getByText(uniqueLabel).click();
        await page.waitForTimeout(2000);

        // Edit button or form immediately opens. Let's assume there's an edit icon/button
        const editBtn = page.getByRole('button', { name: /Modifier|Edit/i }).first();
        if (await editBtn.isVisible()) {
            await editBtn.click();
            await page.waitForTimeout(1000);
        }

        // Change the label
        const modifiedLabel = `${uniqueLabel} Modified`;
        await page.getByLabel('Titre', { exact: false }).fill(modifiedLabel).catch(() => page.locator('input[type="text"]').nth(1).fill(modifiedLabel));

        // Save changes
        await page.getByRole('button', { name: /Sauvegarder|Enregistrer|Update/i }).first().click();
        await page.waitForTimeout(3000);

        // Verify modification
        await expect(page.getByText(modifiedLabel)).toBeVisible({ timeout: 10000 });

        // --- DELETE TRANSACTION ---
        console.log('Deleting the transaction...');
        // Open the transaction details again
        await page.getByText(modifiedLabel).click();
        await page.waitForTimeout(2000);

        // Click delete
        await page.getByRole('button', { name: /Supprimer|Delete/i }).first().click();

        // Wait for confirmation dialog if any
        await page.waitForTimeout(1000);
        const confirmBtn = page.getByRole('button', { name: /Confirmer|Oui/, exact: false }).first();
        if (await confirmBtn.isVisible()) {
            await confirmBtn.click();
        }

        // Wait for deletion
        await page.waitForTimeout(3000);

        // Verify deletion
        await expect(page.getByText(modifiedLabel)).toBeHidden();
    });
});
