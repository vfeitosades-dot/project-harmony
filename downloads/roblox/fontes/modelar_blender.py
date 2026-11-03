import bpy, math, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
COL={'blue':(40,114,232),'red':(231,58,54),'yellow':(255,200,47),'green':(72,168,72),'grass':(95,183,76),'white':(239,239,223),'gray':(111,121,133),'dark':(43,52,64),'black':(26,30,36),'cyan':(48,214,235),'purple':(147,87,204),'orange':(244,132,42),'brown':(131,90,57),'silver':(186,197,201),'ice':(157,223,242)}
assets={}; mats={}; current=None; offset=(0,0,0)
def material(color,glow=False):
 key=(color,glow)
 if key in mats:return mats[key]
 rgb=COL.get(color,color);m=bpy.data.materials.new(str(color));m.diffuse_color=tuple(v/255 for v in rgb)+(1,);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=m.diffuse_color;bs.inputs['Roughness'].default_value=.36
 if glow:bs.inputs['Emission Color'].default_value=m.diffuse_color;bs.inputs['Emission Strength'].default_value=.4
 mats[key]=m;return m
def asset(name):
 global current,offset
 if len(assets)>=21:
  n=len(assets)-21;offset=((n%5)*26,0,85+(n//5)*28)
 current=name;assets[name]=[]
 col=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(col)
 return col

def p(name,size,pos,color='blue',shape='Block',rot=(0,0,0),stud=False,glow=False,alpha=0):
 rgb=COL.get(color,color)
 data=dict(name=name,size=size,pos=pos,color=rgb,shape=shape,rot=rot,stud=stud,glow=glow,alpha=alpha)
 assets[current].append(data)
 def tobl(v):return(v[0],-v[2],v[1])
 sx,sy,sz=size
 if shape=='Ball':bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6)
 elif shape=='Cylinder':bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=1,depth=2)
 else:bpy.ops.mesh.primitive_cube_add()
 obj=bpy.context.object;obj.name=current+'__'+name;obj.location=tobl(tuple(pos[i]+offset[i] for i in range(3)))
 obj.dimensions=(sx,sz,sy);obj.rotation_euler=(math.radians(rot[0]),math.radians(-rot[2]),math.radians(rot[1]))
 obj.data.materials.append(material(color,glow))
 for c in list(obj.users_collection):c.objects.unlink(obj)
 bpy.data.collections[current].objects.link(obj)
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 bevel=obj.modifiers.new('Bordas de brinquedo','BEVEL');bevel.width=.035;bevel.segments=1
 if alpha:obj.hide_render=True
 # Studs geometricos apenas na pre-visualizacao do Blender. No Roblox usam SurfaceType.Studs.
 if stud and shape=='Block' and sx>=2 and sz>=2 and not alpha:
  verts=[];faces=[]
  for ix in range(max(1,int(sx/2))):
   for iz in range(max(1,int(sz/2))):
    x=pos[0]+offset[0]+(ix-(max(1,int(sx/2))-1)/2)*2
    z=pos[2]+offset[2]+(iz-(max(1,int(sz/2))-1)/2)*2
    y=pos[1]+offset[1]+sy/2
    start=len(verts)
    for dy in (0,.16):
     for j in range(8):
      a=j*math.tau/8;verts.append((x+math.cos(a)*.43,-z+math.sin(a)*.43,y+dy))
    faces.append(tuple(start+8+j for j in range(8)))
    for j in range(8):faces.append((start+j,start+(j+1)%8,start+8+(j+1)%8,start+8+j))
  mesh=bpy.data.meshes.new('Studs');mesh.from_pydata(verts,[],faces);mesh.materials.append(material(color));studobj=bpy.data.objects.new(current+'__StudsPreview',mesh);bpy.data.collections[current].objects.link(studobj)
 return obj

def base(w=8,h=1,d=8,color='blue'):p('Base',(w,h,d),(0,0,0),color,stud=True)
def bolts(w,d,y=.62):
 for x in (-w/2+.6,w/2-.6):
  for z in (-d/2+.6,d/2-.6):p('Rebite',(.45,.16,.45),(x,y,z),'silver','Cylinder')
def frame(w,d,y=0,color='dark'):
 for x in (-w/2+.2,w/2-.2):p('Borda',(.4,.35,d),(x,y,0),color)
 for z in (-d/2+.2,d/2-.2):p('Borda',(w,.35,.4),(0,y,z),color)
ids=['Plataforma','PlataformaPeq','DegrauFalso','ParedeBaixa','PlataformaMovel','PlataformaGiratoria','Esteira','Serra','Espinhos','EspinhosEscondidos','Laser','Pendulo','MarteloEmpurrao','BombaRelogio','Lava','Trampolim','Ventilador','PortalTroll','BlocoEscorregadio','ParedeFantasma','CheckpointFalso']
for i,id in enumerate(ids):
 offset=((i%7)*18,0,(i//7)*20);asset(id)
 if id in ['Plataforma','PlataformaPeq']:
  w=4 if id=='PlataformaPeq' else 8;base(w,1,w,'blue');frame(w,w,-.2,'white');bolts(w,w)
 elif id=='DegrauFalso':
  base(color='orange');frame(8,8,-.2,'brown')
  for x,z in [(-1,-1),(0,0),(1,1)]:p('Rachadura',(.2,.06,2),(x,.54,z),'dark',rot=(0,35,0))
 elif id=='ParedeBaixa':
  base(8,4,1,'red')
  for y in (-1.3,0,1.3):p('Junta horizontal',(8,.08,.06),(0,y,-.53),'white')
  for x,y in [(-2,-.65),(2,.65)]:p('Junta vertical',(.08,1.2,.06),(x,y,-.53),'white')
 elif id=='PlataformaMovel':
  base(color='yellow');frame(8,8,-.1);bolts(8,8)
  for x in (-1,1):p('Seta',(1.5,.14,1.5),(x,.6,0),'dark',rot=(0,45,0))
  for z in (-3,3):p('Trilho',(7,.35,.5),(0,-.7,z),'silver')
 elif id=='PlataformaGiratoria':
  base(12,1,12,'yellow');p('Disco',(10,.25,10),(0,.65,0),'orange','Cylinder');p('Eixo',(2,1,2),(0,-.8,0),'dark','Cylinder')
  for a in range(4):p('Raio',(1,.2,9),(0,.84,0),'white',rot=(0,a*45,0))
 elif id=='Esteira':
  base(8,1,12,'dark')
  for z in range(-5,6,2):p('Correia',(6.5,.2,1.5),(0,.65,z),'yellow',stud=True)
  for x in (-3.7,3.7):p('Guia',(.5,.7,12),(x,.65,0),'silver')
 elif id=='Serra':
  base(4,.5,12,'dark');p('Trilho',(1,.4,11),(0,.5,0),'silver')
  p('Disco de corte',(3.2,3.2,.5),(0,1.5,0),'silver','Ball')
  for j in range(12):
   a=j*math.tau/12;p('Dente',(.7,.7,.6),(math.cos(a)*1.5,1.5+math.sin(a)*1.5,0),'white',rot=(0,0,-j*30))
  p('Miolo',(.8,.8,.65),(0,1.5,0),'red','Ball')
 elif id in ['Espinhos','EspinhosEscondidos']:
  base(color='red' if id=='Espinhos' else 'gray');frame(8,8,.6,'yellow')
  for x in (-2,0,2):
   for z in (-2,0,2):
    p('Espinho base',(.9,.7,.9),(x,.8,z),'silver');p('Espinho ponta',(.4,.8,.4),(x,1.5,z),'white',rot=(0,45,0))
 elif id=='Laser':
  for x in (-5,5):p('Emissor',(2,4,2),(x,0,0),'dark',stud=True);p('Lente',(.3,1,1),(x+(-.99 if x>0 else .99),0,0),'red',glow=True)
  p('Feixe',(9,.22,.22),(0,0,0),'red',glow=True)
  for x in (-5,5):p('Sinalizador',(1,.3,1),(x,2.2,0),'yellow',glow=True)
 elif id=='Pendulo':
  p('Suporte',(4,.7,4),(0,3.6,0),'yellow',stud=True);p('Haste',(.4,5,.4),(0,.7,0),'silver');p('Peso',(3.2,3.2,3.2),(0,-2.2,0),'red','Ball');frame(4,4,3.95)
 elif id=='MarteloEmpurrao':
  p('Base',(8,.6,4),(0,-1.7,0),'blue',stud=True);p('Haste',(.7,2.5,.7),(0,-.2,0),'silver');p('Martelo',(7,2,3),(0,1,0),'red',stud=True)
  for x in (-3.4,3.4):p('Face',(.25,2,3),(x,1,0),'yellow')
 elif id=='BombaRelogio':
  p('Bomba',(3.4,3.4,3.4),(0,-.25,0),'black','Ball');p('Tampa',(1,.5,1),(0,1.6,0),'silver','Cylinder');p('Pavio',(.25,.8,.25),(.1,2.1,0),'brown');p('Faisca',(.5,.5,.5),(.1,2.6,0),'orange','Ball',glow=True)
  p('Temporizador',(2,.9,.25),(0,0,-1.6),'red');p('Display',(1.5,.5,.08),(0,.05,-1.76),'yellow',glow=True)
 elif id=='Lava':
  base(color='brown');p('Lava',(7.4,.18,7.4),(0,.58,0),'orange',glow=True)
  for x,z in [(-2,-1),(1,2),(2,-2),(-1,1)]:p('Bolha',(1,.3,1),(x,.75,z),'yellow','Ball',glow=True)
  frame(8,8,.7,'dark')
 elif id=='Trampolim':
  base(color='purple');frame(8,8,.7,'yellow');p('Lona',(6,.25,6),(0,.6,0),'cyan')
  for x in (-3.5,3.5):
   for z in (-2,0,2):p('Mola',(.5,.35,1),(x,.7,z),'silver')
  p('Cruz',(3,.12,.7),(0,.8,0),'white');p('Cruz',(.7,.12,3),(0,.8,0),'white')
 elif id=='Ventilador':
  base(4,.5,4,'purple');p('Motor',(1.2,2.5,1.2),(0,1,0),'dark','Cylinder')
  for a in (0,90):p('Helice',(3.5,.3,.8),(0,1.8,0),'silver',rot=(0,a,0))
  p('Eixo',(.6,.5,.6),(0,2.1,0),'yellow','Cylinder')
 elif id=='PortalTroll':
  base(4,.5,4,'purple')
  for x in (-1.6,1.6):p('Pilar',(.7,5,.9),(x,0,0),'purple',stud=True)
  p('Topo',(3.9,.7,.9),(0,2.5,0),'yellow');p('Energia',(2.4,4.6,.15),(0,0,0),'cyan',glow=True)
  for y in (-1.5,-.3,1):p('Runas',(.35,.35,.2),(0,y,-.2),'white',rot=(0,0,45))
 elif id=='BlocoEscorregadio':
  base(color='ice');frame(8,8,-.3,'white')
  for x in (-2,0,2):p('Reflexo',(.2,.08,3),(x,.57,0),'white',rot=(0,30,0))
 elif id=='ParedeFantasma':
  base(8,6,1,'purple')
  for x in (-2,2):p('Olho',(1.1,1.1,.2),(x,.8,-.6),'white');p('Pupila',(.45,.65,.15),(x,.7,-.75),'black')
  p('Boca',(2,.5,.2),(0,-1,-.6),'black')
 elif id=='CheckpointFalso':
  base(color='purple');p('Mastro',(.4,5,.4),(2,2,1),'white');p('Bandeira',(2.4,1.7,.25),(.8,3.5,1),'red',stud=True)
  p('X',(3,.15,.5),(0,.6,0),'yellow',rot=(0,45,0));p('X',(3,.15,.5),(0,.6,0),'yellow',rot=(0,-45,0))
# Segunda passagem de acabamento: paineis, rebites e faixas de aviso.
dims=[(8,1,8),(4,1,4),(8,1,8),(8,4,1),(8,1,8),(12,1,12),(8,1,12),(4,4,12),(8,1,8),(8,1,8),(12,4,2),(4,8,4),(8,4,4),(4,4,4),(8,1,8),(8,1,8),(4,4,4),(4,6,4),(8,1,8),(8,6,1),(8,1,8)]
for i,id in enumerate(ids):
 current=id;offset=((i%7)*18,0,(i//7)*20);w,h,d=dims[i]
 if id not in ['BombaRelogio','Laser','Serra','Pendulo','MarteloEmpurrao','Ventilador','PortalTroll']:
  for x in (-w/2+.4,w/2-.4):
   for z in (-d/2+.3,d/2-.3):
    p('Parafuso cromado',(.23,.16,.23),(x,h/2+.09,z),'silver','Cylinder')
  p('Placa de serie',(min(w*.55,2.6),.35,.08),(0,-h*.22,-d/2-.05),'dark')
  for x in (-.45,0,.45):p('Indicador',(.16,.15,.06),(x,-h*.22,-d/2-.12),'cyan',glow=True)
  if d>=4 and h<=1:
   for x in (-w/2+.25,w/2-.25):
    p('Reforco',(.5,.7,d*.8),(x,-.45,0),'dark')
   for x in (-1,0,1):p('Saida de ar',(.3,.1,1.1),(x,.56,-d/2+1.2),'dark')
 if id in ['Serra','Espinhos','EspinhosEscondidos','Lava','Esteira']:
  for x in range(-int(w/2)+1,int(w/2),2):p('Faixa de seguranca',(.7,.12,.6),(x,.64,-d/2+.35),'yellow',rot=(0,35,0))
 if id=='Laser':
  for x in (-5,5):
   p('Painel emissor',(1.4,.6,.08),(x,-.8,-1.05),'silver')
   for dx in (-.35,0,.35):p('Indicador',(.16,.16,.08),(x+dx,-.8,-1.12),'cyan',glow=True)
 if id=='Serra':
  for x in (-1.5,1.5):
   for z in (-4.8,4.8):p('Rebite do trilho',(.3,.15,.3),(x,.34,z),'silver','Cylinder')
  p('Motor do trilho',(1.8,.8,1.2),(0,.6,4.7),'blue',stud=True)
 if id=='Ventilador':
  p('Placa do motor',(.8,.4,.08),(0,.8,-.65),'silver')
 if id=='MarteloEmpurrao':
  for x in (-2,0,2):p('Rebite do martelo',(.3,.3,.15),(x,1,-1.6),'silver','Ball')
 if id=='BombaRelogio':
  for a in range(8):
   r=a*math.tau/8;p('Cinta metalica',(.8,.25,.22),(math.cos(r)*1.65,-.25,math.sin(r)*1.65),'silver',rot=(0,-a*45,0))
  for x in (-.45,.1,.65):p('Digito',(.2,.3,.08),(x,.05,-1.83),'white',glow=True)
 if id=='PortalTroll':
  for y in (-1.5,0,1.5):
   for x in (-1.6,1.6):p('Cristal',(.42,.42,.3),(x,y,-.55),'cyan','Ball',glow=True)

# Elementos de cenario, todos criados no Blender e exportados com os mesmos parametros.
offset=(0,0,0)
asset('Ilha')
p('Terra',(24,4,24),(0,-3,0),'brown',stud=True);p('Terra inferior',(18,5,18),(0,-7.5,0),'dark');p('Grama',(26,1,26),(0,-.5,0),'grass',stud=True);p('Nucleo',(10,4,10),(0,-12,0),'gray')
asset('Arvore')
p('Tronco',(2.3,7,2.3),(0,3.5,0),'brown',stud=True);p('Copa inferior',(9,4,8),(0,8,0),'green',stud=True);p('Copa superior',(6,3,6),(1,11,0),'grass',stud=True)
asset('Pinheiro')
p('Tronco',(2,4,2),(0,2,0),'brown');p('Copa',(8,3,8),(0,5,0),'green',stud=True);p('Copa',(6,3,6),(0,8,0),'green',stud=True);p('Copa',(3,3,3),(0,11,0),'grass',stud=True)
asset('Nuvem')
for s,pos in [((16,4,7),(0,0,0)),((8,5,9),(-4,2,0)),((8,4,8),(5,1,0))]:p('Bloco de nuvem',s,pos,'white',stud=True)
asset('Arco')
for x in (-18,18):
 p('Sapata',(5,2,5),(x,1,0),'dark',stud=True);p('Coluna',(3,11,3),(x,7,0),'blue',stud=True);p('Capitel',(5,1,5),(x,13,0),'yellow',stud=True)
 for y in (4,8,12):p('Faixa',(3.2,.7,3.2),(x,y,0),'white')
p('Viga',(40,2,3),(0,14,0),'red',stud=True)
for x in range(-16,17,4):p('Bandeirola',(2.7,1.7,.25),(x,11.8,0),'yellow' if x%8==0 else 'white')
asset('Trofeu')
p('Pedestal',(6,1,6),(0,.5,0),'dark',stud=True);p('Placa',(3,.6,.15),(0,.6,-3.05),'yellow');p('Haste',(1,3,1),(0,2.5,0),'yellow','Cylinder');p('Taca',(4,2.6,4),(0,5,0),'yellow','Cylinder');p('Borda',(4.5,.4,4.5),(0,6.4,0),'yellow','Cylinder');p('Interior',(3.5,.15,3.5),(0,6.65,0),'brown','Cylinder')
for x in (-2.8,2.8):p('Alca',(1,2.5,1),(x,5,0),'yellow');p('Ligacao',(2,.5,1),(x*.8,6.1,0),'yellow')
asset('Banco')
for x in (-3,3):p('Pe',(1.2,2,3),(x,1,0),'dark')
p('Assento',(9,.7,3.5),(0,2.2,0),'red',stud=True);p('Encosto',(9,3,.7),(0,3.8,1.3),'red',stud=True)
asset('Poste')
p('Sapata',(2,1,2),(0,.5,0),'dark',stud=True);p('Poste',(.65,8,.65),(0,5,0),'gray');p('Lanterna',(2,2,2),(0,9.5,0),'yellow',glow=True);p('Chapeu',(2.8,.6,2.8),(0,10.8,0),'red',stud=True)
asset('Oficina')
p('Chao',(18,1,18),(0,-.5,0),'yellow',stud=True)
for x in (-8,8):
 for z in (-8,8):p('Pilar',(1.5,10,1.5),(x,5,z),'red',stud=True)
p('Telhado',(20,1.5,20),(0,11,0),'blue',stud=True);p('Cumeeira',(15,1,15),(0,12.2,0),'blue',stud=True);p('Bancada',(10,1,3),(0,2,5),'brown',stud=True)
for x,col in [(-3,'red'),(0,'blue'),(3,'yellow')]:p('Bloco de obra',(2,2,2),(x,3.5,5),col,stud=True)
asset('Bandeira')
p('Pe',(3,.7,3),(0,.35,0),'dark',stud=True);p('Mastro',(.5,9,.5),(0,5,0),'white');p('Bandeira',(4,2.5,.3),(-2,8,0),'green',stud=True);p('Topo',(.9,.9,.9),(0,10,0),'yellow','Ball')
asset('Rocha')
p('Rocha',(6,4,5),(0,1.2,0),'gray',stud=True);p('Rocha topo',(4,2,3),(-1,3,0),'silver',stud=True)
(ROOT/'modelos.json').write_text(json.dumps(assets))
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'Modelos_Stud_Classico.blend'))
# Render de revisao: somente o catalogo, sem a biblioteca de cenario sobreposta.
for name in assets:
 if name not in ids:bpy.data.collections[name].hide_render=True
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=20;scene.cycles.use_denoising=False
scene.world.color=(.22,.26,.32)
bpy.ops.object.light_add(type='AREA',location=(45,-25,70));bpy.context.object.data.energy=65000;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=70
bpy.ops.object.camera_add(location=(104,-100,105));cam=bpy.context.object;target=Vector((52,-21,0));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=139;scene.camera=cam
scene.render.resolution_x=1600;scene.render.resolution_y=900;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.render.filepath=str(ROOT/'Catalogo_Stud_Classico.png');scene.view_settings.view_transform='Standard'
bpy.ops.render.render(write_still=True)
print('BLENDER_EXPORT_OK',len(assets),'assets',sum(len(v) for v in assets.values()),'parts')
