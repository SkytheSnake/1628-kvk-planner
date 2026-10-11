import assert from 'node:assert/strict';
import { chromium } from 'playwright';
const browser = await chromium.launch({ headless: true });
try {
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('http://localhost:8000/', { waitUntil: 'domcontentloaded' });
  await page.locator('#connectionBanner.ok').waitFor({ timeout: 90000 });
  assert.equal(await page.locator('#slotList > *').count() > 0, true);
  await page.locator('#profileBtn').click();
  await page.locator('#playerId').fill('migration-test-a');
  await page.locator('#findProfileBtn').click();
  await page.waitForFunction(() => document.getElementById('profilePlayerId')?.textContent === 'migration-test-a', null, { timeout: 60000 });
  assert.equal(await page.locator('#profileTruegold').textContent(), '250');
  await page.goto('http://localhost:8000/admin.html', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(5000);
  assert.equal(await page.locator('#adminLoginCard').isVisible(), true);
  assert.equal(await page.locator('#adminApp').isVisible(), false);
  assert.deepEqual(errors, []);
  console.log('Planner connected, Player ID profile loaded, and admin login remained protected.');
} finally {
  await browser.close();
}
