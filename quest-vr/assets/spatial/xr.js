/* Optional native WebXR view. The same world poses back CSS planes and WebGL quads.
   DOM controls remain authoritative; cached canvas surfaces update only on change. */
class HarmonyXR {
 constructor(){this.session=null;this.planes=[];this.images=new Map();this.drag=null;this.refreshing=false;this.refreshAgain=false;this.refreshPromise=null;this.lastRefresh=0;this.alive=false;this.reducedMotion=matchMedia('(prefers-reduced-motion: reduce)').matches;}
 shader(gl,type,source){const shader=gl.createShader(type);gl.shaderSource(shader,source);gl.compileShader(shader);if(!gl.getShaderParameter(shader,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(shader));return shader;}
 initializeGL(){
  this.canvas=document.createElement('canvas');const gl=this.canvas.getContext('webgl',{xrCompatible:true,alpha:true,antialias:false,preserveDrawingBuffer:false});if(!gl)throw Error('WebGL indisponível');this.gl=gl;
  const program=gl.createProgram();gl.attachShader(program,this.shader(gl,gl.VERTEX_SHADER,'attribute vec2 position;uniform mat4 matrix;varying vec2 uv;void main(){uv=vec2(position.x+.5,.5-position.y);gl_Position=matrix*vec4(position,0.,1.);}'));
  gl.attachShader(program,this.shader(gl,gl.FRAGMENT_SHADER,'precision mediump float;uniform sampler2D surface;uniform vec4 tint;varying vec2 uv;void main(){gl_FragColor=texture2D(surface,uv)*tint;if(gl_FragColor.a<.01)discard;}'));gl.linkProgram(program);if(!gl.getProgramParameter(program,gl.LINK_STATUS))throw Error('Não foi possível criar a cena VR');this.program=program;gl.useProgram(program);
  this.buffer=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,this.buffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-.5,-.5,.5,-.5,-.5,.5,-.5,.5,.5,-.5,.5,.5]),gl.STATIC_DRAW);const loc=gl.getAttribLocation(program,'position');gl.enableVertexAttribArray(loc);gl.vertexAttribPointer(loc,2,gl.FLOAT,false,0,0);this.matrixLocation=gl.getUniformLocation(program,'matrix');this.tintLocation=gl.getUniformLocation(program,'tint');gl.uniform1i(gl.getUniformLocation(program,'surface'),0);gl.enable(gl.BLEND);gl.blendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA);gl.enable(gl.CULL_FACE);gl.disable(gl.DEPTH_TEST);
  const dot=document.createElement('canvas');dot.width=dot.height=32;const c=dot.getContext('2d');c.fillStyle='#baffdf';c.beginPath();c.arc(16,16,11,0,Math.PI*2);c.fill();this.pointerTexture=this.texture(dot);const floor=document.createElement('canvas');floor.width=floor.height=256;const f=floor.getContext('2d');f.fillStyle='#122b35';f.fillRect(0,0,256,256);f.strokeStyle='#73b3b430';f.lineWidth=1;f.beginPath();for(let i=0;i<=256;i+=32){f.moveTo(i,0);f.lineTo(i,256);f.moveTo(0,i);f.lineTo(256,i);}f.stroke();this.floorTexture=this.texture(floor);
 }
 texture(canvas){const gl=this.gl,texture=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,texture);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,canvas);return texture;}
 model(id,width,height){
  if(id.startsWith('modal-'))return (this.headMatrix||new DOMMatrix().translate(0,this.heightOffset,0)).translate(0,0,-.82).scale(width*.0014,height*.0014,1);
  if((id==='dock'||id==='taskbar')&&this.headMatrix)return this.headMatrix.translate(0,id==='dock'?-.6:-.73,-S.d*.85*.002).scale(width*.002,height*.002,1);
  let m;if(id==='dock'||id==='taskbar'){m=new DOMMatrix().translate(0,id==='dock'?300:365,-S.d*.85);}else m=SpatialGeometry.matrix(windowPose(id),S.d);
  const a=Array.from(m.toFloat32Array());for(let col=0;col<4;col++)for(let row=0;row<4;row++)a[col*4+row]*=(row===1?-1:1)*(col===1?-1:1);a[12]*=.002;a[13]=a[13]*.002+this.heightOffset;a[14]*=.002;
  return new DOMMatrix(a).scale(width*.002,height*.002,1);
 }
 bounds(node,root){let x=0,y=0,current=node;while(current&&current!==root){x+=current.offsetLeft||0;y+=current.offsetTop||0;current=current.offsetParent;}if(current!==root)return null;for(let parent=node.parentElement;parent&&parent!==root;parent=parent.parentElement){x-=parent.scrollLeft;y-=parent.scrollTop;}return {x:x-root.scrollLeft,y:y-root.scrollTop,w:node.offsetWidth,h:node.offsetHeight};}
 async icon(svg){const key=svg.outerHTML;if(this.images.has(key))return this.images.get(key);const promise=new Promise(resolve=>{const im=new Image();im.onload=()=>resolve(im);im.onerror=()=>resolve(null);const copy=svg.cloneNode(true);copy.setAttribute('xmlns','http://www.w3.org/2000/svg');copy.setAttribute('color','#e1fff2');copy.setAttribute('fill','none');copy.setAttribute('stroke','#e1fff2');im.src='data:image/svg+xml;charset=utf-8,'+encodeURIComponent(new XMLSerializer().serializeToString(copy));});this.images.set(key,promise);return promise;}
 rounded(c,x,y,w,h,r){r=Math.min(r,w/2,h/2);c.beginPath();c.moveTo(x+r,y);c.arcTo(x+w,y,x+w,y+h,r);c.arcTo(x+w,y+h,x,y+h,r);c.arcTo(x,y+h,x,y,r);c.arcTo(x,y,x+w,y,r);c.closePath();}
 async snapshot(root){
  const canvas=document.createElement('canvas');canvas.width=Math.max(1,root.offsetWidth);canvas.height=Math.max(1,root.offsetHeight);const c=canvas.getContext('2d'),targets=[],svgCache=new Map();
  await Promise.all([...root.querySelectorAll('svg')].map(async svg=>svgCache.set(svg.outerHTML,await this.icon(svg))));
  const paint=(node,rect)=>{
   const style=getComputedStyle(node);if(style.display==='none'||style.visibility==='hidden'||node.hidden||rect.w<=0||rect.h<=0)return;
   const radius=parseFloat(style.borderRadius)||0;c.save();c.beginPath();c.rect(0,0,canvas.width,canvas.height);c.clip();c.globalAlpha=node===root?1:Number(style.opacity);
   this.rounded(c,rect.x,rect.y,rect.w,rect.h,radius);if(style.backgroundColor!=='rgba(0, 0, 0, 0)'){c.fillStyle=style.backgroundColor;c.fill();}
   const colors=style.backgroundImage.match(/rgba?\([^)]*\)/g);if(colors?.length>=2){const gradient=c.createLinearGradient(rect.x,rect.y,rect.x+rect.w,rect.y+rect.h);gradient.addColorStop(0,colors[0]);gradient.addColorStop(1,colors[1]);c.fillStyle=gradient;c.fill();}
   if(parseFloat(style.borderTopWidth)>0){c.strokeStyle=style.borderTopColor;c.lineWidth=parseFloat(style.borderTopWidth);c.stroke();}
   if(node.matches('button,[data-window-handle],input,textarea,select'))targets.push({node,...rect});
   if(node.tagName.toLowerCase()==='svg'){const im=svgCache.get(node.outerHTML);if(im)c.drawImage(im,rect.x,rect.y,rect.w,rect.h);c.restore();return;}
   if(node.matches('input[type=checkbox]')){c.fillStyle=node.checked?'#9ce6c8':'#26423f';c.fillRect(rect.x,rect.y,rect.w,rect.h);if(node.checked){c.fillStyle='#153a2e';c.font='bold 12px sans-serif';c.fillText('✓',rect.x+1,rect.y+1);}c.restore();return;}
   if(node.matches('input[type=range]')){const ratio=(Number(node.value)-Number(node.min||0))/(Number(node.max||100)-Number(node.min||0));c.fillStyle='#74948c';c.fillRect(rect.x+4,rect.y+rect.h/2-2,rect.w-8,4);c.fillStyle='#aafbd7';c.beginPath();c.arc(rect.x+4+(rect.w-8)*ratio,rect.y+rect.h/2,7,0,Math.PI*2);c.fill();c.restore();return;}
   const text=node.matches('textarea,input,select')?(node.value||node.placeholder||''):[...node.childNodes].filter(n=>n.nodeType===3).map(n=>n.textContent).join(' ').trim();
   if(text){c.font=`${style.fontWeight} ${style.fontSize} ${style.fontFamily}`;c.fillStyle=style.color;c.textBaseline='top';const padX=parseFloat(style.paddingLeft)||0,padY=parseFloat(style.paddingTop)||0,line=parseFloat(style.lineHeight)||parseFloat(style.fontSize)*1.35,available=rect.w-padX-(parseFloat(style.paddingRight)||0),maxLines=Math.max(1,Math.floor((rect.h-padY)/line));let y=rect.y+padY,used=0;
    for(const paragraph of text.split('\n')){let row='';for(const word of paragraph.split(/\s+/)){if(row&&c.measureText(row+' '+word).width>available){c.fillText(row,rect.x+padX,y,available);y+=line;used++;row=word;if(used>=maxLines)break;}else row+=(row?' ':'')+word;}if(used>=maxLines)break;c.fillText(row,rect.x+padX,y,available);y+=line;used++;if(used>=maxLines)break;}
   }
   c.restore();for(const child of node.children){if(child.closest('svg')&&child.tagName.toLowerCase()!=='svg')continue;const childRect=this.bounds(child,root);if(childRect)paint(child,childRect);}
  };paint(root,{x:0,y:0,w:canvas.width,h:canvas.height});return {canvas,targets};
 }
 refresh(){
  if(!this.alive)return Promise.resolve();this.refreshAgain=true;if(this.refreshPromise)return this.refreshPromise;
  this.refreshPromise=(async()=>{while(this.refreshAgain&&this.alive){this.refreshAgain=false;await this.refreshNow();}})().finally(()=>{this.refreshPromise=null;});return this.refreshPromise;
 }
 async refreshNow(){
  if(!this.alive)return;this.refreshing=true;const session=this.session;try{
   const eye=stage.firstElementChild;if(!eye)return;const nodes=[...eye.querySelectorAll('.spatial-window:not(.is-closing)')].map(n=>({id:n.dataset.window,node:n.querySelector('.panel')}));nodes.push({id:'dock',node:eye.querySelector('.dock')},{id:'taskbar',node:eye.querySelector('.spatial-taskbar')});
   for(const dialog of document.querySelectorAll('dialog[open]'))nodes.push({id:'modal-'+dialog.id,node:dialog});
   const ids=new Set(nodes.map(n=>n.id));for(const plane of this.planes)if(!ids.has(plane.id)&&!plane.closingAt)plane.closingAt=performance.now();
   for(const {id,node} of nodes){if(!node)continue;const signature=node.innerHTML+[...node.querySelectorAll('input,textarea')].map(n=>n.value).join('|')+node.offsetWidth+':'+node.offsetHeight+':'+node.scrollTop;let plane=this.planes.find(p=>p.id===id);if(plane?.closingAt){plane.closingAt=0;plane.born=performance.now();}if(plane?.signature===signature&&plane.marker===node.firstElementChild){plane.node=node;continue;}const snapshot=await this.snapshot(node);if(!this.alive||this.session!==session)return;if(plane)this.gl.deleteTexture(plane.texture);else{plane={id,born:performance.now()};this.planes.push(plane);}Object.assign(plane,{node,signature,marker:node.firstElementChild,width:snapshot.canvas.width,height:snapshot.canvas.height,targets:snapshot.targets,texture:this.texture(snapshot.canvas)});}
  }finally{this.refreshing=false;}
 }
 ray(frame,source){const pose=frame.getPose(source.targetRaySpace,this.reference);if(!pose)return null;const m=pose.transform.matrix;return {origin:[m[12],m[13],m[14]],direction:[-m[8],-m[9],-m[10]]};}
 intersect(ray){let best=null;if(!ray)return null;for(const p of this.planes){if(this.planes.some(p=>p.id.startsWith('modal-')&&!p.closingAt)&&!p.id.startsWith('modal-'))continue;if(p.closingAt)continue;if(p.id!=='dock'&&p.id!=='taskbar'&&!p.id.startsWith('modal-')&&!S.openViews.includes(p.id))continue;const matrix=this.model(p.id,p.width,p.height),hit=SpatialGeometry.hit(ray,matrix);if(!hit||Math.abs(hit.x)>.5||Math.abs(hit.y)>.5||best&&hit.t>=best.distance)continue;const x=(hit.x+.5)*p.width,y=(.5-hit.y)*p.height,target=[...p.targets].reverse().find(t=>x>=t.x&&x<=t.x+t.w&&y>=t.y&&y<=t.y+t.h);best={plane:p,x,y,target:target?.node,distance:hit.t,point:hit.world,matrix};}return best;}
 select(frame,source){
  const ray=this.ray(frame,source),hit=this.intersect(ray);if(!hit)return;if(S.openViews.includes(hit.plane.id))focusWindow(hit.plane.id);const node=hit.target;if(!node?.isConnected){void this.refresh();return;}
  if(node.matches('[data-window-handle],[data-window-resize]')||node.dataset.id==='window-move'){
   const id=hit.plane.id;this.drag={source,id,pose:windowPose(id),point:hit.point,distance:hit.distance,matrix:hit.matrix,mode:node.matches('[data-window-resize]')?'resize':'move',width:hit.plane.width,height:hit.plane.height,local:SpatialGeometry.hit(ray,hit.matrix)};return;
  }
  if(node.matches('input[type=range]')){const target=hit.plane.targets.find(t=>t.node===node),ratio=Math.max(0,Math.min(1,(hit.x-target.x)/target.w)),min=Number(node.min||0),max=Number(node.max||100),step=Number(node.step||1);node.value=String(min+Math.round(ratio*(max-min)/step)*step);node.dispatchEvent(new Event('input',{bubbles:true}));void this.refresh();return;}
  if(node.matches('select')){node.selectedIndex=(node.selectedIndex+1)%node.options.length;node.dispatchEvent(new Event('change',{bubbles:true}));void this.refresh();return;}
  if(node.matches('input[type=checkbox]')){node.click();void this.refresh();return;}
  if(node.matches('textarea,input')){const status=node.closest('.panel')?.querySelector('.note-status');if(status)status.textContent='Edite o texto no navegador antes de entrar no headset. Botões e organização funcionam pelos controles.';void this.refresh();return;}
  node.click();void this.refresh();
 }
 updateDrag(frame,dt){const d=this.drag;if(!d)return;const ray=this.ray(frame,d.source);if(!ray)return;const axes=d.source.gamepad?.axes||[],vertical=axes[axes.length-1]||0,horizontal=axes[axes.length-2]||0;d.distance=clamp(d.distance+(Math.abs(vertical)>.2?vertical*dt*.6:0),.35,3.5);
  if(d.mode==='resize'){const h=SpatialGeometry.hit(ray,d.matrix);if(h)changeWindowPose({width:d.width+(h.x-d.local.x)*d.width*2,height:d.height-(h.y-d.local.y)*d.height*2},d.id);return;}
  const point=ray.origin.map((v,i)=>v+ray.direction[i]*d.distance),delta=point.map((v,i)=>(v-d.point[i])/.002);changeWindowPose({x:d.pose.x+delta[0],y:d.pose.y-delta[1],z:d.pose.z-delta[2],ry:windowPose(d.id).ry+(Math.abs(horizontal)>.2?horizontal*dt*45:0)},d.id);
 }
 draw(matrix,texture,tint=[1,1,1,1]){const gl=this.gl;gl.uniformMatrix4fv(this.matrixLocation,false,matrix.toFloat32Array());gl.uniform4fv(this.tintLocation,tint);gl.bindTexture(gl.TEXTURE_2D,texture);gl.drawArrays(gl.TRIANGLES,0,6);}
 frame(time,frame){
  if(!this.session||frame.session&&frame.session!==this.session)return;this.session.requestAnimationFrame((t,f)=>this.frame(t,f));const pose=frame.getViewerPose(this.reference);if(!pose)return;if(pose.transform?.matrix)this.headMatrix=new DOMMatrix(pose.transform.matrix);const gl=this.gl,layer=this.session.renderState.baseLayer,dt=Math.min(.05,(time-(this.lastFrame||time))/1000);this.lastFrame=time;this.updateDrag(frame,dt);if(!this.drag){for(const source of this.session.inputSources){const axes=source.gamepad?.axes||[],axis=axes[axes.length-1]||0;if(Math.abs(axis)<.2)continue;const hit=this.intersect(this.ray(frame,source)),node=hit?.plane.node;if(node&&node.scrollHeight>node.clientHeight){node.scrollTop=clamp(node.scrollTop+axis*dt*420,0,node.scrollHeight-node.clientHeight);if(time-(this.lastScrollRefresh||0)>80){this.lastScrollRefresh=time;void this.refresh();}}}}
  for(const p of this.planes)if(p.closingAt&&(this.reducedMotion||time-p.closingAt>=180))this.gl.deleteTexture(p.texture);this.planes=this.planes.filter(p=>!p.closingAt||!this.reducedMotion&&time-p.closingAt<180);
  if(time-this.lastRefresh>350){this.lastRefresh=time;void this.refresh();}
  const models=this.planes.filter(p=>p.id==='dock'||p.id==='taskbar'||p.id.startsWith('modal-')||S.openViews.includes(p.id)||p.closingAt).map(p=>{const t=this.reducedMotion?1:clamp((time-p.born)/220,0,1),enter=1-(1-t)**3,close=p.closingAt?clamp((time-p.closingAt)/180,0,1):0,size=.95+.05*enter-.05*close;return {plane:p,model:this.model(p.id,p.width,p.height).scale(size,size,1),alpha:enter*(1-close)};});models.sort((a,b)=>a.model.m43-b.model.m43);
  gl.bindFramebuffer(gl.FRAMEBUFFER,layer.framebuffer);const color={forest:[.045,.085,.075],coast:[.065,.12,.17],night:[.018,.025,.055],sunset:[.15,.085,.12]}[S.env]||[.035,.07,.09];gl.clearColor(...color,1);gl.clear(gl.COLOR_BUFFER_BIT);gl.useProgram(this.program);
  for(const view of pose.views){const viewport=layer.getViewport(view);gl.viewport(viewport.x,viewport.y,viewport.width,viewport.height);const viewMatrix=new DOMMatrix(view.transform.inverse.matrix),vp=new DOMMatrix(view.projectionMatrix).multiply(viewMatrix);for(const item of models)item.depth=viewMatrix.m13*item.model.m41+viewMatrix.m23*item.model.m42+viewMatrix.m33*item.model.m43+viewMatrix.m43;models.sort((a,b)=>a.depth-b.depth);
   const floor=new DOMMatrix().translate(0,this.heightOffset?0:-1.45,-2).rotateAxisAngle(1,0,0,-90).scale(8,8,1);this.draw(vp.multiply(floor),this.floorTexture);
   for(const {plane,model,alpha} of models){const shadow=new DOMMatrix(model.toFloat32Array()).translate(0,-.008,-.012).scale(1.025);this.draw(vp.multiply(shadow),plane.texture,[0,0,0,.35*alpha]);this.draw(vp.multiply(model),plane.texture,[1,1,1,alpha]);}
   for(const source of this.session.inputSources){const hit=this.intersect(this.ray(frame,source));if(hit){const dot=new DOMMatrix(view.transform.matrix||undefined);dot.m41=hit.point[0];dot.m42=hit.point[1];dot.m43=hit.point[2];dot.scaleSelf(.014,.014,1);this.draw(vp.multiply(dot),this.pointerTexture);}}
  }
 }
 cleanup(){this.alive=false;this.refreshAgain=false;this.drag=null;this.session=null;document.body.classList.remove('xr-active');const gl=this.gl;if(gl){for(const p of this.planes)gl.deleteTexture(p.texture);gl.deleteTexture(this.pointerTexture);gl.deleteTexture(this.floorTexture);gl.deleteBuffer(this.buffer);gl.deleteProgram(this.program);gl.getExtension('WEBGL_lose_context')?.loseContext();}this.planes=[];this.gl=null;this.headMatrix=null;this.lastRefresh=0;this.lastFrame=0;}
 async start(){
  if(this.session)return;let session;try{session=await navigator.xr.requestSession('immersive-vr',{optionalFeatures:['local-floor']});this.initializeGL();await this.gl.makeXRCompatible();this.session=session;this.alive=true;try{this.reference=await session.requestReferenceSpace('local-floor');this.heightOffset=1.45;}catch{this.reference=await session.requestReferenceSpace('local');this.heightOffset=0;}session.updateRenderState({baseLayer:new XRWebGLLayer(session,this.gl,{alpha:false,depth:false,antialias:false})});
   session.addEventListener('selectstart',e=>this.select(e.frame,e.inputSource));session.addEventListener('selectend',()=>{this.drag=null;saveLocal();});session.addEventListener('end',()=>this.cleanup(),{once:true});document.body.classList.add('xr-active');await this.refresh();session.requestAnimationFrame((t,f)=>this.frame(t,f));
  }catch(error){if(session)await session.end().catch(()=>{});this.cleanup();tell('Não foi possível iniciar o headset: '+error.message);}
 }
}
const harmonyXR=new HarmonyXR();
(async()=>{if(!navigator.xr)return;try{if(!await navigator.xr.isSessionSupported('immersive-vr'))return;const b=document.createElement('button');b.id='bNativeVR';b.textContent='Entrar no headset VR';b.onclick=()=>harmonyXR.start();$('ui').appendChild(b);}catch{}})();
