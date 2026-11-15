#!/usr/bin/env python3
"""Create a desktop 5.6 ART CONCEPT, not a Godot screenshot."""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import math
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'evidence/Fieldwork_5_6_Perspective_Concept.png'
W,H=1440,810
im=Image.new('RGB',(W,H),'#d7ebdc');p=ImageDraw.Draw(im,'RGBA')
# Desktop UI: small status bar, world 990x680 and manager 400x.
p.rectangle((0,0,1440,58),fill='#fcfaf0')
p.text((22,19),'FIELDWORK  5.6  /  A NEW PERSPECTIVE',fill='#276448')
p.text((650,19),'DAY 01     SPRING        EUR 5,193       WATER 3,463m3',fill='#416658')
p.rectangle((0,58,W,108),fill='#e6f0e0')
p.text((26,72),'PAUSE     1x     4x       FARM       FIELDS       VALLEY       ANIMALS       MARKET       BUILD       MORE',fill='#355f49')
p.rectangle((11,118,1010,799),fill='#bddab2')
p.rectangle((1023,118,1429,799),fill='#fff9ec')
p.text((1043,140),'YOUR FARM',fill='#355f49')
p.line((1042,169,1409,169),fill='#d2dfcc',width=2)
p.text((1043,191),'Little Valley    |    Level 1',fill='#294e3d')
p.text((1043,228),'Plot 01: fertile loam',fill='#355f49')
p.text((1043,260),'Water: 65%   Growth: 0%',fill='#64786d')
p.rounded_rectangle((1043,293,1386,343),radius=12,fill='#387f60')
p.text((1110,313),'Manage selected plot',fill='white')
for i,text in enumerate(['Irrigate +15','Inspect soil & pests','Choose seeds','View today\'s plan']):
 y=363+67*i
 p.rounded_rectangle((1043,y,1386,y+49),radius=11,fill='#dcebd4')
 p.text((1072,y+15),text,fill='#365b47')
p.text((1043,667),'VIEW   2.5D  /  CLASSIC 2D',fill='#365b47')
p.text((1043,714),'Click a plot. Pan and zoom.',fill='#677c6c')
# projected world rectangle inside left surface
X,Y,WW,HH=27,165,960,610
u=min((WW-44)/118,(HH-38)/(118*.56))
origin=(X+WW*.5-(64-54)*u*.5, Y+HH*.5-(64+54)*u*.56*.5)
def iso(x,y): return (origin[0]+(x-y)*u,origin[1]+(x+y)*u*.56)
def poly(pts,fill,outline=None,width=1):
 p.polygon(pts,fill=fill)
 if outline:p.line(pts+[pts[0]],fill=outline,width=width,joint='curve')
base=[iso(1,1),iso(63,1),iso(63,53),iso(1,53)]
poly([(x+1,y+17) for x,y in base], '#789d78')
poly(base,'#9ac797','#d2e4b8',3)
# Perimeter hedges and river
river=[iso(3.3+0.45*math.sin(y*.3),y) for y in [v*.6 for v in range(90)]]
p.line(river,fill='#d4dabd',width=18,joint='curve')
p.line(river,fill='#68b9ba',width=12,joint='curve')
p.line(river,fill='#b8e3d9',width=2,joint='curve')
# plots positions (match 64 x 54)
gx=[7.3,16.6,25.9,35.2,44.5,53.8];gy=[10.8,18.6,26.4,34.2]
for row in range(4):
 for col in range(6):
  i=row*6+col
  x,y=gx[col],gy[row]
  corners=[iso(x,y),iso(x+8.55,y),iso(x+8.55,y+6.75),iso(x,y+6.75)]
  owned=i==0
  fill='#a18d6a' if owned else ('#8bbc81' if (row+col)%2==0 else '#96c78e')
  poly([(px,py+5) for px,py in corners], '#768966')
  poly(corners,fill,'#f2da9d' if owned else '#c8e4aa',2)
  for k in range(3):
   yy=y+1.8+k*1.4
   p.line([iso(x+.5,yy),iso(x+8,yy)],fill='#79674e' if owned else '#78aa72',width=2)
  cx,cy=iso(x+4,y+3)
  # pastel meadow highlight (non-owned)
  if i==0:
   p.ellipse((cx-12,cy-12,cx+12,cy+6),fill='#f5c77a')
  p.text((cx-10,cy-12),str(i+1),fill='#fffaf0' if owned else '#2d5345')
# use real source assets for trees and houses
assets=ROOT/'assets'
def sprite(name,x,y,width=52):
 path=assets/(name+'.png')
 if not path.exists():return
 src=Image.open(path).convert('RGBA'); ratio=src.height/src.width
 h=int(width*ratio);src=src.resize((width,h),Image.Resampling.BICUBIC)
 px,py=iso(x,y)
 im.paste(src,(int(px-width*.5),int(py-h)),src)
for i in range(16):
 x=5+(i%8)*7.3
 y=4 if i<8 else 49
 sprite('tree',x,y,42+(i%3)*6)
sprite('building_farmhouse',9.5,5.3,84)
sprite('building_market',54.2,5.3,84)
sprite('person_ines',31,9,30)
sprite('person_clara',51,9,30)
sprite('animal_cow',20,47,44)
sprite('grass_flowers',13,46,27)
sprite('growth_wheat_3',11.3,14,26)
# selection outline plot1
corner=[iso(gx[0],gy[0]),iso(gx[0]+8.55,gy[0]),iso(gx[0]+8.55,gy[0]+6.75),iso(gx[0],gy[0]+6.75)]
p.line(corner+[corner[0]],fill='#ffe297',width=4)
p.rounded_rectangle((35,124,286,155),radius=10,fill='#fcfaed')
p.text((50,134),'ISOMETRIC FARM  |  2.5D',fill='#315c48')
OUT.parent.mkdir(parents=True,exist_ok=True)
im.save(OUT,optimize=True)
print(OUT)
