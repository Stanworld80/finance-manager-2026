import { test, expect } from '@playwright/test';
import { ensureAuthenticated, confirmDateIfDialogPresent, enableAccessibility, clickDetailActionButton } from './auth_helper';

test.describe('Transactions CRUD E2E', () => {

    test.beforeEach(async ({ page }) => {
        test.setTimeout(240000); // 4 minutes timeout per test to support older hardware
        await ensureAuthenticated(page);
    });

    test('CRUD Dépense', async ({ page }) => {
        const uniqueLabel = `Depense TEST ${Date.now()}`;
        console.log(`Creating expense: ${uniqueLabel}`);

        // Click 'Dépense' button in top bar
        await page.getByRole('button', { name: 'Dépense', exact: true }).click();
        await enableAccessibility(page);
        await page.waitForTimeout(1000);

        // Verify we are on Add Transaction page with Dépense selected
        await expect(page.getByText('Nouvelle Transaction')).toBeVisible();

        // Fill Montant Total
        await page.getByLabel('Montant Total', { exact: false }).click();
        await page.keyboard.type('42.50', { delay: 10 });

        // Fill Libellé
        await page.getByLabel('Libellé', { exact: false }).click();
        await page.keyboard.type(uniqueLabel, { delay: 10 });

        // Select an origin account (e.g., first non-external)
        // Note: Flutter dropdowns in web can be tricky, using getByLabel for the SearchableAccountSelector
        // await page.getByLabel('De (Origine)').click();
        // Skip specific selection for now if default is OK, or try to click it

        // Click Save
        await page.getByRole('button', { name: /Ajouter|Enregistrer|Save/i }).first().click();
        await confirmDateIfDialogPresent(page);
        await page.waitForTimeout(4000);

        // Verify creation in list
        await expect(page.getByText(uniqueLabel).first()).toBeVisible({ timeout: 10000 });

        // --- VERIFY DETAILS ---
        console.log('Verifying the expense details...');
        await page.getByText(uniqueLabel).first().click();
        await enableAccessibility(page);
        await page.waitForTimeout(2000);

        // Verify Amount and Type
        await expect(page.getByText('42.50').first()).toBeVisible();
        await expect(page.getByText('SOURCE').first()).toBeVisible();
        await expect(page.getByText('DESTINATION').first()).toBeVisible();

        // --- MODIFY ---
        console.log('Modifying the expense...');
        await clickDetailActionButton(page, 'edit');
        await enableAccessibility(page);
        await page.waitForTimeout(1000);

        const modifiedLabel = `${uniqueLabel} MOD`;
        await page.getByLabel('Libellé', { exact: false }).click();
        await page.keyboard.down('Control');
        await page.keyboard.press('A');
        await page.keyboard.up('Control');
        await page.keyboard.press('Backspace');
        await page.keyboard.type(modifiedLabel, { delay: 10 });

        // Change amount
        await page.getByLabel('Montant Total', { exact: false }).click();
        await page.keyboard.down('Control');
        await page.keyboard.press('A');
        await page.keyboard.up('Control');
        await page.keyboard.press('Backspace');
        await page.keyboard.type('100.00', { delay: 10 });

        await page.getByRole('button', { name: /Sauvegarder|Enregistrer|Update/i }).first().click();
        await confirmDateIfDialogPresent(page);
        await page.waitForTimeout(4000);

        // Verify modification
        await expect(page.getByText(modifiedLabel).first()).toBeVisible({ timeout: 10000 });

        // --- DELETE ---
        console.log('Deleting the transaction...');
        await clickDetailActionButton(page, 'delete');
        await page.waitForTimeout(1000);
        await page.getByRole('button', { name: /Supprimer|Confirmer|Oui/, exact: false }).first().click();
        await page.waitForTimeout(4000);

        // Verify deletion
        await expect(page.getByText(modifiedLabel).first()).toBeHidden({ timeout: 10000 });
    });

    test('CRUD Revenu', async ({ page }) => {
        const uniqueLabel = `Revenu TEST ${Date.now()}`;
        console.log(`Creating income: ${uniqueLabel}`);

        await page.getByRole('button', { name: 'Revenu', exact: true }).click();
        await enableAccessibility(page);
        await page.waitForTimeout(1000);

        await page.getByLabel('Montant Total', { exact: false }).click();
        await page.keyboard.type('1500.00', { delay: 10 });

        await page.getByLabel('Libellé', { exact: false }).click();
        await page.keyboard.type(uniqueLabel, { delay: 10 });

        await page.getByRole('button', { name: /Ajouter|Enregistrer|Save/i }).first().click();
        await confirmDateIfDialogPresent(page);
        await page.waitForTimeout(4000);

        await expect(page.getByText(uniqueLabel).first()).toBeVisible({ timeout: 10000 });

        // Verify and delete
        await page.getByText(uniqueLabel).first().click();
        await enableAccessibility(page);
        await expect(page.getByText('1500.00').first()).toBeVisible();
        
        await clickDetailActionButton(page, 'delete');
        await page.waitForTimeout(500);
        await page.getByRole('button', { name: /Supprimer|Confirmer|Oui/, exact: false }).first().click();
        await page.waitForTimeout(4000);
        await expect(page.getByText(uniqueLabel).first()).toBeHidden();
    });

    test('CRUD Virement', async ({ page }) => {
        const uniqueLabel = `Virement TEST ${Date.now()}`;
        console.log(`Creating transfer: ${uniqueLabel}`);

        // Click 'Virement' (Transfer) button
        await page.getByRole('button', { name: 'Virement', exact: true }).click();
        await enableAccessibility(page);
        await page.waitForTimeout(1000);

        await page.getByLabel('Montant Total', { exact: false }).click();
        await page.keyboard.type('50.00', { delay: 10 });

        await page.getByLabel('Libellé', { exact: false }).click();
        await page.keyboard.type(uniqueLabel, { delay: 10 });

        // By default, Virement should have two internal accounts. 
        // We assume staging has at least two envelopes.
        
        await page.getByRole('button', { name: /Ajouter|Enregistrer|Save/i }).first().click();
        await confirmDateIfDialogPresent(page);
        await page.waitForTimeout(4000);

        await expect(page.getByText(uniqueLabel).first()).toBeVisible({ timeout: 10000 });

        // Verify details
        await page.getByText(uniqueLabel).first().click();
        await enableAccessibility(page);
        await page.waitForTimeout(1000);
        await expect(page.getByText('50.00').first()).toBeVisible();
        // Check "Virement Lié" or specific labels if applicable
        
        // --- DELETE ---
        console.log('Deleting transfer...');
        await clickDetailActionButton(page, 'delete');
        await page.waitForTimeout(500);
        await page.getByRole('button', { name: /Supprimer|Confirmer|Oui/, exact: false }).first().click();
        await page.waitForTimeout(4000);
        await expect(page.getByText(uniqueLabel).first()).toBeHidden();
    });
});
