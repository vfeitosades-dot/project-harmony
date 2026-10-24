const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync(path.join(__dirname,'../index.html'),'utf8');const code=html.split('// BEGIN VISUAL MOTION')[1]?.split('// END VISUAL MOTION')[0];assert.ok(code);
const context=vm.createContext({});vm.runInContext(code+'\nglobalThis.Tracker=VisualMotionTracker;',context);const Tracker=context.Tracker;
const near=(a,b,message)=>assert.ok(Math.abs(a-b)<.05,message||`${a} must be near ${b}`);
const w=160,h=120;let seed=456;const random=()=>{seed=(1664525*seed+1013904223)>>>0;return seed/4294967296;};
const source=Float32Array.from({length:w*h},()=>random()*180+35);
function frame(dx=0,dy=0,exposure=0){return Float32Array.from({length:w*h},(_,i)=>{const x=i%w,y=Math.floor(i/w),sx=x-dx,sy=y-dy;return sx>=0&&sx<w&&sy>=0&&sy<h?source[sy*w+sx]+exposure:0;});}
for(const [dx,dy]of [[0,0],[-4,2],[6,-4],[-8,-6],[2,8]]){
 const t=new Tracker(w,h);assert.equal(t.process(frame()).valid,false);const r=t.process(frame(dx,dy));assert.equal(r.valid,true,JSON.stringify(r));near(r.dx,dx);near(r.dy,dy);assert.ok(r.tracks>=8);
}
{
 const t=new Tracker(w,h);t.process(frame());const r=t.process(frame(-4,2,30));assert.equal(r.valid,true);near(r.dx,-4);near(r.dy,2,'Uniform exposure changes must not turn into direction');
}
{
 const t=new Tracker(w,h),a=frame(),b=frame(-2,2);for(let y=20;y<80;y++)for(let x=10;x<60;x++)b[y*w+x]=random()*255;
 t.process(a);const r=t.process(b);assert.equal(r.valid,true);near(r.dx,-2);near(r.dy,2,'A minority moving foreground must not dominate background consensus');
}
{
 const t=new Tracker(w,h);const mask=[{x0:0,x1:80,y0:0,y1:120}];t.process(frame(),mask);assert.equal(t.process(frame(-2,0),mask).valid,false,'Tracks in only two image quadrants are insufficient');
}
{
 const t=new Tracker(w,h);t.process(new Float32Array(w*h).fill(100));const r=t.process(new Float32Array(w*h).fill(130));assert.equal(r.valid,false);assert.equal(r.dx,0);assert.equal(r.dy,0);
 t.reset();assert.equal(t.process(frame()).valid,false);assert.throws(()=>t.process(new Float32Array(3)),/dimensions/);
}
{
 const t=new Tracker(w,h);t.process(frame());const r=t.process(frame(35,-20));assert.equal(r.valid,false,'Motion outside the search window must not be integrated');
}
{
 const bilinear=(x,y)=>{const xx=Math.floor(x),yy=Math.floor(y),fx=x-xx,fy=y-yy;if(xx<0||xx>=w-1||yy<0||yy>=h-1)return 0;return source[yy*w+xx]*(1-fx)*(1-fy)+source[yy*w+xx+1]*fx*(1-fy)+source[(yy+1)*w+xx]*(1-fx)*fy+source[(yy+1)*w+xx+1]*fx*fy;};
 const t=new Tracker(w,h);t.process(frame());const shifted=Float32Array.from({length:w*h},(_,i)=>bilinear(i%w-.25,Math.floor(i/w)+.2));const r=t.process(shifted);
 assert.equal(r.valid,true);assert.ok(r.dx>.1&&r.dx<.45,`Subpixel horizontal movement: ${r.dx}`);assert.ok(r.dy<-.08&&r.dy>-.4,`Subpixel vertical movement: ${r.dy}`);
}
console.log('PASS: zero/horizontal/vertical/diagonal optical flow, exposure changes, moving foreground rejection, masks/spatial coverage, textureless scene, reset and excessive motion. Synthetic frames only.');
