'use strict';
const $=s=>document.querySelector(s),$$=s=>[...document.querySelectorAll(s)];
const S={windows:new Map(),z:1,yaw:0,pitch:0,vr:false,env:'lake',camera:null,facing:'environment',hands:false,motion:false,pass:false,sensitivity:1.0,quality:'desligado',handCount:0};
const labels={home:['⌂','Meu espaço'],browser:['◎','Navegador'],notes:['▤','Notas'],media:['▷','Cinema'],settings:['⚙','Ajustes'],environments:['✧','Ambientes']};
let toastTimer,handEngine,handBusy=false,handGeneration=0,lastHandTime=0,lastMotionTime=0,prevFrame=null,handBounds=[],gesture={armed:false,down:false,target:null,drag:null,x:.5,y:.5,missing:0};
const video=$('#camera'),motionCanvas=document.createElement('canvas');motionCanvas.width=160;motionCanvas.height=112;const motionCtx=motionCanvas.getContext('2d',{willReadFrequently:true});
const overlay=$('#landmarks'),octx=overlay.getContext('2d');
function safeLoad(key,fallback=''){try{return localStorage.getItem(key)??fallback;}catch{return fallback;}}
function safeSave(key,value){try{localStorage.setItem(key,value);}catch{toast('O navegador não permitiu salvar neste aparelho.');}}
function toast(msg){const el=$('#toast');el.textContent=msg;el.style.display='block';clearTimeout(toastTimer);toastTimer=setTimeout(()=>el.style.display='none',5500);}
function content(id){switch(id){
case 'home':return `<span class="eyebrow">BEM-VINDO AO SEU ESPAÇO</span><div class="herohead"><div><h2>Um novo ponto de vista.</h2><p>Explore, crie e fique à vontade.</p></div><span class="location">✧ Espaço pessoal</span></div><div class="environmentcard"><span class="eyebrow">SEU AMBIENTE</span><h3>Refúgio ao entardecer</h3><span style="font-size:11px;color:#dcece7">Uma pausa fora do comum.</span><button data-app="environments" aria-label="Trocar ambiente">↗</button></div><div class="sectiontitle"><span>SEUS APLICATIVOS</span><span>04 disponíveis</span></div><div class="appgrid"><button class="appcard" data-app="browser"><span class="appicon">◎</span>Navegador</button><button class="appcard" data-app="notes"><span class="appicon">▤</span>Notas</button><button class="appcard" data-app="media"><span class="appicon">▷</span>Cinema</button><button class="appcard" data-app="settings"><span class="appicon">⚙</span>Ajustes</button></div><p class="footnote"><span>⌖ Arraste o fundo para olhar</span><span>⋮⋮ Arraste a barra para mover</span></p>`;
case 'browser':return `<span class="eyebrow">UMA JANELA PARA A WEB</span><h2 style="margin-top:9px">Onde vamos agora?</h2><form class="urlform"><input type="text" class="url" aria-label="Endereço do site" placeholder="https://exemplo.com" autocomplete="url" spellcheck="false"><button type="submit">Ir ↗</button></form><div class="browserlinks"><button data-url="https://en.wikipedia.org">Wikipedia</button><button data-url="https://www.openstreetmap.org/export/embed.html">Mapa</button><button data-url="https://example.com">Exemplo</button></div><iframe class="browserframe" title="Site aberto" sandbox="allow-scripts allow-forms allow-same-origin allow-popups" referrerpolicy="no-referrer" src="about:blank"></iframe><p class="browserhint">Alguns sites bloqueiam a incorporação. Se ficar em branco ou der erro, abra em outra aba. Gestos não controlam o conteúdo de sites externos.</p><div class="browseractions"><button data-action="external">Abrir em outra aba ↗</button><button data-action="reload">Recarregar</button></div>`;
case 'notes':return `<span class="eyebrow">IDEIAS EM ÓRBITA</span><h2 style="margin-top:9px">Seu bloco de notas.</h2><p>Suas anotações ficam salvas neste navegador.</p><textarea class="notes" aria-label="Suas notas" placeholder="O que você está imaginando?"></textarea><p class="fine notestatus">Salvamento local automático</p>`;
case 'media':return `<span class="eyebrow">SUA SESSÃO PARTICULAR</span><h2 style="margin-top:9px">Cinema no seu espaço.</h2><p>Abra um vídeo do aparelho. O arquivo permanece local.</p><video class="media" controls playsinline></video><label class="filebutton">＋ Escolher vídeo <input type="file" accept="video/*" class="mediafile"></label><p class="fine">Compatibilidade depende do formato suportado pelo navegador. Conteúdo protegido e apps de streaming não são emulados.</p>`;
case 'environments':return `<span class="eyebrow">MUDE DE ARES</span><h2 style="margin-top:9px">Escolha seu refúgio.</h2><p>Um cenário leve, sem downloads de imagens.</p><div class="envoptions"><button data-env="lake">Entardecer</button><button data-env="night">Noite</button><button data-env="aurora">Aurora</button></div><p class="fine">Para ver o ambiente real, ative a câmera e a transparência em Ajustes.</p>`;
case 'settings':return `<span class="eyebrow">DO SEU JEITO</span><h2 style="margin-top:9px">Controle e percepção.</h2><div class="statusbox" data-status>Carregando estado…</div><div class="settingsrow"><div><b>Câmera</b><p>Permissão apenas quando você ativar.</p></div><button data-action="camera">Ativar</button></div><div class="settingsrow"><label for="facing">Lente</label><select id="facing" class="facing"><option value="environment">Traseira</option><option value="user">Frontal</option></select></div><div class="settingsrow"><div><b>IA de mãos</b><p>MediaPipe · modelo carregado pela internet.</p></div><button data-action="hands" aria-pressed="false">Ativar</button></div><div class="settingsrow"><div><b>Movimento pela câmera</b><p>Estimativa 2D experimental, sem giroscópio.</p></div><button data-action="motion" aria-pressed="false">Ativar</button></div><div class="settingsrow"><div><b>Ver ambiente real</b><p>Imagem da câmera atrás dos painéis.</p></div><button data-action="pass" aria-pressed="false">Ativar</button></div><div class="settingsrow"><label>Sensibilidade</label><input class="sensitivity" aria-label="Sensibilidade" type="range" min="0.3" max="2" step="0.1" value="${S.sensitivity}"></div><div class="settingsrow"><div><b>Posição do olhar</b><p>Redefina a direção e organize os painéis.</p></div><button data-action="center">Centralizar</button></div><p class="fine">As imagens são processadas no aparelho, sem envio pelo aplicativo. O carregamento da IA conecta-se ao CDN jsDelivr. Não há reconhecimento de cômodos, profundidade ou posicionamento 6DoF.</p>`;
}}
function openApp(id){
 if(!labels[id])return;
 if(S.windows.has(id)){focusWindow(id);return;}
 const offset=S.windows.size*15;const p={id,x:id==='home'?0:offset,y:id==='home'?0:offset,z:++S.z,w:id==='settings'?520:680,h:null};S.windows.set(id,p);
 for(const eye of $$('.eyeworld')){const el=document.createElement('section');el.className='window';el.dataset.win=id;el.setAttribute('aria-label',labels[id][1]);el.innerHTML=`<div class="windowbar"><span class="winicon">${labels[id][0]}</span><strong>${labels[id][1]}</strong><span class="grip">⋮⋮</span><button data-action="close" aria-label="Fechar ${labels[id][1]}">×</button></div><div class="windowbody">${content(id)}</div><div class="resize" aria-label="Redimensionar painel" role="separator"></div>`;eye.append(el);if(id==='notes')el.querySelector('.notes').value=safeLoad('orbita.notes');}
 focusWindow(id);refreshSettings();render();
}
function focusWindow(id){const p=S.windows.get(id);if(!p)return;p.z=++S.z;$$('.window').forEach(el=>{el.classList.toggle('active',el.dataset.win===id);el.style.zIndex=S.windows.get(el.dataset.win).z;});$$('.dock button[data-app]').forEach(b=>b.classList.toggle('selected',b.dataset.app===id));}
function closeApp(id){const p=S.windows.get(id);if(p?.mediaURL)URL.revokeObjectURL(p.mediaURL);S.windows.delete(id);$$('.window').filter(w=>w.dataset.win===id).forEach(w=>w.remove());}
function render(){
 const viewportWidth=S.vr?innerWidth/2:innerWidth;
 const scale=S.vr?Math.min(viewportWidth/740,(innerHeight-55)/560):1;
 for(const el of $$('.window')){const p=S.windows.get(el.dataset.win);if(!p)continue;
 el.style.width=(S.vr?p.w:Math.min(p.w,innerWidth-28))+'px';if(p.h)el.style.height=p.h+'px';else el.style.height='';
 el.style.transform=`translate(-50%,-50%) translate(${(p.x-S.yaw*8)*scale}px,${(p.y+S.pitch*8)*scale}px) scale(${scale})`;
 }
 document.documentElement.style.setProperty('--sceneX',`${-S.yaw*3}px`);document.documentElement.style.setProperty('--sceneY',`${S.pitch*3}px`);
}
function center(){S.yaw=S.pitch=0;prevFrame=null;for(const p of S.windows.values()){p.x=p.y=0;}render();toast('Olhar centralizado. Toque no aplicativo para trazer seu painel à frente.');}
function refreshSettings(){
 const cam=!!S.camera;
 for(const el of $$('[data-action]')){
 const action=el.dataset.action;const state={camera:cam,hands:S.hands,motion:S.motion,pass:S.pass}[action];
 if(state!==undefined){el.textContent=state?'Desativar':'Ativar';el.setAttribute('aria-pressed',String(state));}
 }
 for(const select of $$('.facing'))select.value=S.facing;
 for(const box of $$('[data-status]'))box.textContent=`Câmera: ${cam?'ligada':'desligada'} · Mãos: ${S.handCount} · Movimento: ${S.motion?S.quality:'desligado'}`;
 $('#trackingStatus').textContent=S.motion?'Movimento visual · '+S.quality:S.hands?'IA de mãos · '+S.handCount+' detectada(s)':'Controle por toque';
}
let pointerDrag=null;
document.addEventListener('pointerdown',e=>{
 if(e.target.closest('dialog,.dock,.topbar,#exitVR'))return;
 const win=e.target.closest('.window');if(win)focusWindow(win.dataset.win);
 const bar=e.target.closest('.windowbar'),resize=e.target.closest('.resize');
 if(bar&&!e.target.closest('button')||resize){const p=S.windows.get(win.dataset.win);pointerDrag={type:resize?'resize':'window',p,x:e.clientX,y:e.clientY,px:p.x,py:p.y,w:win.offsetWidth,h:win.offsetHeight};}
 else if(!win&&e.target.closest('#space'))pointerDrag={type:'look',x:e.clientX,y:e.clientY,yaw:S.yaw,pitch:S.pitch};
 if(pointerDrag){e.preventDefault();document.body.classList.add('dragging');e.target.setPointerCapture?.(e.pointerId);}
});
document.addEventListener('pointermove',e=>{if(!pointerDrag)return;const d=pointerDrag,dx=e.clientX-d.x,dy=e.clientY-d.y;if(d.type==='look'){S.yaw=clamp(d.yaw-dx*.09,-30,30);S.pitch=clamp(d.pitch+dy*.07,-18,18);}else if(d.type==='window'){const scale=S.vr?Math.min(innerWidth/2/740,(innerHeight-55)/560):1;d.p.x=clamp(d.px+dx/scale,-innerWidth*.35,innerWidth*.35);d.p.y=clamp(d.py+dy/scale,-innerHeight*.24,innerHeight*.24);}else{d.p.w=clamp(d.w+dx,280,innerWidth-28);d.p.h=clamp(d.h+dy,170,innerHeight-150);}render();});
function endPointer(){pointerDrag=null;document.body.classList.remove('dragging');}document.addEventListener('pointerup',endPointer);document.addEventListener('pointercancel',endPointer);
function clamp(v,min,max){return Math.max(min,Math.min(max,v));}
document.addEventListener('click',async e=>{
 const b=e.target.closest('button');if(!b)return;
 if(b.dataset.app){openApp(b.dataset.app);return;}
 const win=b.closest('.window'),id=win?.dataset.win;
 if(b.dataset.url){navigate(win,b.dataset.url);return;}
 if(b.dataset.env){S.env=b.dataset.env;document.body.dataset.env=S.env;safeSave('orbita.env',S.env);toast('Ambiente alterado.');return;}
 try{switch(b.dataset.action){
 case 'close':closeApp(id);break;
 case 'camera':if(S.camera)stopCamera();else await startCamera();break;
 case 'hands':if(S.hands)stopHands();else await startHands();break;
 case 'motion':if(!S.camera)await startCamera();S.motion=!S.motion;S.quality='buscando detalhes';prevFrame=null;break;
 case 'pass':if(!S.camera)await startCamera();S.pass=!S.pass;document.body.classList.toggle('passthrough',S.pass);break;
 case 'center':center();break;
 case 'external':{const url=S.windows.get(id)?.url;if(url)window.open(url,'_blank','noopener,noreferrer');else toast('Digite um endereço primeiro.');break;}
 case 'reload':{const url=S.windows.get(id)?.url;if(url)navigate(win,url);break;}
 }}catch(err){toast(err.message||'Não foi possível concluir.');}refreshSettings();
});
function normalizeURL(raw){const text=raw.trim();if(!text)throw Error('Digite o endereço de um site.');const url=new URL(/^[a-z][a-z\d+.-]*:/i.test(text)?text:'https://'+text);if(!['https:','http:'].includes(url.protocol))throw Error('Use um endereço HTTP ou HTTPS.');if(location.protocol==='https:'&&url.protocol==='http:')throw Error('Nesta página segura, use um site HTTPS.');return url.href;}
function navigate(win,raw){try{const url=normalizeURL(raw);S.windows.get(win.dataset.win).url=url;for(const el of $$('.window').filter(w=>w.dataset.win===win.dataset.win)){el.querySelector('.url').value=url;el.querySelector('iframe').src=url;}toast('Abrindo site. Se ele bloquear a janela, use “Abrir em outra aba”.');}catch(err){toast(err.message);}}
document.addEventListener('submit',e=>{if(e.target.matches('.urlform')){e.preventDefault();navigate(e.target.closest('.window'),e.target.querySelector('input').value);}});
document.addEventListener('input',e=>{if(e.target.matches('.notes')){safeSave('orbita.notes',e.target.value);for(const t of $$('.notes'))if(t!==e.target)t.value=e.target.value;}if(e.target.matches('.sensitivity'))S.sensitivity=Number(e.target.value);});
document.addEventListener('change',async e=>{
 if(e.target.matches('.facing')){S.facing=e.target.value;const cam=!!S.camera,wasHands=S.hands,wasMotion=S.motion,wasPass=S.pass;stopCamera();try{if(cam){await startCamera();if(wasHands)await startHands();S.motion=wasMotion;S.pass=wasPass;document.body.classList.toggle('passthrough',S.pass);}}catch(err){toast(err.message);}refreshSettings();}
 if(e.target.matches('.mediafile')){const file=e.target.files[0];if(!file)return;const p=S.windows.get('media');if(p.mediaURL)URL.revokeObjectURL(p.mediaURL);p.mediaURL=URL.createObjectURL(file);for(const media of $$('video.media'))media.src=p.mediaURL;toast('Vídeo carregado. Use o botão de reprodução.');}
});
async function startCamera(){
 if(S.camera)return;
 if(!window.isSecureContext||!navigator.mediaDevices?.getUserMedia)throw Error('A câmera precisa de HTTPS ou localhost. Extraia o ZIP e hospede a pasta em HTTPS.');
 try{S.camera=await navigator.mediaDevices.getUserMedia({video:{facingMode:{ideal:S.facing},width:{ideal:640},height:{ideal:480},frameRate:{ideal:24,max:30}},audio:false});video.srcObject=S.camera;await video.play();prevFrame=null;S.camera.getVideoTracks()[0].addEventListener('ended',()=>{if(S.camera)stopCamera();});toast('Câmera ativada. Escolha IA de mãos ou movimento visual.');}
 catch(err){stopCamera();throw Error(err.name==='NotAllowedError'?'Permissão de câmera negada. Libere-a nas configurações do navegador.':'Não foi possível iniciar a câmera. Verifique a permissão e feche outros aplicativos que a utilizem.');}
 refreshSettings();
}
function stopCamera(){const stream=S.camera;S.camera=null;stream?.getTracks().forEach(t=>t.stop());video.srcObject=null;stopHands();S.motion=false;S.pass=false;prevFrame=null;document.body.classList.remove('passthrough');refreshSettings();}
function loadHandsScript(){
 if(window.Hands)return Promise.resolve();
 return new Promise((resolve,reject)=>{const script=document.createElement('script');const timeout=setTimeout(()=>{script.remove();reject(Error('O carregamento demorou. Verifique a internet e tente novamente.'));},30000);script.src='https://cdn.jsdelivr.net/npm/@mediapipe/hands@0.4.1675469240/hands.js';script.onload=()=>{clearTimeout(timeout);resolve();};script.onerror=()=>{clearTimeout(timeout);script.remove();reject(Error('Não foi possível baixar a IA. É necessária internet para acessar o jsDelivr.'));};document.head.append(script);});
}
let startingHands=false;
async function startHands(){
 if(startingHands)return;startingHands=true;const generation=++handGeneration;
 try{await startCamera();toast('Carregando IA de mãos. O primeiro carregamento pode demorar…');await loadHandsScript();if(generation!==handGeneration||!S.camera)return;
 if(!handEngine){handEngine=new Hands({locateFile:file=>`https://cdn.jsdelivr.net/npm/@mediapipe/hands@0.4.1675469240/${file}`});handEngine.setOptions({maxNumHands:2,modelComplexity:0,minDetectionConfidence:.65,minTrackingConfidence:.65,selfieMode:false});handEngine.onResults(onHands);await handEngine.initialize();}
 if(generation!==handGeneration||!S.camera)return;S.hands=true;gesture.armed=false;toast('IA pronta. Mostre a mão inteira. Abra a pinça antes de selecionar.');
 }catch(err){S.hands=false;toast(err.message||'A IA não pôde iniciar neste aparelho. Use o toque.');}finally{startingHands=false;refreshSettings();}
}
function stopHands(){handGeneration++;S.hands=false;S.handCount=0;handBounds=[];resetGesture();octx.clearRect(0,0,overlay.width,overlay.height);refreshSettings();}
function resetGesture(){gesture.down=false;gesture.armed=false;gesture.drag=null;gesture.target=null;$('#handCursor').hidden=true;$$('.handhover').forEach(t=>t.classList.remove('handhover'));document.body.classList.remove('dragging');}
const connections=[[0,1],[1,2],[2,3],[3,4],[0,5],[5,6],[6,7],[7,8],[5,9],[9,10],[10,11],[11,12],[9,13],[13,14],[14,15],[15,16],[13,17],[17,18],[18,19],[19,20],[0,17]];
function mapCameraPoint(p){const iw=video.videoWidth||640,ih=video.videoHeight||480,scale=Math.max(innerWidth/iw,innerHeight/ih);return {x:(p.x*iw*scale-(iw*scale-innerWidth)/2),y:p.y*ih*scale-(ih*scale-innerHeight)/2};}
function onHands(results){
 if(!S.hands)return;
 const hands=results.multiHandLandmarks||[];S.handCount=hands.length;
 handBounds=hands.map(l=>({x0:Math.max(0,Math.min(...l.map(p=>p.x))-.08),x1:Math.min(1,Math.max(...l.map(p=>p.x))+.08),y0:Math.max(0,Math.min(...l.map(p=>p.y))-.08),y1:Math.min(1,Math.max(...l.map(p=>p.y))+.08)}));
 octx.clearRect(0,0,overlay.width,overlay.height);
 for(const hand of hands){octx.strokeStyle='#bcf1d088';octx.lineWidth=2;octx.beginPath();for(const [a,b]of connections){const p=mapCameraPoint(hand[a]),q=mapCameraPoint(hand[b]);octx.moveTo(p.x,p.y);octx.lineTo(q.x,q.y);}octx.stroke();for(const pt of hand){const p=mapCameraPoint(pt);octx.fillStyle='#d5ffe6';octx.beginPath();octx.arc(p.x,p.y,2,0,Math.PI*2);octx.fill();}}
 if(!hands.length){resetGesture();return;}
 // A mão mais próxima da posição anterior evita alternância frequente entre mãos.
 const hand=hands.reduce((best,h)=>Math.hypot(h[8].x-gesture.x,h[8].y-gesture.y)<Math.hypot(best[8].x-gesture.x,best[8].y-gesture.y)?h:best,hands[0]);
 gesture.x+=(hand[8].x-gesture.x)*.45;gesture.y+=(hand[8].y-gesture.y)*.45;
 const x=clamp((gesture.x-.12)/.76,0,1)*innerWidth,y=clamp((gesture.y-.12)/.76,0,1)*innerHeight;
 const cursor=$('#handCursor');cursor.hidden=false;cursor.style.left=x+'px';cursor.style.top=y+'px';
 const dist=(a,b)=>Math.hypot(hand[a].x-hand[b].x,hand[a].y-hand[b].y);const ratio=dist(4,8)/Math.max(.03,dist(0,9));
 const el=document.elementFromPoint(x,y);const target=el?.closest('button,.windowbar,a');
 $$('.handhover').forEach(t=>t.classList.remove('handhover'));target?.classList.add('handhover');
 if(ratio>.52){if(gesture.down){gesture.down=false;gesture.drag=null;document.body.classList.remove('dragging');}gesture.armed=true;}
 if(ratio<.30&&gesture.armed&&!gesture.down){gesture.down=true;gesture.armed=false;gesture.target=target;
 if(target?.classList.contains('windowbar')&&!el.closest('button')){const p=S.windows.get(target.closest('.window').dataset.win);focusWindow(p.id);gesture.drag={p,x,y,px:p.x,py:p.y};document.body.classList.add('dragging');}
 else if(target){target.click();}}
 if(gesture.down&&gesture.drag){const d=gesture.drag;d.p.x=clamp(d.px+x-d.x,-innerWidth*.35,innerWidth*.35);d.p.y=clamp(d.py+y-d.y,-innerHeight*.24,innerHeight*.24);render();}
 cursor.classList.toggle('pinching',gesture.down);
 if(S.vr){const ex=clamp(x/innerWidth,0,1)*100,ey=clamp(y/innerHeight,0,1)*100;$$('.eyereticle').forEach(r=>{r.style.left=ex+'%';r.style.top=ey+'%';});}
}
function stepMotion(){
 motionCtx.drawImage(video,0,0,160,112);const data=motionCtx.getImageData(0,0,160,112).data;const frame=new Uint8Array(160*112);let mean=0;for(let i=0;i<frame.length;i++){frame[i]=(data[i*4]*.299+data[i*4+1]*.587+data[i*4+2]*.114)|0;mean+=frame[i];}
 if(prevFrame){const m=estimateMotion(prevFrame,frame,160,112,handBounds);S.quality=mean/frame.length<24?'pouca luz':m.valid?'acompanhando':'poucos pontos estáveis';if(m.valid&&mean/frame.length>=24){S.yaw=clamp(S.yaw-m.dx*.34*S.sensitivity,-30,30);S.pitch=clamp(S.pitch-m.dy*.28*S.sensitivity,-18,18);render();}}
 prevFrame=frame;
}
function tick(now){
 if(S.camera&&video.readyState>=2&&!document.hidden){
 if(S.motion&&now-lastMotionTime>95){lastMotionTime=now;stepMotion();}
 if(S.hands&&!handBusy&&now-lastHandTime>80){lastHandTime=now;handBusy=true;handEngine.send({image:video}).catch(()=>{stopHands();toast('O rastreamento falhou neste aparelho. Use o toque ou tente novamente.');}).finally(()=>handBusy=false);}
 }requestAnimationFrame(tick);
}
async function toggleVR(force){
 S.vr=force===undefined?!S.vr:force;document.body.classList.toggle('vr',S.vr);$('#rightEye').hidden=!S.vr;$('#exitVR').hidden=!S.vr;
 if(S.vr){try{await document.documentElement.requestFullscreen();}catch{}try{await screen.orientation.lock('landscape');}catch{toast('Gire o celular na horizontal. Use “Sair do visor” para voltar.');}
 for(const eye of $$('.eyeworld'))if(!eye.querySelector('.eyereticle')){const r=document.createElement('div');r.className='eyereticle';eye.append(r);}}
 else {try{screen.orientation.unlock();}catch{}if(document.fullscreenElement)await document.exitFullscreen().catch(()=>{});}
 render();
}
$('#vr').onclick=()=>toggleVR();$('#exitVR').onclick=()=>toggleVR(false);
$('#fullscreen').onclick=async()=>{try{if(document.fullscreenElement)await document.exitFullscreen();else await document.documentElement.requestFullscreen();}catch{toast('Este navegador não disponibilizou tela cheia.');}};
$('#help').onclick=()=>$('#helpDialog').showModal();$('#closeHelp').onclick=()=>$('#helpDialog').close();
$('#enter').onclick=()=>{$('#welcome').close();safeSave('orbita.visited','yes');};$('.brand').onclick=e=>{e.preventDefault();openApp('home');};
function resize(){overlay.width=innerWidth;overlay.height=innerHeight;render();}
window.addEventListener('resize',resize);document.addEventListener('keydown',e=>{if(e.target.matches('input,textarea,select'))return;if(e.key.toLowerCase()==='r')center();if(e.key==='Escape'&&S.vr)toggleVR(false);});
document.addEventListener('fullscreenchange',()=>{if(!document.fullscreenElement&&S.vr)toggleVR(false);});
document.addEventListener('visibilitychange',()=>{prevFrame=null;if(document.hidden){resetGesture();for(const m of $$('video.media'))m.pause();}});
window.addEventListener('pagehide',()=>stopCamera());
function clock(){ $('#clock').textContent=new Date().toLocaleTimeString('pt-BR',{hour:'2-digit',minute:'2-digit'});refreshSettings();}setInterval(clock,1200);clock();S.env=safeLoad('orbita.env','lake');document.body.dataset.env=S.env;openApp('home');resize();requestAnimationFrame(tick);if(!safeLoad('orbita.visited'))$('#welcome').showModal();
