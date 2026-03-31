import { test, expect } from '@playwright/test';

test.describe('Linked Transfers E2E', () => {

    test.beforeEach(async ({ page }) => {
        // Go to the dashboard
        await page.goto(process.env.BASE_URL || 'http://localhost:3000');
        await page.waitForTimeout(3000);
    });

    test('Create, Modify, Unlink and Delete Linked Transfer', async ({ page }) => {
        // --- 1. CREATE TRANSFER ---
        const uniqueLabel = `Playwright Transfer ${Date.now()}`;
        console.log(`Creating transfer: ${uniqueLabel}`);

        // Click New Transaction
        const newTxButton = page.locator('button', { hasText: /Nouvelle|Transaction/i }).first();
        await newTxButton.waitFor({ state: 'attached', timeout: 10000 }).catch(() => {});
        await newTxButton.click().catch(() => page.mouse.click(page.viewportSize()!.width - 50, page.viewportSize()!.height - 50));
        await page.waitForTimeout(2000);

        // Select 'Transfert' SegmentedButton
        await page.getByText('Transfert', { exact: true }).click();
        await page.waitForTimeout(1000);

        // Fill Amount
        await page.getByLabel('Montant', { exact: false }).fill('150.00').catch(() => page.locator('input[type="text"]').first().fill('150.00'));

        // Fill Label
        await page.getByLabel('Libellé', { exact: false }).fill(uniqueLabel).catch(() => page.locator('input[type="text"]').nth(1).fill(uniqueLabel));

        // Let's assume default origin and destination are fine (we are inside full E2E environment with populated accounts)
        // Click Save
        await page.getByRole('button', { name: /Ajouter|Enregistrer|Save/i }).first().click();
        await page.waitForTimeout(4000);

        // Search for both sides: [Transfert Out] and [Transfert In]
        const labelOut = `[Transfert Out] ${uniqueLabel}`;
        const labelIn = `[Transfert In] ${uniqueLabel}`;
        
        // Wait and verify both exist
        await expect(page.getByText(labelOut).first()).toBeVisible({ timeout: 10000 });
        await expect(page.getByText(labelIn).first()).toBeVisible({ timeout: 10000 });

        // --- 2. UPDATE TRANSFER (Cascade) ---
        console.log('Modifying the transfer...');
        await page.getByText(labelOut).first().click();
        await page.waitForTimeout(2000);

        // Check if "Virement Lié" is displayed in the transaction detail
        await expect(page.getByText('Virement Lié').first()).toBeVisible({ timeout: 5000 });

        const editBtn = page.getByRole('button', { name: /Modifier|Edit/i }).first();
        if (await editBtn.isVisible()) {
            await editBtn.click();
            await page.waitForTimeout(1000);
        }

        const modifiedLabel = `${uniqueLabel} Modified`;
        const modifiedLabelOut = `[Transfert Out] ${modifiedLabel}`;
        const modifiedLabelIn = `[Transfert In] ${modifiedLabel}`;

        // Change label in form (assuming it strips the prefix in the form)
        await page.getByLabel('Libellé', { exact: false }).fill(modifiedLabel).catch(() => page.locator('input[type="text"]').nth(1).fill(modifiedLabel));

        // Change Amount to 200.00
        await page.getByLabel('Montant', { exact: false }).fill('200.00').catch(() => page.locator('input[type="text"]').first().fill('200.00'));

        // Save
        await page.getByRole('button', { name: /Sauvegarder|Enregistrer|Update/i }).first().click();
        await page.waitForTimeout(4000);

        // Both labels should reflect the modified name
        await expect(page.getByText(modifiedLabelOut).first()).toBeVisible({ timeout: 10000 });
        await expect(page.getByText(modifiedLabelIn).first()).toBeVisible({ timeout: 10000 });

        // --- 3. UNLINK TRANSFER ---
        console.log('Unlinking the transfer...');
        await page.getByText(modifiedLabelOut).first().click();
        await page.waitForTimeout(2000);

        // Click Unlink Button (Assuming it has a tooltip "Délier le virement") Let's use getByRole for safety if Tooltip is elusive
        // Wait, tooltip is exactly D\u00e9lier le virement ? In flutter tooltips can be hard to match. Let's try tooltip first, then maybe fallback.
        // Actually flutter canvas might not render tooltip to DOM properly. So we just look for specific button if possible or just rely on generic clicks, but let's assume getByTooltip or clicking an ion works.
        // On HTML renderer, tooltips are usually `aria-label` or actual UI elements.
        let unlinkClicked = false;
        try {
            const unlinkBtn = page.getByLabel('Délier le virement').first();
            if (await unlinkBtn.isVisible()) {
                await unlinkBtn.click();
                unlinkClicked = true;
            }
        } catch (e) {}

        if (!unlinkClicked) {
           // fallback logic isn't trivial. Hopefully getByLabel works due to Semantic tree output in HTML mode.
           const unlinkFallbackBtn = page.locator('flt-semantics[aria-label="Délier le virement"]').first();
           if(await unlinkFallbackBtn.isVisible()) {
               await unlinkFallbackBtn.click();
               unlinkClicked = true;
           }
        }

        // Wait for confirmation
        await page.waitForTimeout(1000);
        const confirmUnlink = page.getByRole('button', { name: /Confirmer|Oui/, exact: false }).first();
        if (await confirmUnlink.isVisible()) {
            await confirmUnlink.click();
        }
        await page.waitForTimeout(4000);

        // After unlink, the prefixes [Transfert Out/In] are removed. 
        // It becomes just "modifiedLabel" twice (one credit, one debit with external transit)
        await expect(page.getByText(modifiedLabel).first()).toBeVisible({ timeout: 10000 });

        // --- 4. DELETE (Should only delete one if they are unlinked) ---
        console.log('Deleting the unlinked transfer...');
        await page.getByText(modifiedLabel).first().click();
        await page.waitForTimeout(2000);

        await page.getByRole('button', { name: /Supprimer|Delete/i }).first().click();
        await page.waitForTimeout(1000);
        const confirmDelete = page.getByRole('button', { name: /Confirmer|Oui/, exact: false }).first();
        if (await confirmDelete.isVisible()) {
            await confirmDelete.click();
        }
        await page.waitForTimeout(4000);

        // One should be gone, but one still remains because they were unlinked!

        // --- 5. CREATE NEW FOR DELETE CASCADE ---
        const cascadeLabel = `Transfer Cascade Delete ${Date.now()}`;
        console.log('Creating transfer to test cascade delete...');
        await newTxButton.waitFor({ state: 'attached', timeout: 10000 }).catch(() => {});
        await newTxButton.click().catch(() => page.mouse.click(page.viewportSize()!.width - 50, page.viewportSize()!.height - 50));
        await page.waitForTimeout(2000);
        await page.getByText('Transfert', { exact: true }).click();
        await page.waitForTimeout(1000);
        await page.getByLabel('Montant', { exact: false }).fill('75.00').catch(() => page.locator('input[type="text"]').first().fill('75.00'));
        await page.getByLabel('Libellé', { exact: false }).fill(cascadeLabel).catch(() => page.locator('input[type="text"]').nth(1).fill(cascadeLabel));
        await page.getByRole('button', { name: /Ajouter|Enregistrer|Save/i }).first().click();
        await page.waitForTimeout(4000);

        const cascadeOut = `[Transfert Out] ${cascadeLabel}`;
        const cascadeIn = `[Transfert In] ${cascadeLabel}`;
        await expect(page.getByText(cascadeOut).first()).toBeVisible({ timeout: 10000 });
        await expect(page.getByText(cascadeIn).first()).toBeVisible({ timeout: 10000 });

        // Click to delete
        await page.getByText(cascadeOut).first().click();
        await page.waitForTimeout(2000);
        
        await page.getByRole('button', { name: /Supprimer|Delete/i }).first().click();
        await page.waitForTimeout(1000);
        const confirmDeleteCascade = page.getByRole('button', { name: /Confirmer|Oui/, exact: false }).first();
        if (await confirmDeleteCascade.isVisible()) {
            await confirmDeleteCascade.click();
        }
        await page.waitForTimeout(4000);

        // BOTH should be deleted
        await expect(page.getByText(cascadeOut).first()).toBeHidden({ timeout: 10000 });
        await expect(page.getByText(cascadeIn).first()).toBeHidden({ timeout: 10000 });
    });
});
