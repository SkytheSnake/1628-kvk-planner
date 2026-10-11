const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const {spawn}=require('node:child_process');const path=require('node:path');let server;
process.on('exit',()=>server?.kill());
const fixture={id:'11111111-1111-1111-1111-111111111111',user_id:'test-user',player_id:'123456',player_name:'Sky',alliance:'CRN',truegold:120,general_speedups:100,construction_speedups:100,research_speedups:45,training_speedups:77,resource_snapshot_required:false,updated_at:'2026-10-05T12:00:00.000Z',calculator_profile:{},calculator_revision:0,calculator_updated_at:null};
(async()=>{
 server=spawn('python3',['-u','-m','http.server','8765','--bind','127.0.0.1','--directory',path.resolve(__dirname,'..')]);await new Promise((resolve,reject)=>{server.stdout.once('data',resolve);server.once('error',reject);});
 const browser=await chromium.launch({headless:true,...(process.env.CHROMIUM_PATH?{executablePath:process.env.CHROMIUM_PATH,args:['--no-sandbox','--no-zygote','--single-process','--disable-dev-shm-usage']}: {})});const context=await browser.newContext({viewport:{width:1440,height:1000},serviceWorkers:'block'});
 await context.route('**/backend.js*',r=>r.fulfill({body:`export const playerDeviceId=()=> 'test-user'; export const playerRpc=(name,args={})=> name==='get_player_profile'?Promise.resolve({data:[window.__testRow()]}):window.__testSave(name,args);`,contentType:'text/javascript'}));
 await context.addInitScript(({fixture})=>{
  window.__testSaveError=false;
  const row=()=>JSON.parse(localStorage.getItem('testDatabase')||JSON.stringify(fixture));
  window.__testRow=row;
  const put=v=>localStorage.setItem('testDatabase',JSON.stringify(v));
  window.__testSave=async(name,args)=>{
   if(window.__testSaveError)return {error:{message:'Simulated connection failure'}};
   const v=row();if(args.p_profile_id!==v.id||args.p_expected_revision!==v.calculator_revision||args.p_expected_updated_at!==v.updated_at)return {error:{message:'Your profile changed in another tab or device. Refresh this page.'}};
   const p=args.p_patch;for(const k of ['stats','city','preferences','plan'])if(k in p)v.calculator_profile[k]=p[k];
   if(p.resources)v.calculator_profile.resources={...v.calculator_profile.resources,...p.resources};
   if(p.booking)Object.assign(v,p.booking);if(p.resources_checked_at)v.calculator_profile.resources_checked_at=new Date().toISOString();
   v.calculator_revision++;v.updated_at=new Date().toISOString();v.calculator_updated_at=v.updated_at;put(v);return {data:v};
  };
 },{fixture});
 const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto('http://127.0.0.1:8765/calculator.html');await page.waitForSelector('#resourceDialog[open]');
 assert.equal(await page.locator('[data-resource="truegold"]').inputValue(),'120');
 assert.equal(await page.locator('#looksGood').isVisible(),false);
 for(const k of ['bread','wood','stone','iron'])await page.locator(`[data-resource="${k}"]`).evaluate(el=>{el.value='1B';el.dispatchEvent(new Event('input',{bubbles:true}));});
 await page.locator('[data-resource="tempered_truegold"]').evaluate(el=>{el.value='0';el.dispatchEvent(new Event('input',{bubbles:true}));});
 await page.evaluate(()=>window.__testSaveError=true);await page.click('#saveResources');await page.waitForSelector('#resourceError:not([hidden])');assert.equal(await page.locator('#resourceDialog').evaluate(el=>el.open),true);
 await page.evaluate(()=>window.__testSaveError=false);await page.click('#saveResources');await page.waitForFunction(()=>!document.getElementById('resourceDialog').open);
 await page.locator('#constructionSpeed').evaluate(el=>{el.value='100';el.dispatchEvent(new Event('input',{bubbles:true}));});await page.selectOption('#saulLevel','5');await page.click('#statsForm button');await page.waitForFunction(()=>JSON.parse(localStorage.getItem('testDatabase')).calculator_profile.stats?.saul_level===5);
 for(const [k,n] of Object.entries({town_center:39,embassy:35,stable:35,academy:30}))await page.selectOption(`[data-city="${k}"]`,String(n));
 await page.click('#cityForm button');await page.waitForFunction(()=>JSON.parse(localStorage.getItem('testDatabase')).calculator_profile.city?.town_center===39);
 await page.selectOption('[data-plan-target="0"]','40');await page.click('#savePlan');await page.waitForFunction(()=>JSON.parse(localStorage.getItem('testDatabase')).calculator_profile.plan?.[0].target===40);
 await page.click('#calculateBtn');await page.waitForSelector('#resultSection:not([hidden])');assert.match(await page.locator('#stageResults').textContent(),/TG1\.4 → TG2/);assert.match(await page.locator('#resourceResults').textContent(),/38 short/);
 let saved=await page.evaluate(()=>JSON.parse(localStorage.getItem('testDatabase')));assert.equal(saved.truegold,120);assert.equal(saved.research_speedups,45);assert.equal(saved.training_speedups,77);
 await page.screenshot({path:path.join(__dirname,'../../calculator-desktop.png'),fullPage:true});
 await page.reload();await page.waitForFunction(()=>!document.getElementById('calculateBtn').disabled);assert.equal(await page.locator('#resourceDialog').evaluate(el=>el.open),false);assert.equal(await page.locator('#constructionSpeed').inputValue(),'100');assert.equal(await page.locator('[data-plan-target="0"]').inputValue(),'40');
 // A fresh session marker should prompt; saved amounts and stats must persist.
 await page.evaluate(()=>sessionStorage.clear());await page.reload();await page.waitForSelector('#resourceDialog[open]');assert.equal(await page.locator('[data-resource="bread"]').inputValue(),'1000000000');await page.click('#looksGood');await page.waitForFunction(()=>!document.getElementById('resourceDialog').open);
 // Concurrent booking updates cannot be overwritten by a calculator save.
 await page.evaluate(()=>{const v=JSON.parse(localStorage.getItem('testDatabase'));v.truegold=999;v.updated_at='2026-10-05T13:00:00.000Z';localStorage.setItem('testDatabase',JSON.stringify(v));});
 await page.click('#editResources');await page.click('#looksGood');await page.waitForSelector('#resourceError:not([hidden])');assert.match(await page.locator('#resourceError').textContent(),/changed/);saved=await page.evaluate(()=>JSON.parse(localStorage.getItem('testDatabase')));assert.equal(saved.truegold,999);
 await page.evaluate(()=>sessionStorage.clear());await page.reload();await page.waitForSelector('#resourceDialog[open]');await page.click('#looksGood');await page.waitForFunction(()=>!document.getElementById('resourceDialog').open);
 await page.setViewportSize({width:390,height:844});await page.click('#calculateBtn');await page.waitForSelector('#resultSection:not([hidden])');assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth));await page.screenshot({path:path.join(__dirname,'../../calculator-mobile.png'),fullPage:true});
 assert.deepEqual(errors,[]);console.log('PASS browser: profile persistence, resource prompt, failed save, overlapping resources, reload, new session, concurrent update protection, desktop/mobile layout, no JS errors');
 await browser.close();server.kill();
})().catch(e=>{console.error(e);process.exit(1);});
