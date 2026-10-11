import assert from 'node:assert/strict';
import { chromium } from 'playwright';
const browser = await chromium.launch({ headless: true });
try {
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.addInitScript(() => {
    window.__kvkTestBackend = {
      auth: { getSession: async () => ({data:{user:{id:'test-owner'}},error:null}) },
      from(table) {
        const result = {data: table === 'admin_users' ? {admin_role:'owner',display_name:'Test Owner'} : [],error:null};
        const query = {
          select(){return this}, eq(){return this}, in(){return this},
          order(){return this}, limit(){return this}, maybeSingle(){return this},
          then(resolve,reject){return Promise.resolve(result).then(resolve,reject)}
        };
        return query;
      }
    };
  });
  await page.route('**/backend.js*', route => route.fulfill({
    contentType:'text/javascript',body:'export const backend = window.__kvkTestBackend;'
  }));
  await page.goto('http://localhost:8000/admin.html', {waitUntil:'domcontentloaded'});
  await page.locator('#adminSlotList .admin-slot').first().waitFor();
  for(const day of ['monday','tuesday','thursday']){
    await page.locator(`.day-tab[data-day="${day}"]`).click();
    await page.waitForFunction(() => document.querySelectorAll('#adminSlotList .admin-slot').length === 48);
    assert.equal(await page.locator('#adminSlotList .admin-slot').count(),48);
    assert.equal(await page.locator('#adminSlotList .slot-time').first().textContent(),'00:00–00:30');
    assert.equal(await page.locator('#adminSlotList .slot-time').last().textContent(),'23:30–00:00');
  }
  await page.locator('#adminSlotList .admin-slot').first().click();
  assert.equal(await page.locator('#applicantDialog').evaluate(el => el.open),true);
  assert.deepEqual(errors,[]);
  console.log('Authenticated admin: all 48 empty slots render on each event day and open for manual booking.');
} finally { await browser.close(); }
