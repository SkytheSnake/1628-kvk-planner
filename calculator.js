import { playerRpc, playerDeviceId } from './backend.js?v=neon-1';
(() => {
'use strict';
const $=id=>document.getElementById(id), C=window.KVK_CALC, D=window.KVK_BUILDINGS;

const resourceLabels={bread:'Bread',wood:'Wood',stone:'Stone',iron:'Iron',truegold:'Truegold',tempered_truegold:'Tempered Truegold',construction_speedups:'Construction speedups (hours)',general_speedups:'General speedups (hours)'};
const shared=new Set(['truegold','construction_speedups','general_speedups']);
let profile=null,plan=[],sessionKey='',ready=false,busy=false,checked=false;
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const format=n=>Number(n).toLocaleString('en-GB',{maximumFractionDigits:2});
const compact=n=>n>=1e9?format(n/1e9)+'B':n>=1e6?format(n/1e6)+'M':n>=1e3?format(n/1e3)+'K':format(n);
function duration(s){s=Math.ceil(s);const d=Math.floor(s/86400),h=Math.floor(s%86400/3600),m=Math.floor(s%3600/60);return [d&&d+'d',h&&h+'h',m&&m+'m',(!d&&!h&&!m)?s+'s':''].filter(Boolean).join(' ');}
function error(e,target='calcError'){const el=$(target);el.textContent=e.message||String(e);el.hidden=false;}
function clearError(){$('calcError').hidden=true;}
function saved(){return profile?.calculator_profile||{};}
function city(){return saved().city||{};}
function owned(k){return shared.has(k)?Number(profile[k]||0):saved().resources?.[k];}
function hasResources(){return ['bread','wood','stone','iron','tempered_truegold'].every(k=>Number.isFinite(Number(saved().resources?.[k]))&&saved().resources?.[k]!=null);}
function assertReady(){if(!ready||!profile)throw Error('Open KvK bookings and complete your player profile first.');if(busy)throw Error('A profile save is already in progress. Please wait.');}
function updateIdentity(){
 $('calcIdentity').textContent=`${profile.alliance} · ${profile.player_name} · ID ${profile.player_id}`;
 const date=saved().resources_checked_at||profile.calculator_updated_at;
 $('resourceTimestamp').textContent='Resources last checked: '+(date?new Date(date).toLocaleString('en-GB'):'Not yet checked');
}
function levels(key,withUnknown=false){const b=D[key];let html=withUnknown?'<option value="">Not set</option><option value="0">Not built</option>':'';for(let n=b.minimum;n<=b.maximum;n++)html+=`<option value="${n}">${C.label(n)}</option>`;return html;}
function populate(){
 const p=saved(),s=p.stats||{};
 $('constructionSpeed').value=s.construction_speed??'';$('saulLevel').value=s.saul_level??0;$('wolfRank').value=s.wolf_rank??0;$('panLevel').value=s.pan_level??0;
 $('cityFields').innerHTML=Object.entries(D).map(([k,b])=>`<label class="calc-field">${b.name}<select data-city="${k}">${levels(k,true)}</select></label>`).join('');
 document.querySelectorAll('[data-city]').forEach(el=>{el.value=p.city?.[el.dataset.city]??'';});
 const prefs=p.preferences||{};
 for(const [k,id] of Object.entries({wolf:'wolfActive',chief:'chiefActive',groundworks:'groundworksActive',kvk:'kvkActive',double_time:'doubleTimeActive',high_king:'highKingActive',ttg_scoring:'ttgScoring'}))$(id).checked=!!prefs[k];
 $('positionPercent').value=prefs.position_percent??'';$('includePrerequisites').checked=prefs.include_prerequisites!==false;
 if($('highKingActive').checked)$('kvkActive').checked=false;
 updateBuffUI();updateIdentity();
}
function updateBuffUI(){
 $('wolfBonus').textContent=`(+${C.WOLF[Number($('wolfRank').value)]}%)`;
 $('panNote').hidden=!Number($('panLevel').value);
 $('positionField').hidden=!($('highKingActive').checked&&$('chiefActive').checked);
 $('positionPercent').required=!$('positionField').hidden;
}
function resourceInputs(){
 $('resourceError').hidden=true;
 $('resourceFields').innerHTML=Object.entries(resourceLabels).map(([k,label])=>`<label class="calc-field">${label}<input data-resource="${k}" type="text" inputmode="decimal" value="${owned(k)==null?'':esc(owned(k))}" required></label>`).join('');
 $('looksGood').hidden=!hasResources();
}
function openResources(){resourceInputs();$('resourceDialog').showModal();}
function acknowledge(){checked=true;try{sessionStorage.setItem(sessionKey,'1');}catch{}$('resourceDialog').close();$('calculateBtn').disabled=false;}
async function savePatch(patch){
 assertReady();busy=true;
 try{
  const {data,error:err}=await playerRpc('save_calculator_profile',{p_profile_id:profile.id,p_expected_revision:profile.calculator_revision??0,p_expected_updated_at:profile.updated_at,p_patch:patch});
  if(err)throw err;
  const row=Array.isArray(data)?data[0]:data;if(!row?.id||row.player_id!==profile.player_id)throw Error('The profile save did not return your player record.');
  profile=row;updateIdentity();$('saveStatus').textContent='✓ Saved to your player profile';$('saveStatus').className='calc-ok';$('resultSection').hidden=true;
 }finally{busy=false;}
}
function readStats(){return {construction_speed:Number($('constructionSpeed').value),saul_level:Number($('saulLevel').value),wolf_rank:Number($('wolfRank').value),pan_level:Number($('panLevel').value)};}
function readBuffs(){return {wolf:$('wolfActive').checked,chief:$('chiefActive').checked,groundworks:$('groundworksActive').checked,kvk:$('kvkActive').checked,double_time:$('doubleTimeActive').checked,high_king:$('highKingActive').checked,position_percent:$('positionPercent').value===''?null:Number($('positionPercent').value),ttg_scoring:$('ttgScoring').checked};}
function renderPlan(){
 $('planRows').innerHTML=plan.map((p,i)=>`<div class="calc-plan-row"><label>Building<select data-plan-building="${i}">${Object.entries(D).map(([k,b])=>`<option value="${k}" ${k===p.building?'selected':''}>${b.name}</option>`).join('')}</select></label><div><small>Current</small><div class="calc-current">${city()[p.building]==null?'Not set':city()[p.building]===0?'Not built':C.label(city()[p.building])}</div></div><label>Target<select data-plan-target="${i}">${levels(p.building)}</select></label><button class="secondary calc-remove" data-remove-plan="${i}" aria-label="Remove building ${i+1}">×</button></div>`).join('');
 plan.forEach((p,i)=>{document.querySelector(`[data-plan-target="${i}"]`).value=p.target;});
}
function defaultTarget(k){return Math.min(D[k].maximum,Math.max(D[k].minimum,(city()[k]??29)+1));}
async function saveResources(e){
 e?.preventDefault();$('resourceError').hidden=true;$('saveResources').disabled=true;$('looksGood').disabled=true;
 try{
  const resources={},booking={};
  document.querySelectorAll('[data-resource]').forEach(el=>{const k=el.dataset.resource,n=C.parseResource(el.value);if(k.includes('speedups')&&n>99999999)throw Error('Speedup hours are too large.');if((k==='truegold'||k==='tempered_truegold')&&!Number.isInteger(n))throw Error('Truegold and Tempered Truegold must be whole numbers.');if(k==='truegold'&&n>2147483647)throw Error('Truegold is too large.');(shared.has(k)?booking:resources)[k]=n;});
  for(const k of Object.keys(booking))if(booking[k]===Number(profile[k]))delete booking[k];
  await savePatch({resources,...(Object.keys(booking).length?{booking}:{}),resources_checked_at:new Date().toISOString()});acknowledge();
 }catch(e){error(e,'resourceError');}finally{$('saveResources').disabled=false;$('looksGood').disabled=false;}
}
function renderResult(r){
 const t=r.totals;
 $('resultSummary').innerHTML=`<div class="calc-stat"><span>BASE CONSTRUCTION</span><strong>${duration(t.baseSeconds)}</strong></div><div class="calc-stat"><span>YOUR TIME · +${format(r.speed)}% SPEED</span><strong>${duration(t.seconds)}</strong></div><div class="calc-stat"><span>ESTIMATED KvK POINTS</span><strong>${format(r.totalPoints)}</strong></div>`;
 let rows=C.resourceKeys.map(k=>{const own=owned(k)??0,short=Math.max(0,t[k]-own);return `<tr><td>${resourceLabels[k]}</td><td title="${format(t[k])}">${compact(t[k])}</td><td title="${format(own)}">${compact(own)}</td><td class="${short?'calc-short':'calc-enough'}">${short?compact(short)+' short':'✓ Enough'}</td></tr>`;}).join('');
 const construction=owned('construction_speedups')*60,general=owned('general_speedups')*60,remaining=Math.max(0,t.speedupMinutes-construction),short=Math.max(0,remaining-general);
 rows+=`<tr><td>Speedups to finish immediately</td><td>${format(t.speedupMinutes/60)}h</td><td>${format((construction+general)/60)}h combined</td><td class="${short?'calc-short':'calc-enough'}">${short?format(short/60)+'h short':'✓ Enough'}</td></tr>`;
 $('resourceResults').innerHTML=rows;
 $('pointBreakdown').textContent=`TG points: ${format(r.points.truegold)} · TTG points: ${format(r.points.tempered_truegold)} · Speedup points: ${format(r.points.speedups)}. Construction speedups available: ${format(construction/60)}h; general speedups needed after those: ${format(remaining/60)}h (${format(general/60)}h owned).`;
 $('resultWarnings').innerHTML=r.warnings.map(w=>`<p class="calc-note">${esc(w)}</p>`).join('');
 $('stageResults').innerHTML=r.steps.map(s=>`<tr><td>${s.name} ${s.from===0?'Not built':C.label(s.from)} → ${C.label(s.to)}${s.auto?' (prerequisite)':''}</td>${C.resourceKeys.slice(4).concat(C.resourceKeys.slice(0,4)).map(k=>`<td title="${format(s[k])}">${compact(s[k])}</td>`).join('')}<td>${duration(s.baseSeconds)}</td><td>${duration(s.seconds)}</td></tr>`).join('');
 $('resultSection').hidden=false;$('resultSection').scrollIntoView({behavior:'smooth',block:'start'});
}
async function start(){
 const theme=localStorage.getItem('kvkTheme')||'pink';if(['pink','purple','teal','green','blue'].includes(theme))document.documentElement.dataset.theme=theme;
 for(const [id,values,caption] of [['saulLevel',C.SAUL,'−% resources'],['wolfRank',C.WOLF,'+% speed'],['panLevel',C.PAN,'hours off each stage']])$(id).innerHTML=values.map((n,i)=>`<option value="${i}">${i?(id==='wolfRank'?'R':'Lv')+i+' · '+(id==='saulLevel'?'−'+n+'% resources':id==='wolfRank'?'+'+n+'% speed':n+'h off each stage'):'None'}</option>`).join('');
 $('resourceDialog').addEventListener('cancel',e=>e.preventDefault());$('resourceForm').addEventListener('submit',saveResources);
 $('looksGood').addEventListener('click',()=>saveResources());
 $('editResources').addEventListener('click',openResources);
 $('statsForm').addEventListener('submit',async e=>{e.preventDefault();clearError();try{await savePatch({stats:readStats()});updateBuffUI();}catch(e){error(e);}});
 $('cityForm').addEventListener('submit',async e=>{e.preventDefault();clearError();try{const values={};document.querySelectorAll('[data-city]').forEach(el=>{if(el.value!=='')values[el.dataset.city]=Number(el.value);});await savePatch({city:values});renderPlan();}catch(e){error(e);}});
 $('savePlan').addEventListener('click',async()=>{clearError();try{const b=readBuffs();if(b.high_king&&b.chief&&b.position_percent==null)throw Error('Enter the High King position percentage shown in-game.');await savePatch({plan,preferences:{...b,include_prerequisites:$('includePrerequisites').checked}});}catch(e){error(e);}});
 $('addBuilding').addEventListener('click',()=>{if(plan.length>=9)return;const k=Object.keys(D).find(k=>!plan.some(p=>p.building===k))||'town_center';plan.push({building:k,target:defaultTarget(k)});renderPlan();$('resultSection').hidden=true;});
 $('planRows').addEventListener('change',e=>{const b=e.target.dataset.planBuilding,t=e.target.dataset.planTarget;if(b!=null){plan[b]={building:e.target.value,target:defaultTarget(e.target.value)};renderPlan();}if(t!=null)plan[t].target=Number(e.target.value);$('resultSection').hidden=true;});
 $('planRows').addEventListener('click',e=>{const i=e.target.dataset.removePlan;if(i!=null){plan.splice(Number(i),1);renderPlan();$('resultSection').hidden=true;}});
 for(const id of ['wolfActive','chiefActive','groundworksActive','kvkActive','doubleTimeActive','highKingActive','ttgScoring','wolfRank','panLevel','includePrerequisites','positionPercent','constructionSpeed','saulLevel'])$(id).addEventListener('change',()=>{if(id==='highKingActive'&&$(id).checked)$('kvkActive').checked=false;if(id==='kvkActive'&&$(id).checked)$('highKingActive').checked=false;updateBuffUI();$('resultSection').hidden=true;});
 $('calculateBtn').addEventListener('click',()=>{clearError();try{assertReady();if(!checked||!hasResources()){openResources();return;}if(!$('statsForm').reportValidity())return;const s=readStats();if(!saved().stats)throw Error('Save your construction stats first.');if(Object.keys(s).some(k=>s[k]!==saved().stats[k]))throw Error('Save your changed construction stats before calculating.');const dirty=[...document.querySelectorAll('[data-city]')].some(el=>(el.value===''?undefined:Number(el.value))!==city()[el.dataset.city]);if(dirty)throw Error('Save your changed building levels before calculating.');renderResult(C.calculate(D,city(),plan,s,readBuffs(),$('includePrerequisites').checked));}catch(e){error(e);}});
 try{
  const {data,error:loadError}=await playerRpc('get_player_profile');
  if(loadError)throw loadError;profile=data?.[0];
  if(!profile||profile.resource_snapshot_required){location.replace('index.html');return;}
  if(!('calculator_profile' in profile))throw Error('The calculator database update has not been installed yet. Please return to bookings and try again later.');
  ready=true;sessionKey=`kvkCalculatorChecked:${playerDeviceId()}:${profile.player_id}`;
  populate();plan=(saved().plan||[]).filter(p=>D[p.building]&&Number.isInteger(p.target)&&D[p.building].rows[p.target]);if(!plan.length)plan=[{building:'town_center',target:defaultTarget('town_center')}];renderPlan();
  $('editResources').disabled=false;
  try{checked=sessionStorage.getItem(sessionKey)==='1';}catch{}
  if(!checked||!hasResources())openResources();else $('calculateBtn').disabled=false;
 }catch(e){error(e);$('calcIdentity').textContent='Unable to load your profile';}
}
start();
})();
