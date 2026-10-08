"""Render contact sheets of a PZ animation using Blender (bpy) for visual checking."""
import math
import numpy as np
import bpy
from PIL import Image, ImageDraw

_FONT = None


def _reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_WORKBENCH'
    sc.display.shading.light = 'STUDIO'
    sc.display.shading.color_type = 'OBJECT'
    sc.render.resolution_x = 360
    sc.render.resolution_y = 420
    sc.render.film_transparent = False
    world = bpy.data.worlds.new('w'); sc.world = world
    world.color = (0.82, 0.84, 0.88)
    return sc


def _to_blender(p):
    # game (DirectX, left-handed): +Y up, +X = character's left, -Z = forward
    # -> blender (right-handed, Z up), character facing +Y. det = -1 un-mirrors the data.
    p = np.asarray(p)
    return np.stack([-p[..., 0], -p[..., 2], p[..., 1]], axis=-1)


def render_sheet(xf, samples, out_png, views=(('front', 0), ('side', 90)), extra=None, title=''):
    """samples: list of (label, world_pose_dict). extra(world) -> list of (pos, color, radius)."""
    sc = _reset()
    me = xf.mesh or xf.load_mesh()
    mesh = bpy.data.meshes.new('body')
    v0 = _to_blender(xf.skin(samples[0][1]))
    mesh.from_pydata(v0.tolist(), [], me['faces'])
    obj = bpy.data.objects.new('body', mesh); obj.color = (0.85, 0.72, 0.6, 1)
    sc.collection.objects.link(obj)
    cam_data = bpy.data.cameras.new('cam'); cam_data.type = 'ORTHO'; cam_data.ortho_scale = 1.15
    cam = bpy.data.objects.new('cam', cam_data); sc.collection.objects.link(cam); sc.camera = cam
    # floor reference
    bpy.ops.mesh.primitive_plane_add(size=1.2, location=(0, 0, 0)); bpy.context.object.color = (0.6, 0.6, 0.62, 1)
    markers = []
    tiles = []
    for label, world in samples:
        co = _to_blender(xf.skin(world))
        mesh.vertices.foreach_set('co', co.ravel()); mesh.update()
        for m in markers:
            bpy.data.objects.remove(m, do_unlink=True)
        markers = []
        for pos, color, r in (extra(world) if extra else []):
            bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=tuple(_to_blender(pos)))
            o = bpy.context.object; o.color = (*color, 1); markers.append(o)
        row = []
        for vname, ang in views:
            a = math.radians(ang)
            cam.location = (2.0 * math.sin(a), -2.0 * math.cos(a), 0.5)
            cam.rotation_euler = (math.radians(90), 0, a)
            path = f'/tmp/_tile.png'
            sc.render.filepath = path
            bpy.ops.render.render(write_still=True)
            im = Image.open(path).convert('RGB')
            ImageDraw.Draw(im).text((6, 4), f'{label} {vname}', fill=(0, 0, 0))
            row.append(im)
        tiles.append(row)
    w, h = tiles[0][0].size
    cols = len(tiles)
    sheet = Image.new('RGB', (w * cols, h * len(views) + 20), 'white')
    ImageDraw.Draw(sheet).text((6, 4), title, fill=(0, 0, 0))
    for c, row in enumerate(tiles):
        for r, im in enumerate(row):
            sheet.paste(im, (c * w, 20 + r * h))
    sheet.save(out_png)
    return out_png
