#!/usr/bin/env python3
# Painted-figure renderer for Düşüş: Choralim Protocol.
# Builds ORIGINAL sprites in the grimdark concept style — no sheet crops.
# Articulated skeleton -> layered shapes -> painterly shading (rim light,
# AO gradient, edge dark, noise) -> supersampled downscale.

import os, math, json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "art")
os.makedirs(ART, exist_ok=True)

SS = 4  # supersample
rng = np.random.default_rng(7)


def hx(c):
    c = c.lstrip('#')
    return tuple(int(c[i:i+2], 16) for i in (0, 2, 4))


def rgba(c, a=255):
    return (c[0], c[1], c[2], a)


def sh(c, f):
    return (min(255, int(c[0]*f)), min(255, int(c[1]*f)), min(255, int(c[2]*f)))


def mix(a, b, t):
    return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))


# ---------------------------------------------------------------- canvas
class Fig:
    """Normalized-space figure: feet at y=0, head ~y=1. Canvas maps to px.
    Two draw modes: flat detail primitives (disc/line/poly/seg) and
    mask-shaded volume primitives (tube/blob/plate/cloth) that render
    painterly light — the difference between a sticker and a model."""

    LIGHT = (-0.52, -0.72)   # direction TOWARD the light source (top-left)

    def __init__(self, height_px, width_px=None, ss=SS):
        self.h = height_px
        self.w = width_px or int(height_px * 0.95)
        self.ss = ss
        self.img = Image.new("RGBA", (self.w*ss, self.h*ss), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)
        self.margin = 0.06  # top/bottom margin fraction
        self.rng = np.random.default_rng(int(rng.integers(1 << 30)))

    def xy(self, p):
        x, y = p
        return (self.w*self.ss*0.5 + x*self.h*self.ss,
                self.h*self.ss*(1.0 - self.margin) - y*self.h*self.ss)

    def r(self, v):
        return v * self.h * self.ss

    # ---- flat primitives (details: glows, eyes, seams, studs)
    def seg(self, p0, p1, w0, w1, col, a=255):
        x0, y0 = self.xy(p0); x1, y1 = self.xy(p1)
        w0, w1 = self.r(w0), self.r(w1)
        dx, dy = x1-x0, y1-y0
        L = math.hypot(dx, dy) or 1.0
        nx, ny = -dy/L, dx/L
        poly = [(x0+nx*w0, y0+ny*w0), (x1+nx*w1, y1+ny*w1),
                (x1-nx*w1, y1-ny*w1), (x0-nx*w0, y0-ny*w0)]
        self.d.polygon(poly, fill=rgba(col, a))
        self.d.ellipse([x0-w0, y0-w0, x0+w0, y0+w0], fill=rgba(col, a))
        self.d.ellipse([x1-w1, y1-w1, x1+w1, y1+w1], fill=rgba(col, a))

    def disc(self, p, rr, col, a=255):
        x, y = self.xy(p); r = self.r(rr)
        self.d.ellipse([x-r, y-r, x+r, y+r], fill=rgba(col, a))

    def poly(self, pts, col, a=255):
        self.d.polygon([self.xy(p) for p in pts], fill=rgba(col, a))

    def line(self, p0, p1, w, col, a=255):
        x0, y0 = self.xy(p0); x1, y1 = self.xy(p1)
        self.d.line([x0, y0, x1, y1], fill=rgba(col, a), width=max(1, int(self.r(w))))

    # ---- mask builders
    def _blank(self):
        return Image.new("L", self.img.size, 0)

    def _m_poly(self, pts):
        m = self._blank()
        ImageDraw.Draw(m).polygon([self.xy(p) for p in pts], fill=255)
        return m

    def _m_seg(self, p0, p1, w0, w1):
        m = self._blank(); d = ImageDraw.Draw(m)
        x0, y0 = self.xy(p0); x1, y1 = self.xy(p1)
        w0p, w1p = self.r(w0), self.r(w1)
        dx, dy = x1-x0, y1-y0
        L = math.hypot(dx, dy) or 1.0
        nx, ny = -dy/L, dx/L
        d.polygon([(x0+nx*w0p, y0+ny*w0p), (x1+nx*w1p, y1+ny*w1p),
                   (x1-nx*w1p, y1-ny*w1p), (x0-nx*w0p, y0-ny*w0p)], fill=255)
        d.ellipse([x0-w0p, y0-w0p, x0+w0p, y0+w0p], fill=255)
        d.ellipse([x1-w1p, y1-w1p, x1+w1p, y1+w1p], fill=255)
        return m

    def _m_disc(self, p, rx, ry=None):
        m = self._blank(); d = ImageDraw.Draw(m)
        x, y = self.xy(p); rxp = self.r(rx); ryp = self.r(ry if ry else rx)
        d.ellipse([x-rxp, y-ryp, x+rxp, y+ryp], fill=255)
        return m

    # ---- shading core
    def _field(self, mask):
        """mask -> (hard sub-mask, bbox, blurred depth field) or None."""
        a = np.asarray(mask).astype(np.float32) / 255.0
        ys, xs = np.where(a > 0.35)
        if len(ys) == 0:
            return None
        pad = int(self.ss * 2)
        y0, y1 = ys.min(), ys.max(); x0, x1 = xs.min(), xs.max()
        y0 = max(0, y0-pad); x0 = max(0, x0-pad)
        y1 = min(a.shape[0]-1, y1+pad); x1 = min(a.shape[1]-1, x1+pad)
        sub = a[y0:y1+1, x0:x1+1]
        soft = np.asarray(mask.filter(ImageFilter.GaussianBlur(self.ss * 1.7)),
                          dtype=np.float32) / 255.0
        dep = np.clip(soft[y0:y1+1, x0:x1+1] * 1.55, 0, 1)
        return sub, (x0, y0), dep

    def _colorize(self, sub, dep, col, br, rimk, cool=0.10, tex=0.5, spec=None):
        """br/rimk/spec: 2D float fields matching sub. Returns RGBA array."""
        g = self.rng.normal(0, 1, sub.shape).astype(np.float32)
        brush = 1.0 + tex * (g * 0.045)
        base = np.asarray(col, np.float32)
        out = np.zeros((*sub.shape, 4), np.float32)
        for c in range(3):
            out[..., c] = base[c] * br * brush
        shade_side = np.clip(0.45 - br * 0.4, 0, 1)
        out[..., 2] += shade_side * cool * 60
        out[..., 0] += rimk * 200
        out[..., 1] += rimk * 185
        out[..., 2] += rimk * 150
        if spec is not None:
            out[..., :3] += spec[..., None] * 255
        out[..., 3] = sub * 255
        return np.clip(out, 0, 255)

    def _paste_arr(self, arr, box):
        layer = Image.fromarray(arr.astype(np.uint8))
        full = Image.new("RGBA", self.img.size, (0, 0, 0, 0))
        full.paste(layer, (box[0], box[1]))
        self.img.alpha_composite(full)

    def plate(self, pts, col, gain=1.0, tex=0.5, rim=0.9, light=None, spec=0.0):
        """Beveled armor facet: directional gradient + lit edge rim."""
        mask = self._m_poly(pts)
        got = self._field(mask)
        if not got:
            return
        sub, (x0, y0), dep = got
        H, W = sub.shape
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        nx = xx / max(1, W-1) - 0.5
        ny = yy / max(1, H-1) - 0.5
        L = np.asarray(light or self.LIGHT, np.float32)
        L /= np.linalg.norm(L)
        lt = np.clip(0.5 + nx*L[0] + ny*L[1] * -1.0, 0, 1)
        br = gain * (0.40 + 0.85 * lt) * (0.70 + 0.45 * dep)
        edge = (sub > 0.4) & (dep < 0.88)
        rimk = np.clip(lt - 0.52, 0, 1) * rim * edge
        spk = np.clip(lt - 0.80, 0, 1) / 0.2 * dep * spec if spec else None
        self._paste_arr(self._colorize(sub, dep, col, br, rimk, tex=tex, spec=spk), (x0, y0))

    def tube(self, p0, p1, w0, w1, col, gain=1.0, tex=0.5, spec=0.0):
        """Cylindrically-shaded tapered limb — the rounded-volume workhorse."""
        mask = self._m_seg(p0, p1, w0, w1)
        got = self._field(mask)
        if not got:
            return
        sub, (x0, y0), dep = got
        H, W = sub.shape
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        xx += x0; yy += y0
        X0, Y0 = self.xy(p0); X1, Y1 = self.xy(p1)
        dx, dy = X1-X0, Y1-Y0
        L = math.hypot(dx, dy) or 1.0
        ux, uy = dx/L, dy/L
        u = ((xx-X0)*ux + (yy-Y0)*uy) / L
        wp = (w0 + (w1-w0)*np.clip(u, 0, 1)) * self.h * self.ss
        s = (xx-X0)*(-uy) + (yy-Y0)*ux
        v = np.abs(s) / np.maximum(wp, 1.0)
        Lx, Ly = self.LIGHT
        nl = np.sign(s) * (-uy*Lx + ux*Ly)   # surface-normal · light
        cyl = np.cos(np.clip(v, 0, 1) * math.pi / 2)
        dif = np.clip(nl, 0, 1)
        br = gain * (0.34 + 0.55*dif + 0.30*cyl) * (0.72 + 0.42*dep)
        edge = (sub > 0.4) & (dep < 0.88)
        rimk = np.clip(dif - 0.35, 0, 1) * 0.9 * edge
        spk = np.clip(dif*cyl - 0.75, 0, 1) / 0.25 * spec if spec else None
        self._paste_arr(self._colorize(sub, dep, col, br, rimk, tex=tex, spec=spk), (x0, y0))

    def blob(self, p, rx, ry, col, gain=1.0, tex=0.6, spec=0.0):
        """Sphere-shaded organic mass (lambert + dome)."""
        mask = self._m_disc(p, rx, ry)
        got = self._field(mask)
        if not got:
            return
        sub, (x0, y0), dep = got
        H, W = sub.shape
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        xx += x0; yy += y0
        cx, cy = self.xy(p); rxp = self.r(rx); ryp = self.r(ry)
        nx_ = (xx-cx)/max(rxp, 1); ny_ = (yy-cy)/max(ryp, 1)
        r2 = nx_*nx_ + ny_*ny_
        z = np.sqrt(np.clip(1.0-r2, 0, 1))
        L = np.asarray((-0.45, -0.62, 0.65), np.float32)
        L /= np.linalg.norm(L)
        dif = np.clip(nx_*L[0] + ny_*L[1] + z*L[2], 0, 1)
        mottle = 1.0 + tex*0.09*np.sin(nx_*7.3 + ny_*4.1) * np.sin(ny_*6.7-1.3)
        br = gain * (0.30 + 0.88*dif) * (0.74 + 0.38*dep) * mottle
        edge = (sub > 0.4) & (dep < 0.88)
        rimk = np.clip(dif - 0.55, 0, 1) * 0.8 * edge
        spk = np.clip(dif*z - 0.72, 0, 1) / 0.28 * spec if spec else None
        self._paste_arr(self._colorize(sub, dep, col, br, rimk, tex=tex, spec=spk), (x0, y0))

    def cloth(self, pts, col, folds=4, gain=1.0, flow=None):
        """Hanging cloth: light-from-top + fold stripes along the drape."""
        mask = self._m_poly(pts)
        got = self._field(mask)
        if not got:
            return
        sub, (x0, y0), dep = got
        H, W = sub.shape
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        nx = xx / max(1, W-1) - 0.5
        ny = yy / max(1, H-1) - 0.5
        L = np.asarray(self.LIGHT, np.float32)
        lt = np.clip(0.5 + nx*L[0]/abs(L[0])*0.5 - ny*0.55, 0, 1)
        # fold stripes run ACROSS the flow direction
        fl = np.asarray(flow or (-0.25, -1.0), np.float32)
        fl /= np.linalg.norm(fl)
        perp = nx*(-fl[1]) + ny*fl[0]
        along = nx*fl[0] + ny*fl[1]
        fold = 0.80 + 0.34*np.sin(perp*folds*math.pi*2 + along*1.5)
        br = gain * (0.38 + 0.72*lt) * fold * (0.74 + 0.40*dep)
        edge = (sub > 0.4) & (dep < 0.88)
        rimk = np.clip(lt - 0.55, 0, 1) * 0.7 * edge
        self._paste_arr(self._colorize(sub, dep, col, br, rimk, tex=0.7), (x0, y0))

    def arc_swoosh(self, c, r0, r1, a0, a1, col, steps=44, gain=1.0):
        """Teardrop motion crescent: pointed ends, fat mid-sweep, soft alpha."""
        cx, cy = self.xy(c)
        R0, R1 = self.r(r0), self.r(r1)
        thetas = np.linspace(a0, a1, steps)
        prof = np.sin(np.linspace(0, math.pi, steps)) ** 0.8
        outer = R0 + (R1-R0) * (0.28 + 0.72*prof)
        pts = [(cx+math.cos(t)*R0*0.94, cy+math.sin(t)*R0*0.94) for t in thetas]
        pts += [(cx+math.cos(thetas[i])*outer[i], cy+math.sin(thetas[i])*outer[i])
                for i in range(steps-1, -1, -1)]
        mask = self._blank()
        ImageDraw.Draw(mask).polygon(pts, fill=255)
        a = np.asarray(mask).astype(np.float32)/255.0
        yy, xx = np.mgrid[0:a.shape[0], 0:a.shape[1]].astype(np.float32)
        ang = np.arctan2(yy-cy, xx-cx)
        span = a1 - a0
        rel = ang - a0
        rel = np.mod(rel, 2*math.pi) if span >= 0 else -np.mod(-rel, 2*math.pi)
        t = np.clip(rel/span if span != 0 else rel, 0, 1)
        rad = np.clip((np.hypot(xx-cx, yy-cy) - R0*0.94)/max(1.0, R1-R0*0.94), 0, 1)
        fade = np.clip(np.sin(t*math.pi), 0, 1) ** 0.55
        al = a * fade * (0.16 + 0.58*rad) * gain
        cA = np.asarray(mix(col, (255, 255, 255), 0.30), np.float32)
        out = np.zeros((*a.shape, 4), np.float32)
        out[..., :3] = cA * (0.70 + 0.45*rad[..., None])
        out[..., 3] = np.clip(al*255, 0, 255)
        lay = Image.fromarray(out.astype(np.uint8)).filter(
            ImageFilter.GaussianBlur(self.ss * 0.9))
        self.img.alpha_composite(lay)

    def arc_band(self, c, r0, r1, a0, a1, col, alpha=90, steps=26):
        self.arc_swoosh(c, r0, r1, a0, a1, col)

    def finish(self):
        """Painterly post: gradient AO, rim light, outline, noise, downscale."""
        im = self.img
        a = np.asarray(im).astype(np.float32)
        al = a[..., 3] > 8
        # vertical AO gradient (top brighter)
        hgt = a.shape[0]
        grad = np.linspace(1.10, 0.72, hgt)[:, None, None]
        a[..., :3] = np.clip(a[..., :3] * grad, 0, 255)
        # rim light: opaque px with transparent neighbor toward light
        m = al.astype(np.uint8)*255
        mm = Image.fromarray(m).filter(ImageFilter.MaxFilter(3))
        dil = np.asarray(mm) > 8
        ero = np.asarray(Image.fromarray(m).filter(ImageFilter.MinFilter(3))) > 8
        edge = dil & ~ero  # 1px shell just outside
        # inside rim near top-left
        ys, xs = np.where(ero)
        rim = np.zeros_like(ero)
        shifted = np.zeros_like(ero)
        shifted[:-3, :-2] = ero[3:, 2:]
        rim = ero & ~shifted
        a[..., 0][rim] = np.clip(a[..., 0][rim]*1.35 + 40, 0, 255)
        a[..., 1][rim] = np.clip(a[..., 1][rim]*1.35 + 38, 0, 255)
        a[..., 2][rim] = np.clip(a[..., 2][rim]*1.30 + 30, 0, 255)
        # dark outer outline
        a[edge, 0] *= 0.10; a[edge, 1] *= 0.10; a[edge, 2] *= 0.14
        a[edge, 3] = 255
        # noise
        n = rng.normal(0, 4.5, a[..., :3].shape)
        a[..., :3] = np.clip(a[..., :3] + n, 0, 255)
        out = Image.fromarray(a.astype(np.uint8))
        out = out.resize((self.w, self.h), Image.LANCZOS)
        return out


# ---------------------------------------------------------------- poses
def base_pose():
    """Neutral standing pose. Joints in normalized space (feet y=0)."""
    return {
        "pelvis": (0.0, 0.52), "chest": (0.0, 0.76), "neck": (0.0, 0.84),
        "head": (0.0, 0.90),
        "l_hip": (-0.07, 0.50), "l_knee": (-0.09, 0.27), "l_foot": (-0.10, 0.02),
        "r_hip": (0.07, 0.50), "r_knee": (0.09, 0.27), "r_foot": (0.10, 0.02),
        "l_sh": (-0.15, 0.79), "l_el": (-0.19, 0.62), "l_ha": (-0.20, 0.47),
        "r_sh": (0.15, 0.79), "r_el": (0.19, 0.62), "r_ha": (0.20, 0.47),
        "blade_ang": 78, "blade_len": 0.42, "cloak": 0.0, "twist": 0.0,
        "crouch": 0.0, "arc": None,
    }


def pose(**m):
    p = base_pose()
    # apply coarse params to joints
    tw = m.get("twist", 0.0)
    cr = m.get("crouch", 0.0)
    lean = m.get("lean", 0.0)
    for k in list(p):
        if isinstance(p[k], tuple):
            x, y = p[k]
            if y > 0.55:  # upper body twists/leans
                x += tw * (y - 0.5) * 1.6 + lean * (y - 0.5)
            if y > 0.5:
                y -= cr * (y - 0.5) * 0.9
            p[k] = (x, y)
    for k, v in m.items():
        if k in p:
            p[k] = v
        if k == "l_leg":  # (dx, dy) offsets applied to knee+foot
            p["l_knee"] = (p["l_knee"][0]+v[0]*0.5, p["l_knee"][1]+v[1]*0.5)
            p["l_foot"] = (p["l_foot"][0]+v[0], max(0.015, p["l_foot"][1]+v[1]))
        if k == "r_leg":
            p["r_knee"] = (p["r_knee"][0]+v[0]*0.5, p["r_knee"][1]+v[1]*0.5)
            p["r_foot"] = (p["r_foot"][0]+v[0], max(0.015, p["r_foot"][1]+v[1]))
        if k == "r_arm":  # (elbow, hand) absolute
            p["r_el"], p["r_ha"] = v
        if k == "l_arm":
            p["l_el"], p["l_ha"] = v
    p.update({k: v for k, v in m.items() if k in ("blade_ang", "blade_len", "cloak", "arc")})
    return p


def hand_off(p, ang_deg, dist):
    a = math.radians(ang_deg)
    h = p["r_ha"]
    return (h[0]+math.cos(a)*dist, h[1]+math.sin(a)*dist)


# ---------------------------------------------------------------- figure render
def render_humanoid(spec, p, height):
    f = Fig(height)
    ARM, ARM2 = spec["armor"], spec["armor2"]
    TRM, GLW = spec["trim"], spec["glow"]
    CLO = spec.get("cloak")
    bulk = spec.get("bulk", 1.0)
    STEEL = spec.get("steel", (168, 178, 196))
    fg = 0.72  # far-side gain

    # ---- swing arc behind everything (baked motion trail)
    if p.get("arc"):
        c, r0, r1, a0, a1 = p["arc"]
        f.arc_swoosh(c, r0, r1, a0, a1, mix(GLW, (255, 255, 255), 0.45))
        f.arc_swoosh(c, r0*0.9, r1*0.72, a0 + (a1-a0)*0.15, a1, GLW, gain=0.45)

    # ---- cloak: torn-hem drape behind body
    if CLO:
        wind = p.get("cloak", 0.0)
        sh_l, sh_r = p["l_sh"], p["r_sh"]
        foot_y = 0.05
        midx = (sh_l[0]+sh_r[0])/2
        tipx = midx - 0.06 - wind*0.34
        hem = [(tipx+0.17, foot_y+0.19), (tipx+0.13, foot_y+0.04),
               (tipx+0.08, foot_y+0.16), (tipx+0.03, foot_y+0.02),
               (tipx-0.02, foot_y+0.13), (tipx-0.07, foot_y+0.03)]
        pts = [(sh_l[0]-0.01, sh_l[1]+0.01), (sh_r[0]+0.01, sh_r[1]+0.01),
               (sh_r[0]+0.04-wind*0.06, 0.52)] + hem + [
               (sh_l[0]-0.03-wind*0.08, 0.50)]
        f.cloth(pts, CLO, folds=4, flow=(tipx-midx, -0.5))
        f.poly([(sh_l[0], sh_l[1]), (sh_r[0], sh_r[1]), (midx, 0.55)], sh(CLO, 0.55), 200)
        f.disc((sh_l[0], sh_l[1]+0.02), 0.013, TRM)
        f.disc((sh_r[0], sh_r[1]+0.02), 0.013, TRM)

    # ---- far limbs (darker pass)
    f.tube(p["l_hip"], p["l_knee"], 0.052*bulk, 0.042*bulk, ARM, gain=fg)
    f.tube(p["l_knee"], p["l_foot"], 0.042*bulk, 0.036*bulk, ARM, gain=fg)
    _boot(f, p["l_foot"], -1, ARM2, bulk, gain=fg)
    f.tube(p["l_sh"], p["l_el"], 0.042*bulk, 0.036*bulk, ARM, gain=fg)
    f.tube(p["l_el"], p["l_ha"], 0.034*bulk, 0.030*bulk, ARM, gain=fg)
    if spec.get("shield"):
        c = p["l_ha"]
        pts = [(c[0]-0.11, c[1]+0.17), (c[0]+0.03, c[1]+0.19),
               (c[0]+0.06, c[1]-0.02), (c[0]+0.02, c[1]-0.17), (c[0]-0.10, c[1]-0.15)]
        f.plate(pts, ARM2, gain=0.9, spec=0.10)
        inner = [(x*0.82+c[0]*0.18-0.015, y*0.84+c[1]*0.16) for x, y in pts]
        f.plate(inner, ARM, gain=1.0, spec=0.12)
        f.disc((c[0]-0.03, c[1]+0.01), 0.020, GLW)
        f.disc((c[0]-0.03, c[1]+0.01), 0.009, (245, 250, 255))

    # ---- torso: beveled angular cuirass
    pel, ch = p["pelvis"], p["chest"]
    wl = pel[0]-0.075*bulk; wr = pel[0]+0.075*bulk
    sl, sr = p["l_sh"], p["r_sh"]
    wy = pel[1]+0.02; shy = ch[1]+0.015
    cx = (wl+wr)/2
    chest_pts = [(wl-0.01, wy), (wr+0.01, wy),
                 (sr[0]+0.045*bulk, sr[1]-0.02), (sr[0]+0.03*bulk, shy+0.06),
                 (sl[0]-0.03*bulk, shy+0.06), (sl[0]-0.045*bulk, sl[1]-0.02)]
    f.plate(chest_pts, ARM, gain=1.0, spec=0.10, tex=0.7)
    # lit left facet + dark right facet for a modeled breastplate
    f.plate([(sl[0]-0.02, shy+0.05), (cx, shy+0.055), (cx-0.01, wy+0.09), (sl[0]-0.03, shy-0.01)],
            sh(ARM, 1.18), gain=1.05, rim=0.4)
    f.plate([(cx, shy+0.055), (sr[0]+0.02, shy+0.05), (sr[0]+0.03, shy-0.01), (cx+0.01, wy+0.09)],
            ARM, gain=0.62, rim=0.2)
    # seams / ridge / collar / belt
    f.line((cx, shy+0.05), (cx, wy+0.02), 0.006, sh(ARM, 0.5), 200)
    for i, yy in enumerate((wy+0.045, wy+0.075, wy+0.105)):
        w2 = (wr-wl)/2 * (0.95 - i*0.12)
        f.line((cx-w2, yy), (cx+w2, yy), 0.005, sh(ARM, 0.58), 210)
    f.line((sl[0]-0.01, shy+0.05), (sr[0]+0.01, shy+0.05), 0.008, TRM, 230)
    f.line((wl-0.02, wy+0.005), (wr+0.02, wy+0.005), 0.016, sh(ARM2, 0.9))
    f.disc((cx, wy+0.008), 0.016, TRM)
    f.disc((cx, wy+0.008), 0.007, GLW)
    f.disc((cx, shy-0.015), 0.019, GLW)
    f.disc((cx, shy-0.015), 0.008, (240, 250, 255))
    for sx_ in (-0.05, 0.05):  # rivets
        f.disc((cx+sx_*bulk, shy+0.03), 0.005, sh(STEEL, 1.2), 220)

    # ---- tabard
    tab = spec.get("tabard")
    if tab:
        ty0 = wy - 0.01
        tl = 0.36 if spec.get("tabard_long") else 0.20
        tw = 0.075 if spec.get("tabard_long") else 0.055
        pts = [(cx-0.045*bulk, ty0), (cx+0.045*bulk, ty0),
               (cx+tw*bulk, ty0-tl), (cx+0.01, ty0-tl*0.8),
               (cx-0.02, ty0-tl*1.08), (cx-tw*bulk, ty0-tl*0.92)]
        f.cloth(pts, tab, folds=3, flow=(-0.1, -1))
        f.line((cx-0.045*bulk, ty0-0.008), (cx+0.045*bulk, ty0-0.008), 0.007, sh(tab, 0.5), 220)
        if spec.get("tabard_long"):
            f.line((cx-tw*bulk, ty0-0.06), (cx-tw*bulk*1.05, ty0-tl*0.85), 0.006, sh(tab, 0.55), 190)
            f.line((cx+tw*bulk, ty0-0.06), (cx+tw*bulk*1.05, ty0-tl*0.85), 0.006, sh(tab, 1.3), 190)

    # ---- pauldrons: per-character signature
    pst = spec.get("pauldron", "plate")
    for sd, sp in ((-1, sl), (1, sr)):
        out = sd * (0.035*bulk)
        if pst == "heavy":
            f.plate([(sp[0]-0.03, sp[1]+0.075*bulk), (sp[0]+out*2.6, sp[1]+0.02),
                     (sp[0]+out*2.4, sp[1]-0.03), (sp[0]-0.02, sp[1]-0.02)], ARM2, spec=0.12)
            f.plate([(sp[0]-0.02, sp[1]+0.03), (sp[0]+out*2.2, sp[1]-0.01),
                     (sp[0]+out*2.3, sp[1]-0.055*bulk), (sp[0]-0.01, sp[1]-0.03)], ARM, spec=0.12)
        elif pst == "spire":
            f.plate([(sp[0]-0.02, sp[1]+0.05*bulk), (sp[0]+out*2.0, sp[1]+0.01),
                     (sp[0]+out*2.2, sp[1]-0.045*bulk), (sp[0]-0.01, sp[1]-0.02)], ARM2, spec=0.15)
            f.tube((sp[0]+out*0.9, sp[1]+0.05*bulk), (sp[0]+out*1.9, sp[1]+0.16*bulk),
                   0.017, 0.003, sh(STEEL, 0.9), spec=0.3)
        elif pst == "plate":
            f.plate([(sp[0]-0.02, sp[1]+0.045*bulk), (sp[0]+out*1.8, sp[1]+0.01),
                     (sp[0]+out*2.2, sp[1]-0.045*bulk), (sp[0]-0.01, sp[1]-0.02)], ARM2, spec=0.15)
            f.line((sp[0]-0.015, sp[1]+0.042*bulk), (sp[0]+out*1.9, sp[1]+0.005), 0.006, sh(ARM2, 1.7), 220)
        f.disc((sp[0], sp[1]+0.045*bulk), 0.009, TRM, 220)

    # ---- faulds (armored skirt) for heavies
    if spec.get("faulds"):
        for i in range(3):
            t = i/2.0 - 0.5
            fx0 = cx + t*0.10*bulk
            f.plate([(fx0-0.035*bulk, wy), (fx0+0.035*bulk, wy),
                     (fx0+0.045*bulk, wy-0.10), (fx0-0.045*bulk, wy-0.10)],
                    sh(ARM, 0.85-0.08*i), gain=0.85, rim=0.4)

    # ---- near limbs
    f.tube(p["r_hip"], p["r_knee"], 0.055*bulk, 0.045*bulk, ARM, gain=1.02)
    f.tube(p["r_knee"], p["r_foot"], 0.045*bulk, 0.038*bulk, ARM, gain=1.05)
    f.blob(p["r_knee"], 0.030*bulk, 0.032*bulk, ARM2, spec=0.15)
    _boot(f, p["r_foot"], 1, ARM2, bulk)
    f.tube(p["r_sh"], p["r_el"], 0.045*bulk, 0.038*bulk, ARM, gain=1.10)
    f.tube(p["r_el"], p["r_ha"], 0.036*bulk, 0.031*bulk, ARM, gain=1.10)
    f.blob(p["r_el"], 0.024*bulk, 0.026*bulk, sh(ARM2, 1.05), spec=0.15)
    _gauntlet(f, p["r_ha"], spec, bulk)

    # ---- head / helm
    hd = p["head"]
    helm = spec.get("helm", "visor")
    hr = 0.082*bulk
    if helm == "hood":
        pts = [(hd[0]-hr*1.15, hd[1]-hr*0.5), (hd[0]-hr*0.5, hd[1]+hr*1.15),
               (hd[0]+hr*0.45, hd[1]+hr*1.25), (hd[0]+hr*1.15, hd[1]-hr*0.4),
               (hd[0]+hr*0.55, hd[1]-hr*0.75), (hd[0]-hr*0.5, hd[1]-hr*0.7)]
        f.cloth(pts, CLO or ARM2, folds=3)
        f.disc((hd[0], hd[1]-hr*0.08), hr*0.70, (18, 14, 20))
        f.disc((hd[0]-0.020, hd[1]-hr*0.04), 0.0085, GLW)
        f.disc((hd[0]+0.020, hd[1]-hr*0.04), 0.0085, GLW)
    elif helm == "horned":
        f.plate([(hd[0]-hr*0.8, hd[1]-hr*0.7), (hd[0]-hr*0.85, hd[1]+hr*0.55),
                 (hd[0]-hr*0.3, hd[1]+hr*0.95), (hd[0]+hr*0.3, hd[1]+hr*0.95),
                 (hd[0]+hr*0.85, hd[1]+hr*0.55), (hd[0]+hr*0.8, hd[1]-hr*0.7)], ARM, spec=0.15)
        for sx in (-1, 1):
            b0 = (hd[0]+sx*hr*0.7, hd[1]+hr*0.55)
            b1 = (hd[0]+sx*hr*1.9, hd[1]+hr*1.15)
            b2 = (hd[0]+sx*hr*2.6, hd[1]+hr*1.9)
            f.tube(b0, b1, 0.020, 0.011, sh(TRM, 1.05), spec=0.2)
            f.tube(b1, b2, 0.011, 0.002, sh(TRM, 1.4), spec=0.3)
        f.line((hd[0]-hr*0.55, hd[1]-hr*0.1), (hd[0]+hr*0.55, hd[1]-hr*0.1), 0.015, GLW)
        f.line((hd[0]-hr*0.4, hd[1]-hr*0.45), (hd[0]+hr*0.4, hd[1]-hr*0.45), 0.007, sh(ARM, 0.6), 220)
    elif helm == "mask":
        f.blob(hd, hr*0.95, hr*1.0, (224, 224, 232), spec=0.2)
        f.poly([(hd[0]-hr*0.5, hd[1]+hr*0.2), (hd[0]+hr*0.5, hd[1]+hr*0.2), (hd[0], hd[1]-hr*0.05)],
               (224, 224, 232))
        f.line((hd[0]-hr*0.4, hd[1]+hr*0.15), (hd[0]+hr*0.4, hd[1]+hr*0.15), 0.009, (140, 18, 28))
        f.disc((hd[0]-0.024, hd[1]-hr*0.12), 0.0075, GLW)
        f.disc((hd[0]+0.024, hd[1]-hr*0.12), 0.0075, GLW)
    elif helm == "bare":
        f.blob(hd, hr*0.9, hr*0.95, spec.get("skin", (176, 137, 104)), spec=0.1)
        f.blob((hd[0]-0.005, hd[1]+hr*0.5), hr*0.72, hr*0.5, (44, 32, 24))
        if spec.get("beard"):
            f.cloth([(hd[0]-hr*0.6, hd[1]-hr*0.25), (hd[0]+hr*0.6, hd[1]-hr*0.25),
                     (hd[0]+hr*0.2, hd[1]-hr*1.3), (hd[0]-hr*0.2, hd[1]-hr*1.2)],
                    (50, 38, 28), folds=3)
        f.disc((hd[0]-0.020, hd[1]-hr*0.05), 0.0065, (26, 20, 16))
        f.disc((hd[0]+0.020, hd[1]-hr*0.05), 0.0065, (26, 20, 16))
    else:  # visor — beveled great helm
        pts = [(hd[0]-hr*0.8, hd[1]-hr*0.75), (hd[0]-hr*0.9, hd[1]+hr*0.3),
               (hd[0]-hr*0.45, hd[1]+hr*1.0), (hd[0]+hr*0.35, hd[1]+hr*1.05),
               (hd[0]+hr*0.9, hd[1]+hr*0.4), (hd[0]+hr*0.75, hd[1]-hr*0.7)]
        f.plate(pts, ARM, spec=0.18, tex=0.6)
        f.plate([(pts[2][0]+0.008, pts[2][1]-0.008), (pts[3][0]-0.008, pts[3][1]-0.008),
                 (hd[0]+hr*0.6, hd[1]+hr*0.35), (hd[0]-hr*0.5, hd[1]+hr*0.3)],
                sh(ARM, 1.22), gain=1.1, rim=0.3)
        f.line((hd[0]-hr*0.6, hd[1]+hr*0.02), (hd[0]+hr*0.62, hd[1]+hr*0.02), 0.015, GLW)
        f.line((hd[0]-hr*0.55, hd[1]-hr*0.38), (hd[0]+hr*0.55, hd[1]-hr*0.38), 0.007, TRM, 230)
        if spec.get("crest"):
            cr = spec["crest"]
            f.cloth([(hd[0]-hr*0.15, hd[1]+hr*0.95), (hd[0]+hr*0.15, hd[1]+hr*0.95),
                     (hd[0]+hr*0.05, hd[1]+hr*1.75), (hd[0]-hr*0.05, hd[1]+hr*1.7)], cr, folds=2)

    # ---- weapon
    w = spec.get("weapon", "none")
    ha = p["r_ha"]
    ang = math.radians(p.get("blade_ang", 78))
    L = p.get("blade_len", spec.get("blade_len", 0.42))
    tip = (ha[0]+math.cos(ang)*L, ha[1]+math.sin(ang)*L)
    if w == "sword":
        nx = math.cos(ang+math.pi/2)*0.014; ny = math.sin(ang+math.pi/2)*0.014
        f.plate([(ha[0]+nx, ha[1]+ny), ((ha[0]+tip[0])*0.5+nx*0.8, (ha[1]+tip[1])*0.5+ny*0.8),
                 (tip[0], tip[1]), ((ha[0]+tip[0])*0.5-nx*0.8, (ha[1]+tip[1])*0.5-ny*0.8),
                 (ha[0]-nx, ha[1]-ny)], STEEL, gain=1.15, spec=0.25, tex=0.3,
                light=(math.cos(ang+math.pi/2)*-0.6-0.3, math.sin(ang+math.pi/2)*-0.6-0.5))
        f.seg(ha, (ha[0]+(tip[0]-ha[0])*0.9, ha[1]+(tip[1]-ha[1])*0.9), 0.004, 0.0015, GLW, 230)
        gd = (ha[0]+math.cos(ang+math.pi/2)*0.055, ha[1]+math.sin(ang+math.pi/2)*0.055)
        gd2 = (ha[0]-math.cos(ang+math.pi/2)*0.055, ha[1]-math.sin(ang+math.pi/2)*0.055)
        f.tube(gd2, gd, 0.011, 0.011, TRM, spec=0.2)
        f.tube(ha, (ha[0]-math.cos(ang)*0.05, ha[1]-math.sin(ang)*0.05), 0.014, 0.013, (52, 42, 34))
    elif w == "cleaver":
        mid = (ha[0]+(tip[0]-ha[0])*0.38, ha[1]+(tip[1]-ha[1])*0.38)
        f.tube(ha, mid, 0.026, 0.030, (96, 92, 104))
        nx = math.cos(ang+math.pi/2)*0.055; ny = math.sin(ang+math.pi/2)*0.055
        f.plate([(mid[0]+nx, mid[1]+ny), (tip[0]+nx*0.7, tip[1]+ny*0.7), (tip[0], tip[1]),
                 (mid[0]-nx*0.45, mid[1]-ny*0.45)], STEEL, gain=1.1, spec=0.3, tex=0.4)
        f.seg(mid, tip, 0.014, 0.002, GLW, 220)
        f.tube(ha, (ha[0]-0.035, ha[1]-0.05), 0.020, 0.018, (70, 56, 40))
    elif w == "staff":
        bt = (ha[0]-0.02, 0.02)
        tp = (ha[0]+0.04, 0.98)
        f.tube(bt, tp, 0.016, 0.011, (86, 66, 46))
        for i in range(3):
            yy = 0.82 + i*0.05
            f.line((ha[0]+0.02, yy), (ha[0]+0.06, yy), 0.009, TRM, 220)
        f.disc(tp, 0.05, GLW, 70)
        f.blob(tp, 0.034, 0.034, GLW, spec=0.4)
        f.disc(tp, 0.014, (245, 250, 255))
    elif w == "claws":
        for i, da in enumerate((-18, 0, 18)):
            a2 = math.radians(p.get("blade_ang", 60)+da)
            t2 = (ha[0]+math.cos(a2)*L*0.7, ha[1]+math.sin(a2)*L*0.7)
            f.tube(ha, t2, 0.014, 0.002, STEEL, spec=0.3)
    return f.finish()


def _boot(f, foot, side, col, bulk, gain=1.0):
    """Flat-bottomed armored boot wedge."""
    x, y = foot
    pts = [(x-0.045*bulk, y+0.045), (x+0.02, y+0.05), (x+side*0.075*bulk, y+0.012),
           (x+side*0.075*bulk, y-0.005), (x-0.045*bulk, y-0.005)]
    f.plate(pts, col, gain=gain, rim=0.5)
    f.line((x-0.04, y+0.042), (x+side*0.05, y+0.028), 0.005, sh(col, 1.6), 210)


def _gauntlet(f, ha, spec, bulk):
    """Fist: wedge knuckle plate."""
    x, y = ha
    f.plate([(x-0.03, y+0.03), (x+0.035, y+0.028), (x+0.045, y-0.02), (x-0.025, y-0.032)],
            spec.get("skin", spec["armor2"]), gain=1.1, spec=0.12)
    f.line((x-0.02, y+0.026), (x+0.03, y+0.024), 0.005, sh(spec["armor2"], 1.7), 220)


def render_organic(spec, p, height):
    """Proterian flesh mass with tentacles — for spitter/host.
    Sphere-shaded blobs + tube limbs: fleshy, not a flat disc."""
    f = Fig(height)
    FL, FL2, GLW = spec["flesh"], spec["flesh2"], spec["glow"]
    cx, cy = 0.0, p.get("cy", 0.45)
    R = spec.get("r", 0.30)
    sq = p.get("squash", 1.0)
    sway = p.get("sway", 0.0)
    ry = R*sq
    # tentacles behind — shaded tubes
    for i in range(spec.get("limbs", 4)):
        a = math.pi*(0.15 + 0.7*i/max(1, spec.get("limbs", 4)-1))
        ext = spec.get("limb_len", 0.30) + p.get("lunge", 0)*0.02
        bx, by = cx + math.cos(a)*R*0.7, cy - math.sin(a)*R*0.7
        tx2 = bx + math.cos(a+math.pi)*ext + sway*0.05
        ty2 = by - math.sin(a+math.pi)*ext*0.4 + 0.05
        f.tube((bx, by), (tx2, ty2), 0.05, 0.012, sh(FL, 0.85), gain=0.85)
        f.blob((tx2, ty2), 0.016, 0.016, (212, 204, 186), gain=0.9)
    # main mass — overlapping shaded blobs (irregular, lumpy silhouette)
    f.blob((cx, cy), R, ry, FL, tex=0.9, spec=0.08)
    f.blob((cx-R*0.35, cy+ry*0.30), R*0.62, ry*0.55, FL, gain=0.92, tex=0.9)
    f.blob((cx+R*0.30, cy-ry*0.25), R*0.55, ry*0.60, sh(FL, 0.85), gain=0.85, tex=0.9)
    # pustules / bumps
    fr = np.random.default_rng(31)
    for i in range(7):
        bx = cx + fr.uniform(-R*0.65, R*0.65)
        by = cy + fr.uniform(-ry*0.55, ry*0.55)
        f.blob((bx, by), fr.uniform(0.014, 0.034), fr.uniform(0.014, 0.034),
               sh(FL2, fr.uniform(0.85, 1.3)), spec=0.15)
    # skirt/legs
    for i in range(4):
        lx = cx - R*0.7 + i*R*0.45
        f.tube((lx, cy-ry*0.9), (lx+0.02, 0.03), 0.035, 0.02, sh(FL, 0.75), gain=0.8)
    # eyes
    ey = cy + ry*0.25
    for i in range(spec.get("eyes", 3)):
        ex = cx - spec.get("eyes", 3)*0.025 + i*0.05 + (i % 2)*0.01
        rr_ = 0.014 if p.get("gaze", 1) > 1.2 else 0.010
        f.disc((ex, ey), rr_, GLW)
        f.disc((ex, ey), rr_*0.4, (255, 255, 255))
    # maw
    if p.get("maw", 0):
        my = cy - ry*0.3
        mr = 0.05 + p["maw"]*0.02
        f.disc((cx, my), mr, (18, 9, 15))
        for i in range(5):
            a2 = math.pi*(0.2+0.6*i/4)
            f.disc((cx+math.cos(a2)*mr*0.8, my-math.sin(a2)*mr*0.8), 0.008, (228, 224, 208))
    # glow veins
    for i in range(4):
        vx = cx + fr.uniform(-R*0.55, R*0.55); vy = cy + fr.uniform(-ry*0.45, ry*0.45)
        f.line((vx, vy), (vx+0.05, vy+0.03), 0.005, GLW, 150)
    # spout barrel — spitter's ranged identity
    if spec.get("spout"):
        sx0 = cx + R*0.25 + p.get("lunge", 0)*0.015
        sy0 = cy + ry*0.45
        sx1 = cx + R*1.15 + p.get("lunge", 0)*0.03
        sy1 = cy + ry*0.55
        f.tube((sx0, sy0), (sx1, sy1), 0.085, 0.06, sh(FL, 0.9))
        f.blob((sx1, sy1), 0.055, 0.055, sh(FL2, 1.15), spec=0.15)
        f.disc((sx1, sy1), 0.028, (14, 9, 17))
        f.disc((sx1, sy1), 0.017, (30, 20, 34))
        if p.get("maw", 0):
            gr = 0.02 + p["maw"]*0.012
            f.disc((sx1, sy1), gr, GLW)
            f.disc((sx1, sy1), gr*0.5, (240, 255, 220))
    # host signature: bone spikes erupting from the mass
    if spec.get("spikes"):
        for i in range(4):
            a3 = math.pi*(0.3 + 0.5*i/3)
            b0 = (cx + math.cos(a3)*R*0.55, cy + math.sin(a3)*ry*0.55)
            b1 = (cx + math.cos(a3)*R*1.15, cy + math.sin(a3)*ry*1.3)
            f.tube(b0, b1, 0.018, 0.003, (208, 200, 184), spec=0.2)
    return f.finish()


def render_husk(spec, p, height):
    """Shambling hollowed host — hunched corpse, long reaching arms."""
    f = Fig(height)
    FL, FL2, GLW = spec["flesh"], spec["flesh2"], spec["glow"]
    lunge = p.get("lunge", 0.0)
    sway = p.get("sway", 0.0)
    sq = p.get("squash", 1.0)
    hip = (0.0, 0.40)
    chest = (0.05 + sway*0.02 + lunge*0.015, 0.66*sq + 0.04)
    head = (chest[0] + 0.10 + lunge*0.025, chest[1] - 0.01)
    # legs — dragging tubes
    f.tube((hip[0]-0.05, hip[1]), (-0.09, 0.02), 0.055, 0.045, FL, gain=0.7)
    f.tube((hip[0]+0.06, hip[1]), (0.10+sway*0.01, 0.02), 0.055, 0.045, FL, gain=0.75)
    # hunched torso — spine tube + chest blob
    f.tube(hip, chest, 0.115, 0.125, FL, gain=0.95, tex=0.9)
    f.blob(chest, 0.135, 0.125, FL, tex=0.9)
    f.blob((chest[0]+0.02, chest[1]-0.02), 0.10, 0.09, sh(FL, 1.1), gain=1.05)
    # exposed ribs
    for i in range(3):
        yy = chest[1] - 0.015 - i*0.04
        f.line((chest[0]-0.08, yy), (chest[0]+0.10, yy-0.012), 0.008, sh(FL2, 0.8), 210)
    # arms — long reaching tubes with clawed hands
    reach = 0.08 + lunge*0.035
    la = (chest[0]-0.06+reach*0.6, chest[1]-0.30-reach*0.4)
    ra = (chest[0]+0.14+reach*1.5, chest[1]-0.26-reach*0.5)
    f.tube((chest[0]-0.07, chest[1]-0.03), la, 0.038, 0.028, FL, gain=0.85)
    f.tube((chest[0]+0.10, chest[1]-0.01), ra, 0.042, 0.030, FL)
    for hx_, hy_ in (la, ra):
        f.blob((hx_, hy_), 0.020, 0.020, sh(FL2, 1.15))
        for da in (-0.5, 0.0, 0.5):
            f.line((hx_, hy_), (hx_+0.035, hy_-0.02+da*0.02), 0.005, (208, 202, 188))
    # sunken head
    f.blob(head, 0.075, 0.070, sh(FL, 0.9))
    f.blob((head[0]+0.03, head[1]-0.008), 0.05, 0.045, sh(FL, 1.08))
    gaze = 0.013 if p.get("gaze", 1) > 1.2 else 0.010
    for dx in (-0.015, 0.038):
        f.disc((head[0]+dx, head[1]), gaze, GLW)
        f.disc((head[0]+dx, head[1]), 0.0045, (255, 255, 255))
    if p.get("maw", 0):
        f.disc((head[0]+0.025, head[1]-0.045), 0.030+p["maw"]*0.010, (16, 7, 13))
        for i in range(3):
            f.disc((head[0]+0.010+i*0.015, head[1]-0.056), 0.006, (226, 222, 206))
    # tattered wrap
    f.line((chest[0]-0.10, chest[1]+0.02), (hip[0]-0.10, hip[1]-0.05), 0.011, sh(FL2, 1.25), 190)
    return f.finish()


def render_drone(spec, p, height):
    f = Fig(height)
    cy = 0.5 + p.get("bob", 0)
    col = spec["armor"]
    hot = p.get("hot", 0)
    f.blob((0, cy), 0.20, 0.19, col, spec=0.15)
    f.blob((-0.03, cy+0.04), 0.10, 0.09, sh(col, 1.25), gain=1.1)
    f.plate([(-0.15, cy+0.12), (0.15, cy+0.12), (0.10, cy+0.02), (-0.10, cy+0.02)],
            sh(col, 0.7), gain=0.8)
    eye = mix(spec["glow"], (255, 90, 60), hot)
    f.disc((0, cy), 0.07+hot*0.02, eye)
    f.disc((0, cy), 0.03, (255, 235, 220))
    for sx in (-1, 1):  # fins
        f.plate([(sx*0.16, cy+0.05), (sx*0.34, cy+0.10+p.get("rot", 0)*sx), (sx*0.30, cy-0.02)],
                sh(col, 1.35), gain=1.1)
    f.disc((0, cy+0.19), 0.013, spec["glow"])
    return f.finish()


def render_turret(spec, p, height):
    f = Fig(height)
    ARM, GLW = spec["armor"], spec["glow"]
    hot = p.get("hot", 0)
    for sx in (-1, 0, 1):  # tripod
        f.tube((0, 0.28), (sx*0.22, 0.02), 0.035, 0.02, ARM, gain=0.75)
    f.plate([(-0.16, 0.42), (0.16, 0.42), (0.20, 0.22), (-0.20, 0.22)], ARM, spec=0.15)
    f.plate([(-0.13, 0.40), (0.13, 0.40), (0.16, 0.25), (-0.16, 0.25)], sh(ARM, 1.2), gain=1.1)
    by = 0.62 if hot else 0.55
    f.tube((0, 0.42), (0.02, by), 0.045, 0.03, sh(ARM, 0.85))
    f.disc((0.02, by), 0.035+hot*0.02, mix(GLW, (255, 255, 255), hot))
    f.disc((0, 0.32), 0.035, mix(sh(GLW, 0.6), GLW, hot))
    return f.finish()


# ---------------------------------------------------------------- specs
ELY = {"armor": hx("23232f"), "armor2": hx("15151f"), "trim": hx("7B1FA2"),
       "glow": hx("00E5FF"), "cloak": hx("8a1620"), "helm": "visor",
       "weapon": "sword", "bulk": 1.0, "tabard": hx("4a1a5e"), "pauldron": "plate",
       "blade_len": 0.46}
SENT = {"armor": hx("2c313a"), "armor2": hx("181c22"), "trim": hx("8B0000"),
        "glow": hx("ff2222"), "helm": "visor", "weapon": "sword",
        "bulk": 1.25, "shield": True, "crest": hx("8B0000"), "tabard": hx("241416"),
        "pauldron": "heavy", "cloak": hx("2a1418"), "blade_len": 0.40}
REX = {"armor": hx("2e2024"), "armor2": hx("1a1216"), "trim": hx("8B0000"),
       "glow": hx("ff2222"), "cloak": hx("6a1016"), "helm": "horned",
       "weapon": "cleaver", "bulk": 1.55, "pauldron": "spire", "faulds": True,
       "blade_len": 0.52}
REX2 = dict(REX, armor=hx("3e1c1c"), armor2=hx("241014"), trim=hx("ff2222"), glow=hx("ff6644"))
NAHUM = {"armor": hx("33202a"), "armor2": hx("1c1218"), "trim": hx("8B0000"),
         "glow": hx("ff3355"), "cloak": hx("241418"), "helm": "visor",
         "weapon": "sword", "bulk": 1.1, "crest": hx("8B0000"), "tabard": hx("2a1216"),
         "pauldron": "plate", "blade_len": 0.50}
TUMAN = {"armor": hx("241c33"), "armor2": hx("161022"), "trim": hx("7B1FA2"),
         "glow": hx("00E676"), "cloak": hx("1c1428"), "helm": "hood",
         "weapon": "staff", "bulk": 0.9, "tabard": hx("1c1430"), "tabard_long": True,
         "pauldron": "none"}
KIRIN = {"armor": hx("e0e0e8"), "armor2": hx("a8acb8"), "trim": hx("8B0000"),
         "glow": hx("00E676"), "cloak": hx("d8d8e0"), "helm": "mask",
         "weapon": "none", "bulk": 0.85, "tabard": hx("c8ccd4"), "shield": True,
         "pauldron": "plate"}
CONST = {"armor": hx("16101e"), "armor2": hx("0c0a12"), "trim": hx("c9a227"),
         "glow": hx("c9a227"), "cloak": hx("16101e"), "helm": "hood",
         "weapon": "staff", "bulk": 0.95, "tabard": hx("16101e"), "tabard_long": True,
         "pauldron": "none"}
HUSK = {"flesh": hx("7a8468"), "flesh2": hx("4e5840"), "glow": hx("8fe87a"),
        "limbs": 4, "eyes": 3, "r": 0.28, "limb_len": 0.32}
SPIT = {"flesh": hx("5a7a2a"), "flesh2": hx("3d5420"), "glow": hx("aaff00"),
        "limbs": 2, "eyes": 4, "r": 0.30, "limb_len": 0.24, "spout": True}
HOST = {"flesh": hx("5e4a6a"), "flesh2": hx("3e2e48"), "glow": hx("ff3355"),
        "limbs": 7, "eyes": 6, "r": 0.38, "limb_len": 0.42, "spikes": True}
DRONE_S = {"armor": hx("363642"), "glow": hx("ff5522")}
TURR_S = {"armor": hx("383846"), "glow": hx("ff2222")}
# NPCs
RHASA = {"armor": hx("3a3428"), "armor2": hx("26221a"), "trim": hx("a8842f"),
         "glow": hx("ffb74d"), "cloak": hx("5c2e22"), "helm": "bare",
         "weapon": "sword", "bulk": 1.3, "skin": hx("8a5a3a"), "beard": True}
NEVA = {"armor": hx("241a30"), "armor2": hx("181020"), "trim": hx("7B1FA2"),
        "glow": hx("c26bff"), "cloak": hx("241a30"), "helm": "hood",
        "weapon": "none", "bulk": 0.8, "tabard": hx("241a30"), "tabard_long": True}
SAPH = {"armor": hx("4a3020"), "armor2": hx("2e1e12"), "trim": hx("d0a040"),
        "glow": hx("00E676"), "cloak": hx("4a3020"), "helm": "hood",
        "weapon": "staff", "bulk": 0.9, "tabard": hx("4a3020"), "tabard_long": True}
VANE = {"armor": hx("c8ccd4"), "armor2": hx("9aa0ac"), "trim": hx("3a7a3a"),
        "glow": hx("00E5FF"), "cloak": hx("c8ccd4"), "helm": "bare",
        "weapon": "none", "bulk": 0.9, "skin": hx("caa27a"), "tabard": hx("c8ccd4")}


# ---------------------------------------------------------------- anim sets
def ely_frames():
    F = {}
    F["idle"] = [render_humanoid(ELY, pose(), 190),
                 render_humanoid(ELY, pose(twist=0.015, cloak=0.1), 190),
                 render_humanoid(ELY, pose(twist=-0.01, cloak=-0.05, crouch=0.02), 190)]
    F["run"] = [
        render_humanoid(ELY, pose(l_leg=(0.09, 0.06), r_leg=(-0.09, -0.01), lean=0.06, cloak=0.55, crouch=0.04,
                                  l_arm=((-0.05, 0.66), (-0.02, 0.55)), blade_ang=55), 190),
        render_humanoid(ELY, pose(lean=0.04, cloak=0.4, crouch=0.06), 190),
        render_humanoid(ELY, pose(l_leg=(-0.09, -0.01), r_leg=(0.09, 0.06), lean=0.06, cloak=0.55, crouch=0.04,
                                  l_arm=((-0.28, 0.60), (-0.30, 0.48)), blade_ang=70), 190),
        render_humanoid(ELY, pose(lean=0.05, cloak=0.45, crouch=0.03), 190)]
    # atk1: horizontal cut — windup back / strike through / recover
    F["atk1"] = [
        render_humanoid(ELY, pose(twist=-0.35, crouch=0.05, cloak=-0.3, blade_ang=150,
                                  r_arm=((0.30, 0.85), (0.34, 0.72))), 190),
        render_humanoid(ELY, pose(twist=0.30, lean=0.10, crouch=0.03, cloak=0.7, blade_ang=-15,
                                  r_arm=((0.24, 0.66), (0.36, 0.60)),
                                  arc=((0.02, 0.62), 0.18, 0.52, math.radians(200), math.radians(-30))), 190),
        render_humanoid(ELY, pose(twist=0.12, blade_ang=-60, cloak=0.3,
                                  r_arm=((0.22, 0.60), (0.28, 0.44))), 190)]
    # atk2: backhand return
    F["atk2"] = [
        render_humanoid(ELY, pose(twist=0.35, crouch=0.05, cloak=0.4, blade_ang=-30,
                                  r_arm=((0.05, 0.70), (-0.02, 0.66))), 190),
        render_humanoid(ELY, pose(twist=-0.30, lean=0.10, crouch=0.03, cloak=-0.5, blade_ang=195,
                                  r_arm=((0.30, 0.72), (0.38, 0.68)),
                                  arc=((0.02, 0.62), 0.18, 0.52, math.radians(-20), math.radians(210))), 190),
        render_humanoid(ELY, pose(twist=-0.1, blade_ang=95, cloak=0.2,
                                  r_arm=((0.24, 0.68), (0.30, 0.55))), 190)]
    # atk3: overhead heavy
    F["atk3"] = [
        render_humanoid(ELY, pose(twist=-0.15, crouch=0.02, blade_ang=115, cloak=-0.4,
                                  r_arm=((0.26, 0.92), (0.30, 1.0))), 190),
        render_humanoid(ELY, pose(lean=0.16, crouch=0.14, cloak=0.8, blade_ang=-95,
                                  r_arm=((0.20, 0.62), (0.24, 0.40)),
                                  arc=((0.04, 0.60), 0.16, 0.55, math.radians(120), math.radians(-80))), 190),
        render_humanoid(ELY, pose(crouch=0.08, blade_ang=-40, cloak=0.4,
                                  r_arm=((0.22, 0.60), (0.26, 0.42))), 190)]
    F["dash"] = [render_humanoid(ELY, pose(lean=0.30, crouch=0.10, cloak=1.2,
                                         l_leg=(-0.10, 0.05), r_leg=(0.12, 0.10), blade_ang=15,
                                         r_arm=((0.26, 0.70), (0.34, 0.62))), 190),
                 render_humanoid(ELY, pose(lean=0.22, crouch=0.08, cloak=0.9,
                                         l_leg=(-0.06, 0.03), r_leg=(0.09, 0.07), blade_ang=25), 190)]
    F["parry"] = [render_humanoid(ELY, pose(crouch=0.10, blade_ang=92, cloak=0.2,
                                          r_arm=((0.16, 0.72), (0.10, 0.62)),
                                          l_arm=((-0.10, 0.70), (-0.04, 0.60))), 190)]
    F["charge"] = [render_humanoid(ELY, pose(lean=0.08, cloak=0.3, blade_ang=75,
                                           r_arm=((0.28, 0.74), (0.40, 0.70))), 190)]
    F["hurt"] = [render_humanoid(ELY, pose(twist=-0.2, lean=-0.12, cloak=-0.4, blade_ang=120), 190)]
    kneel = render_humanoid(ELY, pose(crouch=0.35, twist=0.2, cloak=0.1, blade_ang=30), 190)
    fallen = kneel.rotate(78, expand=False, resample=Image.BICUBIC)
    fallen = Image.eval(fallen, lambda v: int(v * 0.7))
    F["die"] = [kneel, fallen]
    F["windup"] = F["atk1"][:1]
    F["strike"] = F["atk1"][1:2]
    F["p2"] = [render_humanoid(dict(ELY, glow=hx("ff3355"), trim=hx("8B0000")), pose(hurt=0), 190)]
    return F


def humanoid_enemy_frames(spec, height):
    """Generic armed humanoid: idle/windup/strike/hurt/die."""
    return {
        "idle": [render_humanoid(spec, pose(crouch=0.06, twist=0.05, blade_ang=70), height),
                 render_humanoid(spec, pose(crouch=0.09, twist=0.07, blade_ang=66), height)],
        "windup": [render_humanoid(spec, pose(twist=-0.3, crouch=0.14, blade_ang=140,
                                              r_arm=((0.28, 0.80), (0.32, 0.70))), height)],
        "strike": [render_humanoid(spec, pose(twist=0.3, lean=0.14, crouch=0.08, blade_ang=-20,
                                              r_arm=((0.26, 0.62), (0.38, 0.56)),
                                              arc=((0.02, 0.60), 0.16, 0.5, math.radians(190), math.radians(-20))), height),
                   render_humanoid(spec, pose(twist=0.15, blade_ang=-55,
                                              r_arm=((0.22, 0.58), (0.28, 0.42))), height)],
        "hurt": [render_humanoid(spec, pose(twist=-0.2, lean=-0.1, blade_ang=110), height)],
        "die": [render_humanoid(spec, pose(crouch=0.4, twist=0.2, blade_ang=20), height)],
        "atk": [render_humanoid(spec, pose(twist=0.3, lean=0.14, crouch=0.08, blade_ang=-20,
                                           r_arm=((0.26, 0.62), (0.38, 0.56)),
                                           arc=((0.02, 0.60), 0.16, 0.5, math.radians(190), math.radians(-20))), height)],
    }


def organic_frames(spec, height):
    return {
        "idle": [render_organic(spec, {"squash": 1.0}, height),
                 render_organic(spec, {"squash": 0.92, "sway": 1}, height)],
        "windup": [render_organic(spec, {"squash": 0.8, "gaze": 1.4, "sway": -1, "maw": 0.5}, height)],
        "strike": [render_organic(spec, {"squash": 1.15, "lunge": 5, "gaze": 1.4, "maw": 2}, height)],
        "hurt": [render_organic(spec, {"squash": 0.9, "sway": -2}, height)],
        "die": [render_organic(spec, {"squash": 0.55, "cy": 0.3}, height)],
        "atk": [render_organic(spec, {"squash": 1.15, "lunge": 5, "gaze": 1.4, "maw": 2}, height)],
        "p2": [render_organic(dict(spec, glow=(255, 120, 90)), {"squash": 1.05, "gaze": 1.4, "maw": 2}, height)],
    }


def husk_frames(spec, height):
    return {
        "idle": [render_husk(spec, {"squash": 1.0}, height),
                 render_husk(spec, {"squash": 0.95, "sway": 1.5}, height)],
        "windup": [render_husk(spec, {"squash": 0.85, "gaze": 1.4, "sway": -1.5, "lunge": 1}, height)],
        "strike": [render_husk(spec, {"squash": 1.08, "lunge": 5, "gaze": 1.4, "maw": 1}, height)],
        "hurt": [render_husk(spec, {"squash": 0.92, "sway": -2.5}, height)],
        "die": [render_husk(spec, {"squash": 0.6, "sway": 3, "lunge": -2}, height)],
        "atk": [render_husk(spec, {"squash": 1.08, "lunge": 5, "gaze": 1.4, "maw": 1}, height)],
        "p2": [render_husk(dict(spec, glow=(255, 120, 90)), {"squash": 1.05, "gaze": 1.4, "maw": 2}, height)],
    }


def npc_pair(spec, height):
    a = render_humanoid(spec, pose(), height)
    b = render_humanoid(spec, pose(twist=0.02, cloak=0.12), height)
    return a, b


# ---------------------------------------------------------------- painted vistas
def ridge(w, base, amp, seed, rough=0.012):
    r = np.random.default_rng(seed)
    ph = r.uniform(0, 9, 5)
    xs = np.linspace(0, w, w)
    y = base - (np.sin(xs*rough + ph[0])*amp*0.55
                + np.sin(xs*rough*2.7 + ph[1])*amp*0.28
                + np.sin(xs*rough*6.1 + ph[2])*amp*0.17)
    return y


def paint_vista(key, kind, w=1280, h=560):
    """Original painted backdrop: sky gradient + fractal ridges + haze + glows."""
    P = {
        "hub":  {"top": (26, 18, 24), "mid": (96, 54, 34), "hor": (190, 110, 52),
                 "ridges": [(58, 40, 34), (40, 28, 26), (26, 18, 18)],
                 "glow": (255, 140, 50), "glows": 7, "spires": False, "hang": False, "stars": 40},
        "0":    {"top": (30, 20, 22), "mid": (104, 58, 34), "hor": (200, 120, 55),
                 "ridges": [(62, 42, 34), (44, 30, 26), (28, 20, 18)],
                 "glow": (255, 120, 40), "glows": 5, "spires": False, "hang": False, "stars": 30},
        "1":    {"top": (10, 14, 20), "mid": (18, 42, 48), "hor": (40, 90, 92),
                 "ridges": [(26, 52, 58), (18, 36, 44), (12, 24, 32)],
                 "glow": (0, 229, 255), "glows": 9, "spires": False, "hang": True, "stars": 20},
        "2":    {"top": (20, 12, 14), "mid": (70, 30, 24), "hor": (140, 62, 36),
                 "ridges": [(54, 30, 26), (38, 22, 20), (24, 15, 14)],
                 "glow": (255, 90, 40), "glows": 6, "spires": False, "hang": False, "stars": 60},
        "3":    {"top": (14, 10, 24), "mid": (38, 24, 56), "hor": (90, 60, 110),
                 "ridges": [(40, 28, 60), (28, 20, 44), (18, 13, 30)],
                 "glow": (201, 162, 39), "glows": 8, "spires": True, "hang": False, "stars": 80},
    }[kind]
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    # sky gradient 3-stop
    for y in range(h):
        t = y / h
        if t < 0.55:
            c = mix(P["top"], P["mid"], t / 0.55)
        else:
            c = mix(P["mid"], P["hor"], (t - 0.55) / 0.45)
        d.line([(0, y), (w, y)], fill=rgba(c))
    # stars
    r = np.random.default_rng((int(kind) if kind.isdigit() else 40) + 11)
    for _ in range(P["stars"]):
        x, y = int(r.uniform(0, w)), int(r.uniform(0, h * 0.5))
        a = int(r.uniform(60, 190))
        d.point((x, y), fill=(230, 230, 240, a))
    # ridges far->near
    bases = [0.52, 0.66, 0.80]
    for li, col in enumerate(P["ridges"]):
        y = ridge(w, h * bases[li], h * (0.16 + li * 0.05), 100 + li * 7 + (int(kind) if kind.isdigit() else 40))
        pts = [(0, h)] + [(x, y[x]) for x in range(w)] + [(w - 1, h)]
        d.polygon(pts, fill=rgba(col))
        # haze band above ridge — composited layer (ImageDraw replaces, not blends)
        hz = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        hd = ImageDraw.Draw(hz)
        ymin = int(y.min())
        for k in range(16):
            ya = ymin - k * 4
            if ya > 0:
                hd.line([(0, ya), (w, ya)], fill=rgba(P["hor"], max(0, 26 - k * 3)))
        img.alpha_composite(hz)
    # spires (Aeterna towers)
    if P["spires"]:
        for i in range(9):
            x = int(r.uniform(40, w - 40)); tw = int(r.uniform(10, 26))
            top = int(r.uniform(h * 0.2, h * 0.55)); basey = int(h * 0.8)
            d.polygon([(x - tw, basey), (x + tw, basey), (x, top)], fill=rgba(sh(P["ridges"][2], 0.9)))
            for wy in range(top + 12, basey - 8, 16):
                if r.uniform(0, 1) < 0.4:
                    d.point((x + int(r.uniform(-tw * 0.4, tw * 0.4)), wy), fill=rgba(P["glow"], 200))
    # hanging stalactites (Simithar)
    if P["hang"]:
        for i in range(16):
            x = int(r.uniform(0, w)); ln = int(r.uniform(30, 120)); tw = int(r.uniform(8, 22))
            d.polygon([(x - tw, 0), (x + tw, 0), (x, ln)], fill=rgba(sh(P["ridges"][0], 0.8)))
    # glow fires / crystals on near ground
    for i in range(P["glows"]):
        gx = int(r.uniform(60, w - 60)); gy = int(r.uniform(h * 0.72, h * 0.94))
        gr = int(r.uniform(14, 46))
        gl = Image.new("RGBA", (gr * 4, gr * 4), (0, 0, 0, 0))
        gd = ImageDraw.Draw(gl)
        for rr in range(gr, 0, -2):
            gd.ellipse([gr * 2 - rr, gr * 2 - rr, gr * 2 + rr, gr * 2 + rr],
                       fill=rgba(P["glow"], int(70 * (1 - rr / gr) + 14)))
        img.alpha_composite(gl, (gx - gr * 2, gy - gr * 2))
        d.ellipse([gx - 3, gy - 2, gx + 3, gy + 2], fill=rgba(mix(P["glow"], (255, 255, 255), 0.6)))
    # vignette + noise
    a = np.asarray(img).astype(np.float32)
    yy, xx = np.mgrid[0:h, 0:w]
    vig = 1.0 - 0.35 * np.clip(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2, 0, 1)
    a[..., :3] *= vig[..., None]
    a[..., :3] += rng.normal(0, 3, a[..., :3].shape)
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    emit_sprite(key, img)


def paint_fx():
    """Slash crescent + hit spark + soft light disc."""
    # slash arc: crescent with hot outer rim, soft inner falloff
    s = 192
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    px = im.load()
    cx = cy = s / 2
    for y in range(s):
        for x in range(s):
            dx, dy = x - cx, y - cy
            r = math.hypot(dx, dy) / (s / 2)
            if r > 1 or r < 0.30:
                continue
            a = math.atan2(dy, dx)
            # crescent: bright at outer edge + along sweep direction
            body = 1.0 - (r - 0.30) / 0.7
            rim = max(0.0, (r - 0.78) / 0.22)
            al = int(255 * (body * 0.55 + rim * 0.9) * (0.55 + 0.45 * math.cos(a)))
            if al > 0:
                px[x, y] = (255, 255, 255, min(255, al))
    im = im.filter(ImageFilter.GaussianBlur(2))
    emit_sprite("slash_arc", im)
    # spark: 8-point starburst
    s2 = 64
    im2 = Image.new("RGBA", (s2, s2), (0, 0, 0, 0))
    d2 = ImageDraw.Draw(im2)
    c2 = s2 / 2
    for i in range(8):
        a = i * math.pi / 4
        for rr in range(4, 30):
            w2 = max(1, int(4 * (1 - rr / 30)))
            x = c2 + math.cos(a) * rr
            y = c2 + math.sin(a) * rr
            d2.ellipse([x - w2, y - w2, x + w2, y + w2], fill=(255, 255, 255, 220))
    d2.ellipse([c2 - 8, c2 - 8, c2 + 8, c2 + 8], fill=(255, 255, 255, 255))
    im2 = im2.filter(ImageFilter.GaussianBlur(0.8))
    emit_sprite("spark", im2)
    # resonance gate: dark obsidian arch + purple energy core
    g = Image.new("RGBA", (120, 140), (0, 0, 0, 0))
    gd = ImageDraw.Draw(g)
    # pillars
    for sx in (0, 1):
        x0 = 8 + sx * 88
        gd.rectangle([x0, 10, x0 + 24, 130], fill=rgba(hx("2a2530")))
        gd.rectangle([x0 + 3, 14, x0 + 8, 126], fill=rgba(hx("3a3442")))
        gd.rectangle([x0, 4, x0 + 24, 14], fill=rgba(hx("1a1620")))
    gd.rectangle([8, 118, 112, 132], fill=rgba(hx("1f1a26")))
    # energy core
    core = Image.new("RGBA", (120, 140), (0, 0, 0, 0))
    cd = ImageDraw.Draw(core)
    for rr in range(46, 6, -4):
        a2 = int(10 + (46 - rr) * 2.2)
        cd.ellipse([60 - rr, 66 - rr, 60 + rr, 66 + rr], fill=(123, 31, 162, min(255, a2)))
    for i in range(9):
        a3 = i * 0.7
        x = 60 + math.cos(a3) * (14 + i * 3)
        y = 66 + math.sin(a3) * (14 + i * 3)
        cd.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(200, 120, 255, 200))
    cd.ellipse([52, 58, 68, 74], fill=(230, 190, 255, 235))
    g.alpha_composite(core.filter(ImageFilter.GaussianBlur(1.5)))
    emit_sprite("portal", g)
    emit_sprite("gate2", g)
    # soft radial light disc
    s3 = 128
    im3 = Image.new("RGBA", (s3, s3), (0, 0, 0, 0))
    p3 = im3.load()
    for y in range(s3):
        for x in range(s3):
            r = math.hypot(x - s3 / 2, y - s3 / 2) / (s3 / 2)
            if r < 1:
                p3[x, y] = (255, 255, 255, int(255 * max(0.0, 1 - r) ** 2))
    emit_sprite("light", im3)


# ---------------------------------------------------------------- emit
SPRITES = {}
FRAMES = {}


def emit_frames(key, frames):
    FRAMES[key] = {}
    for anim, imgs in frames.items():
        FRAMES[key][anim] = []
        for i, im in enumerate(imgs):
            name = "p_%s_%s_%d.png" % (key, anim, i)
            im.save(os.path.join(ART, name))
            FRAMES[key][anim].append("art/" + name)
        FRAMES[key][anim] = FRAMES[key][anim]


def emit_sprite(key, im):
    name = "p_%s.png" % key
    im.save(os.path.join(ART, name))
    SPRITES[key] = "art/" + name


def portrait(im, key):
    """Bust crop: top ~55% of the figure, squared."""
    w, h = im.size
    crop = im.crop((int(w*0.18), 0, int(w*0.82), int(h*0.55)))
    side = max(crop.size)
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.paste(crop, ((side-crop.size[0])//2, (side-crop.size[1])//2))
    sq = sq.resize((96, 96), Image.LANCZOS)
    emit_sprite(key, sq)


def main():
    # ---- Ely (player)
    ef = ely_frames()
    emit_frames("ely", ef)
    portrait(ef["idle"][0], "por_ely")

    # ---- enemies
    for key, spec, hgt in (("sentinel", SENT, 150),):
        fr = humanoid_enemy_frames(spec, hgt)
        emit_frames(key, fr)
        portrait(fr["idle"][0], "por_" + key)
    fr = husk_frames(HUSK, 120)
    emit_frames("husk", fr)
    portrait(fr["idle"][0], "por_husk")
    for key, spec, hgt in (("spitter", SPIT, 115), ("host", HOST, 210)):
        fr = organic_frames(spec, hgt)
        emit_frames(key, fr)
        portrait(fr["idle"][0], "por_" + key)
    emit_frames("drone", {
        "idle": [render_drone(DRONE_S, {"bob": 0.02}, 80), render_drone(DRONE_S, {"bob": -0.02, "rot": 0.03}, 80)],
        "windup": [render_drone(DRONE_S, {"hot": 0.6}, 80)],
        "strike": [render_drone(DRONE_S, {"hot": 1.0}, 80)],
        "hurt": [render_drone(DRONE_S, {"hot": 0.4, "bob": -0.05}, 80)],
        "die": [render_drone(DRONE_S, {"hot": 0.2, "bob": -0.3}, 80)],
        "atk": [render_drone(DRONE_S, {"hot": 1.0}, 80)],
    })
    emit_frames("turret", {
        "idle": [render_turret(TURR_S, {"hot": 0.0}, 110), render_turret(TURR_S, {"hot": 0.1}, 110)],
        "windup": [render_turret(TURR_S, {"hot": 0.6}, 110)],
        "strike": [render_turret(TURR_S, {"hot": 1.0}, 110)],
        "hurt": [render_turret(TURR_S, {"hot": 0.3}, 110)],
        "die": [render_turret(TURR_S, {"hot": 0.0}, 110)],
        "atk": [render_turret(TURR_S, {"hot": 1.0}, 110)],
    })

    # ---- bosses (idle/atk/p2)
    for key, spec, hgt in (("rex", REX, 220), ("nahum", NAHUM, 185), ("tuman", TUMAN, 180),
                            ("kirin", KIRIN, 180), ("const", CONST, 190)):
        fr = humanoid_enemy_frames(spec, hgt)
        p2spec = REX2 if key == "rex" else dict(spec, glow=mix(spec["glow"], (255, 60, 60), 0.5))
        fr["p2"] = [render_humanoid(p2spec, pose(crouch=0.08, twist=-0.15, blade_ang=100), hgt)]
        emit_frames(key, fr)
        portrait(fr["idle"][0], "por_" + key)

    # ---- NPCs (two-frame idle pairs under npc2_/npcb_)
    for nid, spec, hgt in (("rhasa", RHASA, 170), ("neva", NEVA, 150),
                            ("saphire", SAPH, 160), ("vane", VANE, 160)):
        a, b = npc_pair(spec, hgt)
        emit_sprite("npc2_" + nid, a)
        emit_sprite("npcb_" + nid, b)
        portrait(a, "por_" + nid)

    # ---- painted vistas (room backdrop + cinematic cards + title)
    paint_vista("cbv_hub", "hub")
    paint_vista("cbg_hub", "hub")
    paint_vista("bg_hub", "hub")
    paint_vista("title_bg", "0", w=1280, h=720)
    for b in ("0", "1", "2", "3"):
        paint_vista("cbv_%s_0" % b, b)
        paint_vista("cbg_%s_0" % b, b)
        paint_vista("bg_%s" % b, b)
        paint_vista("cine_%s_0" % b, b, w=1280, h=720)

    # ---- fx sprites
    paint_fx()

    # ---- manifest
    out = ["class_name PaintManifest\nextends RefCounted\n\n",
           "const SPRITES := ", json.dumps(SPRITES, indent=1), "\n\n",
           "const FRAMES := ", json.dumps(FRAMES, indent=1), "\n"]
    man = "".join(out)
    with open(os.path.join(ROOT, "src", "paint_manifest.gd"), "w", encoding="utf-8") as fh:
        fh.write(man)
    print("DONE %d sprites, %d frame sets" % (len(SPRITES), len(FRAMES)))


if __name__ == "__main__":
    main()
