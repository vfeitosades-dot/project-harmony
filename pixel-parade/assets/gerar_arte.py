"""Gera sprites e pranchas originais em pixel art, usando Pillow.
Usar: python assets/gerar_arte.py
"""
from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import math,random
random.seed(41)
BASE=Path(__file__).resolve().parent
SPR=BASE/'sprites'; REF=BASE/'referencias';SPR.mkdir(exist_ok=True);REF.mkdir(exist_ok=True)
INK=(24,29,50); GOLD=(249,198,112); WHITE=(255,239,204)
NAMES=['Rei Pinhão','Madame Maré','Caracol Meteoro','Fantasma do Farol','Cacto Catraca','Maestro Eclipse']
COLS=[(235,176,94),(228,139,205),(226,167,104),(166,220,227),(129,188,117),(191,145,221)]
font='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
def text(d,xy,s,size,fill):d.text(xy,s,font=ImageFont.truetype(font,size),fill=fill)
def out_rect(d,rect,fill,outline=INK,w=2): d.rectangle(rect,fill=fill,outline=outline,width=w)
def out_ellipse(d,rect,fill,outline=INK,w=2): d.ellipse(rect,fill=fill,outline=outline,width=w)
def robot(col=(236,137,102),head=(250,224,175),pose=0):
 im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
 step=pose%4
 out_rect(d,(10,21+(step==2),15,27+(step==2)),(54,72,116),w=1)
 out_rect(d,(17,21+(step==1),22,27+(step==1)),(54,72,116),w=1)
 out_rect(d,(8,14,23,25),col,w=2)
 out_rect(d,(5,5,26,20),head,w=2)
 out_rect(d,(8,8,23,15),(38,58,89),w=1)
 out_rect(d,(10,10,14,13),(175,245,245),outline=None)
 out_rect(d,(18,10,21,13),(175,245,245),outline=None)
 out_rect(d,(11,2,21,5),col,w=1)
 out_rect(d,(14,0,18,3),GOLD,w=1)
 out_rect(d,(22,17,29,20),(238,206,131),w=1)
 if pose==3:
  out_rect(d,(22,16,31,18),(115,237,253),w=1)
 return im

def boss(i):
 im=Image.new('RGBA',(96,96));d=ImageDraw.Draw(im);c=COLS[i]
 if i==0:
  for a in range(12):
   th=2*math.pi*a/12;x=48+32*math.cos(th);y=45+32*math.sin(th)
   out_rect(d,(int(x-7),int(y-7),int(x+7),int(y+7)),(133,153,176),w=2)
  out_ellipse(d,(15,12,81,78),c,w=3)
  out_rect(d,(24,30,72,59),(109,84,81),w=2)
 elif i==1:
  out_ellipse(d,(12,6,84,82),c,w=3)
  for x in (23,34,45,56,67):
   out_rect(d,(x,60,x+7,91),c,w=2)
  out_ellipse(d,(19,15,77,66),(247,174,217),w=2)
 elif i==2:
  out_rect(d,(12,50,88,82),(157,184,137),w=3)
  out_ellipse(d,(25,8,85,69),c,w=3)
  for r in [20,12]:out_ellipse(d,(55-r,38-r,55+r,38+r),(250,212,148),w=2)
  out_rect(d,(8,30,23,66),(157,184,137),w=2)
 elif i==3:
  out_ellipse(d,(18,11,79,75),c,w=3)
  out_rect(d,(18,43,79,76),c,w=2)
  for x in (19,34,50,65):out_ellipse(d,(x,69,x+16,89),c,w=2)
 elif i==4:
  out_rect(d,(29,8,65,86),c,w=3)
  out_rect(d,(14,45,30,65),c,w=2)
  out_rect(d,(66,38,81,63),c,w=2)
  for j in range(12):
   x=33+(j*17)%31;y=13+(j*29)%65;d.line((x,y,x+3,y-4),fill=(205,245,162),width=2)
 else:
  out_ellipse(d,(12,16,83,86),c,w=3)
  out_rect(d,(22,20,74,72),(160,100,183),w=3)
  out_rect(d,(17,6,78,22),(243,190,119),w=3)
  out_rect(d,(42,0,54,13),(243,190,119),w=2)
 # original face shapes
 for x in (31,55):out_rect(d,(x,36,x+11,47),(29,40,66),w=1);d.rectangle((x+2,38,x+4,41),fill=(255,242,198))
 out_rect(d,(37,58,61,63),(89,57,86),w=1)
 return im

for i in range(6):
 im=boss(i);im.save(SPR/f'chefe_{i+1:02}.png')
for who in range(2):
 poses=[robot((238,144,98) if who==0 else (98,173,226),pose=i) for i in range(4)]
 sheet=Image.new('RGBA',(128,32));
 for i,pose in enumerate(poses):sheet.paste(pose,(i*32,0),pose)
 sheet.save(SPR/f'heroi_{who+1}_spritesheet_32px.png')

# 4x scaled moodboards
P=Image.new('RGB',(960,590),(21,25,48));d=ImageDraw.Draw(P)
text(d,(34,16),'PIXEL PARADE  |  GUIA DE PERSONAGENS',24,WHITE)
text(d,(35,58),'Sprites originais 32x32  |  4 quadros por heroi  |  visuais de demonstracao',14,(167,192,218))
for who in range(2):
 x=40+who*465
 d.rounded_rectangle((x,93,x+415,252),radius=10,fill=(42,57,88),outline=(103,133,166),width=3)
 for i in range(4):
  a=robot((238,144,98) if who==0 else (98,173,226),pose=i).resize((84,84),Image.Resampling.NEAREST)
  P.paste(a,(x+25+i*96,111),a)
 text(d,(x+19,213),f"{['BOLIN','PINGO'][who]} - Idle / correr / saltar / disparar",15,WHITE)
text(d,(34,280),'SEIS CHEFES ORIGINAIS  |  SILHUETAS 96x96',20,GOLD)
for i in range(6):
 x=35+(i%3)*307;y=313+(i//3)*130
 d.rounded_rectangle((x,y,x+288,y+112),radius=8,fill=(42,57,88),outline=COLS[i],width=2)
 bi=boss(i).resize((88,88),Image.Resampling.NEAREST);P.paste(bi,(x+6,y+10),bi)
 text(d,(x+105,y+32),NAMES[i].upper(),13,WHITE)
 text(d,(x+105,y+57),f'3 atos | chefe {i+1}/6',11,(195,210,226))
P.save(REF/'prancha_personagens_e_chefes.png')

# Game design UI ref
P=Image.new('RGB',(960,540),(19,24,45));d=ImageDraw.Draw(P)
for y in range(0,540,5):d.line((0,y,960,y),fill=(23+y//80*3,29+y//60*4,55+y//80*4),width=5)
text(d,(39,34),'DIRECAO DE ARTE — 16:9 / PIXEL ART / LEGIBILIDADE',21,WHITE)
colors=[(19,24,45),(53,72,104),(89,117,149),(144,200,217),(245,201,119),(244,146,122),(230,127,192),(140,210,158)]
for i,col in enumerate(colors):d.rectangle((42+i*111,97,135+i*111,166),fill=col,outline=WHITE,width=2)
text(d,(38,204),'HUD: coracoes, indicador de parry, barra de chefe com 3 atos',15,WHITE)
d.rounded_rectangle((39,238,912,333),radius=8,fill=(30,39,65),outline=(226,198,142),width=2)
text(d,(55,260),'P1  ♥ ♥ ♥ ♥      P2  ♥ ♥ ♥ ♥',22,(250,141,154))
text(d,(533,265),'REI PINHAO',20,WHITE)
d.rectangle((535,305,883,317),fill=(17,24,44));d.rectangle((535,305,738,317),fill=GOLD)
text(d,(41,361),'BOTÕES TOUCH: ESQUERDA / DIREITA | PULO | MAGIA | DASH | PARRY',14,(199,226,241))
for i,title in enumerate(['◄','►','▲','✦','D','P']):
 x=54+i*141
 d.rounded_rectangle((x,398,x+100,487),radius=14,fill=(51,81,119),outline=(184,230,242),width=3)
 text(d,(x+31,421),title,30,WHITE)
P.save(REF/'direcao_de_arte_e_ui.png')
print('Artes prontas:', [p.name for p in REF.glob('*.png')])
