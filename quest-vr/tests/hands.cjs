const {chromium}=require('playwright'),assert=require('node:assert/strict');
const testURL=process.env.QUEST_TEST_URL||'http://127.0.0.1:8766/';
(async()=>{const browser=await chromium.launch({...(process.env.CHROMIUM_PATH?{executablePath:process.env.CHROMIUM_PATH}:{}),args:process.env.CHROMIUM_NO_SANDBOX==='1'?['--no-sandbox']:[]});try{
 const page=await browser.newPage();await page.goto(testURL);if(await page.locator('#cameraAccess').evaluate(n=>n.open))await page.locator('#cameraLater').click();
 const result=await page.evaluate(()=>{
  const p=Array.from({length:21},(_,i)=>({x:.4+(i%4)*.02,y:.4+Math.floor(i/4)*.02,z:0}));p[0]={x:.5,y:.7,z:0};p[9]={x:.5,y:.5,z:0};p[5]={x:.4,y:.5,z:0};p[17]={x:.6,y:.5,z:0};p[8]={x:.52,y:.25,z:0};p[4]={x:.25,y:.4,z:0};
  Object.defineProperty(video,'readyState',{configurable:true,value:4});let frames=0;Object.defineProperty(video,'currentTime',{configurable:true,get:()=>frames++});hand.stream={};hand.engine={detectForVideo:()=>({landmarks:[p]})};
  const now=performance.now();updateHands(now);updateHands(now+160);updateHands(now+320);const acquired=S.hand;
  let clicks=0,target='notes';const originalActivate=activate,originalTarget=targetAt;activate=()=>{clicks++;selection.fired=true;};targetAt=()=>target;prefs.dwell=false;S.dwell=700;
  p[4]={...p[8]};for(let t=400;t<=800;t+=80)tick(now+t);const pinchClicks=clicks;
  for(let t=880;t<=2400;t+=80)tick(now+t);const dwellClicks=clicks;
  for(let t=2480;t<=3600;t+=80)tick(now+t);const heldClicks=clicks;
  target=null;tick(now+3680);target='notes';for(let t=3760;t<=4800;t+=80)tick(now+t);const repeatedAfterLeave=clicks;
  const pinching=document.body.classList.contains('pinching');activate=originalActivate;targetAt=originalTarget;hand.stream=null;hand.engine=null;clearHands();return {acquired,pinchClicks,dwellClicks,heldClicks,repeatedAfterLeave,pinching,reset:!S.hand};
 });assert.equal(result.acquired,true);assert.equal(result.pinchClicks,0);assert.equal(result.dwellClicks,1);assert.equal(result.heldClicks,1);assert.equal(result.repeatedAfterLeave,2);assert.equal(result.pinching,false);assert.equal(result.reset,true);
 const blocked=await browser.newPage();await blocked.addInitScript(()=>{Storage.prototype.setItem=function(){throw new DOMException('Quota','QuotaExceededError')}});await blocked.goto(testURL);if(await blocked.locator('#cameraAccess').evaluate(n=>n.open))await blocked.locator('#cameraLater').click();await blocked.locator('[data-app="notes"]').click();await blocked.locator('.note-editor').fill('Sem armazenamento');await blocked.waitForTimeout(500);assert.match(await blocked.locator('.note-status').innerText(),/Sem armazenamento/);
 console.log('PASS: synthetic hand acquisition, pinch does not activate, finger dwell works with gaze disabled, held target fires once, leave-to-rearm and blocked storage.');
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exit(1)});
