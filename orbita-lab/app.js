'use strict';
const $=s=>document.querySelector(s),$$=s=>[...document.querySelectorAll(s)];
const S={windows:new Map(),z:1,yaw:0,pitch:0,vr:false,env:'city',camera:null,facing:'environment',hands:false,motion:false,pass:false,sensitivity:1.0,quality:'desligado',handCount:0};
const labels={home:['▦','Biblioteca'],browser:['◎','Navegador'],notes:['▤','Notas'],media:['▷','Cinema'],settings:['⚙','Ajustes'],environments:['✧','Ambientes'],files:['▱','Arquivos e galeria']};
let toastTimer,handEngine,handBusy=false,handGeneration=0,lastHandTime=0,lastMotionTime=0,prevFrame=null,handBounds=[],gesture={armed:false,down:false,target:null,drag:null,x:.5,y:.5,missing:0};
const video=$('#camera'),motionCanvas=document.createElement('canvas');motionCanvas.width=160;motionCanvas.height=112;const motionCtx=motionCanvas.getContext('2d',{willReadFrequently:true});
const overlay=$('#landmarks'),octx=overlay.getContext('2d');
function safeLoad(key,fallback=''){try{return localStorage.getItem(key)??fallback;}catch{return fallback;}}
function safeSave(key,value){try{localStorage.setItem(key,value);}catch{toast('O navegador não permitiu salvar neste aparelho.');}}
function toast(msg){const el=$('#toast');el.textContent=msg;el.style.display='block';clearTimeout(toastTimer);toastTimer=setTimeout(()=>el.style.display='none',5500);}
const ICONS={camera:'<rect x="3" y="7" width="26" height="20" rx="4"/><path d="M10 7l2-4h8l2 4"/><circle cx="16" cy="17" r="6"/>',browser:'<ellipse cx="16" cy="17" rx="9" ry="11" transform="rotate(38 16 17)"/><path d="M3 27L29 3M22 5l7-2-2 7"/>',files:'<path d="M3 9h26v17a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2zM3 9V5h10l4 4"/>',settings:'<path d="M13 3h6l1 4 4 2 4-1 3 5-3 3v4l2 3-4 5-4-1-3 2-1 3h-6l-1-4-4-2-4 1-3-5 3-3v-4L2 11l4-5 4 1z" transform="translate(1 0) scale(.9)"/><circle cx="16" cy="16" r="5"/>',media:'<rect x="3" y="8" width="26" height="21" rx="3"/><path d="M9 2l7 6 7-6M13 14l8 5-8 5z"/>',notes:'<rect x="5" y="3" width="22" height="26" rx="3"/><path d="M10 10h12M10 16h12M10 22h8"/>',environments:'<circle cx="16" cy="16" r="12"/><path d="M5 19l8-9 7 8 4-4 4 6M16 4v5"/>',people:'<circle cx="11" cy="10" r="5"/><circle cx="23" cy="11" r="4"/><path d="M2 28v-6c0-8 18-8 18 0v6M23 18c6 0 8 4 7 10"/>',grid:'<path d="M4 4h6v6H4zM13 4h6v6h-6zM22 4h6v6h-6zM4 13h6v6H4zM13 13h6v6h-6zM22 13h6v6h-6zM4 22h6v6H4zM13 22h6v6h-6zM22 22h6v6h-6z"/>',youtube:'<rect x="2" y="6" width="28" height="20" rx="6"/><path d="M13 11l9 5-9 5z"/>',instagram:'<rect x="4" y="4" width="24" height="24" rx="7"/><circle cx="16" cy="16" r="6"/><circle cx="24" cy="8" r="1"/>',spotify:'<circle cx="16" cy="16" r="13"/><path d="M7 12q10-5 19 1M9 17q8-4 15 1M11 22q6-3 11 0"/>',whatsapp:'<path d="M5 25l-2 6 7-3a13 13 0 1 0-5-3z"/><path d="M11 9q-4 7 10 14l4-4-5-3-2 2-4-4 1-2z"/>',facebook:'<path d="M19 30V18h5l1-6h-6V9q0-3 6-2V2q-12-3-12 7v3H9v6h4v12"/>',pin:'<path d="M10 3h12l-2 9 6 5H6l6-5zM16 17v13"/>',arrange:'<rect x="2" y="7" width="8" height="18" rx="2"/><rect x="12" y="4" width="8" height="24" rx="2"/><path d="M24 7h6v18h-6"/>'};
function icon(name){return `<svg viewBox="0 0 32 32" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${ICONS[name]||ICONS.browser}</svg>`;}
const LIBRARY=[
 {id:'camera',name:'Câmera',sub:'Ambiente real',color:'camera',icon:'camera',action:'camera-app'},
 {id:'browser',name:'Browser',sub:'Navegador web',color:'browser',icon:'browser'},
 {id:'files',name:'Files',sub:'Arquivos e galeria',color:'files',icon:'files'},
 {id:'settings',name:'Settings',sub:'Configurações',color:'settings',icon:'settings'},
 {id:'media',name:'TV',sub:'Cinema pessoal',color:'media',icon:'media'},
 {id:'notes',name:'Notas',sub:'Suas ideias',color:'notecard',icon:'notes'},
 {id:'youtube',name:'YouTube',sub:'Abrir versão web',color:'youtube',icon:'youtube',url:'https://www.youtube.com'},
 {id:'environments',name:'Horizon',sub:'Seus ambientes',color:'environments',icon:'environments'},
 {id:'spotify',name:'Spotify',sub:'Abrir versão web',color:'spotify',icon:'spotify',url:'https://open.spotify.com'},
 {id:'instagram',name:'Instagram',sub:'Abrir versão web',color:'instagram',icon:'instagram',url:'https://www.instagram.com'},
 {id:'whatsapp',name:'WhatsApp',sub:'Abrir versão web',color:'whatsapp',icon:'whatsapp',url:'https://web.whatsapp.com'},
 {id:'facebook',name:'Facebook',sub:'Abrir versão web',color:'facebook',icon:'facebook',url:'https://www.facebook.com'}
];
const esc=text=>String(text).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function libraryCards(){return LIBRARY.map(a=>`<div class="libraryitem" data-name="${a.name.toLowerCase()} ${a.sub.toLowerCase()}" data-category="${a.url?'web':'local'}"><button class="questcard ${a.color}" ${a.url?`data-web="${a.url}"`:a.action?`data-action="${a.action}"`:`data-app="${a.id}"`} aria-label="Abrir ${a.name}"><span class="cardglyph">${icon(a.icon)}</span><strong>${a.name}</strong><span class="carddot"></span></button><span class="cardcaption">${a.sub}</span></div>`).join('');}
let browserSerial=0,activeWindow='home';
function windowType(id){return id.split(':')[0];}
function newBrowser(url){const id='browser:'+ ++browserSerial;labels[id]=labels.browser;openApp(id);if(url)navigate(document.querySelector(`#leftEye [data-win="${id}"]`),url);return id;}
function content(id){switch(windowType(id)){
case 'home':return `<div class="librarylayout"><aside class="librarysidebar"><button class="side-search" data-action="focus-search">⌕ <span>Pesquisar</span></button><button class="side-selected" data-action="all-apps">${icon('grid')}<span>Aplicativos</span></button><button data-action="filter-local">${icon('files')}<span>Neste aparelho</span></button><button data-action="filter-web">${icon('browser')}<span>Na web</span></button><div class="sidebarbottom"><span class="orbita-symbol">◉</span><small>ÓRBITA OS <em>2.0</em></small><button data-action="guide" aria-label="Abrir guia">?</button></div></aside><div class="librarymain"><div class="libraryheading"><h2>Aplicativos</h2><div><select class="appfilter" aria-label="Filtrar aplicativos"><option value="all">Todos (12)</option><option value="local">Neste aparelho</option><option value="web">Na web</option></select><select class="appsort" aria-label="Ordenar aplicativos"><option value="default">Destaques</option><option value="name">Nome A–Z</option></select></div></div><div class="librarysearch"><span>⌕</span><input type="search" class="appsearch" aria-label="Pesquisar aplicativos" placeholder="Pesquisar aplicativos"><button data-action="free-grid" aria-pressed="false" title="Alternar grade livre" aria-label="Alternar grade livre">▦</button></div><div class="questgrid">${libraryCards()}</div><p class="emptysearch" hidden>Nenhum aplicativo encontrado.</p><div class="libraryfooter"><span><i></i> Seu espaço está pronto</span><span>Apps web abrem no navegador ↗</span></div></div></div>`;
case 'browser':return `<div class="browsertabs" role="tablist" aria-label="Abas do navegador"></div><span class="eyebrow">UMA JANELA PARA A WEB</span><h2 style="margin-top:9px">Onde vamos agora?</h2><form class="urlform"><input type="text" class="url" aria-label="Endereço do site" placeholder="https://exemplo.com" autocomplete="url" spellcheck="false"><button type="submit">Ir ↗</button></form><div class="browserlinks"><button data-url="https://en.wikipedia.org">Wikipedia</button><button data-url="https://www.openstreetmap.org/export/embed.html">Mapa</button><button data-url="https://example.com">Exemplo</button></div><div class="browserstart"><span class="planeticon">${icon('browser')}</span><h3>Uma nova janela para o mundo.</h3><p>Digite um endereço acima ou escolha um atalho.</p><button data-action="new-window">＋ Nova janela flutuante</button></div><iframe hidden class="browserframe" title="Site aberto" sandbox="allow-scripts allow-forms allow-same-origin allow-popups" referrerpolicy="no-referrer" src="about:blank"></iframe><p class="browserhint">Alguns sites bloqueiam a incorporação. Se ficar em branco ou der erro, abra em outra aba. Gestos não controlam o conteúdo de sites externos.</p><div class="browseractions"><button data-action="external">Abrir em outra aba ↗</button><button data-action="reload">Recarregar</button></div>`;
case 'files':return `<span class="eyebrow">ARQUIVOS DO APARELHO</span><h2 style="margin-top:9px">Sua galeria flutuante.</h2><p>Abra fotos e vídeos locais sem enviar arquivos.</p><label class="filebutton">＋ Escolher imagens ou vídeos<input class="galleryfile" type="file" accept="image/*,video/*" multiple></label><div class="gallerygrid"></div><p class="fine">Os arquivos ficam disponíveis enquanto esta janela estiver aberta.</p>`;
case 'notes':return `<span class="eyebrow">IDEIAS EM ÓRBITA</span><h2 style="margin-top:9px">Seu bloco de notas.</h2><p>Suas anotações ficam salvas neste navegador.</p><textarea class="notes" aria-label="Suas notas" placeholder="O que você está imaginando?"></textarea><p class="fine notestatus">Salvamento local automático</p>`;
case 'media':return `<span class="eyebrow">SUA SESSÃO PARTICULAR</span><h2 style="margin-top:9px">Cinema no seu espaço.</h2><p>Abra um vídeo do aparelho. O arquivo permanece local.</p><video class="media" controls playsinline></video><label class="filebutton">＋ Escolher vídeo <input type="file" accept="video/*" class="mediafile"></label><p class="fine">Compatibilidade depende do formato suportado pelo navegador. Conteúdo protegido e apps de streaming não são emulados.</p>`;
case 'environments':return `<span class="eyebrow">MUDE DE ARES</span><h2 style="margin-top:9px">Escolha seu refúgio.</h2><p>Um cenário leve, sem downloads de imagens.</p><div class="envoptions"><button data-env="city">Cidade Horizon</button><button data-env="lake">Entardecer</button><button data-env="night">Noite</button><button data-env="aurora">Aurora</button></div><p class="fine">Para ver o ambiente real, ative a câmera e a transparência em Ajustes.</p>`;
case 'settings':return `<span class="eyebrow">DO SEU JEITO</span><h2 style="margin-top:9px">Controle e percepção.</h2><div class="statusbox" data-status>Carregando estado…</div><div class="settingsrow"><div><b>Câmera</b><p>Permissão apenas quando você ativar.</p></div><button data-action="camera">Ativar</button></div><div class="settingsrow"><label for="facing">Lente</label><select id="facing" class="facing"><option value="environment">Traseira</option><option value="user">Frontal</option></select></div><div class="settingsrow"><div><b>IA de mãos</b><p>MediaPipe · modelo carregado pela internet.</p></div><button data-action="hands" aria-pressed="false">Ativar</button></div><div class="settingsrow"><div><b>Movimento pela câmera</b><p>Estimativa 2D experimental, sem giroscópio.</p></div><button data-action="motion" aria-pressed="false">Ativar</button></div><div class="settingsrow"><div><b>Ver ambiente real</b><p>Imagem da câmera atrás dos painéis.</p></div><button data-action="pass" aria-pressed="false">Ativar</button></div><div class="settingsrow"><label>Sensibilidade</label><input class="sensitivity" aria-label="Sensibilidade" type="range" min="0.3" max="2" step="0.1" value="${S.sensitivity}"></div><div class="settingsrow"><div><b>Posição do olhar</b><p>Redefina a direção e organize os painéis.</p></div><button data-action="center">Centralizar</button></div><p class="fine">As imagens são processadas no aparelho, sem envio pelo aplicativo. O carregamento da IA conecta-se ao CDN jsDelivr. Não há reconhecimento de cômodos, profundidade ou posicionamento 6DoF.</p>`;
}}
function openApp(id){
 if(!labels[id])return;
 if(S.windows.has(id)){focusWindow(id);render();return;}
 const offset=S.windows.size*23;const p={id,x:id==='home'?0:offset,y:id==='home'?0:offset,z:++S.z,w:id==='home'?1000:id==='settings'?560:760,h:null,depth:1,tilt:0,pinned:false,min:false,tabs:[{key:1,url:'',title:'Nova aba'}],activeTab:1,tabSerial:1,galleryURLs:[]};S.windows.set(id,p);
 for(const eye of $$('.eyeworld')){const el=document.createElement('section');el.className='window';el.dataset.win=id;el.setAttribute('aria-label',labels[id][1]);el.innerHTML=`<div class="windowbar"><span class="winicon">${labels[id][0]}</span><strong>${labels[id][1]}</strong><span class="grip">⋮⋮</span><button data-action="minimize" aria-label="Minimizar painel">−</button><button data-action="close" aria-label="Fechar ${labels[id][1]}">×</button></div><div class="windowbody">${content(id)}</div><div class="resize" aria-label="Redimensionar painel" role="separator"></div><div class="spatialbar"><span class="spatialtitle">${labels[id][1]}</span><span class="spatialdrag" title="Arraste para mover">⠿</span><button data-action="near" aria-label="Aproximar painel" title="Aproximar">＋</button><output class="depthvalue">100%</output><button data-action="far" aria-label="Afastar painel" title="Afastar">−</button><i></i><button data-action="tilt-left" aria-label="Inclinar para esquerda" title="Inclinar à esquerda">↶</button><button data-action="tilt-right" aria-label="Inclinar para direita" title="Inclinar à direita">↷</button><button data-action="pin" aria-label="Fixar painel na visão" title="Fixar na visão" aria-pressed="false">${icon('pin')}</button><button data-action="minimize" aria-label="Minimizar painel" title="Minimizar">−</button><button data-action="close" aria-label="Fechar painel" title="Fechar">×</button></div>`;eye.append(el);if(id==='notes')el.querySelector('.notes').value=safeLoad('orbita.notes');}
 if(windowType(id)==='browser')syncTabs(id);focusWindow(id);refreshSettings();render();
}
function focusWindow(id){const p=S.windows.get(id);if(!p)return;p.min=false;activeWindow=id;p.z=++S.z;$$('.window').forEach(el=>{el.classList.toggle('active',el.dataset.win===id);el.style.zIndex=S.windows.get(el.dataset.win).z;});$$('.dock button[data-app]').forEach(b=>b.classList.toggle('selected',b.dataset.app===windowType(id)));render();renderWindowTray();}
function closeApp(id){const p=S.windows.get(id);if(p?.mediaURL)URL.revokeObjectURL(p.mediaURL);p?.galleryURLs.forEach(u=>URL.revokeObjectURL(u));S.windows.delete(id);$$('.window').filter(w=>w.dataset.win===id).forEach(w=>w.remove());renderWindowTray();}
function render(){
 const viewportWidth=S.vr?innerWidth/2:innerWidth;
 const scale=S.vr?Math.min(viewportWidth/1060,(innerHeight-100)/700):1;
 for(const el of $$('.window')){const p=S.windows.get(el.dataset.win);if(!p)continue;
 el.style.width=(S.vr?p.w:Math.min(p.w,innerWidth-28))+'px';if(p.h)el.style.height=p.h+'px';else el.style.height='';
 el.classList.toggle('minimized',p.min);el.classList.toggle('pinned',p.pinned);el.style.transform=`translate(-50%,-50%) translate(${(p.x-(p.pinned?0:S.yaw*8))*scale}px,${(p.y+(p.pinned?0:S.pitch*8))*scale}px) perspective(1600px) rotateY(${p.tilt}deg) scale(${scale*p.depth})`;el.querySelector('.depthvalue').textContent=Math.round(p.depth*100)+'%';el.querySelector('[data-action=pin]').setAttribute('aria-pressed',String(p.pinned));
 }
 document.documentElement.style.setProperty('--sceneX',`${-S.yaw*3}px`);document.documentElement.style.setProperty('--sceneY',`${S.pitch*3}px`);
}
function center(){S.yaw=S.pitch=0;prevFrame=null;for(const p of S.windows.values()){p.x=p.y=0;p.depth=1;p.tilt=0;}render();toast('Olhar centralizado. Toque no aplicativo para trazer seu painel à frente.');}
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
 if(e.target.closest('dialog,.dock,.topbar,.windowtray,.systemactions,#exitVR'))return;
 const win=e.target.closest('.window');if(win&&!win.classList.contains('minimized'))focusWindow(win.dataset.win);
 const bar=e.target.closest('.windowbar,.spatialbar'),resize=e.target.closest('.resize');
 if(bar&&!e.target.closest('button')||resize){const p=S.windows.get(win.dataset.win);pointerDrag={type:resize?'resize':'window',p,x:e.clientX,y:e.clientY,px:p.x,py:p.y,w:win.offsetWidth,h:win.offsetHeight};}
 else if(!win&&e.target.closest('#space'))pointerDrag={type:'look',x:e.clientX,y:e.clientY,yaw:S.yaw,pitch:S.pitch};
 if(pointerDrag){e.preventDefault();document.body.classList.add('dragging');e.target.setPointerCapture?.(e.pointerId);}
});
document.addEventListener('pointermove',e=>{if(!pointerDrag)return;const d=pointerDrag,dx=e.clientX-d.x,dy=e.clientY-d.y;if(d.type==='look'){S.yaw=clamp(d.yaw-dx*.09,-30,30);S.pitch=clamp(d.pitch+dy*.07,-18,18);}else if(d.type==='window'){const scale=S.vr?Math.min(innerWidth/2/1060,(innerHeight-100)/700):1;d.p.x=clamp(d.px+dx/scale,-innerWidth*.35,innerWidth*.35);d.p.y=clamp(d.py+dy/scale,-innerHeight*.24,innerHeight*.24);}else{d.p.w=clamp(d.w+dx,280,innerWidth-28);d.p.h=clamp(d.h+dy,170,innerHeight-150);}render();});
function endPointer(){pointerDrag=null;document.body.classList.remove('dragging');}document.addEventListener('pointerup',endPointer);document.addEventListener('pointercancel',endPointer);
function clamp(v,min,max){return Math.max(min,Math.min(max,v));}
document.addEventListener('click',async e=>{
 const b=e.target.closest('button');if(!b)return;
 if(b.dataset.app){openApp(b.dataset.app);return;}if(b.dataset.web){newBrowser(b.dataset.web);return;}if(b.dataset.restore){focusWindow(b.dataset.restore);render();return;}
 const win=b.closest('.window'),id=win?.dataset.win;
 if(b.dataset.url){navigate(win,b.dataset.url);return;}
 if(b.dataset.env){S.env=b.dataset.env;document.body.dataset.env=S.env;safeSave('orbita.env',S.env);toast('Ambiente alterado.');return;}
 try{switch(b.dataset.action){
 case 'close':closeApp(id);break;
 case 'minimize':{const p=S.windows.get(id);p.min=!p.min;render();renderWindowTray();break;}
 case 'near':S.windows.get(id).depth=clamp(S.windows.get(id).depth+.08,.38,1.25);render();break;
 case 'far':S.windows.get(id).depth=clamp(S.windows.get(id).depth-.08,.38,1.25);render();break;
 case 'tilt-left':S.windows.get(id).tilt=clamp(S.windows.get(id).tilt-8,-32,32);render();break;
 case 'tilt-right':S.windows.get(id).tilt=clamp(S.windows.get(id).tilt+8,-32,32);render();break;
 case 'pin':S.windows.get(id).pinned=!S.windows.get(id).pinned;render();break;
 case 'new-window':newBrowser();break;
 case 'new-tab':{const p=S.windows.get(id);if(p.tabs.length>=12){toast('Limite de 12 abas por janela.');break;}p.activeTab=++p.tabSerial;p.tabs.push({key:p.activeTab,url:'',title:'Nova aba'});syncTabs(id,true);break;}
 case 'tab':{const p=S.windows.get(id);p.activeTab=Number(b.dataset.tab);syncTabs(id,true);break;}
 case 'close-tab':{const p=S.windows.get(id),key=Number(b.dataset.tab);p.tabs=p.tabs.filter(t=>t.key!==key);if(!p.tabs.length)p.tabs.push({key:++p.tabSerial,url:'',title:'Nova aba'});if(p.activeTab===key)p.activeTab=p.tabs.at(-1).key;syncTabs(id,true);break;}
 case 'free-grid':{const p=S.windows.get(id);p.free=!p.free;$$('.window').filter(w=>w.dataset.win===id).forEach(w=>{w.classList.toggle('freegrid',p.free);w.querySelector('[data-action=free-grid]').setAttribute('aria-pressed',String(p.free));});break;}
 case 'focus-search':win.querySelector('.appsearch').focus();break;
 case 'all-apps':filterLibrary(win,'all');break;
 case 'filter-local':filterLibrary(win,'local');break;
 case 'filter-web':filterLibrary(win,'web');break;
 case 'guide':$('#helpDialog').showModal();break;
 case 'arrange':arrangeWindows();break;
 case 'camera-app':openApp('settings');if(!S.camera)await startCamera();S.pass=true;document.body.classList.add('passthrough');break;
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
function navigate(win,raw){try{const url=normalizeURL(raw),id=win.dataset.win,p=S.windows.get(id);p.url=url;const tab=p.tabs.find(t=>t.key===p.activeTab);tab.url=url;tab.title=new URL(url).hostname.replace(/^www\./,'');syncTabs(id,true);toast('Abrindo site. Se ele bloquear a janela, use “Abrir em outra aba”.');}catch(err){toast(err.message);}}
function syncTabs(id,load=false){const p=S.windows.get(id),tab=p.tabs.find(t=>t.key===p.activeTab);p.url=tab.url;for(const win of $$('.window').filter(w=>w.dataset.win===id)){
 win.querySelector('.browsertabs').innerHTML=p.tabs.map(t=>`<div class="browsertab ${t.key===p.activeTab?'current':''}"><button role="tab" aria-selected="${t.key===p.activeTab}" data-action="tab" data-tab="${t.key}">${esc(t.title)}</button><button data-action="close-tab" data-tab="${t.key}" aria-label="Fechar aba ${esc(t.title)}">×</button></div>`).join('')+'<button data-action="new-tab" aria-label="Nova aba">＋</button>';
 win.querySelector('.url').value=tab.url;const frame=win.querySelector('iframe');frame.hidden=!tab.url;win.querySelector('.browserstart').hidden=!!tab.url;if(load)frame.src=tab.url||'about:blank';
}}
function filterLibrary(win,category){if(category)win.querySelector('.appfilter').value=category;const filter=win.querySelector('.appfilter').value,rawSearch=win.querySelector('.appsearch').value,search=rawSearch.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'');for(const view of $$('.window').filter(w=>w.dataset.win===win.dataset.win)){view.querySelector('.appfilter').value=filter;view.querySelector('.appsearch').value=rawSearch;let count=0;for(const item of view.querySelectorAll('.libraryitem')){const name=item.dataset.name.normalize('NFD').replace(/[\u0300-\u036f]/g,'');item.hidden=!(name.includes(search)&&(filter==='all'||item.dataset.category===filter));if(!item.hidden)count++;}view.querySelector('.emptysearch').hidden=!!count;}}
function renderWindowTray(){const tray=$('#windowTray');tray.innerHTML=[...S.windows.values()].map(p=>`<button data-restore="${p.id}" class="${p.min?'is-minimized':''} ${p.id===activeWindow?'current':''}" title="${labels[p.id][1]}${p.min?' · minimizado':''}">${labels[p.id][0]}<span>${labels[p.id][1]}</span>${p.min?'<small>↗</small>':''}</button>`).join('');}
function arrangeWindows(){const panels=[...S.windows.values()];const mobile=innerWidth<800;const widths=panels.map(p=>Math.min(p.w,innerWidth-28));const gap=18;const depth=mobile?.82:clamp((innerWidth-72-gap*Math.max(0,panels.length-1))/widths.reduce((a,b)=>a+b,0),.38,.85);const total=widths.reduce((a,b)=>a+b*depth,0)+gap*Math.max(0,panels.length-1);let cursor=-total/2;panels.forEach((p,i)=>{p.min=false;p.depth=depth;p.x=mobile?i*12:cursor+widths[i]*depth/2;p.y=mobile?i*15:0;p.tilt=mobile?0:clamp(-p.x*.018,-12,12);cursor+=widths[i]*depth+gap;});S.yaw=S.pitch=0;render();renderWindowTray();toast('Painéis organizados. Escolha uma janela na barra de janelas.');}
document.addEventListener('submit',e=>{if(e.target.matches('.urlform')){e.preventDefault();navigate(e.target.closest('.window'),e.target.querySelector('input').value);}});
document.addEventListener('input',e=>{if(e.target.matches('.appsearch'))filterLibrary(e.target.closest('.window'));if(e.target.matches('.notes')){safeSave('orbita.notes',e.target.value);for(const t of $$('.notes'))if(t!==e.target)t.value=e.target.value;}if(e.target.matches('.sensitivity'))S.sensitivity=Number(e.target.value);});
document.addEventListener('change',async e=>{
 if(e.target.matches('.appfilter'))filterLibrary(e.target.closest('.window'));
 if(e.target.matches('.appsort')){const grid=e.target.closest('.window').querySelector('.questgrid');const nodes=[...grid.children];nodes.sort((a,b)=>e.target.value==='name'?a.dataset.name.localeCompare(b.dataset.name,'pt-BR'):LIBRARY.findIndex(t=>a.dataset.name.startsWith(t.name.toLowerCase()))-LIBRARY.findIndex(t=>b.dataset.name.startsWith(t.name.toLowerCase())));nodes.forEach(n=>grid.append(n));}
 if(e.target.matches('.galleryfile')){const p=S.windows.get(e.target.closest('.window').dataset.win);p.galleryURLs.forEach(u=>URL.revokeObjectURL(u));p.galleryURLs=[];const html=[...e.target.files].filter(f=>f.type.startsWith('image/')||f.type.startsWith('video/')).slice(0,24).map(f=>{const url=URL.createObjectURL(f);p.galleryURLs.push(url);return `<figure>${f.type.startsWith('image/')?`<img src="${url}" alt="${esc(f.name)}">`:`<video src="${url}" controls playsinline></video>`}<figcaption>${esc(f.name)}</figcaption></figure>`;}).join('');$$('.window').filter(w=>w.dataset.win===p.id).forEach(w=>w.querySelector('.gallerygrid').innerHTML=html);}

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
 const x=clamp((gesture.x-.12)/.76,0,1)*(S.vr?innerWidth/2:innerWidth),y=clamp((gesture.y-.12)/.76,0,1)*innerHeight;
 const cursor=$('#handCursor');cursor.hidden=false;cursor.style.left=x+'px';cursor.style.top=y+'px';
 const dist=(a,b)=>Math.hypot(hand[a].x-hand[b].x,hand[a].y-hand[b].y);const ratio=dist(4,8)/Math.max(.03,dist(0,9));
 const el=document.elementFromPoint(x,y);const target=el?.closest('button,.windowbar,.spatialbar,a');
 $$('.handhover').forEach(t=>t.classList.remove('handhover'));target?.classList.add('handhover');
 if(ratio>.52){if(gesture.down){gesture.down=false;gesture.drag=null;document.body.classList.remove('dragging');}gesture.armed=true;}
 if(ratio<.30&&gesture.armed&&!gesture.down){gesture.down=true;gesture.armed=false;gesture.target=target;
 if((target?.classList.contains('windowbar')||target?.classList.contains('spatialbar'))&&!el.closest('button')){const p=S.windows.get(target.closest('.window').dataset.win);focusWindow(p.id);gesture.drag={p,x,y,px:p.x,py:p.y};document.body.classList.add('dragging');}
 else if(target){target.click();}}
 if(gesture.down&&gesture.drag){const d=gesture.drag;d.p.x=clamp(d.px+(x-d.x)/(S.vr?Math.min(innerWidth/2/1060,(innerHeight-100)/700):1),-innerWidth*.35,innerWidth*.35);d.p.y=clamp(d.py+(y-d.y)/(S.vr?Math.min(innerWidth/2/1060,(innerHeight-100)/700):1),-innerHeight*.24,innerHeight*.24);render();}
 cursor.classList.toggle('pinching',gesture.down);
 if(S.vr){const ex=clamp(x/(innerWidth/2),0,1)*100,ey=clamp(y/innerHeight,0,1)*100;$$('.eyereticle').forEach(r=>{r.style.left=ex+'%';r.style.top=ey+'%';});}
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
function clock(){ $('#clock').textContent=new Date().toLocaleTimeString('pt-BR',{hour:'2-digit',minute:'2-digit'});refreshSettings();}setInterval(clock,1200);clock();S.env=safeLoad('orbita.env','city');document.body.dataset.env=S.env;openApp('home');resize();requestAnimationFrame(tick);if(!safeLoad('orbita.visited'))$('#welcome').showModal();
// Dock do sistema: os ícones e indicadores refletem o estado disponível.
for(const button of $$('.questdock .dockapp')){const name=button.dataset.app==='home'?'grid':button.dataset.app||'camera';const span=button.querySelector('span');if(span)span.innerHTML=icon(name);}
function systemClock(){const clock=$('#dockClock');if(clock)clock.textContent=new Date().toLocaleTimeString('pt-BR',{hour:'2-digit',minute:'2-digit'});const network=$('#networkIcon');network.title=navigator.onLine?'Navegador conectado à rede (acesso aos sites pode variar)':'Navegador sem conexão';network.style.opacity=navigator.onLine?'1':'.35';}
systemClock();setInterval(systemClock,15000);window.addEventListener('online',systemClock);window.addEventListener('offline',systemClock);
if(navigator.getBattery)navigator.getBattery().then(b=>{const update=()=>{$('#batteryIcon').textContent=b.charging?'ϟ':'▰';$('#batteryIcon').title=`Bateria: ${Math.round(b.level*100)}%${b.charging?' · carregando':''}`;$('#batteryIcon').setAttribute('aria-label',$('#batteryIcon').title);};update();b.addEventListener('levelchange',update);b.addEventListener('chargingchange',update);}).catch(()=>{$('#batteryIcon').hidden=true;});else $('#batteryIcon').hidden=true;
if(safeLoad('orbita.design')!=='2'){S.env='city';document.body.dataset.env='city';safeSave('orbita.env','city');safeSave('orbita.design','2');}
