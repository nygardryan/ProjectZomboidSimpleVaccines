"""Minimal DirectX .X (text) reader/writer for Project Zomboid character animations.

Reads the Frame hierarchy (bind pose), the skinned Body mesh, and AnimationSet keys.
Writes a new AnimationSet back into a copy of a source file so the output has exactly
the structure the game already loads.

Conventions (DirectX): row vectors, M = S * R * T, world = local * parentWorld.
"""
import re
import numpy as np

_num = re.compile(r'-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?')


def _block_end(text, start):
    """Index just past the matching '}' for the '{' at or after start."""
    i = text.index('{', start)
    depth = 0
    while True:
        c = text[i]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1


def quat_to_mat(q):
    """.X key quaternion (w,x,y,z) -> 3x3 rotation for row vectors (v @ R).
    Verified against the game's files: key 0 reproduces FrameTransformMatrix."""
    w, x, y, z = q
    return np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - w * z), 2 * (x * z + w * y)],
        [2 * (x * y + w * z), 1 - 2 * (x * x + z * z), 2 * (y * z - w * x)],
        [2 * (x * z - w * y), 2 * (y * z + w * x), 1 - 2 * (x * x + y * y)],
    ])


def _unused_quat_to_mat_rowconj(q):
    w, x, y, z = q
    return np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y + w * z), 2 * (x * z - w * y)],
        [2 * (x * y - w * z), 1 - 2 * (x * x + z * z), 2 * (y * z + w * x)],
        [2 * (x * z + w * y), 2 * (y * z - w * x), 1 - 2 * (x * x + y * y)],
    ])


def mat_to_quat(m):
    """Inverse of quat_to_mat."""
    c = m
    t = np.trace(c)
    if t > 0:
        s = np.sqrt(t + 1.0) * 2
        w = 0.25 * s
        x = (c[2, 1] - c[1, 2]) / s
        y = (c[0, 2] - c[2, 0]) / s
        z = (c[1, 0] - c[0, 1]) / s
    elif c[0, 0] > c[1, 1] and c[0, 0] > c[2, 2]:
        s = np.sqrt(1.0 + c[0, 0] - c[1, 1] - c[2, 2]) * 2
        w = (c[2, 1] - c[1, 2]) / s
        x = 0.25 * s
        y = (c[0, 1] + c[1, 0]) / s
        z = (c[0, 2] + c[2, 0]) / s
    elif c[1, 1] > c[2, 2]:
        s = np.sqrt(1.0 + c[1, 1] - c[0, 0] - c[2, 2]) * 2
        w = (c[0, 2] - c[2, 0]) / s
        x = (c[0, 1] + c[1, 0]) / s
        y = 0.25 * s
        z = (c[1, 2] + c[2, 1]) / s
    else:
        s = np.sqrt(1.0 + c[2, 2] - c[0, 0] - c[1, 1]) * 2
        w = (c[1, 0] - c[0, 1]) / s
        x = (c[0, 2] + c[2, 0]) / s
        y = (c[1, 2] + c[2, 1]) / s
        z = 0.25 * s
    q = np.array([w, x, y, z])
    return q / np.linalg.norm(q)


def compose(scale, quat, trans):
    m = np.eye(4)
    m[:3, :3] = np.diag(scale) @ quat_to_mat(quat)
    m[3, :3] = trans
    return m


def slerp(q0, q1, t):
    q0 = np.asarray(q0, float); q1 = np.asarray(q1, float)
    d = float(np.dot(q0, q1))
    if d < 0:
        q1 = -q1; d = -d
    if d > 0.9995:
        q = q0 + t * (q1 - q0)
        return q / np.linalg.norm(q)
    th = np.arccos(d)
    return (np.sin((1 - t) * th) * q0 + np.sin(t * th) * q1) / np.sin(th)


class XFile:
    def __init__(self, path):
        self.path = path
        self.text = open(path, encoding='latin-1').read().replace('\r', '')
        self._parse_frames()
        self._parse_anim()
        self.mesh = None

    # ---------- skeleton ----------
    def _parse_frames(self):
        t = self.text
        self.bones = []          # names in file order
        self.parent = {}
        self.rest = {}           # local 4x4
        pos = 0
        stack = []               # (name, end_index)
        for m in re.finditer(r'\bFrame\s+(\w+)\s*\{', t):
            if t.rfind('template', max(0, m.start() - 20), m.start()) != -1:
                continue
            name = m.group(1)
            if name in ('Body',):
                continue
            start = m.start()
            while stack and start > stack[-1][1]:
                stack.pop()
            end = _block_end(t, m.end() - 1)
            mm = re.search(r'FrameTransformMatrix\s*\{([^}]*)\}', t[m.end():end])
            vals = [float(v) for v in _num.findall(mm.group(1))][:16]
            self.rest[name] = np.array(vals).reshape(4, 4)
            self.parent[name] = stack[-1][0] if stack else None
            self.bones.append(name)
            stack.append((name, end))

    def rest_world(self):
        out = {}
        for b in self.bones:
            p = self.parent[b]
            out[b] = self.rest[b] if p is None else self.rest[b] @ out[p]
        return out

    # ---------- animation ----------
    def _parse_anim(self):
        t = self.text
        m = re.search(r'AnimTicksPerSecond\s*\{\s*(\d+)', t)
        self.ticks = int(m.group(1)) if m else 4800
        m = re.search(r'AnimationSet\s+(\w+)\s*\{', t)
        self.anim_name = m.group(1)
        self.anim_start = m.start()
        self.anim_end = _block_end(t, m.end() - 1)
        body = t[m.end():self.anim_end - 1]
        self.keys = {}   # bone -> {'R': [(time, q)], 'S': [...], 'T': [...]}
        for am in re.finditer(r'Animation\s*\{\s*\{\s*(\w+)\s*\}', body):
            bone = am.group(1)
            end = _block_end(body, am.start() + body[am.start():].index('{'))
            chunk = body[am.end():end]
            entry = {}
            for km in re.finditer(r'AnimationKey\s+(\w+)\s*\{([^}]*)\}', chunk):
                nums = _num.findall(km.group(2))
                ktype = int(nums[0]); n = int(nums[1])
                vals = nums[2:]
                width = {0: 4, 1: 3, 2: 3, 4: 16}[ktype]
                seq = []
                i = 0
                for _ in range(n):
                    time = int(float(vals[i])); cnt = int(vals[i + 1])
                    v = np.array([float(x) for x in vals[i + 2:i + 2 + cnt]])
                    seq.append((time, v))
                    i += 2 + cnt
                entry[{0: 'R', 1: 'S', 2: 'T', 4: 'M'}[ktype]] = seq
            self.keys[bone] = entry
        self.duration = max(s[-1][0] for e in self.keys.values() for s in e.values())

    def sample_local(self, bone, time):
        """Local 4x4 at time (ticks); falls back to rest pose for unanimated bones."""
        e = self.keys.get(bone)
        if not e:
            return self.rest[bone]
        def interp(seq, lerp):
            if time <= seq[0][0]:
                return seq[0][1]
            if time >= seq[-1][0]:
                return seq[-1][1]
            for (t0, v0), (t1, v1) in zip(seq, seq[1:]):
                if t0 <= time <= t1:
                    a = (time - t0) / max(1, (t1 - t0))
                    return lerp(v0, v1, a)
        s = interp(e['S'], lambda a, b, x: a + (b - a) * x) if 'S' in e else np.ones(3)
        q = interp(e['R'], slerp) if 'R' in e else mat_to_quat(self.rest[bone][:3, :3])
        tr = interp(e['T'], lambda a, b, x: a + (b - a) * x) if 'T' in e else self.rest[bone][3, :3]
        return compose(s, q, tr)

    def pose_world(self, time, local_override=None):
        out = {}
        for b in self.bones:
            loc = (local_override or {}).get(b)
            if loc is None:
                loc = self.sample_local(b, time)
            p = self.parent[b]
            out[b] = loc if p is None else loc @ out[p]
        return out

    # ---------- mesh (for previews) ----------
    def load_mesh(self):
        t = self.text
        m = re.search(r'\bMesh\s+(\w+)\s*\{', t)
        end = _block_end(t, m.end() - 1)
        body = t[m.end():end]
        nums = _num.findall(body[:body.index('MeshNormals') if 'MeshNormals' in body else len(body)])
        nv = int(nums[0])
        verts = np.array([float(x) for x in nums[1:1 + nv * 3]]).reshape(nv, 3)
        k = 1 + nv * 3
        nf = int(nums[k]); k += 1
        faces = []
        for _ in range(nf):
            c = int(nums[k]); faces.append([int(x) for x in nums[k + 1:k + 1 + c]]); k += 1 + c
        weights = []  # (bone, idx array, w array, offset 4x4)
        for sm in re.finditer(r'SkinWeights\s*\{\s*"(\w+)";([^}]*)\}', body):
            vals = _num.findall(sm.group(2))
            n = int(vals[0])
            idx = np.array([int(v) for v in vals[1:1 + n]], dtype=int)
            w = np.array([float(v) for v in vals[1 + n:1 + 2 * n]])
            off = np.array([float(v) for v in vals[1 + 2 * n:1 + 2 * n + 16]]).reshape(4, 4)
            weights.append((sm.group(1), idx, w, off))
        self.mesh = dict(verts=verts, faces=faces, weights=weights)
        return self.mesh

    def skin(self, world):
        """Linear blend skinning of the Body mesh for a world pose (row-vector convention)."""
        me = self.mesh or self.load_mesh()
        v = np.hstack([me['verts'], np.ones((len(me['verts']), 1))])
        out = np.zeros((len(v), 3)); tot = np.zeros(len(v))
        for bone, idx, w, off in me['weights']:
            if bone not in world:
                continue
            m = off @ world[bone]
            out[idx] += (v[idx] @ m)[:, :3] * w[:, None]
            tot[idx] += w
        tot[tot == 0] = 1
        return out / tot[:, None]


def write_anim(src, out_path, name, frames, ticks_per_sec=None):
    """Write a copy of src.X whose AnimationSet is replaced.

    frames: list of (time_ticks, {bone: local 4x4}) covering every animated bone.
    """
    tps = ticks_per_sec or src.ticks
    lines = [f'AnimationSet {name} {{', ' ']
    for bone in src.bones:
        Rk, Sk, Tk = [], [], []
        prev = None
        for time, locs in frames:
            m = locs[bone]
            sc = np.linalg.norm(m[:3, :3], axis=1)
            q = mat_to_quat(m[:3, :3] / sc[:, None])
            sc = np.where(np.abs(sc - 1) < 1e-4, 1.0, sc)     # snap float noise
            if prev is not None and np.dot(prev, q) < 0:
                q = -q          # keep hemisphere continuous for clean interpolation
            prev = q
            Rk.append((time, q)); Sk.append((time, sc)); Tk.append((time, m[3, :3]))
        def key(kind, seq):
            body = [f'  AnimationKey {kind} {{', f'   {{"S":1,"R":0,"T":2}}[kind];'.replace('{"S":1,"R":0,"T":2}[kind]', str({"S": 1, "R": 0, "T": 2}[kind])), f'   {len(seq)};']
            for i, (time, v) in enumerate(seq):
                term = ';;;' if i == len(seq) - 1 else ';;,'
                body.append(f'   {int(round(time))};{len(v)};' + ','.join(f'{x:.6f}' for x in v) + term)
            body.append('  }')
            return body
        lines += ['', ' Animation {', '  ', f'  {{ {bone} }}', '']
        lines += key('S', Sk) + [''] + key('R', Rk) + [''] + key('T', Tk)
        lines += [' }']
    lines += ['}']
    t = src.text
    # keep everything before the AnimationSet, set ticks, replace the set
    head = re.sub(r'(AnimTicksPerSecond\s*\{\s*)\d+', lambda m: m.group(1) + str(tps), t[:src.anim_start])
    out = head + '\n'.join(lines) + t[src.anim_end:]
    with open(out_path, 'w', encoding='latin-1', newline='\r\n') as f:
        f.write(out)
