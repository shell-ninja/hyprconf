#!/usr/bin/env python3
"""
wallfx.py — Transition maps generator for Quickshell WallpaperFx.

Generates:
  CONTAGION (any wallpaper / landscape):
    A handful of colonies land at random places and eat through the old wallpaper
    along a noise field, with ragged, crisp 4px edges.
  OUTLINE (wallpapers with a character):
    The character is cut out of the new wallpaper (BiRefNet if installed, or fast
    YuNet + GrabCut), generating signed distance maps and pen-stroke contour lines.
    The old wallpaper dims to B&W, the outline is drawn like pen strokes, the character
    fills in, and the rest spreads outward from the character.

Usage:
  wallfx.py elige <IMG>   -> prints "perfil <campo.png> <linea.png>" or "contagio <map> <smooth>"
  wallfx.py spread        -> prints "<map> <smooth>"
  wallfx.py perfil <IMG>  -> prints "<campo.png> <linea.png>"
"""

import hashlib
import json
import os
import random
import sys
from pathlib import Path

HOME = os.path.expanduser("~")
CACHE = os.path.join(HOME, ".cache", "wallfx")
POOL = 12

def _key_fast(img_path):
    try:
        st = os.stat(img_path)
        return hashlib.sha1(f"{os.path.realpath(img_path)}|{st.st_size}|{int(st.st_mtime)}".encode()).hexdigest()[:16]
    except Exception:
        return None

def _fast_spread():
    d = os.path.join(CACHE, "spread")
    if os.path.isdir(d):
        k = random.randrange(POOL)
        path = os.path.join(d, f"spread-{k}.png")
        liso = os.path.join(d, f"spread-{k}-liso.png")
        if os.path.exists(path) and os.path.exists(liso):
            return path, liso
    return None

def _fast_cache_lookup(img_path):
    if not os.path.isfile(img_path):
        return None
    k = _key_fast(img_path)
    if not k:
        return None
    base = os.path.join(CACHE, "perfil", k)
    meta_p = base + ".json"
    campo_p = base + "-campo.png"
    linea_p = base + "-linea.png"
    if os.path.exists(meta_p):
        try:
            with open(meta_p, "r", encoding="utf-8") as f:
                meta = json.load(f)
            if meta.get("ok"):
                if os.path.exists(campo_p) and os.path.exists(linea_p):
                    return "perfil", campo_p, linea_p
            elif meta.get("ok") is False:
                sp = _fast_spread()
                if sp:
                    return "contagio", sp[0], sp[1]
        except Exception:
            pass
    return None

# ZERO-IMPORT FAST PATH: return in <10ms for cached wallpapers without heavy module imports
if len(sys.argv) >= 2:
    cmd = sys.argv[1]
    if cmd == "elige" and len(sys.argv) >= 3:
        fast_res = _fast_cache_lookup(sys.argv[2])
        if fast_res is not None:
            print(f"{fast_res[0]} {fast_res[1]} {fast_res[2]}")
            sys.exit(0)
    elif cmd == "spread":
        sp = _fast_spread()
        if sp is not None:
            print(f"{sp[0]} {sp[1]}")
            sys.exit(0)

# Uncached heavy path: re-exec into dedicated venv if available
VENV_PY = Path.home() / ".local" / "share" / "hyprconf" / "venv" / "bin" / "python3"
if sys.executable != str(VENV_PY) and VENV_PY.exists():
    try:
        os.execv(str(VENV_PY), [str(VENV_PY), os.path.abspath(__file__), *sys.argv[1:]])
    except Exception:
        pass

# Suppress OpenCV C++ backend logging before import
os.environ.setdefault("OPENCV_LOG_LEVEL", "OFF")
os.environ.setdefault("OPENCV_FFMPEG_LOGLEVEL", "-8")

import heapq
import importlib

HAS_CV2 = False
cv2 = None
np = None
try:
    cv2 = importlib.import_module("cv2")
    np = importlib.import_module("numpy")
    from PIL import Image
    HAS_CV2 = True
except Exception:
    HAS_CV2 = False
    try:
        from PIL import Image
    except Exception:
        sys.exit(1)

MODEL_PATH = os.path.join(HOME, ".hyprconf", "hypr", "scripts", "models", "face_detection_yunet.onnx")

GW, GH = 240, 135
FIELD_MAX = 1280
SD_RANGE = 16.0
WIDE = 48.0


# ───────────────────────────── contagion ─────────────────────────────

def _value_noise(rng, w, h, scale):
    nx, ny = int(w / scale) + 3, int(h / scale) + 3
    lat = rng.random((ny, nx))
    xs = np.arange(w) / scale
    ys = np.arange(h) / scale
    ix, iy = xs.astype(int), ys.astype(int)
    fx, fy = xs - ix, ys - iy
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    top = lat[iy][:, ix] * (1 - fx) + lat[iy][:, ix + 1] * fx
    bot = lat[iy + 1][:, ix] * (1 - fx) + lat[iy + 1][:, ix + 1] * fx
    return top * (1 - fy)[:, None] + bot * fy[:, None]


def _blur(a, sigma):
    r = int(3 * sigma) + 1
    x = np.arange(-r, r + 1)
    k = np.exp(-x * x / (2.0 * sigma * sigma))
    k /= k.sum()
    a = np.pad(a, r, mode="edge")
    a = sum(k[i] * a[:, i:i + a.shape[1] - 2 * r] for i in range(2 * r + 1))
    a = sum(k[i] * a[i:i + a.shape[0] - 2 * r, :] for i in range(2 * r + 1))
    return a


def _rgb16(v, extra=None):
    q = np.clip(v * 65535.0 + 0.5, 0, 65535).astype(np.uint16)
    rgb = np.zeros(v.shape + (3,), np.uint8)
    if extra is not None:
        rgb[..., 0] = extra
    rgb[..., 1] = q >> 8
    rgb[..., 2] = q & 255
    return rgb


_STEPS = [(-1, 0, 1.0), (1, 0, 1.0), (0, -1, 1.0), (0, 1, 1.0),
          (-1, -1, 1.4142), (1, -1, 1.4142), (-1, 1, 1.4142), (1, 1, 1.4142)]


def _arrival(cost, seeds, w=GW, h=GH):
    INF = float("inf")
    arrival = [INF] * (w * h)
    heap = []
    for i, t0 in seeds:
        arrival[i] = t0
        heap.append((t0, i))
    heapq.heapify(heap)
    while heap:
        t, i = heapq.heappop(heap)
        if t != arrival[i]:
            continue
        x, y = i % w, i // w
        ci = cost[i]
        for dx, dy, d in _STEPS:
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h:
                j = ny * w + nx
                cand = t + (ci + cost[j]) * 0.5 * d
                if cand < arrival[j]:
                    arrival[j] = cand
                    heapq.heappush(heap, (cand, j))
    return arrival


def _ranked(arrival, shape=(GH, GW)):
    a = np.array(arrival)
    rank = np.empty(a.size)
    rank[np.argsort(a, kind="stable")] = np.arange(a.size)
    return (rank / (a.size - 1) * 65535).astype(np.uint16).reshape(shape)


def contagion_map(seed):
    w, h = GW * 2, GH * 2
    rng = np.random.default_rng(seed)
    n = (0.52 * _value_noise(rng, w, h, rng.uniform(18, 65))
         + 0.30 * _value_noise(rng, w, h, rng.uniform(7, 20))
         + 0.18 * _value_noise(rng, w, h, rng.uniform(2, 6)))
    cost = 0.12 + np.exp(rng.uniform(5, 9) * (n - 0.5)) + rng.uniform(0.15, 0.65) * rng.random((h, w))
    cost = cost.ravel().tolist()
    seeds = []
    for _ in range(int(rng.integers(6, 13))):
        x, y = int(rng.uniform(0.06, 0.94) * w), int(rng.uniform(0.08, 0.92) * h)
        seeds.append((y * w + x, float(rng.uniform(0, (w * h) ** 0.5 * 0.12))))
    return _ranked(_arrival(cost, seeds, w, h), (h, w))


def _write_pair(path, liso, a):
    h, w = a.shape
    rgb = np.zeros((h, w, 3), np.uint8)
    rgb[..., 0] = a >> 8
    rgb[..., 1] = a & 255
    smooth = _blur(a.astype(np.float64) / 65535.0, 2.5)
    for dest, arr in ((path, rgb), (liso, _rgb16(smooth))):
        tmp = f"{dest}.{os.getpid()}.tmp.png"
        Image.fromarray(arr, "RGB").save(tmp)
        os.replace(tmp, dest)


def spread():
    d = os.path.join(CACHE, "spread")
    os.makedirs(d, exist_ok=True)
    k = random.randrange(POOL)
    path = os.path.join(d, f"spread-{k}.png")
    liso = os.path.join(d, f"spread-{k}-liso.png")
    if not (os.path.exists(path) and os.path.exists(liso)):
        _write_pair(path, liso, contagion_map(random.randrange(1 << 30)))
    return path, liso


def renew(path):
    import time
    time.sleep(3)
    k = os.path.basename(path).split("-")[1].split(".")[0]
    d = os.path.dirname(path)
    _write_pair(os.path.join(d, f"spread-{k}.png"), os.path.join(d, f"spread-{k}-liso.png"),
                contagion_map(random.randrange(1 << 30)))


# ───────────────────────────── outline ─────────────────────────────

def _key(img):
    st = os.stat(img)
    return hashlib.sha1(f"{os.path.realpath(img)}|{st.st_size}|{int(st.st_mtime)}".encode()).hexdigest()[:16]


_session = None


def _cutout_fast(img_path, target_size):
    """Multi-subject detector and GrabCut fallback (faces, animals, cars, objects)."""
    if not HAS_CV2:
        return None
    img = cv2.imread(img_path)
    if img is None:
        return None
    h, w = img.shape[:2]
    scale = min(1.0, 960.0 / max(h, w))
    small = cv2.resize(img, (int(w * scale), int(h * scale)))
    sh, sw = small.shape[:2]

    rect = None

    # A. Try FaceDetectorYN for human faces
    if os.path.exists(MODEL_PATH) and hasattr(cv2, "FaceDetectorYN"):
        try:
            detector = cv2.FaceDetectorYN.create(
                model=MODEL_PATH,
                config="",
                input_size=(sw, sh),
                score_threshold=0.55,
                nms_threshold=0.3
            )
            _, faces = detector.detect(small)
            if faces is not None and len(faces) > 0:
                best = max(faces, key=lambda f: (f[2] * f[3]) * f[-1])
                bx, by, bw, bh = best[:4]
                rect = (
                    int(max(2, bx - bw * 1.0)),
                    int(max(2, by - bh * 0.5)),
                    int(min(sw - 4, bw * 3.0)),
                    int(min(sh - by - 4, bh * 4.5))
                )
        except Exception:
            pass

    # B. Saliency and edge contrast bounding for animals, cars, vehicles, and objects
    if rect is None:
        try:
            gray = cv2.cvtColor(small, cv2.COLOR_BGR2GRAY)
            gx = cv2.Sobel(gray, cv2.CV_32F, 1, 0, ksize=3)
            gy = cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=3)
            mag = cv2.magnitude(gx, gy)
            mag = cv2.normalize(mag, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)

            # Center-weighted Gaussian spatial prior (focal subjects are centered)
            Y, X = np.ogrid[:sh, :sw]
            cy, cx = sh / 2.0, sw / 2.0
            dist_sq = ((X - cx) / sw)**2 + ((Y - cy) / sh)**2
            weight = np.exp(-dist_sq * 3.0)
            weighted_mag = (mag * weight).astype(np.uint8)

            blurred = cv2.GaussianBlur(weighted_mag, (25, 25), 0)
            _, thresh = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

            contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            if contours:
                valid = [c for c in contours if cv2.contourArea(c) >= 0.02 * sw * sh]
                if valid:
                    c = max(valid, key=cv2.contourArea)
                    x, y, cw, ch = cv2.boundingRect(c)
                    pad_x, pad_y = int(cw * 0.1), int(ch * 0.1)
                    rect = (
                        max(2, x - pad_x),
                        max(2, y - pad_y),
                        min(sw - 4, cw + pad_x * 2),
                        min(sh - 4, ch + pad_y * 2)
                    )
        except Exception:
            pass

    if rect is None:
        return None

    try:
        mask = np.zeros((sh, sw), np.uint8)
        bgd = np.zeros((1, 65), np.float64)
        fgd = np.zeros((1, 65), np.float64)
        cv2.grabCut(small, mask, rect, bgd, fgd, 5, cv2.GC_INIT_WITH_RECT)
        bin_mask = np.where((mask == 2) | (mask == 0), 0, 1).astype(np.uint8)
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        bin_mask = cv2.morphologyEx(bin_mask, cv2.MORPH_CLOSE, kernel)
        m_img = Image.fromarray(bin_mask * 255).resize(target_size, Image.Resampling.BILINEAR)
        return m_img
    except Exception:
        return None


_ort_session = None


def _get_ort_session():
    global _ort_session
    if _ort_session is not None:
        return _ort_session
    script_dir = os.path.dirname(os.path.abspath(__file__))
    candidates = [
        os.path.join(script_dir, "..", "models", "silueta.onnx"),
        os.path.join(HOME, ".hyprconf", "hypr", "scripts", "models", "silueta.onnx"),
        os.path.join(HOME, ".local", "share", "rembg", "models", "silueta", "silueta.onnx"),
        os.path.join(HOME, ".local", "share", "hyprconf", "models", "silueta.onnx"),
    ]
    silueta_path = next((p for p in candidates if os.path.exists(p)), None)
    if not silueta_path:
        return None
    try:
        ort = importlib.import_module("onnxruntime")
        opts = ort.SessionOptions()
        opts.intra_op_num_threads = min(4, os.cpu_count() or 4)
        opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        _ort_session = ort.InferenceSession(silueta_path, opts, providers=["CPUExecutionProvider"])
        return _ort_session
    except Exception:
        return None


def _cutout(im, img_path):
    """Blazing fast salient subject segmentation via direct ONNX (~0.6s on CPU)."""
    # 1. Direct ONNX Runtime (fast, lightweight, no rembg/numba/scipy overhead)
    sess = _get_ort_session()
    if sess is not None and HAS_CV2:
        try:
            # Fast in-memory resize to 320x320: avoids duplicate disk read
            im_320 = im.resize((320, 320), Image.BILINEAR)
            rgb_320 = np.array(im_320, dtype=np.float32) / 255.0
            blob = ((rgb_320 - [0.485, 0.456, 0.406]) / [0.229, 0.224, 0.225]).transpose(2, 0, 1)[np.newaxis, ...].astype(np.float32)

            input_name = sess.get_inputs()[0].name
            pred = sess.run(None, {input_name: blob})[0][0, 0]
            if float(pred.max()) >= 0.35:
                tw, th = im.size
                mask_resized = cv2.resize((np.clip(pred, 0, 1) * 255.0).astype(np.uint8), (tw, th), interpolation=cv2.INTER_LINEAR)
                return Image.fromarray(mask_resized, "L")
            else:
                # Direct ONNX evaluated and determined no salient subject exists.
                # Cleanly route to contagio rather than falling back to GrabCut edge bounding.
                return None
        except Exception:
            pass

    # 2. Multi-subject saliency + GrabCut fallback (only used if ONNX runtime is unavailable)
    m = _cutout_fast(img_path, im.size)
    if m is not None:
        return m
    return None


def _fill_holes(mask):
    """Fills enclosed interior holes in binary mask using OpenCV only (zero scipy dependency)."""
    if not HAS_CV2 or mask is None:
        return mask
    contours, _ = cv2.findContours(mask.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    filled = np.zeros_like(mask)
    cv2.drawContours(filled, contours, -1, 1, cv2.FILLED)
    return filled


def perfil(img, force=False):
    if not HAS_CV2:
        return None
    d = os.path.join(CACHE, "perfil")
    os.makedirs(d, exist_ok=True)
    base = os.path.join(d, _key(img))
    meta_path = base + ".json"
    campo_path = base + "-campo.png"
    linea_path = base + "-linea.png"
    if not force and os.path.exists(meta_path) and os.path.exists(campo_path) and os.path.exists(linea_path):
        try:
            meta = json.load(open(meta_path))
            if meta.get("ok"):
                return campo_path, linea_path
        except Exception:
            pass

    im = Image.open(img).convert("RGB")
    im.thumbnail((FIELD_MAX, FIELD_MAX))

    mask_path = base + "-mascara.png"
    mask = None
    if not force and os.path.exists(mask_path):
        try:
            m_cand = Image.open(mask_path).convert("L")
            if np.asarray(m_cand).max() > 0:
                mask = m_cand
        except Exception:
            pass

    if mask is None:
        raw_mask = _cutout(im, img)
        if raw_mask is None:
            json.dump({"img": img, "ok": False}, open(meta_path, "w"))
            return None
        mask = raw_mask.convert("L")
        try:
            mask_arr = np.asarray(mask, dtype=np.uint8)
            cv2.imwrite(mask_path, mask_arr, [cv2.IMWRITE_PNG_COMPRESSION, 1])
        except Exception:
            mask.save(mask_path)

    m = np.asarray(mask.resize(im.size), np.float32) / 255.0
    h, w = m.shape
    b = (m > 0.5).astype(np.uint8)

    # Fill enclosed holes before filtering so cavities within subjects aren't treated as voids
    b = _fill_holes(b)

    # Filter specks of foreground
    n, lab, stats, _ = cv2.connectedComponentsWithStats(b, connectivity=8)
    keep = np.zeros(n, bool)
    keep[1:] = stats[1:, cv2.CC_STAT_AREA] >= 0.001 * w * h
    b = keep[lab].astype(np.uint8)

    # Fill again after speck filtering to ensure solid silhouette
    b = _fill_holes(b)

    cover = float(b.mean())
    unsure = float(((m > 0.1) & (m < 0.9)).mean())

    ok = 0.012 <= cover <= 0.82 and unsure <= 0.30
    meta = {"img": img, "ok": ok, "cover": round(cover, 3), "w": w, "h": h}
    if not ok:
        json.dump(meta, open(meta_path, "w"))
        return None

    din = cv2.distanceTransform(b, cv2.DIST_L2, 5)
    dout = cv2.distanceTransform(1 - b, cv2.DIST_L2, 5)
    sd = cv2.GaussianBlur(dout - din, (5, 5), 1.0)

    inner_max = np.percentile(din[b > 0], 99) if np.any(b > 0) else 1.0
    inner = np.clip(din / max(inner_max, 1.0), 0, 1)

    rng = np.random.default_rng(int(_key(img)[:8], 16))
    noise = (0.6 * _value_noise(rng, w, h, w / 9.0) + 0.4 * _value_noise(rng, w, h, w / 28.0))
    warped = dout * (0.75 + 0.5 * noise) + noise * 0.08 * max(w, h)
    outside = b == 0
    order = np.zeros((h, w), np.float32)
    vals = warped[outside]
    r = np.empty(vals.size)
    r[np.argsort(vals, kind="stable")] = np.arange(vals.size)
    order[outside] = r / max(vals.size - 1, 1)

    # Outline contour parameters (smooth vector polyline to eliminate rough pixel staircases)
    # Using RETR_EXTERNAL ensures only outer silhouettes are traced, preventing hollow donut outlines
    edge = np.zeros((h, w), np.uint8)
    param_at = np.zeros((h, w), np.float32)
    contours, _ = cv2.findContours(b, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    for c in contours:
        if len(c) < 35 or abs(cv2.contourArea(c)) < 0.0006 * w * h:
            continue
        c_poly = cv2.approxPolyDP(c, epsilon=1.2, closed=True)
        if len(c_poly) < 4:
            continue
        pts = c_poly[:, 0, :]
        seg = np.sqrt((np.diff(pts, axis=0, append=pts[:1]) ** 2).sum(1))
        s = np.concatenate([[0], np.cumsum(seg)[:-1]])
        L = s[-1] + seg[-1]
        if L < 1e-3:
            continue
        s = (s - s[np.argmin(pts[:, 1])]) % L
        p = np.minimum(s, L - s) / (L / 2)
        p[(pts[:, 0] <= 1) | (pts[:, 0] >= w - 2) | (pts[:, 1] <= 1) | (pts[:, 1] >= h - 2)] = -1
        cv2.polylines(edge, [c_poly], isClosed=True, color=1, thickness=1)
        for idx, pt in enumerate(pts):
            param_at[pt[1], pt[0]] = p[idx]

    line = np.zeros((h, w), np.uint8)
    if edge.any():
        _, labels = cv2.distanceTransformWithLabels(1 - edge, cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
        ys, xs = np.nonzero(edge)
        table = np.concatenate([[0], param_at[ys, xs]])
        near = np.abs(sd) < SD_RANGE
        v = table[labels[near]]
        line[near] = np.where(v < 0, 0, np.clip(v * 255, 1, 255)).astype(np.uint8)

    rgb = np.zeros((h, w, 3), np.uint8)
    rgb[..., 0] = np.clip(dout / WIDE * 255, 0, 255)
    rgb[..., 1] = np.clip(inner * 255, 0, 255)
    rgb[..., 2] = np.clip((sd + SD_RANGE) / (2 * SD_RANGE) * 255, 0, 255)

    smooth = cv2.GaussianBlur(order.astype(np.float32), (0, 0), 4.0)
    linea = _rgb16(smooth, extra=line)

    for suffix, arr in (("-campo.png", rgb), ("-linea.png", linea)):
        tmp = f"{base}{suffix}.{os.getpid()}.tmp.png"
        try:
            bgr = cv2.cvtColor(arr, cv2.COLOR_RGB2BGR)
            cv2.imwrite(tmp, bgr, [cv2.IMWRITE_PNG_COMPRESSION, 1])
        except Exception:
            Image.fromarray(arr, "RGB").save(tmp)
        os.replace(tmp, base + suffix)

    json.dump(meta, open(meta_path, "w"))
    return base + "-campo.png", base + "-linea.png"


def elige(img):
    """Picks between perfil (character outline) and contagio (pixel colonies)."""
    # 1. Check if perfil is already cached and valid (instant ~0ms)
    d = os.path.join(CACHE, "perfil")
    base = os.path.join(d, _key(img))
    meta_path = base + ".json"
    campo_path = base + "-campo.png"
    linea_path = base + "-linea.png"
    if os.path.exists(meta_path) and os.path.exists(campo_path) and os.path.exists(linea_path):
        try:
            with open(meta_path, "r") as f:
                meta = json.load(f)
            if meta.get("ok"):
                return "perfil", campo_path, linea_path
        except Exception:
            pass

    # 2. Fast on-demand cutout (~0.9s via direct ONNX)
    res = perfil(img)
    if res is not None:
        return "perfil", res[0], res[1]

    # 3. If image has no character/subject, return contagio
    sp = spread()
    try:
        import subprocess
        subprocess.Popen(
            [sys.executable, os.path.abspath(__file__), "renew", sp[0]],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True
        )
    except Exception:
        pass
    return "contagio", sp[0], sp[1]


def warm(folder):
    exts = (".jpg", ".jpeg", ".png", ".webp")
    if not os.path.isdir(folder):
        return
    for name in sorted(os.listdir(folder)):
        path = os.path.join(folder, name)
        if name.lower().endswith(exts) and os.path.isfile(path):
            try:
                k = _key_fast(path)
                if k:
                    meta_p = os.path.join(CACHE, "perfil", k + ".json")
                    if os.path.exists(meta_p):
                        continue
                perfil(path)
            except Exception:
                pass


def main():
    if len(sys.argv) < 2:
        print("Usage: wallfx.py <elige|spread|perfil|warm> [IMG|DIR]", file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "elige" and len(sys.argv) >= 3:
        kind, f1, f2 = elige(sys.argv[2])
        print(f"{kind} {f1} {f2}")
    elif cmd == "spread":
        m1, m2 = spread()
        print(f"{m1} {m2}")
    elif cmd == "perfil" and len(sys.argv) >= 3:
        res = perfil(sys.argv[2])
        if res is None:
            sys.exit(1)
        print(f"{res[0]} {res[1]}")
    elif cmd == "warm":
        folder = sys.argv[2] if len(sys.argv) >= 3 else os.path.join(HOME, ".hyprconf", "hypr", "Wallpaper")
        warm(folder)
    elif cmd == "renew" and len(sys.argv) >= 3:
        renew(sys.argv[2])
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
