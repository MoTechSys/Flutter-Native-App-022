from PIL import Image, ImageDraw
import os

SRC = '/home/user/assets/icons/edu_icon.png'
RES = '/home/user/flutter_app/android/app/src/main/res'
im = Image.open(SRC).convert('RGB')

# Tile bbox (found earlier): 204..818 -> crop with inset to avoid rounded corners
tile = im.crop((204, 204, 819, 819)).resize((1024, 1024), Image.LANCZOS)
tp = tile.load()

# Brand gradient (matches app: purple 5B4BDB -> violet/magenta bottom-right)
C1 = (0x5B, 0x4B, 0xDB)   # AppColors.primary
C2 = (0x7C, 0x3A, 0xB8)
def gradient(size):
    g = Image.new('RGB', (size, size)); p = g.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size - 2)
            p[x, y] = tuple(int(C1[i] * (1 - t) + C2[i] * t) for i in range(3))
    return g

# Artwork mask: white + green pixels, restricted to inner 80% to skip corners
art = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0)); ap = art.load()
lo, hi = 100, 924
for y in range(lo, hi):
    for x in range(lo, hi):
        r, g, b = tp[x, y]
        if r > 200 and g > 200 and b > 200:
            ap[x, y] = (255, 255, 255, 255)
        elif g > 120 and r < 110 and b < 160 and g - r > 50:
            ap[x, y] = (0x1F, 0xA9, 0x7A, 255)
# anti-alias edges by slight downscale/upscale
art = art.resize((512, 512), Image.LANCZOS).resize((1024, 1024), Image.LANCZOS)
bbox = art.getbbox(); art = art.crop(bbox)

def compose(size, scale, shape):
    """gradient bg + artwork scaled to `scale` of size; shape: 'rounded'|'circle'|'square'"""
    bg = gradient(size).convert('RGBA')
    t = int(size * scale); ratio = min(t / art.width, t / art.height)
    a = art.resize((max(1, int(art.width * ratio)), max(1, int(art.height * ratio))), Image.LANCZOS)
    bg.paste(a, ((size - a.width) // 2, (size - a.height) // 2), a)
    if shape == 'square': return bg
    mask = Image.new('L', (size, size), 0); d = ImageDraw.Draw(mask)
    if shape == 'circle': d.ellipse((0, 0, size - 1, size - 1), fill=255)
    else: d.rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.22), fill=255)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0)); out.paste(bg, (0, 0), mask); return out

def fg_layer(size):
    """adaptive foreground: artwork only, transparent, inside safe zone (66/108)"""
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    t = int(size * 0.52); ratio = min(t / art.width, t / art.height)
    a = art.resize((int(art.width * ratio), int(art.height * ratio)), Image.LANCZOS)
    out.paste(a, ((size - a.width) // 2, (size - a.height) // 2), a); return out

dens = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
for d, s in dens.items():
    folder = f'{RES}/mipmap-{d}'; os.makedirs(folder, exist_ok=True)
    compose(s, 0.68, 'rounded').save(f'{folder}/ic_launcher.png')
    compose(s, 0.62, 'circle').save(f'{folder}/ic_launcher_round.png')
    a = s * 108 // 48
    gradient(a).save(f'{folder}/ic_launcher_background.png')
    fg_layer(a).save(f'{folder}/ic_launcher_foreground.png')

os.makedirs(f'{RES}/mipmap-anydpi-v26', exist_ok=True)
xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
open(f'{RES}/mipmap-anydpi-v26/ic_launcher.xml', 'w').write(xml)
open(f'{RES}/mipmap-anydpi-v26/ic_launcher_round.xml', 'w').write(xml)

# previews: how launcher masks the adaptive icon (circle & squircle) + legacy
bg = gradient(432).convert('RGBA'); f = fg_layer(432); bg.paste(f, (0, 0), f)
inner = bg.crop((54, 54, 378, 378))  # visible 72dp of 108dp
for shape, name in [('circle', 'adaptive_circle'), ('rounded', 'adaptive_squircle')]:
    m = Image.new('L', inner.size, 0); d = ImageDraw.Draw(m)
    if shape == 'circle': d.ellipse((0, 0, 323, 323), fill=255)
    else: d.rounded_rectangle((0, 0, 323, 323), radius=80, fill=255)
    o = Image.new('RGBA', inner.size, (255, 255, 255, 0)); o.paste(inner, (0, 0), m); o.save(f'/home/user/icon_preview_{name}.png')
compose(512, 0.68, 'rounded').save('/home/user/icon_preview_legacy.png')

web = '/home/user/flutter_app/web'
compose(192, 0.68, 'rounded').save(f'{web}/icons/Icon-192.png'); compose(512, 0.68, 'rounded').save(f'{web}/icons/Icon-512.png')
compose(192, 0.6, 'square').save(f'{web}/icons/Icon-maskable-192.png'); compose(512, 0.6, 'square').save(f'{web}/icons/Icon-maskable-512.png')
compose(64, 0.68, 'rounded').save(f'{web}/favicon.png')
compose(1024, 0.68, 'square').save('/home/user/flutter_app/assets/icons/app_icon.png')
print('done')
