"""Generate consistent transparent 2D crop growth stages; deterministic assets.

Run: python3 tools/generate_growth_sprites.py
Requires Pillow (build time only; Godot needs no Python/runtime dependencies).
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math

ROOT = Path(__file__).resolve().parents[1] / "assets"
ROOT.mkdir(exist_ok=True)
SWATCHES = {
    "wheat": (209, 170, 78), "bean": (91, 145, 75), "sunflower": (245, 196, 65),
    "potato": (194, 155, 96), "strawberry": (221, 82, 97), "barley": (230, 186, 88),
    "carrot": (236, 137, 68), "lettuce": (129, 180, 92), "maize": (244, 209, 87),
    "tomato": (211, 87, 69), "pumpkin": (224, 139, 55), "lavender": (157, 116, 185),
}
STAGE = {"sown": 0, "sprout": 1, "young": 2, "flowering": 3}
SCALE = 4
W, H = 84 * SCALE, 100 * SCALE

def sx(point):
    return tuple(int(v*SCALE) for v in point)

def polygon(d, pts, fill, outline=None, width=1):
    d.polygon([sx(p) for p in pts], fill=fill)
    if outline:
        d.line([sx(p) for p in pts] + [sx(pts[0])], fill=outline, width=width*SCALE, joint="curve")

def line(d, pts, fill, w=2):
    d.line([sx(p) for p in pts], fill=fill, width=w*SCALE, joint="curve")

def ellipse(d, rect, fill, outline=None, width=1):
    d.ellipse((*sx(rect[:2]), *sx(rect[2:])), fill=fill, outline=outline, width=width*SCALE)

def plant(name: str, phase: int) -> Image.Image:
    col = SWATCHES[name]
    sprout = (80, 155, 93, 255)
    dark = (46, 110, 78, 255)
    outline = (53, 91, 60, 240)
    accent = (*col, 255)
    im = Image.new("RGBA", (W, H), (0,0,0,0))
    d = ImageDraw.Draw(im)
    if phase == 0:
        # tiny seed with a root marker
        ellipse(d, (35,74,48,86), (180,142,88,255), (121,92,59,255), 2)
        line(d, [(41,84),(41,93)],(242,229,202,210),2)
        return im.resize((84,100),Image.Resampling.LANCZOS)
    stems = 1 if phase == 1 else (2 if phase == 2 else 3)
    heights = [28, 52, 69, 84]
    for k in range(stems):
        h = heights[phase] * (0.86+0.12*((k+1)%3))
        x = 42 + (k-(stems-1)/2)*14
        top = 87-h
        line(d, [(x,87),(x-2+4*math.sin(k*1.3),top)], dark, 3 if phase<3 else 4)
        for j in range(1 if phase==1 else (2 if phase==2 else 3)):
            t = (j+1)/float((2 if phase==1 else (3 if phase==2 else 4)))
            yy = 87-h*t
            direction = -1 if (j+k)%2==0 else 1
            pts = [(x,yy+6),(x+direction*(11+phase*3),yy-5),(x+direction*(17+phase*3),yy-10),(x+direction*7,yy-9)]
            polygon(d,pts,sprout,outline,1)
            line(d,[(x,yy+4),(x+direction*13,yy-7)],(154,203,122,255),1)
        if phase == 3:
            if name in ["wheat", "barley", "maize"]:
                for r in range(4):
                    ellipse(d,(x-5,top+r*4,x+5,top+8+r*4),accent, (138,107,55,255),1)
            elif name in ["lettuce", "carrot", "potato"]:
                ellipse(d,(x-7,top-4,x+8,top+10),sprout,outline,1)
            else:
                for petal in range(7):
                    a = petal * math.tau / 7
                    px = x + math.cos(a) * 8
                    py = top + math.sin(a) * 8
                    ellipse(d,(px-4,py-5,px+4,py+4),accent,(*col[:3],255))
                ellipse(d,(x-5,top-5,x+5,top+5),(247,212,109,255))
    return im.resize((84,100),Image.Resampling.LANCZOS)

if __name__ == '__main__':
    for crop in SWATCHES:
        for phase in range(4):
            file = ROOT / f"growth_{crop}_{phase}.png"
            plant(crop, phase).save(file)
    print(f"Generated {len(SWATCHES)*4} crop stage sprites in {ROOT}")
