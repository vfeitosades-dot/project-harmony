const testURL=process.env.QUEST_TEST_URL||'http://127.0.0.1:8766/';
const {chromium}=require('playwright');
const assert=require('node:assert/strict');
(async()=>{const browser=await chromium.launch({...(process.env.CHROMIUM_PATH?{executablePath:process.env.CHROMIUM_PATH}:{}),args:process.env.CHROMIUM_NO_SANDBOX==='1'?['--no-sandbox']:[]});const page=await browser.newPage();await page.goto(testURL);
const result=await page.evaluate(()=>{
 const landmarks=Array.from({length:21},(_,i)=>({x:.4+(i%4)*.02,y:.4+Math.floor(i/4)*.02,z:0}));landmarks[0]={x:.5,y:.7,z:0};landmarks[9]={x:.5,y:.5,z:0};landmarks[5]={x:.4,y:.5,z:0};landmarks[17]={x:.6,y:.5,z:0};landmarks[8]={x:.52,y:.25,z:0};landmarks[4]={x:.25,y:.4,z:0};
 Object.defineProperty(video,'readyState',{configurable:true,value:4});let t=0;Object.defineProperty(video,'currentTime',{configurable:true,get:()=>t++});hand.stream={};hand.engine={detectForVideo:()=>({landmarks:[landmarks]})};
 const now=performance.now();updateHands(now);updateHands(now+160);updateHands(now+320);const acquired=S.hand,armed=hand.armed;
 let clicks=0;const originalActivate=activate,originalTarget=targetAt;activate=()=>clicks++;targetAt=()=>'notes';selection.id='notes';selection.since=now;selection.fired=false;
 landmarks[4]={...landmarks[8]};for(let d=400;d<=1600;d+=80){selection.id='notes';updateHands(now+d);}const pinched=hand.pinched;
 activate=originalActivate;targetAt=originalTarget;hand.stream=null;hand.engine=null;clearHands();return {acquired,armed,clicks,pinched,reset:!S.hand&&!hand.pinched&&!hand.armed};
});assert.equal(result.acquired,true);assert.equal(result.armed,true);assert.equal(result.clicks,1);assert.equal(result.pinched,true);assert.equal(result.reset,true);
const blocked=await browser.newPage();await blocked.addInitScript(()=>{Storage.prototype.setItem=function(){throw new DOMException('Quota','QuotaExceededError')}});await blocked.goto(testURL);await blocked.locator('[data-app="notes"]').click();await blocked.locator('.note-editor').fill('Sem armazenamento');await blocked.waitForTimeout(500);assert.match(await blocked.locator('.note-status').innerText(),/Sem armazenamento/);
console.log('PASS: hand acquisition, release-to-arm, normalized pinch latch, held-pinch single click, reset after loss, blocked-storage recovery. Synthetic landmarks only.');await browser.close();})().catch(e=>{console.error(e);process.exit(1)});
