// Deterministic signal tests for the actual inline estimator (no browser required).
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync(path.join(__dirname,'../index.html'),'utf8');
const estimator=html.split('// BEGIN DIRECTION ESTIMATOR')[1]?.split('// END DIRECTION ESTIMATOR')[0];assert.ok(estimator,'Estimator source must exist');
const context=vm.createContext({});vm.runInContext(estimator+'\nglobalThis.Engine=DirectionAssistant;',context);const Engine=context.Engine;
const rms=values=>Math.sqrt(values.reduce((s,v)=>s+v*v,0)/values.length);
let seed=123;const random=()=>{seed=(1664525*seed+1013904223)>>>0;return seed/4294967296-.5;};
const results=[];
for(const hz of [30,60,120]){
 const model=new Engine();let old=0;const raw=[],baseline=[],adaptive=[];
 for(let i=0;i<hz*8;i++){
  const t=i/hz,measurement=random()*.9+Math.sin(t*73)*.15;
  model.sample(measurement,0,t*1000,{gyro:.1});old+=(measurement-old)*(1-Math.exp(-1/hz/.09));
  if(i>hz*2){raw.push(measurement);baseline.push(old);adaptive.push(model.pose(t*1000).yaw);}
 }
 const a=rms(adaptive),b=rms(baseline);assert.ok(a<b*.85,`Stationary noise must improve at ${hz}Hz`);
 results.push({hz,jitterRMS:a,oldJitterRMS:b,rawRMS:rms(raw)});
}
for(const hz of [30,60,120]){
 const model=new Engine();let old=0;const errors=[],baseline=[];
 for(let i=0;i<hz*5;i++){
  const t=i/hz,truth=t<1?0:t<3?(t-1)*60:120,gyro=t>=1&&t<3?60:0;
  model.sample(truth,0,t*1000,{gyro});old+=(truth-old)*(1-Math.exp(-1/hz/.09));const pose=model.pose(t*1000);
  if(t>1.3&&t<2.8){errors.push(pose.yaw-truth);baseline.push(old-truth);}
  if(t>=3.1)assert.ok(pose.yaw<=120.05,'Stop must not extrapolate past the target with a quiet gyroscope');
 }
 assert.ok(rms(errors)<rms(baseline)*.35,`Tracking lag must improve at ${hz}Hz`);
 results.push({hz,movingErrorRMS:rms(errors),oldMovingErrorRMS:rms(baseline)});
}
{
 const model=new Engine();for(let i=0;i<100;i++)model.sample(0,0,i*1000/60,{gyro:0});
 assert.equal(model.sample(70,0,100*1000/60,{gyro:0}),false);assert.equal(model.pose(100*1000/60).yaw,0);
 for(let i=101;i<110;i++)model.sample(0,0,i*1000/60,{gyro:0});assert.ok(Math.abs(model.yaw)<.01,'Transient spike must not poison subsequent samples');
 for(let i=110;i<120;i++)model.sample(45,0,i*1000/60,{gyro:0});assert.ok(Math.abs(model.yaw)<.1,'Persistent compass step at measured rest must preserve the view');
 for(let i=120;i<180;i++)model.sample(45+(i-120)*.5,0,i*1000/60,{gyro:30});assert.ok(model.yaw>25,'Real movement after compass correction must remain responsive');
 assert.equal(model.pose(model.time+10,{prediction:0}).yaw,model.yaw,'Zero anticipation must disable prediction between samples');
 const stale=model.pose(model.time+500);assert.equal(stale.fresh,false);assert.equal(stale.yaw,model.yaw,'No prediction after signal loss');
 const before=model.time;assert.equal(model.sample(NaN,0,before+10),false);assert.equal(model.sample(0,0,before-1),false);assert.equal(model.time,before);
 model.reset();assert.equal(model.yaw,0);assert.equal(model.rejected,0);
}
{
 const model=new Engine();for(let i=0;i<180;i++)model.sample(i*.5,Math.sin(i/30)*12,i*1000/60,{gyro:null});assert.ok(Number.isFinite(model.pose(model.time).yaw));assert.ok(model.yaw>85,'Orientation-only fallback must track without Motion permission');
 const weights=[...model.weights];assert.ok(weights[1]>weights[0],'Online learning must favor the moving predictor on constant velocity');
 assert.ok(Math.abs(weights.reduce((a,b)=>a+b,0)-1)<1e-10);
 model.reset();for(let i=0;i<50;i++)model.sample(i,0,i*1000/60,{adaptive:false});assert.equal(model.pose(model.time,{adaptive:false}).yaw,model.yaw,'Basic mode must not predict');
}
{
 const model=new Engine();let atTurn=null;
 for(let i=0;i<240;i++){
  const t=i/60,truth=t<2?t*60:120-(t-2)*60;
  model.sample(truth,0,t*1000,{gyro:60});
  if(i===120)atTurn=model.pose(t*1000).yaw;
  if(i>=123&&i<135)assert.ok(model.pose(t*1000).yaw<atTurn,'Reversal must follow the new direction promptly');
 }
 assert.ok(model.velocity[0]<-50);
}
console.log('PASS: 30/60/120Hz jitter and motion benchmarks, transient/persistent sensor jumps, real turn after correction, stale/invalid data, learned predictor weights, orientation-only fallback and basic mode.');
console.log(JSON.stringify(results,null,2));
