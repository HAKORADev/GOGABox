#!/usr/bin/env python3
"""v03911_dessert_bake.py - THE DESSERT SHELF (fruit slasher, third skin).

The owner asked for the Cake Slice Ninja desserts (gamesnacks) as the
slasher's third produce skin, assets + VFX "with some color and size
modifications ofc so they could get in" (docs/DECOMPILATION.md, THE
USAGE LAW: study copies stay outside the repo; crafted assets get
modified/redesigned before they enter GOGABox; provenance recorded).

The studied build is a PlayCanvas 3D game: every dessert is a real mesh
(whole + pre-cut L/R halves) with a small diffuse texture. This tool
BAKES those meshes into flat 2D sprites with a tiny software renderer:

  - parse the model JSON (node transforms, positions, uvs, indices)
  - orthographic projection from the front, painter's sort
  - per-triangle affine texture mapping (numpy, supersampled 2x)
  - a soft lambert light so the sprite reads at game size
  - THE MODIFICATIONS: one consistent 240px content box (the slasher's
    scale law), a gentle saturation lift to match the box's fruity
    palette, and a clean alpha trim

Outputs: assets/games/slasher/dessert_<name>.png (+ _h1/_h2 halves).
Re-derive: python3 tools/v03911_dessert_bake.py <study_dir> <out_dir>
"""
import json
import math
import sys
import pathlib
import numpy as np
from PIL import Image, ImageEnhance

CANVAS = 256
SS = 2                       # supersample
CONTENT = 236                # the content box inside the canvas (the
                             # slasher draws fruits at ~118-124 logical
                             # px from a 256 canvas - same family)


# ----------------------------------------------------------- the math
def rot_x(a):
    a = math.radians(a)
    return np.array([[1, 0, 0], [0, math.cos(a), -math.sin(a)],
                     [0, math.sin(a), math.cos(a)]])


def rot_y(a):
    a = math.radians(a)
    return np.array([[math.cos(a), 0, math.sin(a)], [0, 1, 0],
                     [-math.sin(a), 0, math.cos(a)]])


def rot_z(a):
    a = math.radians(a)
    return np.array([[math.cos(a), -math.sin(a), 0],
                     [math.sin(a), math.cos(a), 0], [0, 0, 1]])


def node_matrix(n):
    """PlayCanvas local matrix: T * R(z*y*x) * S."""
    p = n.get("position", [0, 0, 0])
    r = n.get("rotation", [0, 0, 0])
    s = n.get("scale", [1, 1, 1])
    R = rot_z(r[2]) @ rot_y(r[1]) @ rot_x(r[0])
    M = np.eye(4)
    M[:3, :3] = R @ np.diag(s)
    M[:3, 3] = p
    return M


def world_matrices(model):
    nodes = model["nodes"]
    parents = model.get("parents", list(range(len(nodes))))
    mats = [None] * len(nodes)
    for i, n in enumerate(nodes):
        local = node_matrix(n)
        pi = parents[i] if i < len(parents) else -1
        if pi is not None and 0 <= int(pi) < len(nodes) and int(pi) != i \
                and mats[int(pi)] is not None:
            mats[i] = mats[int(pi)] @ local
        else:
            mats[i] = local
    return mats


def load_streams(model, vi):
    vs = model["vertices"][vi]
    pd = vs["position"]["data"]
    ud = vs["texCoord0"]["data"]
    pos = np.array(json.loads(pd) if isinstance(pd, str) else pd,
                   dtype=np.float64).reshape(-1, 3)
    uv = np.array(json.loads(ud) if isinstance(ud, str) else ud,
                  dtype=np.float64).reshape(-1, 2)
    return pos, uv


def render_model(model, tex_img, out_size=CANVAS, light=None,
                 tilt=0.0):
    """Render every meshInstance -> RGBA numpy (supersampled)."""
    mats = world_matrices(model)
    tris = []       # (a, b, c screen 2d, depth, tex 2d x3, shade)
    pos_all = []
    for mi in model.get("meshInstances", []):
        ni = int(mi["node"])
        mesh = model["meshes"][int(mi["mesh"])]
        vi = int(mesh.get("vertices", 0))
        pos, uv = load_streams(model, vi)
        wpos = (mats[ni][:3, :3] @ pos.T).T + mats[ni][:3, 3]
        pos_all.append(wpos)
    if not pos_all:
        return None
    P = np.vstack(pos_all)
    if tilt != 0.0:
        # THE 3/4 VIEW: tip the model toward the camera so flat bakes
        # (donut, cookie) show their face - the studied game shows its
        # desserts the same way
        Rv = rot_x(-tilt)
        P = (Rv @ P.T).T
    lo, hi = P.min(axis=0), P.max(axis=0)
    center = (lo + hi) / 2.0
    vcenter = center
    span = max(hi[0] - lo[0], hi[1] - lo[1], 1e-6)
    scale = (out_size * SS * 0.92) / span
    W = out_size * SS
    if light is None:
        light = np.array([-0.38, 0.5, 0.82])
    light = light / np.linalg.norm(light)
    tex = np.asarray(tex_img.convert("RGB"), dtype=np.float64)
    TH, TW = tex.shape[0], tex.shape[1]
    order_z = []
    verts2 = []
    uvs2 = []
    shades = []
    tris_idx = []
    for mi in model.get("meshInstances", []):
        ni = int(mi["node"])
        mesh = model["meshes"][int(mi["mesh"])]
        vi = int(mesh.get("vertices", 0))
        pos, uv = load_streams(model, vi)
        wpos = (mats[ni][:3, :3] @ pos.T).T + mats[ni][:3, 3]
        # normals from the stream if present, else per-face
        wnrm = np.zeros_like(wpos)
        try:
            nd = model["vertices"][vi]["normal"]["data"]
            nrm = np.array(json.loads(nd) if isinstance(nd, str) else nd,
                dtype=np.float64).reshape(-1, 3)
            wnrm = (mats[ni][:3, :3] @ nrm.T).T
        except Exception:
            pass
        vw = (Rv @ wpos.T).T if tilt != 0.0 else wpos
        wn = (Rv @ wnrm.T).T if tilt != 0.0 else wnrm
        wpos2 = vw - vcenter
        sx = (wpos2[:, 0] * scale + W / 2.0)
        sy = (-wpos2[:, 1] * scale + W / 2.0)
        depth = wpos2[:, 2]
        idx = np.array(mesh["indices"][mesh.get("base", 0):
                                       mesh.get("base", 0)
                                       + mesh["count"]])
        for t in idx.reshape(-1, 3):
            a, b, c = int(t[0]), int(t[1]), int(t[2])
            n = np.cross(vw[b] - vw[a], vw[c] - vw[a])
            ln = np.linalg.norm(n)
            if ln < 1e-9:
                continue
            n = n / ln
            nn = (Rv @ n) if tilt != 0.0 else n
            # two-sided: light the face that looks at the camera
            if nn[2] < 0:
                nn = -nn
            lam = max(0.0, float(nn @ light))
            shade = 0.52 + 0.48 * lam
            tris_idx.append((a, b, c))
            order_z.append((depth[a] + depth[b] + depth[c]) / 3.0)
            verts2.append(((sx[a], sy[a]), (sx[b], sy[b]),
                           (sx[c], sy[c])))
            uvs2.append(((uv[a][0] * TW, (1.0 - uv[a][1]) * TH),
                         (uv[b][0] * TW, (1.0 - uv[b][1]) * TH),
                         (uv[c][0] * TW, (1.0 - uv[c][1]) * TH)))
            shades.append(shade)
    if not tris_idx:
        return None
    # painter's sort: far (small z) first
    order = np.argsort(np.array(order_z))
    img = np.zeros((W, W, 4), dtype=np.float64)
    for oi in order:
        (a, b, c) = tris_idx[oi]
        p0 = np.array(verts2[oi][0]); p1 = np.array(verts2[oi][1])
        p2 = np.array(verts2[oi][2])
        t0 = np.array(uvs2[oi][0]); t1 = np.array(uvs2[oi][1])
        t2 = np.array(uvs2[oi][2])
        sh = shades[oi]
        xmin = max(0, int(min(p0[0], p1[0], p2[0])))
        xmax = min(W - 1, int(max(p0[0], p1[0], p2[0])) + 1)
        ymin = max(0, int(min(p0[1], p1[1], p2[1])))
        ymax = min(W - 1, int(max(p0[1], p1[1], p2[1])) + 1)
        if xmax <= xmin or ymax <= ymin:
            continue
        xs, ys = np.meshgrid(np.arange(xmin, xmax) + 0.5,
                             np.arange(ymin, ymax) + 0.5)
        det = (p1[1] - p2[1]) * (p0[0] - p2[0]) \
            + (p2[0] - p1[0]) * (p0[1] - p2[1])
        if abs(det) < 1e-9:
            continue
        w0 = ((p1[1] - p2[1]) * (xs - p2[0])
              + (p2[0] - p1[0]) * (ys - p2[1])) / det
        w1 = ((p2[1] - p0[1]) * (xs - p2[0])
              + (p0[0] - p2[0]) * (ys - p2[1])) / det
        w2 = 1.0 - w0 - w1
        inside = (w0 >= -0.001) & (w1 >= -0.001) & (w2 >= -0.001)
        if not inside.any():
            continue
        tu = (w0 * t0[0] + w1 * t1[0] + w2 * t2[0])
        tv = (w0 * t0[1] + w1 * t1[1] + w2 * t2[1])
        tu = np.clip(tu.astype(int), 0, TW - 1)
        tv = np.clip(tv.astype(int), 0, TH - 1)
        col = tex[tv, tu] * sh
        region = img[ymin:ymax, xmin:xmax]
        m = inside
        for ch in range(3):
            region[..., ch][m] = col[..., ch][m]
        region[..., 3][m] = 255.0
    return img


def bake(model_path, tex_path, out_path, tilt=0.0):
    model = json.load(open(model_path))["model"]
    tex = Image.open(tex_path)
    img = render_model(model, tex, CANVAS, tilt=tilt)
    if img is None:
        print("  !! no triangles:", model_path)
        return False
    a = Image.fromarray(img.astype(np.uint8), "RGBA")
    a = a.resize((CANVAS, CANVAS), Image.LANCZOS)
    # the alpha: supersampled coverage (0 -> transparent)
    alpha = np.asarray(a).copy()
    alpha[..., 3] = np.clip(alpha[..., 3], 0, 255)
    im = Image.fromarray(alpha, "RGBA")
    # THE MODIFICATIONS: a gentle saturation lift (the box's palette)
    rgb = im.convert("RGB")
    rgb = ImageEnhance.Color(rgb).enhance(1.14)
    rgb = ImageEnhance.Contrast(rgb).enhance(1.04)
    im = Image.merge("RGBA", (*rgb.split(), im.split()[3]))
    # trim + fit the content box, square canvas
    bbox = im.getchannel("A").getbbox()
    if bbox:
        im = im.crop(bbox)
    side = max(im.size)
    k = CONTENT / float(side)
    im = im.resize((max(1, int(im.size[0] * k)),
                    max(1, int(im.size[1] * k))), Image.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(im, ((CANVAS - im.size[0]) // 2,
                      (CANVAS - im.size[1]) // 2), im)
    canvas.save(out_path)
    print("  baked", out_path.name, im.size)
    return True


DESSERTS = [
    # (slug, whole model, whole tex, half1, half2, tex, view tilt deg)
    ("cake", "Cake.json", "Cake.jpg", "Cake-L.json", "Cake-R.json", 14.0),
    ("cupcake", "Cupcake.json", "cupcake.jpg", "Cupcake-L.json",
     "Cupcake-R.json", 26.0),
    ("donut", "Donut.json", "Donut.jpg", "Donut-L.json", "Donut-R.json",
     62.0),
    ("macaron", "Macaron.json", "Macaron_BaseColor.jpg", "Macaron-L.json",
     "Macaron-R.json", 58.0),
    ("cakeroll", "Cakeroll.json", "CakeRoll_BaseColor.jpg",
     "Cakeroll-L.json", "Cakeroll-R.json", 18.0),
    ("cookie", "cookies-full.json", "cookies.jpg", "cookies-l.json",
     "cookies-r.json", 62.0),
]


def main():
    study = pathlib.Path(sys.argv[1])
    out = pathlib.Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    base = study / "v" / "5bh2c88k8pku8" / "files" / "assets"
    def find(name):
        hits = list(base.rglob(name))
        if not hits:
            hits = list(study.rglob(name))
        return hits[0]
    for slug, wm, wt, m1, m2, tilt in DESSERTS:
        print(slug, "tilt", tilt)
        bake(find(wm), find(wt), out / f"dessert_{slug}.png", tilt)
        bake(find(m1), find(wt), out / f"dessert_{slug}_h1.png", tilt)
        bake(find(m2), find(wt), out / f"dessert_{slug}_h2.png", tilt)


if __name__ == "__main__":
    main()
