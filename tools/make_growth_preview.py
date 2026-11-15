"""Generate an asset composition sheet; not an in-engine screenshot."""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT/'assets'
DEST = ROOT/'evidence/Fieldwork-4.7-Growth-Atlas.png'
DEST.parent.mkdir(exist_ok=True)
CROPS = ['wheat','bean','sunflower','potato','strawberry','barley','carrot','lettuce','maize','tomato','pumpkin','lavender']
SPANISH = ['Trigo','Habichuela','Girasol','Patata','Fresa','Cebada','Zanahoria','Lechuga','Maíz','Tomate','Calabaza','Lavanda']
STAGES = ['Seed', 'Sprout', 'Young', 'Bloom', 'Mature']
W,H=1900,1000
im=Image.new('RGB',(W,H),(231,240,225))
d=ImageDraw.Draw(im)
try:
    fontpath='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
    boldpath='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
    titlef=ImageFont.truetype(boldpath,42)
    subtitlef=ImageFont.truetype(fontpath,20)
    label=ImageFont.truetype(boldpath,18)
    tiny=ImageFont.truetype(fontpath,14)
except OSError:
    titlef=subtitlef=label=tiny=ImageFont.load_default()
d.rounded_rectangle((18,18,W-18,H-18),radius=25,fill=(244,249,239),outline=(154,186,151),width=3)
d.text((62,40),'FIELDWORK 4.7  /  LIVING FARM',font=titlef,fill=(37,81,59))
d.text((66,100),'CROP GROWTH ASSET ATLAS   |   12 CROPS   |   FIVE VISUAL STAGES',font=subtitlef,fill=(93,119,91))
cardw=439; cardh=254; xs=[35,501,967,1433]; ys=[156,418,680]
for index,crop in enumerate(CROPS):
    x=xs[index%4]; y=ys[index//4]
    d.rounded_rectangle((x,y,x+cardw,y+cardh),radius=18,fill=(255,254,246),outline=(194,215,185),width=2)
    d.text((x+18,y+12),f'{crop.upper()}  /  {SPANISH[index]}',font=label,fill=(51,95,69))
    d.line((x+18,y+47,x+cardw-18,y+47),fill=(211,229,203),width=2)
    for stage in range(5):
        cellx=x+12+stage*84
        celly=y+56
        d.rounded_rectangle((cellx,celly,cellx+78,celly+139),radius=10,fill=(239,245,234))
        name=f'growth_{crop}_{stage}.png' if stage<4 else f'crop_{crop}.png'
        art=Image.open(ASSETS/name).convert('RGBA')
        art.thumbnail((74,99),Image.Resampling.LANCZOS)
        im.paste(art,(cellx+(78-art.width)//2,celly+10+(98-art.height)//2),art)
        d.text((cellx+7,celly+117),STAGES[stage],font=tiny,fill=(66,104,78))
    d.text((x+18,y+210),'The game reads growth from the saved crop state.',font=tiny,fill=(111,139,108))
d.text((65,961),'ASSET COMPOSITION • Not a screenshot from Godot • All stages rendered with transparent PNGs',font=tiny,fill=(114,132,111))
im.save(DEST)
print(DEST)
