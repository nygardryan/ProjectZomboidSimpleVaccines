"""Render 32x32 Build 42-style inventory icons from the mod's 3D models (Blender, transparent bg)."""
import math, numpy as np, bpy
from PIL import Image, ImageFilter
from render_models import read_static, add_obj, D

OUT = 'icons_out/'
import os; os.makedirs(OUT, exist_ok=True)


def setup():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_WORKBENCH'
    sc.display.shading.light = 'STUDIO'; sc.display.shading.color_type = 'TEXTURE'
    sc.display.shading.show_cavity = True
    sc.render.resolution_x = sc.render.resolution_y = 256
    sc.render.film_transparent = True
    sc.view_settings.view_transform = 'Standard'
    cd = bpy.data.cameras.new('c'); cd.type = 'ORTHO'
    cam = bpy.data.objects.new('c', cd); sc.collection.objects.link(cam); sc.camera = cam
    return sc, cam


def look(cam, loc, target, scale):
    cam.data.ortho_scale = scale; cam.location = loc
    d = np.array(target) - np.array(loc)
    cam.rotation_euler = (math.atan2(math.hypot(d[0], d[1]), -d[2]), 0, math.atan2(d[1], d[0]) - math.pi / 2)


def finish(path_in, name):
    im = Image.open(path_in).convert('RGBA')
    bbox = im.getbbox(); im = im.crop(bbox)
    w, h = im.size; s = 28 / max(w, h)                       # fit in 28 px, leave room for the outline
    im = im.resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)
    canvas = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    canvas.paste(im, ((32 - im.width) // 2, (32 - im.height) // 2), im)
    a = canvas.split()[3].point(lambda v: 255 if v > 60 else 0)
    ring = a.filter(ImageFilter.MaxFilter(3))
    outline = Image.new('RGBA', (32, 32), (28, 24, 22, 255)); outline.putalpha(ring)
    out = Image.alpha_composite(outline, canvas)
    out.save(OUT + name + '.png')
    return out


icons = {}
V, F, UV = read_static(D + 'FAVSyringe.X')
for v in ['Empty', 'Dirty', 'Crude', 'Simple', 'Perfect']:
    sc, cam = setup()
    # tilt the syringe diagonally (needle to the upper right), like the game's long item icons
    a = math.radians(45)
    R = np.eye(4); R[:3, :3] = [[math.cos(a), math.sin(a), 0], [-math.sin(a), math.cos(a), 0], [0, 0, 1]]
    T = np.diag([2.6, 1.0, 2.6, 1.0])          # chunkier barrel/plunger so it reads at 32 px (icon only)
    add_obj('s', V, F, UV, f'FAVSyringe_{v}', T @ R)
    look(cam, (0.0, -0.6, 0.0), (0, 0, 0.0), 0.17)
    sc.render.filepath = '/tmp/icon.png'; bpy.ops.render.render(write_still=True)
    icons[f'Item_FAVSyringe{v}'] = finish('/tmp/icon.png', f'Item_FAVSyringe{v}')
Vp, Fp, UVp = read_static(D + 'FAVPetriDish.X')
for v, tex in [('Cells', 'FAVPetri_Cells'), ('Boiled', 'FAVPetri_Boiled')]:
    sc, cam = setup()
    add_obj('p', Vp, Fp, UVp, tex)
    look(cam, (0.25, -0.35, 0.45), (0, 0, 0.004), 0.1)
    sc.render.filepath = '/tmp/icon.png'; bpy.ops.render.render(write_still=True)
    icons[f'Item_FAVPetri{v}'] = finish('/tmp/icon.png', f'Item_FAVPetri{v}')

# contact sheet: 1x and 4x on the game's dark inventory background
names = list(icons)
sheet = Image.new('RGBA', (len(names) * 140, 190), (58, 56, 52, 255))
for i, n in enumerate(names):
    ic = icons[n]
    sheet.alpha_composite(ic, (i * 140 + 10, 10))
    sheet.alpha_composite(ic.resize((128, 128), Image.NEAREST), (i * 140 + 6, 50))
sheet.convert('RGB').save('out/icons_check.png')
print('ok', names)
