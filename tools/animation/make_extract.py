"""Build Bob_FAV_ExtractDNA: kneel at a corpse and make careful cuts with a knife/scalpel (loops, 2.67 s)."""
import numpy as np
from xanim import XFile, write_anim
from ik import (sample_locals, world_from_locals, solve_chain, grip_relative,
                set_prop_local, blend_locals, smoothstep)

SRC = 'src/anims/'
base = XFile(SRC + 'Bob_IdleMakingLow.X'); base.load_mesh()
slice_ = XFile(SRC + 'Bob_IdleSlicingFood.X')
GRIP_R = grip_relative(slice_, 0, 'Bip01_Prop1', 'Bip01_R_Hand')
GRIP_L = grip_relative(base, 0, 'Bip01_Prop2', 'Bip01_L_Hand')
BLADE_TIP = 0.10
TPS = base.ticks
DUR = 4 * 3200 / 4800          # exactly 4 cycles of the kneel loop -> seamless

chain = ['Bip01_R_Clavicle', 'Bip01_R_UpperArm', 'Bip01_R_Forearm', 'Bip01_R_Hand']
regw = {'Bip01_R_Clavicle': 10.0, 'Bip01_R_UpperArm': 1.0, 'Bip01_R_Forearm': 1.0, 'Bip01_R_Hand': 0.6}


def tip_dir(w):
    p = GRIP_R @ w['Bip01_R_Hand']
    d = p[1, :3] / np.linalg.norm(p[1, :3])
    return p[3, :3] + BLADE_TIP * d, d


w0 = world_from_locals(base, sample_locals(base, 0))
lh = w0['Bip01_L_Hand'][3, :3]
# work spot: just right of the steadying left hand, at corpse height
spot = np.array([lh[0] - 0.09, 0.045, lh[2] - 0.05])
blade = np.array([0.15, -0.75, -0.55]); blade /= np.linalg.norm(blade)


def path(t):
    """Knife tip target + blend weight of the cutting pose over one loop."""
    # 0-0.35 move in, 0.35-2.2 three cuts (cut, lift, carry back), 2.2-end lift & return
    if t < 0.35:
        return None, smoothstep(t / 0.35)
    if t > 2.2:
        return None, 1 - smoothstep((t - 2.2) / (DUR - 2.2))
    u = (t - 0.35) / 1.85 * 3                     # stroke phase 0..3
    n = min(np.floor(u), 2); k = u - n
    if k < 0.65:                                  # cut: draw the blade toward the body, pressing down
        c = smoothstep(k / 0.65)
        off = np.array([0.0, -0.004 * np.sin(np.pi * c), 0.06 * (c - 0.5)])
    else:                                         # lift ~2 cm and carry the blade back for the next cut
        r = smoothstep((k - 0.65) / 0.35)
        off = np.array([0.0, 0.02 * np.sin(np.pi * r), 0.06 * (0.5 - r)])
    off[0] += 0.015 * (n - 1) + 0.015 * (k >= 0.65) * smoothstep((k - 0.65) / 0.35) * (n < 2)
    return spot + off, 1.0


frames = []
prev_x = None
cut_cache = {}
for t in np.arange(0, DUR + 1e-6, 1 / 30):
    loop_t = (t * TPS) % base.duration
    loc = sample_locals(base, loop_t)
    goal, wgt = path(t)
    if goal is None:                              # entering / leaving: aim at the first / last stroke point
        goal = spot + np.array([-0.015 if t < 1 else 0.015, 0.0, -0.03])   # first cut start / last carry-back end
    def obj(w, goal=goal):
        tip, d = tip_dir(w)
        return 5000 * np.sum((tip - goal) ** 2) + 1.5 * (1 - np.dot(d, blade))
    cut, err, prev_x = solve_chain(base, loc, chain, obj, weights=regw, reg=0.004, x0=prev_x)
    if wgt < 1:
        cut = blend_locals(loc, cut, wgt)
    # head watches the work
    def look(w):
        z = w['Bip01_Head'][2, :3]; z = z / np.linalg.norm(z)
        to = spot - w['Bip01_Head'][3, :3]; to /= np.linalg.norm(to)
        return 2.0 * (1 - np.dot(z, to))
    cut, _, _ = solve_chain(base, cut, ['Bip01_Neck', 'Bip01_Head'], look,
                            weights={'Bip01_Neck': 2.5, 'Bip01_Head': 1.0}, reg=2.0)
    set_prop_local(base, cut, 'Bip01_Prop1', 'Bip01_R_Hand', GRIP_R)
    set_prop_local(base, cut, 'Bip01_Prop2', 'Bip01_L_Hand', GRIP_L)
    frames.append((t * TPS, cut))

out = 'out/Bob_FAV_ExtractDNA.X'
write_anim(base, out, 'Bob_FAV_ExtractDNA', frames)
print('wrote', out, len(frames), 'frames; spot', spot.round(3))
