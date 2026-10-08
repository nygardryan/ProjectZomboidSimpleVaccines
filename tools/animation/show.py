"""Render a clip file with the hand prop drawn as a syringe (barrel + needle)."""
import sys, numpy as np
from xanim import XFile
from preview import render_sheet
path, out, n = sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 6
prop = sys.argv[4] if len(sys.argv) > 4 else 'Bip01_Prop1'
x = XFile(path); x.load_mesh()
def syringe(w):
    M = w[prop]; d = M[1, :3] / np.linalg.norm(M[1, :3]); o = M[3, :3]
    pts = [(o + s * d, (0.95, 0.95, 1.0), 0.009) for s in np.linspace(-0.04, 0.035, 7)]
    pts += [(o + s * d, (0.15, 0.15, 0.15), 0.003) for s in np.linspace(0.04, 0.075, 6)]
    return pts
ts = np.linspace(0, x.duration, n)
render_sheet(x, [(f'{t/x.ticks:.2f}s', x.pose_world(t)) for t in ts], out, extra=syringe,
             views=(('front-left', 225), ('left side', 270)), title=f'{x.anim_name} ({x.duration/x.ticks:.2f}s) - syringe drawn at {prop}')
