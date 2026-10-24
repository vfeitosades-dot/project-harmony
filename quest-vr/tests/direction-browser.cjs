const {chromium}=require('playwright'),assert=require('node:assert/strict');
const testURL=process.env.QUEST_TEST_URL||'http://127.0.0.1:8766/';
(async()=>{
 const browser=await chromium.launch({...(process.env.CHROMIUM_PATH?{executablePath:process.env.CHROMIUM_PATH}:{}),headless:true,args:process.env.CHROMIUM_NO_SANDBOX==='1'?['--no-sandbox']:[]});
 try{
  const page=await browser.newPage(),errors=[],external=[];page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>{if(new URL(r.url()).origin!==new URL(testURL).origin)external.push(r.url());});await page.goto(testURL);
  const results=await page.evaluate(()=>{
   const originalNow=performance.now.bind(performance);let clock=1000;performance.now=()=>clock;
   try{
    prefs.sensitivity=1;motion.active=true;resetDirection(false,true);S.yaw=S.pitch=0;
    onOrientation({alpha:359,beta:90,gamma:0});clock+=16;onOrientation({alpha:1,beta:90,gamma:0});const wrap=motion.targetYaw;
    const rawBefore=JSON.stringify(motion.raw);onOrientation({alpha:NaN,beta:90,gamma:0});const invalidIgnored=rawBefore===JSON.stringify(motion.raw);
    S.yaw=23;S.pitch=7;screenChanged();clock+=16;onOrientation({alpha:130,beta:85,gamma:0});const afterRotation={yaw:motion.targetYaw,pitch:motion.targetPitch};
    clock+=900;onOrientation({alpha:200,beta:80,gamma:0});const afterGap={yaw:motion.targetYaw,pitch:motion.targetPitch};
    clock+=16;onOrientation({alpha:200,beta:180,gamma:0});const pole={pitch:motion.targetPitch,elevation:motion.raw.elevation};
    recenter();const centered={yaw:S.yaw,pitch:S.pitch,filterYaw:direction.yaw};
    clock+=20;resetDirection(false,true);onOrientation({alpha:0,beta:90,gamma:0});calibrateDirection();
    for(let i=0;i<85;i++){clock+=1000/60;onMotion({rotationRate:{alpha:.05,beta:.02,gamma:0}});onOrientation({alpha:Math.sin(i)*.08,beta:90+Math.sin(i*.7)*.06,gamma:0});}
    const calibrated={done:motion.calibration===null,noise:direction.noise,heading:motion.base.heading,message:document.getElementById('status').textContent};
    const noise=direction.noise,weights=[...direction.weights];recenter();const learnedPreserved=direction.noise===noise&&direction.weights.every((w,i)=>w===weights[i]);
    const oldTarget=targetAt;targetAt=()=>'notes';selection.id='notes';selection.since=clock-5000;selection.fired=false;S.hand=false;prefs.dwell=true;
    motion.lastAt=clock-1000;const view=S.view;tick(clock);const staleDwellBlocked=S.view===view&&document.getElementById('ret').style.getPropertyValue('--p')==='0';targetAt=oldTarget;
    stopSensors(false);return {wrap,invalidIgnored,afterRotation,afterGap,pole,centered,calibrated,learnedPreserved,staleDwellBlocked};
   }finally{performance.now=originalNow;}
  });
  assert.equal(results.wrap,-2);assert.equal(results.invalidIgnored,true);assert.deepEqual(results.afterRotation,{yaw:23,pitch:7});assert.deepEqual(results.afterGap,{yaw:23,pitch:7});assert.equal(results.pole.pitch,75);assert.ok(results.pole.elevation>89);assert.deepEqual(results.centered,{yaw:0,pitch:0,filterYaw:0});assert.equal(results.calibrated.done,true);assert.ok(results.calibrated.noise<.2);assert.match(results.calibrated.message,/Calibração concluída/);assert.equal(results.staleDwellBlocked,true);assert.equal(results.learnedPreserved,true);
  const cancelled=await page.evaluate(async()=>{
   let release;DeviceOrientationEvent.requestPermission=()=>new Promise(resolve=>release=resolve);DeviceMotionEvent.requestPermission=async()=>'granted';
   const pending=toggleSensors();stopSensors(false);release('granted');await pending;return !motion.active&&!motion.starting;
  });assert.equal(cancelled,true,'A cancelled permission request must not reactivate sensors');
  const fallback=await page.evaluate(async()=>{
   DeviceOrientationEvent.requestPermission=async()=>'granted';DeviceMotionEvent.requestPermission=()=>{throw new Error('Motion denied')};await toggleSensors();const active=motion.active;stopSensors(false);
   DeviceOrientationEvent.requestPermission=async()=>'denied';await toggleSensors();return {active,denied:!motion.active,enabled:!document.getElementById('bGyro').disabled};
  });assert.deepEqual(fallback,{active:true,denied:true,enabled:true});
  await page.locator('#bSettings').click();await page.locator('#directionAI').uncheck();await page.locator('#prediction').fill('12');await page.locator('.settings-close').click();await page.reload();const saved=await page.evaluate(()=>({enabled:prefs.directionAI,prediction:prefs.prediction}));assert.deepEqual(saved,{enabled:false,prediction:12});
  assert.deepEqual(errors,[]);assert.deepEqual(external,[],'Direction assistant must not request a remote model or server');
  console.log('PASS: wrap, invalid events, continuous view on screen rotation/resume, pole handling, recenter, guided calibration, stale-signal dwell guard, optional Motion permission failure, Orientation denial, persistent assistant controls; no external requests or page errors.');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
