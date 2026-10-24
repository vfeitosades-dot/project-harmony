const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync(path.join(__dirname,'../index.html'),'utf8'),code=html.split('// BEGIN VISUAL MOTION')[1]?.split('// END VISUAL MOTION')[0];assert.ok(code);
const context=vm.createContext({});vm.runInContext(code+'\nglobalThis.Fit=VisualRotationFit;globalThis.Sensor=VisualRotationSensor;globalThis.Tracker=VisualMotionTracker;',context);
const {Fit,Sensor,Tracker}=context,w=160,h=120,f=w/(2*Math.tan(65*Math.PI/360)),rad=Math.PI/180;
// Independent Rodrigues reference, not the estimator's projection function.
function rotate(v,r,inverse=false){const angle=Math.hypot(...r);if(angle===0)return [...v];const a=r.map(x=>x/angle),c=Math.cos(angle),s=Math.sin(angle)*(inverse?-1:1),dot=a.reduce((sum,x,i)=>sum+x*v[i],0),cross=[a[1]*v[2]-a[2]*v[1],a[2]*v[0]-a[0]*v[2],a[0]*v[1]-a[1]*v[0]];return v.map((x,i)=>x*c+cross[i]*s+a[i]*dot*(1-c));}
function tracksFor(r){const tracks=[];for(let y=16;y<h-12;y+=16)for(let x=16;x<w-12;x+=16){const a=[(x-w/2)/f,(y-h/2)/f,1],b=rotate(a,r,true);tracks.push({x,y,dx:f*(b[0]/b[2]-a[0]),dy:f*(b[1]/b[2]-a[1])});}return tracks;}
for(const degrees of [[0,0,0],[0,3,0],[-2,0,0],[0,0,5],[2,-3,4]]){
 const expected=degrees.map(x=>x*rad),tracks=tracksFor(expected);for(let i=0;i<10;i++)tracks[i]={...tracks[i],dx:20-i,dy:-15+i};
 const fitted=new Fit(w,h).fit(tracks);assert.ok(fitted,`Must fit rotation ${degrees}`);for(let i=0;i<3;i++)assert.ok(Math.abs(fitted.rotation[i]-expected[i])<.001,`Axis ${i}: ${fitted.rotation[i]/rad} vs ${degrees[i]}`);assert.ok(fitted.rms<.05);
}
{
 const zoom=tracksFor([0,0,0]).map(p=>({...p,dx:(p.x-w/2)*.12,dy:(p.y-h/2)*.12}));assert.equal(new Fit(w,h).fit(zoom),null,'Strong zoom is not a coherent rotation');
 const small=tracksFor([0,.02,0]).filter(p=>p.x<60&&p.y<60);assert.equal(new Fit(w,h).fit(small),null,'Rotation must have spatial support');
}
let seed=113;const random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};
const noise=Float32Array.from({length:w*h},()=>40+random()*170),source=new Float32Array(w*h);
for(let y=1;y<h-1;y++)for(let x=1;x<w-1;x++){let s=0;for(let j=-1;j<=1;j++)for(let i=-1;i<=1;i++)s+=noise[(y+j)*w+x+i]*(i===0?2:1)*(j===0?2:1);source[y*w+x]=s/16;}
function sample(x,y){const xx=Math.floor(x),yy=Math.floor(y),dx=x-xx,dy=y-yy;if(xx<0||xx>=w-1||yy<0||yy>=h-1)return 0;return source[yy*w+xx]*(1-dx)*(1-dy)+source[yy*w+xx+1]*dx*(1-dy)+source[(yy+1)*w+xx]*(1-dx)*dy+source[(yy+1)*w+xx+1]*dx*dy;}
const measured=[];
for(const degrees of [[0,2,0],[-1.5,0,0],[0,0,3],[1,-1.4,2]]){
 const rotation=degrees.map(v=>v*rad),image=Float32Array.from({length:w*h},(_,i)=>{const ray=rotate([(i%w-w/2)/f,(Math.floor(i/w)-h/2)/f,1],rotation);return sample(f*ray[0]/ray[2]+w/2,f*ray[1]/ray[2]+h/2);});
 const tracker=new Tracker(w,h);tracker.process(source);const result=tracker.process(image);assert.equal(result.valid,true,`Image warp ${degrees}: ${result.reason}`);
 for(let i=0;i<3;i++)assert.ok(Math.abs(result.rotation[i]/rad-degrees[i])<.3,`Image rotation axis ${i}: ${result.rotation[i]/rad} vs ${degrees[i]}`);
 measured.push({expected:degrees,estimated:Array.from(result.rotation,v=>v/rad),rmsPixels:result.rms});
}
{
 const sensor=new Sensor();for(let i=0;i<720;i++)sensor.integrate([0,rad,0]);assert.ok(Math.abs(sensor.yaw-720)<1e-6,'Continuous yaw must unwrap through multiple turns');assert.ok(Math.abs(Math.hypot(...sensor.q)-1)<1e-10);
 sensor.reset();sensor.integrate([0,0,90*rad]);const tilted=sensor.integrate([10*rad,0,0]);assert.ok(Math.abs(tilted.yaw-10)<.01,'Local pitch after a 90 degree bank must change world yaw');assert.ok(Math.abs(tilted.pitch)<.01);
 sensor.reset();const front=sensor.integrate([0,2*rad,0],{front:true});assert.ok(Math.abs(front.yaw+2)<.01);
 sensor.reset(720,7);const multi=sensor.integrate([0,0,0]);assert.ok(Math.abs(multi.yaw-720)<.01,'Reanchoring after multiple turns must not create a full-turn jump');
 sensor.reset(0,0,90);const recovered=sensor.integrate([10*rad,0,0]);assert.ok(Math.abs(recovered.yaw-10)<.01,'Short tracking loss must preserve the banked coordinate frame');
 sensor.reset(20,7);const anchor=sensor.integrate([0,0,0]);assert.ok(Math.abs(anchor.yaw-20)<.01&&Math.abs(anchor.pitch-7)<.01,'Reanchoring must preserve the visible pose');
}
console.log('PASS: independent 3-axis rotation ground truth, outliers, zoom and coverage rejection, actual perspective image warps, quaternion composition, multi-turn yaw, front mirror and reanchoring. Synthetic images only.');console.log(JSON.stringify(measured,null,2));
