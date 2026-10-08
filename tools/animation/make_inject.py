"""Build Bob_FAV_Inject: right hand injects a syringe into the left upper arm (~3 s)."""
import numpy as np
from xanim import XFile, write_anim
from ik import (sample_locals, world_from_locals, solve_chain, grip_relative,
                set_prop_local, blend_locals, smoothstep)

SRC = 'src/anims/'
base = XFile(SRC + 'Bob_IdleTakePills.X'); base.load_mesh()
slice_ = XFile(SRC + 'Bob_IdleSlicingFood.X')
band = XFile(SRC + 'Bob_BandageLeftArm.X')

# Syringe geometry in prop space (+Y = needle direction, origin = grip)
NEEDLE_TIP = 0.075
GRIP_R = grip_relative(slice_, 0, 'Bip01_Prop1', 'Bip01_R_Hand')     # knife-style grip
GRIP_L = grip_relative(base, 0, 'Bip01_Prop2', 'Bip01_L_Hand')       # resting left prop

idle = sample_locals(base, 0)


def place_props(loc):
    set_prop_local(base, loc, 'Bip01_Prop1', 'Bip01_R_Hand', GRIP_R)
    set_prop_local(base, loc, 'Bip01_Prop2', 'Bip01_L_Hand', GRIP_L)
    return loc


def tip_and_dir(w):
    prop = GRIP_R @ w['Bip01_R_Hand']
    d = prop[1, :3] / np.linalg.norm(prop[1, :3])
    return prop[3, :3] + NEEDLE_TIP * d, d


# 1) Left arm: lift slightly away from the body so the deltoid is exposed.
w0 = world_from_locals(base, idle)
elbow0 = w0['Bip01_L_Forearm'][3, :3]
elbow_goal = elbow0 + np.array([0.035, 0.01, -0.02])
left_pose, err, _ = solve_chain(
    base, idle, ['Bip01_L_UpperArm', 'Bip01_L_Forearm'],
    lambda w: 2000 * np.sum((w['Bip01_L_Forearm'][3, :3] - elbow_goal) ** 2)
    + 2000 * np.sum((w['Bip01_L_Hand'][3, :3] - (w0['Bip01_L_Hand'][3, :3] + np.array([0.05, 0.03, -0.03]))) ** 2),
    reg=0.01)
print('left arm err', err)

# 2) Injection site on the left deltoid from the skinned mesh.
wl = world_from_locals(base, left_pose)
verts = base.skin(wl)
sh = wl['Bip01_L_UpperArm'][3, :3]; el = wl['Bip01_L_Forearm'][3, :3]
axis = (el - sh) / np.linalg.norm(el - sh)
lat = np.array([1.0, 0.0, -0.6])                     # outer side of the arm, a little to the front
normal = lat - np.dot(lat, axis) * axis; normal /= np.linalg.norm(normal)
centre = sh + axis * 0.035
# arm surface: furthest skinned vertex along `normal` near that height
near = verts[np.abs((verts - centre) @ axis) < 0.02]
r = max(0.022, float(np.max((near - centre) @ normal))) if len(near) else 0.028
site = centre + normal * r
print('site', site.round(3), 'normal', normal.round(2))

# 3) Right arm poses: approach (needle 3.5 cm off the skin) and inserted.
band_mid = sample_locals(band, band.duration * 0.4)
start = dict(left_pose)
for b in ['Bip01_R_Clavicle', 'Bip01_R_UpperArm', 'Bip01_R_Forearm', 'Bip01_R_Hand']:
    start[b] = band_mid[b]
chain = ['Bip01_R_Clavicle', 'Bip01_R_UpperArm', 'Bip01_R_Forearm', 'Bip01_R_Hand']
regw = {'Bip01_R_Clavicle': 8.0, 'Bip01_R_UpperArm': 1.0, 'Bip01_R_Forearm': 1.0, 'Bip01_R_Hand': 0.5}
needle_dir = -normal + np.array([0.0, -0.25, 0.0]); needle_dir /= np.linalg.norm(needle_dir)


def reach(loc0, tip_goal, x0=None):
    def obj(w):
        tip, d = tip_and_dir(w)
        return 4000 * np.sum((tip - tip_goal) ** 2) + 2.0 * (1 - np.dot(d, needle_dir))
    return solve_chain(base, loc0, chain, obj, weights=regw, reg=0.004, x0=x0)


approach, e1, xa = reach(start, site - needle_dir * 0.035)
_w = world_from_locals(base, left_pose)
chest = _w['Bip01_Spine1'][3, :3] + np.array([0.02, 0.0, -0.17])     # in front of the chest
def reach_mid(loc0):
    def obj(w):
        tip, d = tip_and_dir(w)
        up = np.array([0.35, 0.75, 0.2]); up /= np.linalg.norm(up)
        return 3000 * np.sum((tip - chest) ** 2) + 1.0 * (1 - np.dot(d, up))
    return solve_chain(base, loc0, chain, obj, weights=regw, reg=0.006)
mid, em, _ = reach_mid(dict(left_pose))
print('mid err', em)
inserted, e2, xi = reach(start, site + needle_dir * 0.010, x0=xa)
pressed, e3, _ = reach(start, site + needle_dir * 0.013, x0=xi)
print('ik errors', e1, e2, e3)
for p in (approach, inserted, pressed):
    tip, d = tip_and_dir(world_from_locals(base, p))

# 4) Head looks at the injection site.
def look(loc):
    def obj(w):
        z = w['Bip01_Head'][2, :3]; z = z / np.linalg.norm(z)
        to = site - w['Bip01_Head'][3, :3]; to /= np.linalg.norm(to)
        return 3.0 * (1 - np.dot(z, to))
    out, _, _ = solve_chain(base, loc, ['Bip01_Neck', 'Bip01_Head'], obj,
                            weights={'Bip01_Neck': 2.5, 'Bip01_Head': 1.0}, reg=2.2)
    return out

approach_l, inserted_l, pressed_l = look(approach), look(inserted), look(pressed)
mid_l = place_props(look(mid))
idle_l = place_props(dict(idle))
for p in (approach_l, inserted_l, pressed_l):
    place_props(p)
left_l = place_props(dict(left_pose))

# 5) Timeline (seconds) -> keyed every 1/30 s.
segments = [
    (0.00, 0.45, idle_l, mid_l),
    (0.45, 0.90, mid_l, approach_l),
    (0.90, 1.15, approach_l, inserted_l),
    (1.15, 1.85, inserted_l, pressed_l),
    (1.85, 2.10, pressed_l, approach_l),
    (2.10, 2.55, approach_l, mid_l),
    (2.55, 3.00, mid_l, idle_l),
]
TPS = base.ticks
frames = []
for t in np.arange(0, 3.0 + 1e-6, 1 / 30):
    for a, b, pa, pb in segments:
        if a <= t <= b:
            s = smoothstep((t - a) / (b - a))
            loc = blend_locals(pa, pb, s)
            break
    place_props(loc)
    frames.append((t * TPS, loc))

out = 'out/Bob_FAV_Inject.X'
write_anim(base, out, 'Bob_FAV_Inject', frames)
print('wrote', out, len(frames), 'frames')
