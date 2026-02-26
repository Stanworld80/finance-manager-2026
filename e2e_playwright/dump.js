const { chromium } = require('playwright');
(async () => {
    const browser = await chromium.launch();
    const page = await browser.newPage();
    console.log('Navigating to Staging...');
    await page.goto('https://finance-manager-2026-stg.web.app/?force-semantics=true');
    console.log('Waiting for load...');
    await page.waitForTimeout(5000);
    console.log('Clicking to trigger semantics...');
    await page.mouse.click(500, 500);
    await page.waitForTimeout(2000);
    console.log('Pressing Tab to trigger semantics...');
    await page.keyboard.press('Tab');
    await page.waitForTimeout(2000);

    const content = await page.content();
    console.log('DOM Dump:');
    console.log(content.substring(0, 3000));

    const inputsCount = await page.locator('input').count();
    console.log('Input count:', inputsCount);

    for (let i = 0; i < inputsCount; i++) {
        const html = await page.locator('input').nth(i).evaluate(el => el.outerHTML);
        console.log(`Input ${i}:`, html);
    }

    const semantics = await page.locator('flt-semantics').count();
    console.log('Semantics count:', semantics);

    await browser.close();
})();
