from PIL import Image, ImageDraw
from pathlib import Path
out=Path(__file__).resolve().parents[1] / 'assets'
# Original vector-style farmer portraits matching the existing flat-shaded world.
roles=[
 ('ines','#e0b995','#51352e','#b37e89','bun',''),
 ('mateo','#c58d6f','#3a3529','#6797aa','crop','beard'),
 ('rosa','#ab7358','#2a211d','#b8a36a','wave',''),
 ('bruno','#e3b48c','#663f2a','#7b9f69','hat','beard'),
 ('lila','#a77962','#272528','#8d79ae','braids',''),
 ('clara','#e9c9a7','#896a48','#6c9e8f','long',''),
 ('elena','#c68d70','#523e32','#b96e65','bun',''),
 ('paco','#e4b59b','#4a4235','#d3a15f','hat','moustache'),
 ('omar','#805e4c','#251f20','#5d8597','crop','beard'),
 ('sofia','#d6a685','#623d30','#a077b0','braids','')]
for name,skin,hair,clothing,style,facial in roles:
 sc=4
 W,H=120*sc,165*sc
 img=Image.new('RGBA',(W,H),(0,0,0,0)); d=ImageDraw.Draw(img)
 def E(xy,fill,outline=None,width=0):d.ellipse([int(z*sc) for z in xy],fill=fill,outline=outline,width=width*sc)
 def R(xy,fill,outline=None,width=0):d.rounded_rectangle([int(z*sc) for z in xy],radius=11*sc,fill=fill,outline=outline,width=width*sc)
 def L(coords,fill,width):d.line([(int(x*sc),int(y*sc)) for x,y in coords],fill=fill,width=width*sc,joint='curve')
 E((19,141,101,159),'#315b434a')
 # boots and pants
 R((43,112,58,145),'#4e5846');R((62,112,77,145),'#4e5846')
 E((38,138,61,152),'#4a4035');E((60,138,85,152),'#4a4035')
 # body and sleeves
 R((30,74,89,125),clothing)
 E((25,84,44,107),skin);E((76,84,95,107),skin)
 L([(55,71),(63,84)],'#fff8e2',3)
 R((55,66,65,81),skin)
 # hair rear, behind head
 if style in ['long','braids','bun','wave']:
  R((32,29,87,98),hair)
 # head
 E((37,25,83,78),skin)
 # hair top profile: reference same head center
 if style=='hat':
  E((33,19,87,45),hair)
  R((26,28,93,41),'#a78650')
  E((39,15,82,34),'#9b7d4d')
 elif style=='bun':
  E((58,14,86,41),hair)
  E((36,21,84,45),hair)
 elif style=='braids':
  E((36,23,84,45),hair)
  for yy in (44,54,64,74,84):
   E((31,yy,40,yy+11),hair);E((80,yy,89,yy+11),hair)
 elif style=='wave':
  for j in range(5):E((35+j*10,19+(j%2)*3,52+j*9,43),hair)
 elif style=='long':
  E((37,21,83,42),hair)
  R((32,39,42,99),hair);R((78,39,88,98),hair)
 else:
  E((36,22,84,40),hair)
 # tiny facial features
 E((49,49,53,53),'#34302b');E((67,49,71,53),'#34302b')
 if facial=='beard':
  E((45,62,76,77),hair)
  E((50,59,71,69),skin)
 elif facial=='moustache':
  E((53,61,61,66),hair);E((60,61,68,66),hair)
 else:
  L([(54,67),(61,70),(68,67)],'#8f574b',2)
 # bag straps, sleeves subtle
 L([(41,80),(40,115)],'#ffffff42',2)
 img.resize((120,165),Image.Resampling.LANCZOS).save(out/f'person_{name}.png')
print('Generated',len(roles),'unique farmers')
