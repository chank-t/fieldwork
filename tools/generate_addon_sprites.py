from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
from math import sin,cos,pi
import random
out=Path(__file__).resolve().parents[1] / 'assets'
S=3

def canvas(w,h): return Image.new('RGBA',(w*S,h*S),(0,0,0,0))
def dr(im):return ImageDraw.Draw(im)
def xy(v):return tuple(int(x*S) for x in v)
def el(d,b,fill,outline='#403d33',width=2):d.ellipse(xy(b),fill=fill,outline=outline,width=width*S if outline else 0)
def poly(d,pts,fill,outline='#403d33',width=2):d.polygon([xy(p) for p in pts],fill=fill);d.line([xy(p) for p in pts+[pts[0]]],fill=outline,width=width*S,joint='curve') if outline else None
def line(d,pts,fill,width=2): d.line([xy(p) for p in pts],fill=fill,width=width*S,joint='curve')
def save(im,name,size):im.resize(size,Image.Resampling.LANCZOS).save(out/name)

# Friendly flat animals match existing outline-and-shadow sprite language.
for animal in ['cow','pig','horse','alpaca','turkey','goose']:
 im=canvas(130,105); d=dr(im)
 el(d,(22,87,114,100),'#547450',None)
 if animal in ('cow','pig','horse','alpaca'):
  fill={'cow':'#f0ebe0','pig':'#ebb2b3','horse':'#ba8762','alpaca':'#e6d8bc'}[animal]
  el(d,(15,34,100,83),fill)
  for x in (30,80):
   poly(d,[(x,73),(x+13,73),(x+11,96),(x+1,96)],'#795d48' if animal=='horse' else '#d5bfae')
  if animal=='cow':
   el(d,(34,39,62,57),'#625b50',None);el(d,(67,59,86,77),'#625b50',None)
  if animal=='horse':
   poly(d,[(19,42),(16,52),(18,77),(12,76),(8,42)],'#453e36')
   poly(d,[(81,32),(91,12),(110,17),(116,35),(100,51)],'#b5835f')
   poly(d,[(91,11),(99,6),(100,25)],'#514338'); poly(d,[(104,14),(113,9),(114,29)],'#514338')
   el(d,(89,39,127,70),'#b78364')
  elif animal=='alpaca':
   poly(d,[(75,47),(79,8),(111,8),(113,49)],fill)
   el(d,(91,13,125,48),'#f0e3cc')
   el(d,(88,4,96,20),fill);el(d,(109,4,117,21),fill)
  else:
   el(d,(83,23,126,69),fill)
   if animal=='cow':
    poly(d,[(89,35),(87,18),(97,21),(101,35)],'#c9b4a0');poly(d,[(110,32),(114,16),(123,25),(122,38)],'#c9b4a0')
    el(d,(105,47,128,65),'#e5b6b4')
   if animal=='pig':
    poly(d,[(89,36),(86,14),(105,25)],'#e9a5ac');poly(d,[(110,29),(125,15),(124,41)],'#e9a5ac')
    el(d,(104,50,132,72),'#dc999e')
    el(d,(118,57,120,60),'#9e6870',None);el(d,(124,57,126,60),'#9e6870',None)
  el(d,(105,38,109,43),'#2f2b2a',None)
  if animal=='horse':line(d,[(88,23),(82,30),(79,47)],'#4a3935',3)
 else:
  fill='#d6a26e' if animal=='turkey' else '#f7f4ec'
  el(d,(27,44,95,87),fill)
  for x in (47,69):line(d,[(x,82),(x-1,95)],'#d59850',3)
  poly(d,[(86,50),(102,44),(115,57),(100,67)],'#e4b05e' if animal=='turkey' else '#e7ba7b')
  el(d,(82,26,115,61),fill)
  if animal=='turkey':
   for t in range(5):
    a=(t-2)*0.55
    poly(d,[(30,60),(26+cos(a)*28,42+sin(a)*36),(36+cos(a)*37,39+sin(a)*42)],'#b37a58')
   el(d,(102,52,108,66),'#c65d54')
  else:
   poly(d,[(15,56),(6,31),(28,42)],fill)
  poly(d,[(107,40),(129,47),(106,52)],'#dc9964')
  el(d,(104,37,109,42),'#292e2b',None)
 save(im,'animal_'+animal+'.png',(130,105))

# Flat stylized crops with growth-stage scaling handled by World.gd.
for crop in ['maize','tomato','pumpkin','lavender']:
 im=canvas(96,118);d=dr(im)
 el(d,(11,103,85,113),'#54734a',None)
 if crop=='maize':
  for k in range(3):
   cx=24+k*24
   line(d,[(cx,102),(cx,25-k*4)],'#638c4e',3)
   poly(d,[(cx,84),(cx-18,64),(cx-18,47),(cx,65)],'#548a53')
   poly(d,[(cx,76),(cx+14,62),(cx+17,42),(cx+1,60)],'#568b50')
   el(d,(cx-6,37,cx+7,64),'#dfb656')
   for j in range(4):line(d,[(cx-4+j*3,40),(cx-4+j*3,61)],'#b98536',1)
   line(d,[(cx,32),(cx,18)],'#ba9a5b',2)
 if crop=='tomato':
  line(d,[(44,99),(46,23)],'#527b4a',4)
  for x,y in [(22,54),(64,47),(25,78),(69,81),(42,41)]:
   line(d,[(47,79),(x,y)],'#557b48',3)
   el(d,(x-14,y-9,x+9,y+7),'#508853')
   el(d,(x-8,y+2,x+9,y+19),'#dc594e')
   poly(d,[(x-4,y+1),(x+1,y-4),(x+6,y+1)],'#5c8b48')
 if crop=='pumpkin':
  line(d,[(43,102),(49,56)],'#4b7847',4)
  for x,y,r in [(26,79,19),(62,80,22),(44,94,18)]:
   el(d,(x-r,y-r/2,x+r,y+r/2),'#d99b43')
   for shift in (-6,6):line(d,[(x+shift,y-r/2),(x+shift+2,y+r/2)],'#b46c2a',2)
  for x,y in [(20,49),(58,51),(81,59)]:el(d,(x-14,y-8,x+8,y+7),'#638b4c')
 if crop=='lavender':
  for k in range(7):
   cx=17+k*10;top=28+(k%3)*7
   line(d,[(45,104),(cx,top)],'#648951',2)
   for j in range(4):
    y=top+j*8
    el(d,(cx-4,y-3,cx+3,y+5),'#9c83c0',None)
    el(d,(cx+2,y-1,cx+9,y+6),'#b39bcc',None)
 save(im,'crop_'+crop+'.png',(96,118))

# Farmstead additions with compatible illustrated perspective.
for name,roof,sign in [('pasture','#74a58c','PASTURE'),('stable','#aa755e','STABLE'),('pigsty','#a56d60','PIGS'),('lookout','#779d84','LOOKOUT'),('clinic','#75a4a7','CLINIC')]:
 im=canvas(210,173);d=dr(im)
 el(d,(20,143,190,161),'#6d9471',None)
 if name=='lookout':
  for x in (70,145):
   poly(d,[(x,68),(x+8,68),(x+8,146),(x,146)],'#9d815e')
  poly(d,[(54,65),(169,65),(158,80),(62,80)],roof)
  poly(d,[(57,66),(109,32),(168,66)],'#537461')
  for x in (67,84,101,118,135):line(d,[(x,75),(x,99)],'#b58f63',2)
 else:
  poly(d,[(31,64),(174,64),(174,144),(31,144)],'#e4d4b5')
  poly(d,[(20,66),(98,20),(187,66)],roof)
  poly(d,[(47,89),(81,89),(81,114),(47,114)],'#9ababb')
  poly(d,[(120,90),(153,90),(153,114),(120,114)],'#9ababb')
  poly(d,[(89,113),(119,113),(119,144),(89,144)],'#8a7057')
  for x in (52,58,64,70,76,125,131,137,143,149):line(d,[(x,89),(x,114)],'#f0e9d5',1)
 save(im,'building_'+name+'.png',(210,173))

# Natural decorations / wildlife, 96x96 RGBA.
for name in ['rock','reed','flower_patch','grass_flowers','wildlife_viper','wildlife_wasp','field_sign']:
 im=canvas(96,96);d=dr(im)
 if name=='rock':
  el(d,(8,63,90,90),'#618264',None)
  poly(d,[(14,70),(24,46),(67,40),(83,58),(72,78),(23,80)],'#b8ae9b')
  line(d,[(24,53),(39,61),(36,74)],'#958d80',2)
 elif name=='reed':
  el(d,(7,77,90,92),'#688f71',None)
  for i in range(8):
   x=15+i*9
   line(d,[(x,86),(x+2,20+i%3*8)],'#4f7d55',3)
   el(d,(x-3,15+i%3*8,x+7,32+i%3*8),'#a5884f')
 elif name in ('flower_patch','grass_flowers'):
  for i in range(12):
   x=12+(i*23)%78;y=40+(i*19)%44
   line(d,[(x,y+10),(x,y-6)],'#5f8754',2)
   el(d,(x-5,y-10,x+5,y),'#e9ba64' if i%3==0 else '#c49bd2' if i%3==1 else '#f3e4b7',None)
   el(d,(x-2,y-7,x+2,y-3),'#c48b46',None)
 elif name=='wildlife_viper':
  line(d,[(17,75),(32,65),(47,77),(65,53),(76,64),(80,51)],'#4f6e49',9)
  el(d,(70,37,89,57),'#6b8058')
  el(d,(80,42,84,46),'#28312a',None)
  line(d,[(87,48),(95,50)],'#a85d62',2)
 elif name=='wildlife_wasp':
  el(d,(31,42,70,71),'#cfab4e')
  for x in (39,51,63):line(d,[(x,46),(x,66)],'#5d4b34',4)
  el(d,(29,19,48,49),'#c9ddd9')
  el(d,(51,19,73,49),'#c9ddd9')
  poly(d,[(50,70),(58,82),(65,70)],'#645037')
 elif name=='field_sign':
  poly(d,[(42,38),(52,38),(51,93),(43,93)],'#886a4a')
  poly(d,[(14,15),(81,15),(81,55),(14,55)],'#f6e8b8')
 save(im,name+'.png',(96,96))
print('created assets',len(list(out.glob('*.png'))))
