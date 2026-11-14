#!/usr/bin/env python3
"""
hypr-colors.py — Autonomous Theme Extractor & Desktop Color Synchronizer.
Extracts vibrant obsidian palettes directly from wallpapers using Pillow,
synchronizes Theme.qml, qmldir, and colors.json across all Quickshell subprojects,
and triggers live reloads for Hyprland, Kitty, and Qt/KDE apps.
"""

import json
import os
import re
import sys
import fcntl
import colorsys
import subprocess
from pathlib import Path
from PIL import Image

HOME = os.getenv("HOME", str(Path.home()))
LOCAL_CACHE = Path(HOME) / ".local" / "share" / "hyprconf" / ".cache"
CACHE_DIR = LOCAL_CACHE if (LOCAL_CACHE.exists() or LOCAL_CACHE.parent.exists()) else (Path(HOME) / ".hyprconf" / "hypr" / ".cache")
LEGACY_CACHE = Path(HOME) / ".hyprconf" / "hypr" / ".cache"
CURRENT_WALLPAPER = LOCAL_CACHE / "current_wallpaper.png"


def resolve_current_wallpaper():
    for candidate in (LOCAL_CACHE / "current_wallpaper.png", LEGACY_CACHE / "current_wallpaper.png"):
        if candidate.exists():
            try:
                return str(candidate.resolve())
            except Exception:
                return str(candidate)
    return None
SCRIPTS_DIR = Path(HOME) / ".hyprconf/hypr/scripts"
COLORS_SH = SCRIPTS_DIR / "sh/colors.sh"
QS_DIR = Path(HOME) / ".hyprconf/quickshell"


def get_lock_file() -> Path:
    """Return a user-isolated lock path to prevent multi-user permission collisions."""
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
    if runtime_dir and Path(runtime_dir).is_dir():
        return Path(runtime_dir) / "hypr_colors_sync.lock"
    uid = os.getuid()
    tmp_path = Path(f"/tmp/hypr_colors_sync_{uid}.lock")
    try:
        tmp_path.touch(exist_ok=True)
        return tmp_path
    except Exception:
        fallback = CACHE_DIR / "hypr_colors_sync.lock"
        fallback.parent.mkdir(parents=True, exist_ok=True)
        return fallback


def rgb_to_hex(r, g, b):
    return f"#{int(max(0, min(255, r))):02x}{int(max(0, min(255, g))):02x}{int(max(0, min(255, b))):02x}"


ALL_VARIANTS = ("vibrant", "muted", "expressive", "warm", "cool", "pastel", "original")


def hex_to_rgb(hex_str):
    h = str(hex_str).lstrip("#")
    if len(h) != 6:
        return (22, 24, 32)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def hls_to_hex(h, l, s):
    r, g, b = colorsys.hls_to_rgb(
        h % 1.0,
        max(0.0, min(1.0, l)),
        max(0.0, min(1.0, s)),
    )
    return rgb_to_hex(round(r * 255), round(g * 255), round(b * 255))


def blend_rgb(rgb_a, rgb_b, t):
    t = max(0.0, min(1.0, t))
    return tuple(round(rgb_a[i] * (1.0 - t) + rgb_b[i] * t) for i in range(3))


def blend_hex(hex_a, hex_b, t):
    return rgb_to_hex(*blend_rgb(hex_to_rgb(hex_a), hex_to_rgb(hex_b), t))


def relative_luminance(hex_str):
    def _lin(c):
        v = c / 255.0
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4

    r, g, b = hex_to_rgb(hex_str)
    return 0.2126 * _lin(r) + 0.7152 * _lin(g) + 0.0722 * _lin(b)


def contrast_ratio(hex_a, hex_b):
    la = relative_luminance(hex_a)
    lb = relative_luminance(hex_b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def pick_on_color(bg_hex, dark_hex, light_hex):
    return dark_hex if contrast_ratio(bg_hex, dark_hex) >= contrast_ratio(bg_hex, light_hex) else light_hex


def hue_diff(h1, h2):
    d = abs((h1 % 1.0) - (h2 % 1.0))
    return min(d, 1.0 - d)


def lerp_hue(h_from, h_to, t):
    d = ((h_to % 1.0) - (h_from % 1.0) + 0.5) % 1.0 - 0.5
    return (h_from + d * t) % 1.0


def tint_color(hex_str, lum_factor=1.15):
    """Adjust color luminance while keeping hue and saturation."""
    try:
        r, g, b = hex_to_rgb(hex_str)
        hls_h, hls_l, hls_s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
        new_l = max(0.0, min(1.0, hls_l * lum_factor))
        return hls_to_hex(hls_h, new_l, hls_s)
    except Exception:
        return hex_str


def _extract_image_clusters(wallpaper_path):
    """Extract distinct chromatic clusters from a wallpaper sorted by prominence."""
    img = Image.open(wallpaper_path).convert("RGB")
    img.thumbnail((320, 320))
    colors_list = img.getcolors(maxcolors=200000)
    if not colors_list:
        q = img.convert("P", palette=Image.ADAPTIVE, colors=64)
        pal = q.getpalette()[:192]
        colors_list = []
        for count, idx in q.getcolors(maxcolors=256):
            colors_list.append((count, (pal[idx * 3], pal[idx * 3 + 1], pal[idx * 3 + 2])))

    # 1. Cluster image pixels into 24 distinct hue sectors (15 deg each)
    sectors = {}
    for count, (r, g, b) in colors_list:
        h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
        if s >= 0.08 and 0.08 <= l <= 0.92:
            bin_idx = int(h * 24) % 24
            if bin_idx not in sectors:
                sectors[bin_idx] = {"pixels": 0, "samples": []}
            sectors[bin_idx]["pixels"] += count
            sectors[bin_idx]["samples"].append((count, r, g, b, h, l, s))

    # 2. Extract distinct color clusters with ~25 deg minimum separation
    distinct_clusters = []
    for _, data in sorted(sectors.items(), key=lambda x: x[1]["pixels"], reverse=True):
        data["samples"].sort(key=lambda x: x[6] * (x[0] ** 0.4), reverse=True)
        top = data["samples"][0]
        h = top[4]
        if any(hue_diff(h, prev["h"]) < 0.07 for prev in distinct_clusters):
            continue
        distinct_clusters.append({
            "h": top[4],
            "l": top[5],
            "s": top[6],
            "rgb": (top[1], top[2], top[3]),
            "pixels": data["pixels"],
        })

    if not distinct_clusters:
        distinct_clusters = [{
            "h": 0.60,
            "l": 0.56,
            "s": 0.70,
            "rgb": (92, 148, 250),
            "pixels": 1000,
        }]

    return distinct_clusters


def _derive_palette_from_clusters(distinct_clusters, variant="vibrant"):
    """Build foreground-matched dark UI, semantic, and ANSI tokens from image clusters."""
    dom_cluster = distinct_clusters[0]
    dom_h = dom_cluster["h"]
    var = (variant or "vibrant").lower()

    # 3. Derive Primary, Secondary, and chosen tonal hue based on requested variant
    if var == "original":
        h, l, s = dom_cluster["h"], dom_cluster["l"], dom_cluster["s"]
        primary = hls_to_hex(h, min(0.72, max(0.55, l)), min(0.92, max(0.28, s)))

        sec_cluster = distinct_clusters[1] if len(distinct_clusters) > 1 else dom_cluster
        sh, sl, ss = sec_cluster["h"], sec_cluster["l"], sec_cluster["s"]
        if hue_diff(sh, h) < 0.06:
            sh = (h + 0.14) % 1.0
        secondary = hls_to_hex(sh, min(0.70, max(0.53, sl)), min(0.88, max(0.28, ss)))
        chosen_hue = h

    elif var == "muted":
        h = dom_cluster["h"]
        primary = hls_to_hex(h, 0.58, min(0.45, max(0.24, dom_cluster["s"] * 1.05)))

        sec_cluster = distinct_clusters[1] if len(distinct_clusters) > 1 else dom_cluster
        sh = sec_cluster["h"]
        if hue_diff(sh, h) < 0.06:
            sh = (h + 0.12) % 1.0
        secondary = hls_to_hex(sh, 0.54, min(0.40, max(0.22, sec_cluster["s"] * 0.95)))
        chosen_hue = h

    elif var == "expressive":
        expr_cands = [c for c in distinct_clusters if hue_diff(c["h"], dom_h) >= 0.16]
        target_cluster = expr_cands[0] if expr_cands else (distinct_clusters[1] if len(distinct_clusters) > 1 else dom_cluster)
        h = target_cluster["h"]
        if target_cluster == dom_cluster and len(distinct_clusters) == 1:
            h = (dom_h + 0.33) % 1.0
        primary = hls_to_hex(h, 0.63, min(0.95, max(0.68, target_cluster["s"] * 2.1)))

        sec_h = (h + 0.12) % 1.0
        secondary = hls_to_hex(sec_h, 0.60, 0.72)
        chosen_hue = h

    elif var == "warm":
        warm_sorted = sorted(distinct_clusters, key=lambda c: hue_diff(c["h"], 0.08))
        warm_cluster = warm_sorted[0]
        h = warm_cluster["h"]
        if hue_diff(h, 0.08) > 0.28:
            h = 0.08
        primary = hls_to_hex(h, 0.63, min(0.95, max(0.68, warm_cluster["s"] * 2.2)))

        sec_h = (h + 0.07) % 1.0
        secondary = hls_to_hex(sec_h, 0.60, 0.72)
        chosen_hue = h

    elif var == "cool":
        cool_sorted = sorted(distinct_clusters, key=lambda c: hue_diff(c["h"], 0.58))
        cool_cluster = cool_sorted[0]
        h = cool_cluster["h"]
        if hue_diff(h, 0.58) > 0.28:
            h = 0.58
        primary = hls_to_hex(h, 0.63, min(0.95, max(0.68, cool_cluster["s"] * 2.2)))

        sec_h = (h + 0.10) % 1.0
        secondary = hls_to_hex(sec_h, 0.60, 0.72)
        chosen_hue = h

    elif var == "pastel":
        fs_cands = [c for c in distinct_clusters if hue_diff(c["h"], dom_h) >= 0.18]
        target_cluster = fs_cands[0] if fs_cands else (distinct_clusters[1] if len(distinct_clusters) > 1 else dom_cluster)
        h = target_cluster["h"]
        primary = hls_to_hex(h, 0.75, min(0.68, max(0.45, target_cluster["s"] * 1.55)))

        sec_h = (h + 0.09) % 1.0
        secondary = hls_to_hex(sec_h, 0.71, 0.50)
        chosen_hue = h

    else:
        vib_cluster = sorted(distinct_clusters, key=lambda c: c["s"] * 2.0 + (c["pixels"] ** 0.15), reverse=True)[0]
        h = vib_cluster["h"]
        primary = hls_to_hex(h, 0.62, min(0.96, max(0.70, vib_cluster["s"] * 2.2)))

        sec_cluster = distinct_clusters[1] if len(distinct_clusters) > 1 else vib_cluster
        sh = sec_cluster["h"]
        if hue_diff(sh, h) < 0.08:
            sh = (h + 0.12) % 1.0
        secondary = hls_to_hex(sh, 0.60, min(0.92, max(0.64, sec_cluster["s"] * 1.9)))
        chosen_hue = h

    # 3b. Derive a distinct 3rd accent from remaining wallpaper clusters or split-complement
    pr, pg, pb = hex_to_rgb(primary)
    sr, sg, sb = hex_to_rgb(secondary)
    prim_h = colorsys.rgb_to_hls(pr / 255.0, pg / 255.0, pb / 255.0)[0]
    sec_h = colorsys.rgb_to_hls(sr / 255.0, sg / 255.0, sb / 255.0)[0]
    tert_cands = [c for c in distinct_clusters if hue_diff(c["h"], prim_h) >= 0.11 and hue_diff(c["h"], sec_h) >= 0.11]
    if tert_cands:
        th = tert_cands[0]["h"]
        ts = min(0.75, max(0.42, tert_cands[0]["s"] * 1.6))
    else:
        th = (chosen_hue + 0.42) % 1.0
        ts = 0.58 if var not in ("muted", "pastel") else 0.44
    tertiary = hls_to_hex(th, 0.66 if var != "pastel" else 0.74, ts)

    # 4. Foreground-matched dark tonal scale directly anchored to chosen_hue
    fg_hue = chosen_hue
    fg_sat = 0.14 if var in ("muted", "pastel") else 0.22
    foreground = hls_to_hex(fg_hue, 0.93, fg_sat)
    inactive_tab_fg = hls_to_hex(fg_hue, 0.72, fg_sat * 0.85)

    dark_sat = 0.20 if var == "muted" else (0.24 if var == "pastel" else 0.30)
    background = hls_to_hex(fg_hue, 0.095, dark_sat)
    surface = hls_to_hex(fg_hue, 0.135, max(0.16, dark_sat - 0.03))
    color0 = hls_to_hex(fg_hue, 0.195, max(0.14, dark_sat - 0.07))
    muted = hls_to_hex(fg_hue, 0.48, 0.18 if var != "muted" else 0.13)

    # 5. Contrast-guaranteed foreground text on primary/secondary/error surfaces
    accent = primary
    on_primary = pick_on_color(primary, background, foreground)
    on_secondary = pick_on_color(secondary, background, foreground)
    error = hls_to_hex(lerp_hue(0.975, chosen_hue, 0.08), 0.66, 0.80 if var != "muted" else 0.60)
    on_error = pick_on_color(error, background, foreground)

    # 6. Harmonized ANSI palette (distinct semantic terminal colors gently aligned with palette)
    ansi_sat = 0.62 if var == "muted" else (0.64 if var == "pastel" else 0.78)
    ansi_hi_sat = min(0.92, ansi_sat + 0.06)

    color1 = error
    color9 = hls_to_hex(lerp_hue(0.975, chosen_hue, 0.08), 0.73, ansi_hi_sat)

    green_h = lerp_hue(0.39, chosen_hue, 0.10)
    color2 = hls_to_hex(green_h, 0.66, ansi_sat * 0.90)
    color10 = hls_to_hex(green_h, 0.73, ansi_hi_sat * 0.92)

    yellow_h = lerp_hue(0.11, chosen_hue, 0.08)
    color3 = hls_to_hex(yellow_h, 0.70, ansi_sat)
    color11 = hls_to_hex(yellow_h, 0.77, ansi_hi_sat)

    blue_h = prim_h if 0.52 <= prim_h <= 0.72 else lerp_hue(0.60, chosen_hue, 0.14)
    color4 = primary if 0.52 <= prim_h <= 0.72 else hls_to_hex(blue_h, 0.67, ansi_sat)
    color12 = tint_color(color4, 1.10) if relative_luminance(color4) < 0.45 else color4

    mag_h = sec_h if 0.73 <= sec_h <= 0.95 else lerp_hue(0.79, chosen_hue, 0.14)
    color5 = secondary if 0.73 <= sec_h <= 0.95 else hls_to_hex(mag_h, 0.68, ansi_sat)
    color13 = tint_color(color5, 1.10) if relative_luminance(color5) < 0.45 else color5

    cyan_h = prim_h if 0.45 <= prim_h < 0.52 else (sec_h if 0.45 <= sec_h < 0.52 else lerp_hue(0.50, chosen_hue, 0.14))
    color6 = primary if 0.45 <= prim_h < 0.52 else hls_to_hex(cyan_h, 0.67, ansi_sat * 0.92)
    color14 = tint_color(color6, 1.10) if relative_luminance(color6) < 0.45 else color6

    color15 = hls_to_hex(fg_hue, 0.97, 0.22)

    colors = {
        "primary": primary,
        "secondary": secondary,
        "tertiary": tertiary,
        "accent": accent,
        "surface": surface,
        "background": background,
        "foreground": foreground,
        "on_primary": on_primary,
        "on_secondary": on_secondary,
        "on_surface": foreground,
        "error": error,
        "on_error": on_error,
        "muted": muted,
        "color0": color0,
        "color1": color1,
        "color2": color2,
        "color3": color3,
        "color4": color4,
        "color5": color5,
        "color6": color6,
        "color7": foreground,
        "color8": muted,
        "color9": color9,
        "color10": color10,
        "color11": color11,
        "color12": color12,
        "color13": color13,
        "color14": color14,
        "color15": color15,
        "cursor": foreground,
        "cursor_text_color": background,
        "selection_foreground": foreground,
        "selection_background": color0,
        "active_border_color": primary,
        "inactive_border_color": color0,
        "url_color": primary,
        "active_tab_foreground": on_primary,
        "active_tab_background": primary,
        "inactive_tab_foreground": inactive_tab_fg,
        "inactive_tab_background": color0,
        "cursor_trail_color": primary,
        "variant": var,
    }
    return colors


def extract_wallpaper_palette(wallpaper_path, variant="vibrant"):
    """Extract a harmonized obsidian color scheme directly from a wallpaper."""
    try:
        distinct_clusters = _extract_image_clusters(wallpaper_path)
        return _derive_palette_from_clusters(distinct_clusters, variant=variant)
    except Exception as e:
        print(f"Warning: Failed to extract palette from {wallpaper_path}: {e}", file=sys.stderr)
        return None


def _build_preview_payload(wallpaper_path, distinct_clusters, variant):
    palette = _derive_palette_from_clusters(distinct_clusters, variant=variant)
    raw_swatches = [
        rgb_to_hex(*c["rgb"])
        for c in distinct_clusters[:6]
    ]
    swatches = [
        {"color": palette["background"], "label": "BG"},
        {"color": palette["surface"], "label": "Surface"},
        {"color": palette["primary"], "label": "Primary"},
        {"color": palette["secondary"], "label": "Secondary"},
        {"color": palette["tertiary"], "label": "Accent"},
        {"color": palette["foreground"], "label": "FG"},
    ]
    return {
        "variant": palette["variant"],
        "background": palette["background"],
        "surface": palette["surface"],
        "color0": palette["color0"],
        "muted": palette["muted"],
        "primary": palette["primary"],
        "secondary": palette["secondary"],
        "tertiary": palette["tertiary"],
        "accent": palette["accent"],
        "foreground": palette["foreground"],
        "error": palette["error"],
        "swatches": swatches,
        "wallpaper_colors": raw_swatches,
    }


def extract_wallpaper_preview(wallpaper_path, variant="vibrant", all_variants=False):
    """Fast read-only palette preview payload for UI wallpaper browsers."""
    try:
        distinct_clusters = _extract_image_clusters(wallpaper_path)
        if all_variants:
            variants_map = {}
            for var_name in ALL_VARIANTS:
                variants_map[var_name] = _build_preview_payload(wallpaper_path, distinct_clusters, var_name)
            return {
                "path": str(wallpaper_path),
                "variants": variants_map,
            }
        payload = _build_preview_payload(wallpaper_path, distinct_clusters, variant or "vibrant")
        payload["path"] = str(wallpaper_path)
        return payload
    except Exception as e:
        fb = get_fallback_colors()
        return {
            "path": str(wallpaper_path),
            "variant": (variant or "vibrant").lower(),
            "error_msg": str(e),
            "background": fb["background"],
            "surface": fb["surface"],
            "primary": fb["primary"],
            "secondary": fb["secondary"],
            "tertiary": fb.get("tertiary", fb["secondary"]),
            "foreground": fb["foreground"],
            "swatches": [
                {"color": fb["background"], "label": "BG"},
                {"color": fb["surface"], "label": "Surface"},
                {"color": fb["primary"], "label": "Primary"},
                {"color": fb["secondary"], "label": "Secondary"},
                {"color": fb.get("tertiary", fb["secondary"]), "label": "Accent"},
                {"color": fb["foreground"], "label": "FG"},
            ],
            "wallpaper_colors": [],
        }


def get_fallback_colors():
    """Default obsidian dark theme colors when no wallpaper is available."""
    colors_file = QS_DIR / "colors.json"
    if colors_file.exists():
        try:
            return json.loads(colors_file.read_text())
        except Exception:
            pass

    return {
        "primary": "#58a6ff",
        "secondary": "#8980f5",
        "tertiary": "#4ad9c8",
        "accent": "#58a6ff",
        "surface": "#1e222d",
        "background": "#161922",
        "foreground": "#eceff6",
        "on_primary": "#161922",
        "on_secondary": "#161922",
        "on_surface": "#eceff6",
        "error": "#f4637d",
        "on_error": "#161922",
        "muted": "#6c7388",
    }


def generate_hypr_lua(colors, dual_tone=None):
    """Write hypr/theme.lua so Hyprland window borders stay synchronized."""
    theme_file = Path(HOME) / ".hyprconf/hypr/theme.lua"
    legacy_noctalia = Path(HOME) / ".hyprconf/hypr/noctalia.lua"
    legacy_config_noctalia = Path(HOME) / ".config/hypr/noctalia.lua"

    if dual_tone is None:
        dual_tone = get_dual_tone_border()

    active_border_expr = "{ colors = {primary, tertiary}, angle = 45 }" if dual_tone else "primary"
    group_border_expr = "{ colors = {primary, secondary}, angle = 45 }" if dual_tone else "primary"

    def strip_hash(h):
        return str(h).lstrip("#")

    content = f"""-- Auto-generated by hypr-colors.py

local primary = "rgb({strip_hash(colors.get('primary', '#67aae4'))})"
local tertiary = "rgb({strip_hash(colors.get('tertiary', colors.get('secondary', '#e96779')))})"
local surface = "rgb({strip_hash(colors.get('surface', '#161f27'))})"
local inactive_border = "rgb({strip_hash(colors.get('inactive_border_color', colors.get('color0', '#1d293f')))})"
local on_surface = "rgb({strip_hash(colors.get('on_surface', '#f2f2f3'))})"
local secondary = "rgb({strip_hash(colors.get('secondary', '#5c60d6'))})"
local on_secondary = "rgb({strip_hash(colors.get('on_secondary', '#1f1825'))})"
local error = "rgb({strip_hash(colors.get('error', '#fd4663'))})"
local on_error = "rgb({strip_hash(colors.get('on_error', '#1f1825'))})"

local function apply_theme()
    hl.config({{
        general = {{
            col = {{
                active_border = {active_border_expr},
                inactive_border = inactive_border,
            }},
        }},
        group = {{
            col = {{
                border_active = {group_border_expr},
                border_inactive = inactive_border,
                border_locked_active = error,
                border_locked_inactive = inactive_border,
            }},

            groupbar = {{
                col = {{
                    active = secondary,
                    inactive = surface,
                    locked_active = error,
                    locked_inactive = surface,
                }},
                text_color = on_secondary,
                text_color_inactive = on_surface,
                text_color_locked_active = on_error,
                text_color_locked_inactive = on_surface,
            }},
        }},
    }})
end

return {{
    colors = {{
        primary = primary,
        tertiary = tertiary,
        surface = surface,
        inactive_border = inactive_border,
        on_surface = on_surface,
        secondary = secondary,
        on_secondary = on_secondary,
        error = error,
        on_error = on_error,
    }},
    apply_theme = apply_theme
}}
"""
    try:
        theme_file.parent.mkdir(parents=True, exist_ok=True)
        theme_file.write_text(content)
        legacy_noctalia.unlink(missing_ok=True)
        legacy_config_noctalia.unlink(missing_ok=True)
        print(f"Hyprland theme updated: {theme_file}")
    except Exception as e:
        print(f"Warning: Failed writing theme.lua: {e}", file=sys.stderr)


def generate_kitty_conf(colors):
    """Write kitty/themes/theme.conf so Kitty stays synchronized."""
    theme_file = Path(HOME) / ".hyprconf/kitty/themes/theme.conf"
    noctalia_file = Path(HOME) / ".hyprconf/kitty/themes/noctalia.conf"
    lines = []
    for i in range(16):
        key = f"color{i}"
        val = colors.get(key, "#f2f2f3")
        lines.append(f"{key} {val}")
    lines.append("")
    for k in [
        ("cursor", colors.get("cursor", "#f2f2f3")),
        ("cursor_text_color", colors.get("cursor_text_color", colors.get("background", "#161f27"))),
        ("background", colors.get("background", "#161f27")),
        ("foreground", colors.get("foreground", "#f2f2f3")),
        ("selection_foreground", colors.get("selection_foreground", "#afb3b6")),
        ("selection_background", colors.get("selection_background", colors.get("color0", "#1d2a34"))),
        ("active_border_color", colors.get("primary", "#67aae4")),
        ("inactive_border_color", colors.get("color0", "#1d2a34")),
        ("url_color", colors.get("primary", "#67aae4")),
        ("active_tab_foreground", colors.get("on_primary", "#1f1825")),
        ("active_tab_background", colors.get("primary", "#67aae4")),
        ("inactive_tab_foreground", colors.get("inactive_tab_foreground", "#afb3b6")),
        ("inactive_tab_background", colors.get("color0", "#1d2a34")),
        ("cursor_trail_color", colors.get("cursor_trail_color", colors.get("primary", "#67aae4"))),
    ]:
        lines.append(f"{k[0]:24} {k[1]}")
    content = "\n".join(lines) + "\n"
    try:
        theme_file.parent.mkdir(parents=True, exist_ok=True)
        theme_file.write_text(content)
        noctalia_file.unlink(missing_ok=True)
        print(f"Kitty theme updated: {theme_file}")
    except Exception as e:
        print(f"Warning: Failed writing kitty theme.conf: {e}", file=sys.stderr)


def generate_qt6ct_colors(colors):
    """Write qt6ct colors for Qt6 and Dolphin integration."""
    src = Path(HOME) / ".hyprconf/qt6ct/colors/theme.conf"
    src_legacy = Path(HOME) / ".hyprconf/qt6ct/colors/noctalia.conf"
    dst_dir = Path(HOME) / ".config/qt6ct/colors"
    dst = dst_dir / "theme.conf"
    dst_legacy = dst_dir / "noctalia.conf"

    bg = colors.get("background", "#161f27")
    fg = colors.get("foreground", "#f2f2f3")
    prim = colors.get("primary", "#67aae4")
    sec = colors.get("secondary", "#5c60d6")
    c0 = colors.get("color0", "#1d2a34")

    row = f"{fg}, {bg}, #ffffff, #cacaca, #9f9f9f, #b8b8b8, {fg}, #ffffff, {fg}, {bg}, {bg}, {bg}, {prim}, {bg}, {sec}, {prim}, {c0}, {bg}, {c0}, {fg}, {fg}, {prim}"
    content = f"""[ColorScheme]
# Generated by hypr-colors.py
active_colors={row}
disabled_colors={row}
inactive_colors={row}
"""
    try:
        src.parent.mkdir(parents=True, exist_ok=True)
        src.write_text(content)
        src_legacy.unlink(missing_ok=True)
        dst_dir.mkdir(parents=True, exist_ok=True)
        dst.write_text(content)
        dst_legacy.unlink(missing_ok=True)
    except Exception as e:
        print(f"Warning: Failed writing qt6ct colors: {e}", file=sys.stderr)


def get_gnome_accent_name(hex_color):
    """Map primary hex color to nearest GNOME accent-color enum."""
    try:
        h_str = str(hex_color).lstrip("#")
        r, g, b = tuple(int(h_str[i:i+2], 16) for i in (0, 2, 4))
        h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
        if s < 0.15:
            return "slate"
        if h < 0.04 or h >= 0.96:
            return "red"
        elif h < 0.12:
            return "orange"
        elif h < 0.20:
            return "yellow"
        elif h < 0.44:
            return "green"
        elif h < 0.54:
            return "teal"
        elif h < 0.68:
            return "blue"
        elif h < 0.82:
            return "purple"
        else:
            return "pink"
    except Exception:
        return "blue"


def generate_gtk_theme(colors):
    """Write dynamic obsidian theme.css for GTK3 and GTK4."""
    primary = colors.get("primary", "#658aad")
    secondary = colors.get("secondary", "#5f8eb4")
    background = colors.get("background", "#0e1115")
    surface = colors.get("surface", "#171d20")
    foreground = colors.get("foreground", "#f2f2f3")
    on_primary = colors.get("on_primary", "#181d25")
    error = colors.get("error", "#fd4663")
    on_error = colors.get("on_error", "#181d25")
    sec_dark = tint_color(secondary, 0.4)

    gtk3_content = f"""/*
 * GTK Colors (GTK3)
 * Generated by hypr-colors.py
 * stylelint-disable at-rule-no-unknown
 */

@define-color accent_color {primary};
@define-color accent_bg_color {primary};
@define-color accent_fg_color {on_primary};

@define-color destructive_bg_color {error};
@define-color destructive_fg_color {on_error};

@define-color error_bg_color {error};
@define-color error_fg_color {on_error};

@define-color window_bg_color {background};
@define-color window_fg_color {foreground};

@define-color view_bg_color {background};
@define-color view_fg_color {foreground};

@define-color headerbar_bg_color {surface};
@define-color headerbar_fg_color {foreground};
@define-color headerbar_backdrop_color @window_bg_color;

@define-color popover_bg_color {surface};
@define-color popover_fg_color {foreground};

@define-color card_bg_color {surface};
@define-color card_fg_color {foreground};

@define-color dialog_bg_color {background};
@define-color dialog_fg_color {foreground};

@define-color overview_bg_color {surface};
@define-color overview_fg_color {foreground};

@define-color sidebar_bg_color {surface};
@define-color sidebar_fg_color {foreground};
@define-color sidebar_backdrop_color @window_bg_color;
@define-color sidebar_border_color @window_bg_color;

@define-color secondary_sidebar_bg_color {background};
@define-color secondary_sidebar_fg_color {foreground};

/* Focused selection states */
@define-color theme_selected_bg_color @accent_bg_color;
@define-color theme_selected_fg_color @accent_fg_color;

/* Backdrop/unfocused states */
@define-color theme_unfocused_fg_color @window_fg_color;
@define-color theme_unfocused_text_color @view_fg_color;
@define-color theme_unfocused_bg_color @window_bg_color;
@define-color theme_unfocused_base_color @window_bg_color;
@define-color theme_unfocused_selected_bg_color @accent_bg_color;
@define-color theme_unfocused_selected_fg_color @accent_fg_color;
"""

    gtk4_content = f"""/*
 * GTK Colors (GTK4)
 * Generated by hypr-colors.py
 * stylelint-disable at-rule-no-unknown
 */

@define-color accent_color {primary};
@define-color accent_bg_color {primary};
@define-color accent_fg_color {on_primary};

@define-color destructive_bg_color {error};
@define-color destructive_fg_color {on_error};

@define-color error_bg_color {error};
@define-color error_fg_color {on_error};

@define-color window_bg_color {background};
@define-color window_fg_color {foreground};

@define-color view_bg_color {background};
@define-color view_fg_color {foreground};

@define-color headerbar_bg_color {background};
@define-color headerbar_fg_color {foreground};
@define-color headerbar_backdrop_color @window_bg_color;

@define-color popover_bg_color {surface};
@define-color popover_fg_color {foreground};

@define-color card_bg_color {surface};
@define-color card_fg_color {foreground};

@define-color dialog_bg_color {background};
@define-color dialog_fg_color {foreground};

@define-color overview_bg_color {surface};
@define-color overview_fg_color {foreground};

@define-color sidebar_bg_color {surface};
@define-color sidebar_fg_color {foreground};
@define-color sidebar_backdrop_color @window_bg_color;
@define-color sidebar_border_color @window_bg_color;

@define-color secondary_sidebar_bg_color {background};
@define-color secondary_sidebar_fg_color {foreground};

/* Focused selection states */
@define-color theme_selected_bg_color @accent_bg_color;
@define-color theme_selected_fg_color @accent_fg_color;

/* Backdrop/unfocused states */
@define-color theme_unfocused_fg_color @window_fg_color;
@define-color theme_unfocused_text_color @view_fg_color;
@define-color theme_unfocused_bg_color @window_bg_color;
@define-color theme_unfocused_base_color @window_bg_color;
@define-color theme_unfocused_selected_bg_color @accent_bg_color;
@define-color theme_unfocused_selected_fg_color @accent_fg_color;

:root {{
    --accent-color: {primary};
    --accent-bg-color: {primary}; 
    --accent-fg-color: {on_primary};

    --destructive-bg-color: {error};
    --destructive-fg-color: {on_error};

    --error-bg-color: {error};
    --error-fg-color: {on_error};
    --error-color: {error};

    --window-bg-color: {background};
    --window-fg-color: {foreground};

    --view-bg-color: {background};
    --view-fg-color: {foreground};

    --headerbar-bg-color: {background};
    --headerbar-fg-color: {foreground};
    --headerbar-backdrop-color: @window_bg_color;

    --popover-bg-color: {surface};
    --popover-fg-color: {foreground};

    --card-bg-color: {surface};
    --card-fg-color: {foreground};

    --dialog-bg-color: {background};
    --dialog-fg-color: {foreground};

    --overview-bg-color: {surface};
    --overview-fg-color: {foreground};

    --sidebar-bg-color: {surface};
    --sidebar-fg-color: {foreground};
    --sidebar-backdrop-color: @window_bg_color;
    --sidebar-border-color: @window_bg_color;

    --warning-bg-color: {sec_dark};
    --warning-fg-color: #f2f2f3;
    --warning-color: {secondary};

    --success-color: {primary};
    --success-bg-color: {surface};
    --success-fg-color: #f2f2f3;
    
    --shade-color: rgba(0, 0, 0, 0.36);
}}
"""

    def write_gtk_files(base_dir: Path, v3_text: str, v4_text: str):
        try:
            d3 = base_dir / "gtk-3.0"
            d4 = base_dir / "gtk-4.0"
            d3.mkdir(parents=True, exist_ok=True)
            d4.mkdir(parents=True, exist_ok=True)
            (d3 / "theme.css").write_text(v3_text)
            (d4 / "theme.css").write_text(v4_text)

            # Clean up old noctalia.css and legacy colors.css
            (d3 / "noctalia.css").unlink(missing_ok=True)
            (d4 / "noctalia.css").unlink(missing_ok=True)
            (d3 / "colors.css").unlink(missing_ok=True)
            (d4 / "colors.css").unlink(missing_ok=True)

            main_css3 = d3 / "gtk.css"
            import_str = '@import url("theme.css");\n'
            if not main_css3.exists() or main_css3.read_text().strip() != import_str.strip():
                main_css3.write_text(import_str)

            main_css4 = d4 / "gtk.css"
            if not main_css4.exists() or main_css4.read_text().strip() != import_str.strip():
                main_css4.write_text(import_str)
        except Exception as e:
            print(f"Warning: Failed writing GTK theme in {base_dir}: {e}", file=sys.stderr)

    write_gtk_files(Path(HOME) / ".hyprconf", gtk3_content, gtk4_content)
    if (Path(HOME) / ".config").exists():
        write_gtk_files(Path(HOME) / ".config", gtk3_content, gtk4_content)

    print("GTK3 and GTK4 themes updated: theme.css")


def reload_gtk(colors):
    """Notify running GTK3 and GTK4 apps to reload CSS styles and apply accent-color."""
    try:
        accent_name = get_gnome_accent_name(colors.get("primary", "#658aad"))
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "accent-color", accent_name], capture_output=True, timeout=2)
        subprocess.run("killall -HUP xsettingsd 2>/dev/null || true", shell=True, timeout=2)
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", "adw-gtk3"], capture_output=True, timeout=2)
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", "adw-gtk3-dark"], capture_output=True, timeout=2)
    except Exception as e:
        print(f"Warning: Failed reloading GTK theme: {e}", file=sys.stderr)


def generate_browser_ntp_theme(colors):
    """Sync Chromium-based and Firefox-based minimal New Tab theme CSS with GTK background."""
    css_content = f"""/* Auto-generated by hypr-colors.py */
:root {{
  --bg: {colors.get("background", "#11171f")};
  --surface: {colors.get("surface", "#19212c")};
  --primary: {colors.get("primary", "#6c86ac")};
  --secondary: {colors.get("secondary", "#7366a9")};
  --fg: {colors.get("foreground", "#e9ecf1")};
  --muted: {colors.get("muted", "#647690")};
  color-scheme: dark;
}}
"""
    targets = [
        Path(HOME) / ".local/share/hyprconf/browser-ntp/chromium/theme.css",
        Path(HOME) / ".local/share/hyprconf/browser-ntp/firefox/colors.css",
        Path(HOME) / ".local/share/hyprconf/brave-ntp/theme.css",
    ]
    for target in targets:
        if not target.parent.exists():
            continue
        tmp_file = target.parent / f".{target.name}.tmp"
        try:
            tmp_file.write_text(css_content)
            os.replace(tmp_file, target)
        except Exception as e:
            print(f"Warning: Failed writing browser NTP theme ({target}): {e}", file=sys.stderr)



def generate_btop_theme(colors):
    """Write btop/themes/theme.theme so btop stays synchronized."""
    theme_file = Path(HOME) / ".hyprconf/btop/themes/theme.theme"
    noctalia_file = Path(HOME) / ".hyprconf/btop/themes/noctalia.theme"

    bg = colors.get("background", "#0e1315")
    fg = colors.get("foreground", "#f2f2f3")
    prim = colors.get("primary", "#48bbf2")
    sec = colors.get("secondary", "#676fac")
    c0 = colors.get("color0", "#171d20")
    muted = colors.get("muted", "#6b6372")
    error = colors.get("error", "#fd4663")

    content = f"""# btop theme generated by hypr-colors.py

theme[main_bg]="{bg}"
theme[main_fg]="{fg}"
theme[title]="{prim}"
theme[hi_fg]="{sec}"
theme[selected_bg]="{c0}"
theme[selected_fg]="{fg}"
theme[inactive_fg]="{muted}"
theme[proc_misc]="{sec}"
theme[cpu_box]="{muted}"
theme[mem_box]="{muted}"
theme[net_box]="{muted}"
theme[proc_box]="{muted}"
theme[div_line]="{muted}"
theme[temp_start]="{prim}"
theme[temp_mid]="{sec}"
theme[temp_end]="{error}"
theme[cpu_start]="{prim}"
theme[cpu_mid]="{sec}"
theme[cpu_end]="{error}"
theme[free_start]="{prim}"
theme[free_mid]="{sec}"
theme[free_end]="{sec}"
theme[cached_start]="{prim}"
theme[cached_mid]="{sec}"
theme[cached_end]="{sec}"
theme[available_start]="{prim}"
theme[available_mid]="{sec}"
theme[available_end]="{sec}"
theme[used_start]="{prim}"
theme[used_mid]="{sec}"
theme[used_end]="{error}"
theme[download_start]="{prim}"
theme[download_mid]="{sec}"
theme[download_end]="{sec}"
theme[upload_start]="{prim}"
theme[upload_mid]="{sec}"
theme[upload_end]="{sec}"
"""
    try:
        theme_file.parent.mkdir(parents=True, exist_ok=True)
        theme_file.write_text(content)
        noctalia_file.unlink(missing_ok=True)
        config_themes = Path(HOME) / ".config/btop/themes"
        if config_themes.exists() and not config_themes.is_symlink():
            (config_themes / "theme.theme").write_text(content)
            (config_themes / "noctalia.theme").unlink(missing_ok=True)
        print(f"Btop theme updated: {theme_file}")
    except Exception as e:
        print(f"Warning: Failed writing btop theme: {e}", file=sys.stderr)


def generate_neovim_theme(colors):
    """Write nvim/lua/matugen.lua with base16 palette and Telescope/MiniPick highlights."""
    theme_file = Path(HOME) / ".hyprconf/nvim/lua/matugen.lua"

    bg = colors.get("background", "#0e1315")
    surface = colors.get("surface", "#171d20")
    c0 = colors.get("color0", "#1d293f")
    muted = colors.get("muted", "#6b6372")
    muted_light = colors.get("inactive_tab_foreground", "#afb1b6")
    fg = colors.get("foreground", "#f2f2f3")
    white = colors.get("color15", "#ffffff")
    error = colors.get("error", "#fd4663")
    prim = colors.get("primary", "#48bbf2")
    sec = colors.get("secondary", "#676fac")

    prim_bright = tint_color(prim, 1.25)
    sec_bright = tint_color(sec, 1.25)
    sec_warm = tint_color(sec, 1.15)
    sec_light = tint_color(sec, 1.35)

    content = f"""-- Auto-generated by hypr-colors.py
local M = {{}}

function M.setup()
  require('base16-colorscheme').setup({{
    base00 = '{bg}',
    base01 = '{surface}',
    base02 = '{c0}',
    base03 = '{muted}',
    base04 = '{muted_light}',
    base05 = '{fg}',
    base06 = '{fg}',
    base07 = '{white}',
    base08 = '{error}',
    base09 = '{sec_warm}',
    base0A = '{sec}',
    base0B = '{prim}',
    base0C = '{sec_light}',
    base0D = '{prim_bright}',
    base0E = '{sec_bright}',
    base0F = '{sec_light}',
  }})

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         {{ fg = '{fg}',          bg = '{bg}' }})
  hi('TelescopeBorder',         {{ fg = '{muted}',       bg = '{bg}' }})
  hi('TelescopePromptNormal',   {{ fg = '{fg}',          bg = '{bg}' }})
  hi('TelescopePromptBorder',   {{ fg = '{muted}',       bg = '{bg}' }})
  hi('TelescopePromptPrefix',   {{ fg = '{prim}',        bg = '{bg}' }})
  hi('TelescopePromptCounter',  {{ fg = '{muted_light}', bg = '{bg}' }})
  hi('TelescopePromptTitle',    {{ fg = '{bg}',          bg = '{prim}' }})
  hi('TelescopePreviewTitle',   {{ fg = '{bg}',          bg = '{sec}' }})
  hi('TelescopeResultsTitle',   {{ fg = '{bg}',          bg = '{sec_warm}' }})
  hi('TelescopeSelection',      {{ fg = '{fg}',          bg = '{c0}' }})
  hi('TelescopeSelectionCaret', {{ fg = '{prim}',        bg = '{c0}' }})
  hi('TelescopeMatching',       {{ fg = '{prim}',        bold = true }})

  -- mini.pick
  hi('MiniPickNormal',          {{ fg = '{fg}',          bg = '{bg}' }})
  hi('MiniPickBorder',          {{ fg = '{muted}',       bg = '{bg}' }})
  hi('MiniPickPrompt',          {{ fg = '{fg}',          bg = '{bg}' }})
  hi('MiniPickPromptPrefix',    {{ fg = '{prim}',        bg = '{bg}' }})
  hi('MiniPickBorderText',      {{ fg = '{bg}',          bg = '{prim}' }})
  hi('MiniPickMatchCurrent',    {{ fg = '{fg}',          bg = '{c0}' }})
  hi('MiniPickPromptCaret',     {{ fg = '{prim}',        bg = '{c0}' }})
  hi('MiniPickMatchRanges',     {{ fg = '{prim}',        bold = true }})
end

-- Register a signal handler for SIGUSR1 (hypr-colors.py live updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
"""
    try:
        theme_file.parent.mkdir(parents=True, exist_ok=True)
        theme_file.write_text(content)
        config_matugen = Path(HOME) / ".config/nvim/lua/matugen.lua"
        if config_matugen.exists() and not config_matugen.is_symlink():
            config_matugen.write_text(content)
        print(f"Neovim theme updated: {theme_file}")
    except Exception as e:
        print(f"Warning: Failed writing neovim matugen.lua: {e}", file=sys.stderr)



def generate_shell_colors(colors):
    """Export colors as bash variables in colors.sh for shell scripts and gum."""
    content = [
        "#!/usr/bin/env bash",
        "# ==============================================================================",
        "# colors.sh — Dynamic System Theme Palette",
        "# Auto-generated by hypr-colors.py. Do not edit manually.",
        "# ==============================================================================",
        "",
        "# Core theme colors",
        f'primary="{colors.get("primary", "#48bbf2")}"',
        f'secondary="{colors.get("secondary", "#676fac")}"',
        f'accent="{colors.get("accent", "#48bbf2")}"',
        f'surface="{colors.get("surface", "#171d20")}"',
        f'background="{colors.get("background", "#0e1315")}"',
        f'foreground="{colors.get("foreground", "#f2f2f3")}"',
        f'on_primary="{colors.get("on_primary", "#12151c")}"',
        f'on_secondary="{colors.get("on_secondary", "#12151c")}"',
        f'on_surface="{colors.get("on_surface", "#f2f2f3")}"',
        f'error="{colors.get("error", "#fd4663")}"',
        f'on_error="{colors.get("on_error", "#181f25")}"',
        f'muted="{colors.get("muted", "#6b6372")}"',
        "",
        "# Terminal ANSI colors",
    ]

    for i in range(16):
        key = f"color{i}"
        if key in colors:
            content.append(f'{key}="{colors[key]}"')

    cursor_val = colors.get("cursor", "#f2f2f3")
    active_b = colors.get("active_border_color", colors.get("primary", "#48bbf2"))
    inactive_b = colors.get("inactive_border_color", colors.get("surface", "#171d20"))

    content.extend([
        "",
        "# UI elements",
        f'cursor="{cursor_val}"',
        f'active_border="{active_b}"',
        f'inactive_border="{inactive_b}"',
        "",
    ])

    try:
        COLORS_SH.parent.mkdir(parents=True, exist_ok=True)
        COLORS_SH.write_text("\n".join(content))
        os.chmod(COLORS_SH, 0o755)
        print(f"Shell colors generated: {COLORS_SH}")
    except Exception as e:
        print(f"Warning: Failed writing colors.sh: {e}", file=sys.stderr)


def sync_quickshell_colors(colors):
    """Generate Theme.qml, colors.json, and qmldir for Quickshell components,
    and propagate them to all subdirectories (settings, launcher, launcher-theme, island, lockscreen)."""
    if not QS_DIR.exists():
        return

    theme_qml_content = """pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // Dynamic Obsidian Glassmorphism Palette (auto-updated from colors.json without restarting Quickshell)
    property var _palette: ({
        primary: "#48bbf2",
        secondary: "#676fac",
        tertiary: "#e96779",
        accent: "#48bbf2",
        surface: "#171d20",
        background: "#0e1315",
        foreground: "#f2f2f3",
        on_primary: "#12151c",
        on_secondary: "#12151c",
        on_surface: "#f2f2f3",
        error: "#fd4663",
        on_error: "#181f25",
        muted: "#6b6372",
        variant: "vibrant"
    })

    readonly property color primary: _palette.primary || "#48bbf2"
    readonly property color secondary: _palette.secondary || "#676fac"
    readonly property color tertiary: _palette.tertiary || _palette.secondary || "#e96779"
    readonly property color accent: _palette.accent || _palette.primary || "#48bbf2"
    readonly property color surface: _palette.surface || "#171d20"
    readonly property color background: _palette.background || "#0e1315"
    readonly property color foreground: _palette.foreground || "#f2f2f3"
    readonly property color on_primary: _palette.on_primary || "#12151c"
    readonly property color on_secondary: _palette.on_secondary || "#12151c"
    readonly property color on_surface: _palette.on_surface || "#f2f2f3"
    readonly property color error: _palette.error || "#fd4663"
    readonly property color on_error: _palette.on_error || "#181f25"
    readonly property color muted: _palette.muted || "#6b6372"
    readonly property string variant: _palette.variant || "vibrant"

    readonly property string _colorsPath: {
        var h = Quickshell.env("HOME")
        if (h && h.length > 0) return h + "/.hyprconf/quickshell/colors.json"
        var u = Qt.resolvedUrl("colors.json").toString()
        return u.indexOf("file://") === 0 ? decodeURIComponent(u.slice(7)) : u
    }

    function _applyColorsJson(txt) {
        if (!txt || txt.trim().length === 0) return
        try {
            var parsed = JSON.parse(txt.trim())
            if (parsed && typeof parsed === "object" && parsed.primary) {
                root._palette = parsed
            }
        } catch (e) {}
    }

    readonly property FileView _colorsWatcher: FileView {
        id: colorsFileView
        path: root._colorsPath
        watchChanges: true
        onLoaded: root._applyColorsJson(text())
        onFileChanged: reload()
    }

    // Color helper functions
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    function mix(c1, c2, ratio) {
        var t = Math.max(0.0, Math.min(1.0, ratio))
        return Qt.rgba(
            c1.r + (c2.r - c1.r) * t,
            c1.g + (c2.g - c1.g) * t,
            c1.b + (c2.b - c1.b) * t,
            c1.a + (c2.a - c1.a) * t
        )
    }

    // Unified Obsidian Frosted Glass Tokens (zero-cost reactive palette derivatives)
    readonly property color glassBase: Qt.rgba(background.r, background.g, background.b, 0.82)
    readonly property color glassElevated: Qt.rgba(surface.r, surface.g, surface.b, 0.72)
    readonly property color glassCard: Qt.rgba(surface.r, surface.g, surface.b, 0.56)
    readonly property color glassWell: Qt.rgba(background.r, background.g, background.b, 0.52)
    readonly property color glassRimTop: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.16)
    readonly property color glassRimMid: Qt.rgba(accent.r, accent.g, accent.b, 0.20)
    readonly property color glassRimBottom: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.04)
    readonly property color glassShadow: Qt.rgba(0, 0, 0, 0.48)
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, 0.16)
    readonly property color accentGlow: Qt.rgba(accent.r, accent.g, accent.b, 0.34)
    readonly property color primarySoft: Qt.rgba(primary.r, primary.g, primary.b, 0.16)

    readonly property int radiusModal: 22
    readonly property int radiusCard: 16
    readonly property int radiusTile: 13
    readonly property int radiusPill: 999
}
"""

    qmldir_content = """singleton Theme 1.0 Theme.qml
LockscreenSystemGraph 1.0 LockscreenSystemGraph.qml
LockscreenAudioVisualizer 1.0 LockscreenAudioVisualizer.qml
"""

    try:
        QS_DIR.mkdir(parents=True, exist_ok=True)
        for name in ("quickshell", "hypr", "gtk-3.0", "gtk-4.0", "btop", "kitty", "nvim", "xsettingsd"):
            cfg_path = Path(HOME) / f".config/{name}"
            src_path = Path(HOME) / f".hyprconf/{name}"
            if not cfg_path.exists() and src_path.exists():
                try:
                    cfg_path.parent.mkdir(parents=True, exist_ok=True)
                    cfg_path.symlink_to(src_path)
                except Exception:
                    pass

        def safe_write(p: Path, content: str):
            try:
                if not p.exists() or p.read_text() != content:
                    p.write_text(content)
            except Exception:
                p.write_text(content)

        # 1. Write root Theme.qml, qmldir, and colors.json only when changed
        safe_write(QS_DIR / "Theme.qml", theme_qml_content)
        safe_write(QS_DIR / "qmldir", qmldir_content)
        safe_write(QS_DIR / "colors.json", json.dumps(colors, indent=2) + "\n")
        user_colors_json = Path(HOME) / ".local" / "share" / "hyprconf" / "colors.json"
        if user_colors_json.parent.exists():
            safe_write(user_colors_json, json.dumps(colors, indent=2) + "\n")

        # Subproject qmldir definitions
        SUBPROJECT_QMLDIRS = {
            "settings": """singleton Theme 1.0 Theme.qml
BezierGraph 1.0 BezierGraph.qml
CapsuleSwitch 1.0 CapsuleSwitch.qml
ModernSlider 1.0 ModernSlider.qml
ModernDropdown 1.0 ModernDropdown.qml
SettingCard 1.0 SettingCard.qml
DraggableWidget 1.0 DraggableWidget.qml
LockscreenSection 1.0 LockscreenSection.qml
WeatherSection 1.0 WeatherSection.qml
IslandSection 1.0 IslandSection.qml
WidgetsSection 1.0 WidgetsSection.qml
DockSection 1.0 DockSection.qml
ResizableDraggableWidget 1.0 ResizableDraggableWidget.qml
DesktopClock 1.0 DesktopClock.qml
DesktopVisualizer 1.0 DesktopVisualizer.qml
DesktopSystemMonitor 1.0 DesktopSystemMonitor.qml
DesktopAudioPlayer 1.0 DesktopAudioPlayer.qml
DesktopWeather 1.0 DesktopWeather.qml
AudioVisualizer 1.0 AudioVisualizer.qml
LockscreenSystemGraph 1.0 LockscreenSystemGraph.qml
LockscreenAudioVisualizer 1.0 LockscreenAudioVisualizer.qml
BarSection 1.0 BarSection.qml
KeybindsSection 1.0 KeybindsSection.qml
UpdateSection 1.0 UpdateSection.qml
""",
            "dock": """singleton Theme 1.0 Theme.qml
DockLayer 1.0 DockLayer.qml
DockItem 1.0 DockItem.qml
DockContextMenu 1.0 DockContextMenu.qml
""",
            "launcher": """singleton Theme 1.0 Theme.qml
Style1 1.0 Style1.qml
Style2 1.0 Style2.qml
Spotlight 1.0 Spotlight.qml
""",
            "launcher-theme": """singleton Theme 1.0 Theme.qml
""",
            "emoji": """singleton Theme 1.0 Theme.qml
""",
            "quickpaste": """singleton Theme 1.0 Theme.qml
""",
            "updater": """singleton Theme 1.0 Theme.qml
""",
            "keybinds": """singleton Theme 1.0 Theme.qml
""",
            "screenshot": """singleton Theme 1.0 Theme.qml
ScreenshotView 1.0 ScreenshotView.qml
""",
            "wallpaper": """singleton Theme 1.0 Theme.qml
WallpaperView 1.0 WallpaperView.qml
""",
            "welcome": """singleton Theme 1.0 Theme.qml
""",
            "widgets": """singleton Theme 1.0 Theme.qml
DesktopWidgetsLayer 1.0 DesktopWidgetsLayer.qml
DesktopClock 1.0 DesktopClock.qml
DesktopVisualizer 1.0 DesktopVisualizer.qml
DesktopSystemMonitor 1.0 DesktopSystemMonitor.qml
DesktopAudioPlayer 1.0 DesktopAudioPlayer.qml
DesktopWeather 1.0 DesktopWeather.qml
""",
            "island": """singleton Theme 1.0 Theme.qml
IslandShape 1.0 IslandShape.qml
CollapsedBar 1.0 CollapsedBar.qml
DashboardView 1.0 DashboardView.qml
HomePage 1.0 HomePage.qml
PowerView 1.0 PowerView.qml
WallpaperView 1.0 WallpaperView.qml
ProfileBanner 1.0 ProfileBanner.qml
QuickToggles 1.0 QuickToggles.qml
WifiCard 1.0 WifiCard.qml
BluetoothCard 1.0 BluetoothCard.qml
VerticalSlider 1.0 VerticalSlider.qml
BottomCard 1.0 BottomCard.qml
LauncherView 1.0 LauncherView.qml
Style1 1.0 Style1.qml
Style2 1.0 Style2.qml
Spotlight 1.0 Spotlight.qml
ThemeSwitcherView 1.0 ThemeSwitcherView.qml
ScreenshotView 1.0 ScreenshotView.qml
PolkitView 1.0 PolkitView.qml
StatusPage 1.0 StatusPage.qml
NetworkDetailPage 1.0 NetworkDetailPage.qml
ClipboardView 1.0 ClipboardView.qml
AudioVisualizer 1.0 AudioVisualizer.qml
EmojiView 1.0 EmojiView.qml
KeybindsView 1.0 KeybindsView.qml
WifiNetworkDialog 1.0 WifiNetworkDialog.qml
WeatherPage 1.0 WeatherPage.qml
IslandBatteryIndicator 1.0 IslandBatteryIndicator.qml
IslandMediaIndicators 1.0 IslandMediaIndicators.qml
GlassRim 1.0 GlassRim.qml
WallpaperFx 1.0 WallpaperFx.qml
""",
            "lockscreen": """singleton Theme 1.0 Theme.qml
LockscreenSystemGraph 1.0 LockscreenSystemGraph.qml
LockscreenAudioVisualizer 1.0 LockscreenAudioVisualizer.qml
""",
            "bar": """singleton Theme 1.0 Theme.qml
Bar 1.0 Bar.qml
BarPopup 1.0 BarPopup.qml
BarPowerMenu 1.0 BarPowerMenu.qml
BarOSD 1.0 BarOSD.qml
BarNotificationToast 1.0 BarNotificationToast.qml
BarTrailBridge 1.0 BarTrailBridge.qml
Pill 1.0 Pill.qml
ActionButton 1.0 ActionButton.qml
MonoText 1.0 MonoText.qml
SvgIcon 1.0 SvgIcon.qml
BarWidgetLoader 1.0 BarWidgetLoader.qml
BarLauncher 1.0 widgets/BarLauncher.qml
BarTray 1.0 widgets/BarTray.qml
BarWorkspaces 1.0 widgets/BarWorkspaces.qml
BarWeather 1.0 widgets/BarWeather.qml
BarPowerProfile 1.0 widgets/BarPowerProfile.qml
BarMedia 1.0 widgets/BarMedia.qml
BarClock 1.0 widgets/BarClock.qml
BarNotification 1.0 widgets/BarNotification.qml
BarPkgUpdate 1.0 widgets/BarPkgUpdate.qml
BarQuickToggles 1.0 widgets/BarQuickToggles.qml
BarCaffeine 1.0 widgets/BarCaffeine.qml
BarNightlight 1.0 widgets/BarNightlight.qml
BarClipboard 1.0 widgets/BarClipboard.qml
BarSystemInfo 1.0 widgets/BarSystemInfo.qml
BarVolume 1.0 widgets/BarVolume.qml
BarPower 1.0 widgets/BarPower.qml
BarBattery 1.0 widgets/BarBattery.qml
BarNetwork 1.0 widgets/BarNetwork.qml
BarActiveWindow 1.0 widgets/BarActiveWindow.qml
BarVisualizer 1.0 widgets/BarVisualizer.qml
BarDnd 1.0 widgets/BarDnd.qml
""",
        }

        # 2. Propagate Theme.qml, colors.json, and custom qmldir into all subdirectories
        for item in QS_DIR.iterdir():
            if item.is_dir() and not item.name.startswith("."):
                sub_theme = item / "Theme.qml"
                sub_colors = item / "colors.json"
                sub_qmldir = item / "qmldir"

                if not sub_theme.is_symlink() or (os.path.islink(sub_theme) and os.readlink(sub_theme) != "../Theme.qml"):
                    sub_theme.unlink(missing_ok=True)
                    sub_theme.symlink_to("../Theme.qml")

                if not sub_colors.is_symlink() or (os.path.islink(sub_colors) and os.readlink(sub_colors) != "../colors.json"):
                    sub_colors.unlink(missing_ok=True)
                    sub_colors.symlink_to("../colors.json")

                if item.name in SUBPROJECT_QMLDIRS:
                    expected_content = SUBPROJECT_QMLDIRS[item.name]
                    if sub_qmldir.is_symlink() or not sub_qmldir.exists() or sub_qmldir.read_text() != expected_content:
                        sub_qmldir.unlink(missing_ok=True)
                        sub_qmldir.write_text(expected_content)
                else:
                    if not sub_qmldir.exists():
                        sub_qmldir.symlink_to("../qmldir")

        # Ensure island has valid relative symlinks to launcher styles
        island_dir = QS_DIR / "island"
        launcher_dir = QS_DIR / "launcher"
        if island_dir.exists() and launcher_dir.exists():
            for style in ("Style1.qml", "Style2.qml"):
                style_link = island_dir / style
                target_rel = Path("..") / "launcher" / style
                if (launcher_dir / style).exists():
                    try:
                        if not style_link.is_symlink() or os.readlink(style_link) != str(target_rel):
                            style_link.unlink(missing_ok=True)
                            style_link.symlink_to(target_rel)
                    except Exception:
                        pass

        # Ensure island and bar have valid relative symlinks to dock, widgets, and island modules
        for shell_name in ("island", "bar"):
            shell_dir = QS_DIR / shell_name
            if shell_dir.exists():
                mods = [("dock_mod", "dock"), ("widgets_mod", "widgets")]
                if shell_name == "bar":
                    mods.append(("island_mod", "island"))
                for mod_name, folder in mods:
                    m_link = shell_dir / mod_name
                    target_rel = Path("..") / folder
                    if (QS_DIR / folder).exists():
                        try:
                            if not m_link.is_symlink() or os.readlink(m_link) != str(target_rel):
                                m_link.unlink(missing_ok=True)
                                m_link.symlink_to(target_rel)
                        except Exception:
                            pass

        # Ensure settings has valid relative symlinks to desktop widgets
        settings_dir = QS_DIR / "settings"
        widgets_dir = QS_DIR / "widgets"
        if settings_dir.exists() and widgets_dir.exists():
            for widget in ("DesktopClock.qml", "DesktopVisualizer.qml", "DesktopSystemMonitor.qml", "DesktopAudioPlayer.qml", "DesktopWeather.qml"):
                w_link = settings_dir / widget
                target_rel = Path("..") / "widgets" / widget
                if (widgets_dir / widget).exists():
                    try:
                        if not w_link.is_symlink() or os.readlink(w_link) != str(target_rel):
                            w_link.unlink(missing_ok=True)
                            w_link.symlink_to(target_rel)
                    except Exception:
                        pass

        # Theme.qml watches colors.json reactively via FileView — no full shell reload needed!
        print(f"Quickshell colors synced: {QS_DIR}/colors.json")
    except Exception as e:
        print(f"Warning: Quickshell color sync failed: {e}", file=sys.stderr)


def notify_kde_reload():
    """Signal running Qt/KDE apps (e.g. Dolphin) to reload their color palette via DBus."""
    try:
        subprocess.run(
            [
                "dbus-send", "--session", "--type=signal",
                "/KGlobalSettings", "org.kde.KGlobalSettings.notifyChange",
                "int32:3", "int32:0",
            ],
            capture_output=True, timeout=3,
        )
    except Exception:
        pass


def _wallpaper_config_path(for_write=False) -> Path:
    """Resolve user wallpaper_config.json path with cache fallback."""
    user_cfg = Path.home() / ".local" / "share" / "hyprconf" / "wallpaper_config.json"
    if for_write:
        return user_cfg if user_cfg.parent.exists() else (CACHE_DIR / "wallpaper_config.json")
    return user_cfg if user_cfg.exists() else (CACHE_DIR / "wallpaper_config.json")


def _read_wallpaper_config() -> dict:
    """Load persisted theme preferences from wallpaper_config.json."""
    cfg_file = _wallpaper_config_path(for_write=False)
    if cfg_file.exists():
        try:
            data = json.loads(cfg_file.read_text())
            if isinstance(data, dict):
                return data
        except Exception:
            pass
    return {}


def _write_wallpaper_config(updates: dict):
    """Persist one or more theme preference keys to wallpaper_config.json."""
    cfg_file = _wallpaper_config_path(for_write=True)
    try:
        cfg_data = _read_wallpaper_config()
        changed = False
        for k, v in updates.items():
            if cfg_data.get(k) != v:
                cfg_data[k] = v
                changed = True
        if changed or not cfg_file.exists():
            cfg_file.parent.mkdir(parents=True, exist_ok=True)
            cfg_file.write_text(json.dumps(cfg_data, indent=2))
    except Exception:
        pass


def get_saved_variant():
    """Retrieve user-selected color variant from wallpaper_config.json."""
    variant = _read_wallpaper_config().get("color_variant")
    return str(variant).lower() if variant else "vibrant"


def get_dual_tone_border() -> bool:
    """Return whether 45-degree dual-tone active borders are enabled (default True)."""
    val = _read_wallpaper_config().get("dual_tone_border")
    return val if isinstance(val, bool) else True


def sync_hypr_border_only(dual_tone=None):
    """Regenerate only hypr/theme.lua from colors.json and reload Hyprland borders."""
    if dual_tone is not None:
        _write_wallpaper_config({"dual_tone_border": bool(dual_tone)})
    else:
        dual_tone = get_dual_tone_border()

    colors = None
    colors_file = QS_DIR / "colors.json"
    if colors_file.exists():
        try:
            colors = json.loads(colors_file.read_text())
        except Exception:
            colors = None
    if not colors:
        wall = resolve_current_wallpaper()
        if wall and os.path.exists(wall):
            colors = extract_wallpaper_palette(wall, variant=get_saved_variant())
    if not colors:
        colors = get_fallback_colors()

    generate_hypr_lua(colors, dual_tone=dual_tone)
    subprocess.run(["hyprctl", "eval", "local _s, _m = pcall(dofile, os.getenv('HOME') .. '/.hyprconf/hypr/theme.lua'); if _s and _m and _m.apply_theme then _m.apply_theme() end"], capture_output=True)


def sync_theme(wallpaper_path=None, variant=None):
    # Auto-resolve current wallpaper if none provided
    if not wallpaper_path:
        wallpaper_path = resolve_current_wallpaper()

    if not variant:
        variant = get_saved_variant()
    else:
        _write_wallpaper_config({"color_variant": variant})

    colors = None
    if wallpaper_path and os.path.exists(wallpaper_path):
        colors = extract_wallpaper_palette(wallpaper_path, variant=variant)

    if not colors:
        colors = get_fallback_colors()

    # Generate Hyprland borders and Kitty theme
    generate_hypr_lua(colors)
    generate_kitty_conf(colors)

    # Generate colors.sh for shell scripts and gum
    generate_shell_colors(colors)

    # Sync qt6ct color scheme so Dolphin picks up the new palette
    generate_qt6ct_colors(colors)

    # Sync btop theme so terminal monitor matches system palette
    generate_btop_theme(colors)

    # Sync Neovim base16 and telescope palette
    generate_neovim_theme(colors)

    # Sync GTK3 and GTK4 themes
    generate_gtk_theme(colors)
    reload_gtk(colors)

    # Sync minimal New Tab themes for Chromium-based & Firefox-based browsers
    generate_browser_ntp_theme(colors)

    # Update Hyprland border colors in-memory via theme.lua (instant, zero compositor shake)
    subprocess.run(["hyprctl", "eval", "local _s, _m = pcall(dofile, os.getenv('HOME') .. '/.hyprconf/hypr/theme.lua'); if _s and _m and _m.apply_theme then _m.apply_theme() end"], capture_output=True)

    # Send SIGUSR1 to reload running Kitty and Neovim instances
    subprocess.run("killall -SIGUSR1 kitty 2>/dev/null || true", shell=True)
    subprocess.run("killall -SIGUSR1 nvim 2>/dev/null || true", shell=True)

    # Notify KDE/Qt apps (Dolphin, etc.) to reload their color palette via DBus
    notify_kde_reload()

    # Sync Quickshell components (Theme.qml, qmldir, colors.json) and trigger hot-reload
    sync_quickshell_colors(colors)

    print(f"Theme colors applied ({variant}): primary={colors.get('primary')} accent={colors.get('accent')} surface={colors.get('surface')}")


def _parse_bool_flag(raw: str) -> bool:
    return raw.strip().lower() in ("1", "true", "on", "yes", "enable", "enabled")


def _parse_cli_args(args):
    wall = None
    variant = None
    palette_mode = False
    all_variants = False
    dual_border = None
    sync_lua_only = False

    idx = 0
    while idx < len(args):
        arg = args[idx]
        if arg in ("--palette", "--json"):
            palette_mode = True
            idx += 1
        elif arg == "--all-variants":
            palette_mode = True
            all_variants = True
            idx += 1
        elif arg == "--sync-lua":
            sync_lua_only = True
            idx += 1
        elif arg == "--dual-border" and idx + 1 < len(args):
            dual_border = _parse_bool_flag(args[idx + 1])
            idx += 2
        elif arg.startswith("--dual-border="):
            dual_border = _parse_bool_flag(arg.split("=", 1)[1])
            idx += 1
        elif arg in ("--variant", "-v") and idx + 1 < len(args):
            variant = args[idx + 1].strip().lower()
            idx += 2
        elif arg.startswith("--variant="):
            variant = arg.split("=", 1)[1].strip().lower()
            idx += 1
        elif not wall and os.path.exists(arg):
            wall = arg
            idx += 1
        elif not variant and arg.lower() in ALL_VARIANTS:
            variant = arg.lower()
            idx += 1
        else:
            idx += 1

    return wall, variant, palette_mode, all_variants, dual_border, sync_lua_only


def main():
    wall, variant, palette_mode, all_variants, dual_border, sync_lua_only = _parse_cli_args(sys.argv[1:])

    # Fast read-only preview mode skips system sync lock & compositor writes
    if palette_mode:
        if not wall:
            wall = resolve_current_wallpaper()
        payload = extract_wallpaper_preview(wall, variant=variant or "vibrant", all_variants=all_variants)
        print(json.dumps(payload))
        return

    # Use user-isolated lock to avoid multi-user permission collisions
    lock_file = get_lock_file()
    try:
        lock_fd = os.open(str(lock_file), os.O_CREAT | os.O_RDWR, 0o600)
    except PermissionError:
        fallback = CACHE_DIR / "hypr_colors_sync.lock"
        fallback.parent.mkdir(parents=True, exist_ok=True)
        lock_fd = os.open(str(fallback), os.O_CREAT | os.O_RDWR, 0o600)

    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        # Another instance is already syncing colors, skip
        sys.exit(0)

    try:
        if dual_border is not None:
            _write_wallpaper_config({"dual_tone_border": dual_border})

        if sync_lua_only or (dual_border is not None and not wall and not variant):
            sync_hypr_border_only(dual_tone=dual_border if dual_border is not None else get_dual_tone_border())
        else:
            if not wall:
                wall = resolve_current_wallpaper()

            sync_theme(wall, variant=variant)
    finally:
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_UN)
            os.close(lock_fd)
        except Exception:
            pass


if __name__ == "__main__":
    main()
