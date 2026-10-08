"""Read the exported .X static models back and render them textured (format + look check)."""
import re, math, numpy as np, bpy
from PIL import Image, ImageDraw
from xanim import XFile
from preview import _to_blender

num = re.compile(r'-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?')
D = 'models_out/'


def read_static(path):
    t = open(path, encoding='latin-1').read().replace('\r', '')
    m = re.search(r'\n Mesh (\w+) \{', t); body = t[m.end():]
    vals = num.findall(body[:body.index('MeshNormals')])
    nv = int(vals[0]); V = np.array(vals[1:1 + 3 * nv], float).reshape(-1, 3); k = 1 + 3 * nv
    nf = int(vals[k]); k += 1; F = []
    for _ in range(nf):
        c = int(vals[k]); F.append([int(x) for x in vals[k + 1:k + 1 + c]]); k += 1 + c
    tb = body[body.index('MeshTextureCoords'):]
    tv = num.findall(tb[tb.index('{'):]); nt = int(tv[0])
    UV = np.array(tv[1:1 + 2 * nt], float).reshape(-1, 2)
    assert nt == nv, 'uv count mismatch'
    return V, F, UV


def add_obj(name, V, F, UV, tex, M=None):
    G = V if M is None else (np.hstack([V, np.ones((len(V), 1))]) @ M)[:, :3]
    me = bpy.data.meshes.new(name)
    me.from_pydata(_to_blender(G).tolist(), [], F)
    uvl = me.uv_layers.new()
    for poly in me.polygons:
        for li, vi in zip(poly.loop_indices, poly.vertices):
            uvl.data[li].uv = (UV[vi][0], 1 - UV[vi][1])
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree; img = nt.nodes.new('ShaderNodeTexImage')
    img.image = bpy.data.images.load(D + tex + '.png'); img.interpolation = 'Closest'
    nt.links.new(img.outputs['Color'], nt.nodes['Principled BSDF'].inputs['Base Color'])
    me.materials.append(mat)
    o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    return o


def setup(res=(420, 300)):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_WORKBENCH'
    sc.display.shading.light = 'STUDIO'; sc.display.shading.color_type = 'TEXTURE'
    sc.render.resolution_x, sc.render.resolution_y = res
    w = bpy.data.worlds.new('w'); sc.world = w; w.color = (0.8, 0.82, 0.86)
    cd = bpy.data.cameras.new('c'); cd.type = 'ORTHO'
    cam = bpy.data.objects.new('c', cd); sc.collection.objects.link(cam); sc.camera = cam
    return sc, cam


def shot(sc, cam, loc, look, scale, path):
    cam.data.ortho_scale = scale
    cam.location = loc
    d = np.array(look) - np.array(loc)
    cam.rotation_euler = (math.atan2(math.hypot(d[0], d[1]), -d[2]), 0, math.atan2(d[1], d[0]) - math.pi / 2)
    sc.render.filepath = path; bpy.ops.render.render(write_still=True)
    return Image.open(path).convert('RGB')


if __name__ == '__main__':
    tiles = []
    # 1) the five syringe colourways, hand model
    sc, cam = setup()
    V, F, UV = read_static(D + 'FAVSyringe.X')
    for i, tex in enumerate(['FAVSyringe_Empty', 'FAVSyringe_Dirty', 'FAVSyringe_Crude', 'FAVSyringe_Simple', 'FAVSyringe_Perfect']):
        M = np.eye(4); M[3, :3] = [0.035 * (i - 2), 0, 0]
        add_obj(tex, V, F, UV, tex, M)
    im = shot(sc, cam, (0.4, -0.6, 0.35), (0, 0, 0.005), 0.24, '/tmp/m1.png')
    ImageDraw.Draw(im).text((6, 4), 'FAVSyringe.X (hand) - empty, dirty, crude, simple, perfect', fill=(0, 0, 0)); tiles.append(im)
    # 2) world syringe + petri dishes
    sc, cam = setup()
    Vw, Fw, UVw = read_static(D + 'FAVSyringe_World.X')
    add_obj('w', Vw, Fw, UVw, 'FAVSyringe_Crude')
    Vp, Fp, UVp = read_static(D + 'FAVPetriDish.X')
    M = np.eye(4); M[3, :3] = [0.06, 0, -0.07]; add_obj('p1', Vp, Fp, UVp, 'FAVPetri_Cells', M)
    M = np.eye(4); M[3, :3] = [-0.06, 0, -0.07]; add_obj('p2', Vp, Fp, UVp, 'FAVPetri_Boiled', M)
    bpy.ops.mesh.primitive_plane_add(size=0.6)
    im = shot(sc, cam, (0.25, -0.45, 0.35), (0, 0.06, 0), 0.26, '/tmp/m2.png')
    ImageDraw.Draw(im).text((6, 4), 'On the ground: syringe (world), petri dish cells / boiled', fill=(0, 0, 0)); tiles.append(im)
    # 3) syringe in the hand at the moment of injection (real clip + skinned body)
    for t_s, label in ((1.5, 'inject 1.5s'), (0.45, 'inject 0.45s')):
        sc, cam = setup()
        x = XFile('out/Bob_FAV_Inject.X'); x.load_mesh()
        w = x.pose_world(t_s * x.ticks)
        body = bpy.data.meshes.new('b'); body.from_pydata(_to_blender(x.skin(w)).tolist(), [], x.mesh['faces'])
        bo = bpy.data.objects.new('b', body); sc.collection.objects.link(bo)
        add_obj('s', V, F, UV, 'FAVSyringe_Simple', w['Bip01_Prop1'])
        site = _to_blender(w['Bip01_L_UpperArm'][3, :3])
        im = shot(sc, cam, tuple(site + np.array([-0.35, 0.45, 0.12])), tuple(site + np.array([0, 0, -0.04])), 0.32, '/tmp/m3.png')
        ImageDraw.Draw(im).text((6, 4), label + ' (front-left close-up)', fill=(0, 0, 0)); tiles.append(im)

    W = max(t.width for t in tiles)
    sheet = Image.new('RGB', (W * 2, tiles[0].height * 2), 'white')
    for i, t in enumerate(tiles):
        sheet.paste(t, ((i % 2) * W, (i // 2) * t.height))
    sheet.save('out/models_check.png')
    print('ok')
