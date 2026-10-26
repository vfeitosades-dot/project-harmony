/* Estimativa relativa 2D por blocos. Não calcula pose 3D ou SLAM. */
(function(root){
function estimate(prev, curr, w, h, excluded=[]){
 const vectors=[]; let tested=0;
 for(let y=14;y<h-14;y+=14)for(let x=14;x<w-14;x+=16){
  if(excluded.some(b=>x/w>b.x0&&x/w<b.x1&&y/h>b.y0&&y/h<b.y1))continue;
  let mean=0,sq=0;
  for(let j=-3;j<=3;j++)for(let i=-3;i<=3;i++){const v=prev[(y+j)*w+x+i];mean+=v;sq+=v*v;}
  if(sq/49-(mean/49)**2<110)continue;
  tested++;let best=Infinity,second=Infinity,bx=0,by=0;
  for(let dy=-7;dy<=7;dy++)for(let dx=-7;dx<=7;dx++){
   let err=0;
   for(let j=-3;j<=3;j+=2)for(let i=-3;i<=3;i+=2)err+=Math.abs(prev[(y+j)*w+x+i]-curr[(y+j+dy)*w+x+i+dx]);
   if(err<best){second=best;best=err;bx=dx;by=dy;}else if(err<second)second=err;
  }
  if(best/16<27&&second-best>10&&Math.abs(bx)<7&&Math.abs(by)<7)vectors.push([bx,by]);
 }
 if(vectors.length<5)return {valid:false,confidence:0,dx:0,dy:0};
 const median=a=>a.sort((a,b)=>a-b)[Math.floor(a.length/2)];
 const mx=median(vectors.map(v=>v[0])),my=median(vectors.map(v=>v[1]));
 const inliers=vectors.filter(v=>Math.hypot(v[0]-mx,v[1]-my)<2);
 const confidence=inliers.length/Math.max(1,tested);
 return {valid:inliers.length>=5&&confidence>.35,confidence,dx:median(inliers.map(v=>v[0]))||0,dy:median(inliers.map(v=>v[1]))||0};
}
root.estimateMotion=estimate;
if(typeof module!=='undefined')module.exports=estimate;
})(typeof window!=='undefined'?window:globalThis);
