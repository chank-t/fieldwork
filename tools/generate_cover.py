from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
from pathlib import Path
from math import sin,cos,pi
import random
random.seed(14)
W,H=1600,900
im=Image.new('RGB',(W,H)); px=im.load()
# Sunrise, warm haze, saturated living valley horizon
for y in range(H):
 t=y/H
 if t<.55:
  k=t/.55;a=(148,199,217);b=(246,222,177)
 else:
  k=(t-.55)/.45;a=(246,222,177);b=(127,160,114)
 for x in range(W):
  v=tuple(int(a[i]*(1-k)+b[i]*k) for i in range(3))
  px[x,y]=v
d=ImageDraw.Draw(im,'RGBA')
# atmospheric sun
for r in range(160,37,-5):
 d.ellipse((1220-r,190-r,1220+r,190+r),fill=(255,238,170,max(0,18-(160-r)//12)))
d.ellipse((1160,130,1280,250),fill=(255,244,187,255))
# distant hills, far green layers
for c,pts in [
 ((161,183,161,245),[(0,535),(160,440),(350,495),(520,407),(720,488),(930,405),(1200,483),(1430,412),(1600,473),(1600,900),(0,900)]),
 ((111,159,126,255),[(0,580),(200,515),(370,590),(600,510),(800,570),(1040,480),(1260,555),(1600,500),(1600,900),(0,900)]),
 ((77,133,104,255),[(0,700),(250,570),(540,653),(810,540),(1140,650),(1450,575),(1600,610),(1600,900),(0,900)]),
]:d.polygon(pts,fill=c)
# farm fields, diagonal planted plots
for idx in range(10):
 x0=idx*168-120
 pts=[(x0,655),(x0+175,630),(x0+460,900),(x0+125,900)]
 palette=[(160,184,97,255),(188,191,104,255),(137,168,92,255),(208,183,99,255),(91,156,103,255)]
 d.polygon(pts,fill=palette[idx%5])
 for q in range(3):
  xx=x0+35+q*25
  d.line([(xx,672),(xx+180,895)],fill=(237,218,142,125),width=5)
# winding brook and wave stripes
river=[(0,788),(120,739),(245,709),(349,694),(449,703),(540,742),(630,813),(695,900)]
d.line(river,fill=(76,156,170,255),width=100,joint='curve')
d.line(river,fill=(119,191,194,255),width=70,joint='curve')
for i in range(22):
 x=20+i*31;y=780-65*sin(i*.19)
 d.arc((x,y,x+58,y+22),180,345,fill=(211,238,226,145),width=3)
# rendered farmhouse and barn on hill horizon (left and right)
def house(x,y,scale=1,color=(232,211,172,255),roof=(145,87,64,255)):
 w=int(200*scale);h=int(130*scale)
 d.rounded_rectangle((x,y,x+w,y+h),radius=11,fill=color,outline=(68,97,73,255),width=5)
 d.polygon([(x-30,y+20),(x+w//2,y-75*scale),(x+w+30,y+20)],fill=roof)
 d.line([(x-30,y+20),(x+w//2,y-75*scale),(x+w+30,y+20)],fill=(85,72,56,255),width=7)
 for wx in [x+30,x+w-73]:
  d.rounded_rectangle((wx,y+35,wx+42,y+79),radius=5,fill=(133,175,175,255),outline=(79,100,79,255),width=4)
  d.line([(wx+21,y+36),(wx+21,y+79)],fill=(236,220,187,255),width=3)
 d.rectangle((x+w//2-20,y+h-70,x+w//2+20,y+h),fill=(136,98,66,255))
house(440,407,.85)
house(1270,480,.63,(214,197,160,255),(112,103,83,255))
# orchard trees, silhouette stems and soft canopies
for i in range(21):
 x=80+i*78 + random.randint(-15,15)
 y=500+int(45*sin(i*.8))
 if 390 < x < 650 or 1260 < x < 1450:continue
 w=random.randint(18,27)
 d.line([(x,y+85),(x,y)],fill=(92,89,63,255),width=8)
 d.ellipse((x-w*2,y-w,x+w*2,y+w),fill=(60+random.randint(0,25),125+random.randint(0,20),84,240))
 for j in range(3):
  fx=x+random.randint(-w,w);fy=y+random.randint(-w//2,w//2)
  d.ellipse((fx-5,fy-5,fx+5,fy+5),fill=(226,174,97,230))
# fields near foreground: textured multicolour leaves and flowers
for i in range(125):
 x=random.randint(50,W-50);y=random.randint(730,880)
 color=random.choice([(243,214,136,190),(238,225,176,190),(217,167,119,180),(216,185,207,180)])
 if x<690 and y>720:continue
 d.line([(x,y),(x-4,y-23)],fill=(64,126,75,175),width=3)
 d.ellipse((x-8,y-30,x+3,y-17),fill=color)
# foreground shadow texture & border
im=im.filter(ImageFilter.GaussianBlur(radius=.15))
im.save(Path(__file__).resolve().parents[1] / 'assets' / 'cover_landscape.png',optimize=True)
print('cover created',im.size)
