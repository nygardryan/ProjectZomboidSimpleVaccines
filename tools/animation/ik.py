"""Small FK/IK helpers on top of xanim for authoring PZ clips."""
import numpy as np
from scipy.optimize import minimize
from scipy.spatial.transform import Rotation as Rot


def world_from_locals(xf, locals_):
    out = {}
    for b in xf.bones:
        p = xf.parent[b]
        out[b] = locals_[b] if p is None else locals_[b] @ out[p]
    return out


def sample_locals(xf, t):
    return {b: xf.sample_local(b, t).copy() for b in xf.bones}


def apply_delta(local, rotvec):
    m = local.copy()
    m[:3, :3] = Rot.from_rotvec(rotvec).as_matrix() @ local[:3, :3]
    return m


def solve_chain(xf, locals_, chain, objective, weights=None, reg=0.02, x0=None):
    """Optimise rotation deltas on `chain` bones.

    objective(world) -> scalar error. weights: per-bone regularisation multipliers.
    Returns new locals dict (copy) and the final error.
    """
    weights = weights or {}
    n = len(chain)

    def build(x):
        loc = dict(locals_)
        for i, b in enumerate(chain):
            loc[b] = apply_delta(locals_[b], x[3 * i:3 * i + 3])
        return loc

    def f(x):
        w = world_from_locals(xf, build(x))
        r = sum(weights.get(b, 1.0) * np.dot(x[3 * i:3 * i + 3], x[3 * i:3 * i + 3]) for i, b in enumerate(chain))
        return objective(w) + reg * r

    res = minimize(f, np.zeros(3 * n) if x0 is None else x0, method='L-BFGS-B')
    loc = build(res.x)
    return loc, objective(world_from_locals(xf, loc)), res.x


def grip_relative(xf, t, prop, hand):
    w = xf.pose_world(t)
    return w[prop] @ np.linalg.inv(w[hand])


def set_prop_local(xf, locals_, prop, hand, rel):
    """Place a prop bone rigidly in the hand (props are children of Bip01, not the hand)."""
    w = world_from_locals(xf, locals_)
    want = rel @ w[hand]
    parent = xf.parent[prop]
    locals_[prop] = want @ np.linalg.inv(w[parent])
    return locals_


def blend_locals(a, b, t):
    """Per-bone blend of two local pose dicts (slerp rotations, lerp translations)."""
    from xanim import mat_to_quat, compose, slerp
    out = {}
    for k in a:
        ma, mb = a[k], b[k]
        sa = np.linalg.norm(ma[:3, :3], axis=1); sb = np.linalg.norm(mb[:3, :3], axis=1)
        qa = mat_to_quat(ma[:3, :3] / sa[:, None]); qb = mat_to_quat(mb[:3, :3] / sb[:, None])
        out[k] = compose(sa + (sb - sa) * t, slerp(qa, qb, t), ma[3, :3] + (mb[3, :3] - ma[3, :3]) * t)
    return out


def smoothstep(t):
    t = min(max(t, 0.0), 1.0)
    return t * t * (3 - 2 * t)
