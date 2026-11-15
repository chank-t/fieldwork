#!/usr/bin/env python3
"""Deterministic original pixel-art sprites for Fieldwork 5.2 crops and plots.
Run from any directory; generates editable PNGs without external downloaded art."""
from PIL import Image, ImageDraw
from pathlib import Path
import colorsys, random, math, json
ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'assets'
CONTENT=json.loads((ROOT/'data/catalog.json').read_text())['crops']
NEW_IDS=['rye','oats','chickpea','lentil','beetroot','cucumber','aubergine','basil','raspberry','blueberry','rice','apple','olive','almond','grape']
FORMS={'rye':'grain','oats':'grain','chickpea':'pulse','lentil':'pulse','beetroot':'root','cucumber':'vine','aubergine':'vine','basil':'herb','raspberry':'berry','blueberry':'berry','rice':'rice','apple':'tree','olive':'tree','almond':'tree','grape':'vineyard'}
FRUIT={'rye':'#dfc16c','oats':'#dab46c','chickpea':'#a7b979','lentil':'#b3a16f','beetroot':'#b44768','cucumber':'#5da064','aubergine':'#77569d','basil':'#71ba83','raspberry':'#cb5164','blueberry':'#6176b7','rice':'#e4cf86','apple':'#d94f48','olive':'#7c9062','almond':'#bea77a','grape':'#8a66aa'}

def rgb(h):return tuple(int(h[i:i+2],16) for i in (1,3,5))
def scale(c,v):return tuple(max(0,min(255,int(x*v))) for x in c)
def art(crop,stage):
    sz=(42,50) if stage <4 else (48,59)
    im=Image.new('RGBA',sz,(0,0,0,0));d=ImageDraw.Draw(im)
    form=FORMS[crop];rng=random.Random(crop+':'+str(stage));fruit=rgb(FRUIT[crop])
    green=rgb('#50935e' if form not in ('rice','grain') else '#83a55d')
    dark=scale(green,.68);light=scale(green,1.25)
    cx=sz[0]//2;bottom=sz[1]-5
    # Small organic ground-shadow to anchor every standalone sprite.
    d.ellipse((cx-10,bottom-2,cx+10,bottom+1),fill=(45,69,42,60))
    if stage == 0:
        d.line((cx,bottom-2,cx,bottom-11),fill=dark,width=2)
        d.ellipse((cx-9,bottom-11,cx,bottom-6),fill=light)
        d.ellipse((cx,bottom-12,cx+9,bottom-6),fill=green)
    elif form in ('tree','vineyard'):
        height={1:13,2:21,3:27,4:34}[stage]
        top=bottom-height
        d.polygon([(cx-3,bottom),(cx-1,top+9),(cx+3,top+9),(cx+4,bottom)],fill=rgb('#83634a'))
        d.line((cx,top+13,cx-11,top+6),fill=rgb('#71513d'),width=2)
        d.line((cx,top+12,cx+11,top+4),fill=rgb('#71513d'),width=2)
        if form=='vineyard':
            d.line((cx-16,bottom-17,cx+16,bottom-17),fill=rgb('#b69b72'),width=2)
            d.line((cx-16,bottom-17,cx-16,bottom-3),fill=rgb('#b69b72'),width=2)
            d.line((cx+16,bottom-17,cx+16,bottom-3),fill=rgb('#b69b72'),width=2)
        for i in range(9 if stage>2 else 5):
            px=cx+rng.randint(-15,15);py=top+rng.randint(0,15)
            rr=5 if stage>2 else 3
            d.ellipse((px-rr,py-rr,px+rr,py+rr),fill=(light if i%3==0 else green if i%2==0 else dark))
        if stage>=3:
            for i in range(10 if stage==4 else 5):
                px=cx+rng.randint(-15,15);py=top+rng.randint(1,15)
                d.ellipse((px-2,py-2,px+2,py+2),fill=fruit)
                d.point((px-1,py-1),fill=scale(fruit,1.24))
    else:
        stems=5 if form in ('grain','rice') else 4 if form in ('berry','pulse','vine','herb','vineyard') else 3
        growth={1:14,2:20,3:28,4:37}[stage]
        for i in range(stems):
            bx=cx+(i-(stems-1)/2)*5
            angle=rng.randint(-6,6)
            ty=bottom-growth+rng.randrange(-4,5)
            tx=bx+angle
            d.line((bx,bottom-2,tx,ty),fill=dark,width=2)
            for j in range(2 if stage == 1 else 4 if stage >=3 else 3):
                yl=bottom-7-j*(growth-5)/max(1,(3 if stage >=3 else 2))
                xx=bx+(tx-bx)*(bottom-yl)/growth
                length=4 if stage==1 else 5 if form=='grain' else 7
                side=-1 if (i+j)%2 else 1
                d.ellipse((xx+min(0,side*length),yl-3,xx+max(0,side*length),yl+2),fill=light if j%2 else green)
            if stage>=3:
                if form in ('grain','rice'):
                    for k in range(5 if stage==4 else 3):
                        yy=ty+k*3
                        d.ellipse((tx-2+(k%2),yy-1,tx+2+(k%2),yy+2),fill=fruit)
                elif form in ('berry','pulse'):
                    for k in range(3 if stage==3 else 5):
                        fx=tx+rng.randrange(-8,9);fy=ty+rng.randrange(2,13)
                        d.ellipse((fx-2,fy-2,fx+2,fy+2),fill=fruit)
                elif form in ('vine','root'):
                    for k in range(1 if stage==3 else 2):
                        fx=bx+rng.randrange(-5,6);fy=bottom-rng.randint(7,18)
                        rr=2 if stage==3 else 4
                        d.ellipse((fx-rr,fy-rr,fx+rr,fy+rr),fill=fruit)
                elif form=='herb':
                    for k in range(4):
                        fx=tx+rng.randrange(-5,6);fy=ty+rng.randrange(0,12)
                        d.ellipse((fx-2,fy-2,fx+2,fy+2),fill=light)
        if form=='root' and stage>=2:
            rr=3 if stage<=2 else 5
            d.ellipse((cx-rr,bottom-4,cx+rr,bottom+2),fill=fruit)
        if form=='rice' and stage>=2:
            d.ellipse((cx-18,bottom-4,cx+18,bottom+1),fill=(*rgb('#76b9c8'),100))
    # A clean 1px outline on the most salient base stem is intentionally stylized.
    target=(84,100) if stage < 4 else (96,118)
    return im.resize(target,Image.Resampling.NEAREST)

for crop in NEW_IDS:
    assert crop in CONTENT
    for stage in range(5):
        filename=(f'growth_{crop}_{stage}.png' if stage<4 else f'crop_{crop}.png')
        art(crop,stage).save(ASSETS/filename)

# 5.2 plot-mode texture sheets: tileable, deterministic drawn in native pixel colors.
for plot,bg,accent in [('raised','#9d7755','#d2aa7c'),('orchard','#988266','#a59a73'),('paddy','#6ca6a6','#c4d9b5')]:
    rr=random.Random('fieldwork52_'+plot)
    im=Image.new('RGBA',(192,192),rgb(bg)+(255,));d=ImageDraw.Draw(im)
    if plot=='paddy':
        for y in range(0,192,21):
            d.rectangle((0,y,191,y+9),fill=rgb('#75afaf'))
            for x in range(10,192,31):
                d.line((x,y+6,x+8,y+6),fill=rgb('#c3dfd7'),width=2)
        for i in range(75):
            x=rr.randrange(192);y=rr.randrange(192);d.ellipse((x,y,x+1,y+1),fill=rgb('#bde4e1'))
    else:
        for y in range(14,192,39):
            if plot=='raised':
                d.rectangle((0,y,191,y+7),fill=rgb(accent));d.line((0,y+8,191,y+8),fill=rgb('#684f3c'),width=2)
            else:
                d.line((0,y,191,y),fill=rgb(accent),width=2)
        for i in range(100):
            x=rr.randrange(192);y=rr.randrange(192)
            d.ellipse((x,y,x+rr.randrange(2,6),y+rr.randrange(2,6)),fill=rgb(accent))
    im.save(ASSETS/f'terrain52_{plot}.png')

# Contact sheet for visual asset inspection, not a screenshot of a running game.
thumbs=Image.new('RGB',(5*172,3*205),'#edf0df');d=ImageDraw.Draw(thumbs)
for i,crop in enumerate(NEW_IDS):
    art_im=Image.open(ASSETS/f'crop_{crop}.png')
    x=(i%5)*172; y=(i//5)*205
    d.rounded_rectangle((x+7,y+6,x+165,y+196),14,fill='#faf8ec',outline='#c5d9c6',width=2)
    thumbs.paste(art_im,(x+38,y+20),art_im)
    d.text((x+16,y+165),crop.replace('_',' ').title(),fill='#294d3a')
(ROOT/'evidence'/'Fieldwork_5_2_Crop_Atlas.png').parent.mkdir(exist_ok=True)
thumbs.save(ROOT/'evidence'/'Fieldwork_5_2_Crop_Atlas.png')
print('5.2 visual assets:',len(NEW_IDS)*5+3)
