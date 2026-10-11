(function(root){
'use strict';
const SAUL=[0,3,6,9,12,15], WOLF=[0,5,7,9,12,15], PAN=[0,2,3,4,6,8];
const resourceKeys=['bread','wood','stone','iron','truegold','tempered_truegold'];
function number(v,name,max=1e15){
 const n=Number(v); if(v==='' || v==null || !Number.isFinite(n)||n<0||n>max) throw Error(`Enter a valid ${name}.`); return n;
}
function rank(v,name){ const n=number(v,name,5);if(!Number.isInteger(n))throw Error(`Invalid ${name}.`);return n; }
function label(n){n=Number(n);if(n<=30)return String(n);const tier=Math.floor((n-30)/5),stage=(n-30)%5;return stage?`${tier ? 'TG'+tier : '30'}.${stage}`:`TG${tier}`;}
function parseResource(v){
 const s=String(v).trim().replace(/,/g,'');const m=/^(\d+(?:\.\d+)?)([kmb])?$/i.exec(s);
 if(!m)throw Error('Use a positive number, or a short form such as 500K, 1.5M or 2B.');
 const n=Number(m[1])*({k:1e3,m:1e6,b:1e9}[m[2]?.toLowerCase()]||1);return number(n,'resource amount');
}
function calculate(data,city,plan,stats,buffs,includePrerequisites=true){
 if(!Array.isArray(plan)||!plan.length)throw Error('Add at least one building to your plan.');
 const saul=rank(stats.saul_level??0,'Saul level'),wolf=rank(stats.wolf_rank??0,'Wolf rank'),pan=rank(stats.pan_level??0,'Pan level');
 let speed=number(stats.construction_speed,'Construction Speed',10000);
 if(buffs.high_king&&buffs.kvk)throw Error('High King and KvK construction bonuses cannot be selected together.');
 if(buffs.wolf)speed+=WOLF[wolf];
 if(buffs.chief)speed+=buffs.high_king?number(buffs.position_percent,'High King position percentage',100):10;
 if(buffs.groundworks)speed+=10;if(buffs.kvk)speed+=5;
 const states={},requested={},warnings=new Set(),steps=[],visiting=new Set();
 for(const [k,v] of Object.entries(city||{})){
  if(!data[k])continue;const n=number(v,`${data[k].name} level`,data[k].maximum);
  if(!Number.isInteger(n)||n!==0&&!data[k].rows[n])throw Error(`Invalid saved ${data[k].name} level.`);states[k]=n;
 }
 for(const p of plan){
  if(!data[p.building])throw Error('Unknown building.');
  const n=number(p.target,`${data[p.building].name} target`,data[p.building].maximum);
  if(!Number.isInteger(n)||!data[p.building].rows[n])throw Error('Invalid target level.');
  if(states[p.building]===undefined)throw Error(`Save your current ${data[p.building].name} level first.`);
  if(n<=states[p.building])throw Error(`${data[p.building].name}: choose a target above your saved level.`);
  requested[p.building]=Math.max(requested[p.building]||0,n);
 }
 function upgrade(key,target){
  const building=data[key];if(states[key]===undefined)throw Error(`Save your current ${building.name} level so prerequisites can be calculated.`);
  if(states[key]>=target)return;
  const marker=`${key}:${target}`;if(visiting.has(marker))throw Error('A circular prerequisite was found. Check the building data.');visiting.add(marker);
  while(states[key]<target){
   const from=states[key],next=from===0?building.minimum:from+1,row=building.rows[next];
   if(!row)throw Error(`No verified data for ${building.name} ${label(next)}.`);
   for(const [dep,level] of Object.entries(row.requires)){
    if(includePrerequisites){upgrade(dep,level);}else if(states[dep]===undefined||states[dep]<level){warnings.add(`Requires ${data[dep].name} ${label(level)}; prerequisite costs are excluded.`);}
   }
   for(const text of row.unsupported||[])warnings.add(`Check ${text} in-game; these early utility building costs are excluded.`);
   // Saul's speed is ALREADY in the displayed account speed; apply only his RSS discount.
   const cost=Object.fromEntries(resourceKeys.map(k=>[k,k==='truegold'||k==='tempered_truegold'?row[k]:Math.ceil(row[k]*(100-SAUL[saul])/100)]));
   const timeWithSpeed=row.seconds/(1+speed/100)*(buffs.double_time?0.8:1);
   // Pan's fixed deduction is an estimate until the order is validated against a live timer.
   const seconds=Math.max(0,timeWithSpeed-PAN[pan]*3600);
   const speedupMinutes=Math.ceil(seconds/60);
   steps.push({building:key,name:building.name,from,to:next,auto:!requested[key]||next>requested[key],...cost,baseSeconds:row.seconds,seconds,speedupMinutes,requires:row.requires});
   states[key]=next;
  }
  visiting.delete(marker);
 }
 for(const key of Object.keys(requested))upgrade(key,requested[key]);
 const totals={...Object.fromEntries(resourceKeys.map(k=>[k,0])),baseSeconds:0,seconds:0,speedupMinutes:0};
 for(const step of steps)for(const k of Object.keys(totals))totals[k]+=step[k];
 const points={truegold:totals.truegold*2000,tempered_truegold:buffs.ttg_scoring?totals.tempered_truegold*30000:0,speedups:totals.speedupMinutes*30};
 if(totals.tempered_truegold&&!buffs.ttg_scoring)warnings.add('Tempered Truegold points are excluded until you confirm this task is available in your KvK event.');
 if(pan)warnings.add('Pan estimate: his fixed time deduction is applied after speed and Double Time for each stage. Check one live upgrade timer before relying on this estimate.');
 return {steps,totals,points,totalPoints:Object.values(points).reduce((a,b)=>a+b,0),speed,states,warnings:[...warnings]};
}
const api={SAUL,WOLF,PAN,resourceKeys,label,parseResource,calculate};
if(typeof module!=='undefined'&&module.exports)module.exports=api;else root.KVK_CALC=api;
})(typeof window!=='undefined'?window:globalThis);
