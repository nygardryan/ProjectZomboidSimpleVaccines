"""Build Simple Vaccines item models in Blender and write them as Project Zomboid .X static meshes.

Models (game units, same scale as the game's hand props):
  FAVSyringe        - hand-held syringe, +Y = needle, origin = grip (barrel middle)
  FAVSyringe_World  - same syringe lying flat on the ground (length along X, Y up)
  FAVPetriDish      - covered petri dish with a cell culture inside (Y up, origin on the floor)
Textures (one atlas layout per model, several colourways):
  FAVSyringe_Empty / _Dirty / _Crude / _Simple / _Perfect, FAVPetri_Cells / _Boiled
Also saves FAVModels.blend so the meshes can be edited in Blender later.
"""
import math, os
import numpy as np
import bpy, bmesh
from PIL import Image, ImageDraw

OUT = 'models_out'
os.makedirs(OUT, exist_ok=True)
HEADER_SRC = 'src/models/Scalpel.X'


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def cyl(name, r, y0, y1, seg, uv_rect, cap=True, r_top=None, planar=False):
    """Cylinder along Blender +Z (= game +Y) from y0 to y1, UVs mapped into uv_rect (u0,v0,u1,v1)."""
    bpy.ops.mesh.primitive_cone_add(vertices=seg, radius1=r, radius2=r if r_top is None else r_top,
                                    depth=y1 - y0, location=(0, 0, (y0 + y1) / 2),
                                    end_fill_type='NGON' if cap else 'NOTHING')
    o = bpy.context.object; o.name = name
    u0, v0, u1, v1 = uv_rect
    uvl = o.data.uv_layers.active.data
    for loop in o.data.loops:
        uv = uvl[loop.index].uv
        if planar:                       # top-down projection so the whole disc shows the painted region
            co = o.data.vertices[loop.vertex_index].co
            uv[0] = u0 + (u1 - u0) * (0.5 + 0.5 * co.x / r)
            uv[1] = v0 + (v1 - v0) * (0.5 + 0.5 * co.y / r)
        else:
            uv[0] = u0 + (u1 - u0) * min(max(uv[0], 0), 1)
            uv[1] = v0 + (v1 - v0) * min(max(uv[1], 0), 1)
    return o


def box(name, sx, sy, sz, cz, uv_rect):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, cz))
    o = bpy.context.object; o.name = name; o.scale = (sx, sz, sy)
    bpy.ops.object.transform_apply(scale=True)
    u0, v0, u1, v1 = uv_rect
    uvl = o.data.uv_layers.active.data
    for loop in o.data.loops:
        uv = uvl[loop.index].uv
        uv[0] = u0 + (u1 - u0) * uv[0]; uv[1] = v0 + (v1 - v0) * uv[1]
    return o


def join(name, objs):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.object; o.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.to_mesh(o.data); bm.free()
    return o


# atlas regions (u0, v0, u1, v1)
BARREL = (0.0, 0.0, 0.5, 1.0)
PLASTIC = (0.5, 0.0, 0.75, 1.0)
METAL = (0.75, 0.0, 1.0, 1.0)


def build_syringe():
    parts = [
        cyl('needle', 0.0008, 0.040, 0.078, 6, METAL, cap=False, r_top=0.0003),
        cyl('hub', 0.0032, 0.033, 0.041, 10, PLASTIC, r_top=0.0014),
        cyl('barrel', 0.0065, -0.040, 0.034, 14, BARREL),
        box('flange', 0.022, 0.003, 0.009, -0.0405, PLASTIC),
        cyl('rod', 0.0024, -0.064, -0.039, 8, PLASTIC),
        cyl('thumb', 0.0062, -0.067, -0.064, 12, PLASTIC),
    ]
    return join('FAVSyringe', parts)


def build_petri():
    parts = [
        cyl('dish', 0.034, 0.0, 0.007, 24, (0.0, 0.0, 0.5, 0.5), cap=True),
        cyl('culture', 0.030, 0.0012, 0.0042, 20, (0.5, 0.0, 1.0, 0.5), cap=True, planar=True),
        cyl('lid', 0.036, 0.0072, 0.0105, 24, (0.0, 0.5, 0.5, 1.0), cap=True, planar=True),
    ]
    return join('FAVPetriDish', parts)


def mesh_arrays(o, rot=None):
    """Triangles in game coords (+Y up/needle) with per-corner normals/uvs, wound like the game's files."""
    me = o.data
    me.calc_loop_triangles()
    uvl = me.uv_layers.active.data
    V, N, UV, F = [], [], [], []
    for tri in me.loop_triangles:
        idx = []
        for li, vi in zip(tri.loops, tri.vertices):
            b = np.array(me.vertices[vi].co)
            n = np.array(tri.normal) if not tri.use_smooth else np.array(me.vertices[vi].normal)
            n = np.array(tri.normal)
            # blender (Z up) -> game (Y up), un-mirrored for DirectX's left-handed axes
            g = np.array([-b[0], b[2], -b[1]]); gn = np.array([-n[0], n[2], -n[1]])
            if rot is not None:
                g = g @ rot; gn = gn @ rot
            u, v = uvl[li].uv
            V.append(g); N.append(gn); UV.append((u, 1 - v)); idx.append(len(V) - 1)
        a, b2, c = (V[i] for i in idx)
        if np.dot(np.cross(b2 - a, c - a), N[idx[0]]) < 0:
            idx = [idx[0], idx[2], idx[1]]
        F.append(idx)
    return np.array(V), np.array(N), np.array(UV), F


def write_x(path, name, tex, V, N, UV, F):
    src = open(HEADER_SRC, encoding='latin-1').read().replace('\r', '')
    header = src[:src.index('\nMaterial ') + 1]      # up to the real Material block (not 'template Material')
    L = [header.rstrip('\n'), '',
         'Material FAVMaterial {', ' 1.000000;1.000000;1.000000;1.000000;;', ' 9.999999;',
         ' 0.000000;0.000000;0.000000;;', ' 0.000000;0.000000;0.000000;;', '',
         ' TextureFilename {', f'  "{tex}.png";', ' }', '}', '',
         f'Frame {name} {{', ' ', '', ' FrameTransformMatrix {',
         '  1.000000,0.000000,0.000000,0.000000,0.000000,1.000000,0.000000,0.000000,0.000000,0.000000,1.000000,0.000000,0.000000,0.000000,0.000000,1.000000;;',
         ' }', '', f' Mesh {name} {{', f'  {len(V)};']
    fmt = lambda v: ';'.join(f'{x:.6f}' for x in v)
    L += [f'  {fmt(v)};' + (';' if i == len(V) - 1 else ',') for i, v in enumerate(V)]
    L += [f'  {len(F)};']
    L += [f'  3;{f[0]},{f[1]},{f[2]};' + (';' if i == len(F) - 1 else ',') for i, f in enumerate(F)]
    L += ['', '  MeshNormals {', f'   {len(N)};']
    L += [f'   {fmt(n / np.linalg.norm(n))};' + (';' if i == len(N) - 1 else ',') for i, n in enumerate(N)]
    L += [f'   {len(F)};']
    L += [f'   3;{f[0]},{f[1]},{f[2]};' + (';' if i == len(F) - 1 else ',') for i, f in enumerate(F)]
    L += ['  }', '', '  MeshMaterialList {', '   1;', f'   {len(F)};']
    L += ['   0' + (';' if i == len(F) - 1 else ',') for i in range(len(F))]
    L += ['   { FAVMaterial }', '  }', '', '  MeshTextureCoords c1 {', f'   {len(UV)};']
    L += [f'   {u:.6f};{v:.6f};' + (';' if i == len(UV) - 1 else ',') for i, (u, v) in enumerate(UV)]
    L += ['  }', ' }', '}', '']
    with open(path, 'w', encoding='latin-1', newline='\r\n') as f:
        f.write('\n'.join(L))


def hexrgb(h):
    h = h.lstrip('#'); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def syringe_texture(name, liquid, fill, dirty=False):
    """64x64 atlas: left half barrel (liquid + graduations), plastic strip, metal strip."""
    S = 64
    im = Image.new('RGBA', (S, S), (225, 232, 238, 255))
    d = ImageDraw.Draw(im)
    # barrel: v runs along the barrel (image y=0 is the needle end after the 1-v flip)
    glass = (214, 224, 232)
    d.rectangle([0, 0, S // 2 - 1, S - 1], fill=glass)
    if liquid:
        # image row 0 = needle end of the barrel; liquid fills from there toward the plunger
        bot = int(S * fill)
        d.rectangle([0, 0, S // 2 - 1, bot], fill=hexrgb(liquid))
        d.rectangle([0, bot - 1, S // 2 - 1, bot], fill=tuple(min(255, c + 40) for c in hexrgb(liquid)))
    for y in range(4, S - 2, 6):                               # graduation marks
        d.line([(2, y), (9 if (y // 6) % 2 else 6, y)], fill=(70, 80, 90))
    d.line([(S // 2 - 6, 0), (S // 2 - 6, S)], fill=(245, 250, 255))   # highlight
    if dirty:
        import random
        rnd = random.Random(7)
        for _ in range(40):
            x = rnd.randint(0, S // 2 - 3); y = rnd.randint(0, S - 4)
            d.ellipse([x, y, x + rnd.randint(1, 3), y + rnd.randint(1, 4)], fill=(150 + rnd.randint(0, 60), 50, 55))
        d.rectangle([0, 0, S // 2 - 1, S - 1], outline=(110, 90, 80))
    d.rectangle([S // 2, 0, 3 * S // 4 - 1, S - 1], fill=(240, 240, 236) if not dirty else (205, 196, 182))
    d.rectangle([3 * S // 4, 0, S - 1, S - 1], fill=(176, 182, 188))
    d.line([(3 * S // 4 + 4, 0), (3 * S // 4 + 4, S)], fill=(230, 235, 240))
    im.save(f'{OUT}/{name}.png')


def petri_texture(name, culture, speckle):
    S = 64
    im = Image.new('RGBA', (S, S), (215, 228, 235, 255))
    d = ImageDraw.Draw(im)
    # UV v runs bottom-up, image rows top-down: lid region (v 0.5-1) = top half, dish (v 0-0.5) = bottom half
    d.rectangle([0, S // 2, S // 2 - 1, S - 1], fill=(205, 222, 230))          # dish walls/base
    lid = tuple(int(c * 0.55 + 235 * 0.45) for c in hexrgb(culture))          # culture seen through the glass lid
    d.rectangle([0, 0, S // 2 - 1, S // 2 - 1], fill=lid)
    import random
    rnd = random.Random(3)
    d.rectangle([S // 2, 0, S - 1, S - 1], fill=hexrgb(culture))
    for _ in range(90):
        x = rnd.randint(S // 2, S - 3); y = rnd.randint(0, S - 3)
        c = hexrgb(speckle if rnd.random() < 0.6 else culture)
        d.ellipse([x, y, x + rnd.randint(1, 3), y + rnd.randint(1, 3)], fill=tuple(max(0, v - rnd.randint(0, 30)) for v in c))
    for _ in range(60):                                                        # speckles visible through the lid
        x = rnd.randint(2, S // 2 - 4); y = rnd.randint(2, S // 2 - 4)
        c = hexrgb(speckle)
        d.ellipse([x, y, x + rnd.randint(1, 2), y + rnd.randint(1, 2)], fill=tuple(int(v * 0.6 + 235 * 0.4) for v in c))
    d.line([(S // 2 - 5, 0), (S // 2 - 5, S // 2 - 1)], fill=(245, 250, 255))   # glass glint
    im.save(f'{OUT}/{name}.png')


reset()
syr = build_syringe()
petri = build_petri()
bpy.ops.wm.save_as_mainfile(filepath=f'{OUT}/FAVModels.blend')

V, N, UV, F = mesh_arrays(syr)
write_x(f'{OUT}/FAVSyringe.X', 'FAVSyringe', 'FAVSyringe_Empty', V, N, UV, F)
# lying flat: needle (+Y) rotated to +X, raised by the barrel radius so it rests on the floor
rot = np.array([[0, -1, 0], [1, 0, 0], [0, 0, 1.0]])
Vw, Nw, UVw, Fw = mesh_arrays(syr, rot=rot)
Vw[:, 1] -= Vw[:, 1].min()          # rests on the floor
Vw[:, 0] -= (Vw[:, 0].max() + Vw[:, 0].min()) / 2
write_x(f'{OUT}/FAVSyringe_World.X', 'FAVSyringe_World', 'FAVSyringe_Empty', Vw, Nw, UVw, Fw)
Vp, Np_, UVp, Fp = mesh_arrays(petri)
write_x(f'{OUT}/FAVPetriDish.X', 'FAVPetriDish', 'FAVPetri_Cells', Vp, Np_, UVp, Fp)

syringe_texture('FAVSyringe_Empty', None, 0)
syringe_texture('FAVSyringe_Dirty', '#bf4951', 0.12, dirty=True)
syringe_texture('FAVSyringe_Crude', '#59935a', 0.8)
syringe_texture('FAVSyringe_Simple', '#a0499e', 0.8)
syringe_texture('FAVSyringe_Perfect', '#cacb13', 0.8)
petri_texture('FAVPetri_Cells', '#8e4c50', '#6c1e1c')
petri_texture('FAVPetri_Boiled', '#b299a0', '#7e686b')

for n, (v, f) in {'FAVSyringe': (V, F), 'FAVSyringe_World': (Vw, Fw), 'FAVPetriDish': (Vp, Fp)}.items():
    print(n, 'tris', len(f), 'bbox min', v.min(0).round(4), 'max', v.max(0).round(4))
