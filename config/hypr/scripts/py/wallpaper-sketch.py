#!/usr/bin/env python3
"""
wallpaper-sketch.py — Dynamic character & contour sketch generator for Hyprconf.

Generates an obsidian line-art sketch of a wallpaper and detects character
focal points for 2-stage animated transitions.

Features:
- Fast AI/CV Face & Character Detection (OpenCV YuNet + Saliency Density fallback)
- Isolates character contours on obsidian canvas (#090a0e)
- Calculates normalized focal coordinates (X, Y) for circle-grow bloom transitions
- Deterministic caching in ~/.local/share/hyprconf/.cache/sketches/
- Outputs: <sketch_path> <focal_pos> <has_character>
"""

import hashlib
import json
import os
import sys
from pathlib import Path

# Try importing OpenCV and NumPy, either from venv or system
VENV_PY = Path.home() / ".local" / "share" / "hyprconf" / "venv" / "bin" / "python3"
if sys.executable != str(VENV_PY) and VENV_PY.exists():
    # If running with system python but venv exists, hand off to venv python
    try:
        os.execv(str(VENV_PY), [str(VENV_PY), os.path.abspath(__file__), *sys.argv[1:]])
    except Exception:
        pass

# Suppress OpenCV C++ backend logging before any CV import
os.environ.setdefault("OPENCV_LOG_LEVEL", "OFF")
os.environ.setdefault("OPENCV_FFMPEG_LOGLEVEL", "-8")

HAS_CV2 = False
cv2 = None
try:
    import importlib
    cv2 = importlib.import_module("cv2")
    if hasattr(cv2, "FaceDetectorYN"):
        HAS_CV2 = True
except Exception:
    HAS_CV2 = False

try:
    from PIL import Image, ImageEnhance, ImageFilter, ImageOps, ImageChops, ImageStat, ImageDraw
except ImportError:
    sys.exit(1)

CACHE_DIR = Path.home() / ".local" / "share" / "hyprconf" / ".cache" / "sketches"
CACHE_DIR.mkdir(parents=True, exist_ok=True)

MODEL_PATHS = [
    Path.home() / ".hyprconf" / "hypr" / "scripts" / "models" / "face_detection_yunet.onnx",
    Path("/main/Code/shell-ninja/hyprconf-qs/config/hypr/scripts/models/face_detection_yunet.onnx"),
    Path.home() / ".local" / "share" / "hyprconf" / "models" / "face_detection_yunet.onnx"
]


def _get_model_path():
    for p in MODEL_PATHS:
        if p.exists():
            return str(p)
    return None


def get_cache_paths(img_path: str):
    p = Path(img_path).resolve()
    st = p.stat()
    key = hashlib.sha256(f"{p}|{st.st_size}|{int(st.st_mtime)}".encode()).hexdigest()[:16]
    img_cache = CACHE_DIR / f"sketch_{key}.jpg"
    meta_cache = CACHE_DIR / f"sketch_{key}.meta.json"
    return img_cache, meta_cache


def detect_character_cv2(img_path: str, model_path: str):
    """Detects character/face using YuNet deep learning face detector."""
    try:
        detector = cv2.FaceDetectorYN.create(
            model=model_path,
            config="",
            input_size=(640, 360),
            score_threshold=0.62,
            nms_threshold=0.3,
            top_k=5000
        )
        img = cv2.imread(img_path)
        if img is None:
            return None
        h, w = img.shape[:2]
        
        # Scale to max 960 for high-speed inference (~40-70ms)
        max_d = 960
        scale = min(1.0, max_d / max(h, w))
        work_w, work_h = int(w * scale), int(h * scale)
        small = cv2.resize(img, (work_w, work_h))
        
        detector.setInputSize((work_w, work_h))
        _, faces = detector.detect(small)
        
        if faces is not None and len(faces) > 0:
            # Sort by face area * confidence
            best = max(faces, key=lambda f: (f[2] * f[3]) * f[-1])
            bx, by, bw, bh = best[:4]
            conf = best[-1]
            if conf >= 0.65:
                # Center of face
                fcx = (bx + bw / 2) / work_w
                fcy = (by + bh / 2) / work_h
                # Approximate full character box (head down to body)
                char_top = max(0, by - bh * 0.3)
                char_bottom = min(work_h, by + bh * 3.8)
                char_left = max(0, bx - bw * 0.8)
                char_right = min(work_w, bx + bw * 1.8)
                
                return {
                    "has_character": True,
                    "focal_x": round(float(fcx), 3),
                    "focal_y": round(float(fcy), 3),
                    "char_box": (
                        float(char_left / work_w),
                        float(char_top / work_h),
                        float(char_right / work_w),
                        float(char_bottom / work_h)
                    )
                }
    except Exception:
        pass
    return None


def detect_character_pillow(im: Image.Image):
    """Fallback character detector using skin-tone fusion and edge concentration."""
    orig_w, orig_h = im.size
    sw = 320
    sh = int(orig_h * (sw / orig_w))
    small = im.resize((sw, sh), Image.Resampling.BILINEAR)
    
    # Skin tone detector in HSV
    hsv = small.convert("HSV")
    h_chan, s_chan, v_chan = hsv.split()
    h_p, s_p, v_p = h_chan.load(), s_chan.load(), v_chan.load()
    
    skin_mask = Image.new("L", (sw, sh), 0)
    skin_p = skin_mask.load()
    skin_count = 0
    for y in range(sh):
        for x in range(sw):
            hv, sv, vv = h_p[x, y], s_p[x, y], v_p[x, y]
            if (3 <= hv <= 26) and (30 <= sv <= 180) and (70 <= vv <= 250):
                skin_p[x, y] = 255
                skin_count += 1
                
    skin_ratio = skin_count / (sw * sh)
    
    gray = small.convert("L")
    edges = gray.filter(ImageFilter.FIND_EDGES)
    skin_edges = ImageChops.multiply(edges, skin_mask)
    skin_edge_density = skin_edges.filter(ImageFilter.GaussianBlur(radius=8))
    
    stat_se = ImageStat.Stat(skin_edge_density)
    max_se = stat_se.extrema[0][1]
    
    if max_se >= 20 and 0.005 <= skin_ratio <= 0.12:
        # Detected human/anime character
        gw, gh = 16, 9
        cw, ch = sw / gw, sh / gh
        sep = skin_edge_density.load()
        sum_x, sum_y, sum_w = 0.0, 0.0, 0.0
        for gy in range(gh):
            for gx in range(gw):
                x1, x2 = int(gx * cw), int((gx + 1) * cw)
                y1, y2 = int(gy * ch), int((gy + 1) * ch)
                val, cnt = 0, 0
                for sy in range(y1, y2, 2):
                    for sx in range(x1, x2, 2):
                        val += sep[sx, sy]
                        cnt += 1
                avg = val / max(cnt, 1)
                if avg > 6:
                    sum_x += (gx + 0.5) * cw * avg
                    sum_y += (gy + 0.5) * ch * avg
                    sum_w += avg
        if sum_w > 0:
            cx = (sum_x / sum_w) / sw
            cy = (sum_y / sum_w) / sh
            return {
                "has_character": True,
                "focal_x": round(float(cx), 3),
                "focal_y": round(float(cy), 3),
                "char_box": (max(0.0, cx - 0.25), max(0.0, cy - 0.20), min(1.0, cx + 0.25), min(1.0, cy + 0.45))
            }
            
    return {"has_character": False, "focal_x": 0.5, "focal_y": 0.5, "char_box": None}


def generate_sketch(input_path: str, output_path: str):
    """Generates an obsidian line-art sketch and metadata."""
    orig = Image.open(input_path).convert("RGB")
    orig_w, orig_h = orig.size
    
    # 1. Detect Character (YuNet preferred, Pillow fallback)
    meta = None
    model_p = _get_model_path()
    if HAS_CV2 and model_p:
        meta = detect_character_cv2(input_path, model_p)
        
    if meta is None:
        meta = detect_character_pillow(orig)
        
    has_char = meta["has_character"]
    focal_x = meta["focal_x"]
    focal_y = meta["focal_y"]
    char_box = meta.get("char_box")
    
    # 2. Downscale large images for fast processing (max 1920px width)
    max_dim = 1920
    if max(orig_w, orig_h) > max_dim:
        scale = max_dim / max(orig_w, orig_h)
        work_w = int(orig_w * scale)
        work_h = int(orig_h * scale)
        img = orig.resize((work_w, work_h), Image.Resampling.BILINEAR)
    else:
        img = orig
        work_w, work_h = orig_w, orig_h

    # 3. Dual-pass Edge Detection (Difference of Gaussians + FIND_EDGES)
    gray = img.convert("L")
    b1 = gray.filter(ImageFilter.GaussianBlur(radius=1.0))
    b2 = gray.filter(ImageFilter.GaussianBlur(radius=2.6))
    dog = ImageOps.invert(ImageChops.difference(b1, b2))
    dog_boost = ImageOps.autocontrast(dog, cutoff=3)

    raw_edges = gray.filter(ImageFilter.FIND_EDGES)
    raw_boost = ImageOps.autocontrast(raw_edges, cutoff=3)
    pencil = ImageOps.invert(raw_boost)
    pencil = ImageEnhance.Contrast(pencil).enhance(2.0)

    # Blend DoG and fine pencil sketch
    sketch_bw = ImageOps.invert(Image.blend(dog_boost, pencil, 0.45))

    # Tint lines silver/accent on obsidian dark (#090a0e)
    sketch_rgb = ImageOps.colorize(
        sketch_bw,
        black=(9, 10, 14),
        white=(222, 230, 244)
    )

    # 4. If has_character, isolate the character in the sketch!
    if has_char and char_box:
        # Create a smooth elliptical vignette around the character
        x1 = int(char_box[0] * work_w)
        y1 = int(char_box[1] * work_h)
        x2 = int(char_box[2] * work_w)
        y2 = int(char_box[3] * work_h)
        
        mask = Image.new("L", (work_w, work_h), 0)
        draw = ImageDraw.Draw(mask)
        # Draw ellipse bounding character with padding
        pad_x = int((x2 - x1) * 0.25)
        pad_y = int((y2 - y1) * 0.20)
        draw.ellipse(
            [max(0, x1 - pad_x), max(0, y1 - pad_y), min(work_w, x2 + pad_x), min(work_h, y2 + pad_y)],
            fill=255
        )
        # Gaussian blur the mask for a soft glowing transition into obsidian
        blur_r = max(18, int(min(work_w, work_h) * 0.05))
        smooth_mask = mask.filter(ImageFilter.GaussianBlur(radius=blur_r))
        
        obsidian_base = Image.new("RGB", (work_w, work_h), (9, 10, 14))
        final_img = Image.composite(sketch_rgb, obsidian_base, smooth_mask)
    else:
        final_img = sketch_rgb

    # 5. Atomic write
    tmp_out = f"{output_path}.{os.getpid()}.tmp.jpg"
    final_img.save(tmp_out, "JPEG", quality=88, optimize=True)
    os.replace(tmp_out, output_path)

    return {
        "has_character": has_char,
        "focal_x": focal_x,
        "focal_y": focal_y,
        "focal_pos": f"{focal_x:.2f},{focal_y:.2f}"
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: wallpaper-sketch.py <wallpaper_path>", file=sys.stderr)
        sys.exit(1)

    input_path = sys.argv[1]
    if not os.path.isfile(input_path):
        print(f"File not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    img_cache, meta_cache = get_cache_paths(input_path)

    # Check cache hit
    if img_cache.exists() and meta_cache.exists():
        try:
            meta = json.loads(meta_cache.read_text())
            focal_pos = meta.get("focal_pos", "0.50,0.50")
            has_char = "1" if meta.get("has_character") else "0"
            print(f"{img_cache} {focal_pos} {has_char}")
            return
        except Exception:
            pass

    # Generate sketch & detect
    meta = generate_sketch(input_path, str(img_cache))
    try:
        meta_cache.write_text(json.dumps(meta, indent=2))
    except Exception:
        pass

    focal_pos = meta.get("focal_pos", "0.50,0.50")
    has_char = "1" if meta.get("has_character") else "0"
    print(f"{img_cache} {focal_pos} {has_char}")


if __name__ == "__main__":
    main()
