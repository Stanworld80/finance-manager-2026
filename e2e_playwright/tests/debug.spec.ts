import { test, expect } from '@playwright/test';

test('dump dom', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(5000); // give it time to load Flutter

    // Try to force semantics by tabbing or clicking
    await page.keyboard.press('Tab');
    await page.waitForTimeout(2000);

    const content = await page.content();
    console.log(content.substring(0, 3000));

    // Check for semantic tags
    const semanticsCount = await page.locator('flt-semantics').count();
    console.log(`Semantic tags count: ${semanticsCount}`);

    // Also dump input tags
    const inputCount = await page.locator('input').count();
    console.log(`Input tags count: ${inputCount}`);
});
