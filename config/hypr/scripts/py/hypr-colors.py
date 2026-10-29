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
CURRENT_WALLPAPER = CACHE_DIR / "current_wallpaper.png"
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


def tint_color(hex_str, lum_factor=1.15):
    """Adjust color luminance while keeping hue and saturation."""
    try:
        h = str(hex_str).lstrip("#")
        r, g, b = tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
        hls_h, hls_l, hls_s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
        new_l = max(0.0, min(1.0, hls_l * lum_factor))
        nr, ng, nb = [int(x * 255) for x in colorsys.hls_to_rgb(hls_h, new_l, hls_s)]
        return rgb_to_hex(nr, ng, nb)
    except Exception:
        return hex_str



def extract_wallpaper_palette(wallpaper_path, variant="vibrant"):
    """Extract distinct color scheme variants directly from the wallpaper itself,
    following Noctalia Shell's Material You color generation theory:
      - 'vibrant': Boosts the highest-chroma, most energetic color present in the wallpaper.
      - 'muted': Samples the wallpaper's primary dominant tonal spot with calm, refined saturation.
      - 'expressive': Discovers secondary/divergent hue clusters present in the image (hue shift >= 50°).
      - 'warm': Finds the warmest hue present in the wallpaper (reds, oranges, ambers, warm coppers).
      - 'cool': Finds the coolest hue present in the wallpaper (cyans, blues, glacial teals, indigos).
      - 'pastel': Lightens an authentic secondary wallpaper tone into an airy, luminous pastel accent.
      - 'original': Direct dominant sampling preserving authentic lightness and saturation.
    """
    try:
        img = Image.open(wallpaper_path).convert("RGB")
        img.thumbnail((320, 320))
        colors_list = img.getcolors(maxcolors=200000)
        if not colors_list:
            # Fallback if getcolors exceeds maxcolors
            q = img.convert("P", palette=Image.ADAPTIVE, colors=64)
            pal = q.getpalette()[:192]
            colors_list = []
            for count, idx in q.getcolors(maxcolors=256):
                colors_list.append((count, (pal[idx * 3], pal[idx * 3 + 1], pal[idx * 3 + 2])))

        # 1. Cluster all image pixels into 24 distinct hue sectors (15° each)
        sectors = {}
        total_colored_pixels = 0
        for count, (r, g, b) in colors_list:
            h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
            # Filter out near-pure monochrome/near-black/near-white
            if s >= 0.08 and 0.08 <= l <= 0.92:
                bin_idx = int(h * 24) % 24
                if bin_idx not in sectors:
                    sectors[bin_idx] = {"pixels": 0, "samples": []}
                sectors[bin_idx]["pixels"] += count
                sectors[bin_idx]["samples"].append((count, r, g, b, h, l, s))
                total_colored_pixels += count

        # 2. Extract distinct color clusters from the wallpaper, ordered by prominence
        distinct_clusters = []
        for bin_idx, data in sorted(sectors.items(), key=lambda x: x[1]["pixels"], reverse=True):
            # Sort samples in cluster by weighted saturation & count
            data["samples"].sort(key=lambda x: x[6] * (x[0] ** 0.4), reverse=True)
            top = data["samples"][0]
            h = top[4]
            # Ensure minimum ~25° hue separation between clusters
            if any(abs(h - prev["h"]) < 0.07 or abs(abs(h - prev["h"]) - 1.0) < 0.07 for prev in distinct_clusters):
                continue
            distinct_clusters.append({
                "h": top[4],
                "l": top[5],
                "s": top[6],
                "rgb": (top[1], top[2], top[3]),
                "pixels": data["pixels"]
            })

        # Fallback if image has very few distinct colored clusters
        if not distinct_clusters:
            distinct_clusters = [{
                "h": 0.60,
                "l": 0.50,
                "s": 0.70,
                "rgb": (68, 138, 255),
                "pixels": 1000
            }]

        # Dominant cluster (Tonal spot / main color of the wallpaper)
        dom_cluster = distinct_clusters[0]
        dom_h = dom_cluster["h"]

        var = (variant or "vibrant").lower()

        # 3. Derive Primary and Secondary colors based on the requested Noctalia variant
        if var == "original":
            # Direct dominant sampling preserving authentic lightness and saturation
            h, l, s = dom_cluster["h"], dom_cluster["l"], dom_cluster["s"]
            target_l = min(0.70, max(0.40, l))
            target_s = min(0.95, max(0.25, s))
            r, g, b = [int(x * 255) for x in colorsys.hls_to_rgb(h, target_l, target_s)]
            primary = rgb_to_hex(r, g, b)

            sec_cluster = distinct_clusters[1] if len(distinct_clusters) > 1 else dom_cluster
            sh, sl, ss = sec_cluster["h"], sec_cluster["l"], sec_cluster["s"]
            sr, sg, sb = [int(x * 255) for x in colorsys.hls_to_rgb(sh, min(0.70, max(0.40, sl)), min(0.90, max(0.25, ss)))]
            secondary = rgb_to_hex(sr, sg, sb)
            chosen_hue = h

        elif var == "muted":
            # Soft, refined atmospheric tone from the wallpaper's dominant cluster
            h = dom_cluster["h"]
            target_l = 0.56
            target_s = min(0.42, max(0.22, dom_cluster["s"] * 1.05))
            r, g, b = [int(x * 255) for x in colorsys.hls_to_rgb(h, target_l, target_s)]
            primary = rgb_to_hex(r, g, b)

            sec_cluster = distinct_clusters[1] if len(distinct_clusters) > 1 else dom_cluster
            sh = sec_cluster["h"]
            sr, sg, sb = [int(x * 255) for x in colorsys.hls_to_rgb(sh, 0.52, min(0.38, max(0.20, sec_cluster["s"] * 0.95)))]
            secondary = rgb_to_hex(sr, sg, sb)
            chosen_hue = h

        elif var == "expressive":
            # Material You Expressive: Discovers a divergent secondary hue cluster from the wallpaper
            expr_cands = [c for c in distinct_clusters if abs(c["h"] - dom_h) >= 0.16 and abs(c["h"] - dom_h) <= 0.84]
            target_cluster = expr_cands[0] if expr_cands else (distinct_clusters[1] if len(distinct_clusters) > 1 else dom_cluster)
            h = target_cluster["h"]
            # If the image was monochrome and only 1 hue existed, shift hue by 120° for genuine expressiveness
            if target_cluster == dom_cluster and len(distinct_clusters) == 1:
                h = (dom_h + 0.33) % 1.0
            r, g, b = [int(x * 255) for x in colorsys.hls_to_rgb(h, 0.62, min(1.0, max(0.68, target_cluster["s"] * 2.2)))]
            primary = rgb_to_hex(r, g, b)

            sec_h = (h + 0.12) % 1.0
            sr, sg, sb = [int(x * 255) for x in colorsys.hls_to_rgb(sec_h, 0.58, 0.72)]
            secondary = rgb_to_hex(sr, sg, sb)
            chosen_hue = h

        elif var == "warm":
            # Finds the warmest color cluster present in the wallpaper (reds/oranges/yellows/ambers)
            # Hue distance to pure warm orange (~0.08 = 28°)
            warm_sorted = sorted(distinct_clusters, key=lambda c: min(abs(c["h"] - 0.08), abs(c["h"] - 1.08)))
            warm_cluster = warm_sorted[0]
            h = warm_cluster["h"]
            # If wallpaper has no warm tones at all, synthesize an analogous warm counterpart
            if abs(h - 0.08) > 0.28 and abs(h - 1.08) > 0.28:
                h = 0.08  # Warm amber
            r, g, b = [int(x * 255) for x in colorsys.hls_to_rgb(h, 0.62, min(1.0, max(0.70, warm_cluster["s"] * 2.4)))]
            primary = rgb_to_hex(r, g, b)

            sec_h = (h + 0.06) % 1.0
            sr, sg, sb = [int(x * 255) for x in colorsys.hls_to_rgb(sec_h, 0.58, 0.72)]
            secondary = rgb_to_hex(sr, sg, sb)
            chosen_hue = h

        elif var == "cool":
            # Finds the coolest color cluster present in the wallpaper (cyans/blues/glacial teals)
            # Hue distance to pure cool blue-cyan (~0.58 = 210°)
            cool_sorted = sorted(distinct_clusters, key=lambda c: abs(c["h"] - 0.58))
            cool_cluster = cool_sorted[0]
            h = cool_cluster["h"]
            # If wallpaper has no cool tones at all, synthesize an analogous cool counterpart
            if abs(h - 0.58) > 0.28:
                h = 0.58  # Cool blue-cyan
            r, g, b = [int(x * 255) for x in colorsys.hls_to_rgb(h, 0.62, min(1.0, max(0.70, cool_cluster["s"] * 2.4)))]
            primary = rgb_to_hex(r, g, b)

            sec_h = (h + 0.10) % 1.0
            sr, sg, sb = [int(x * 255) for x in colorsys.hls_to_rgb(sec_h, 0.58, 0.72)]
            secondary = rgb_to_hex(sr, sg, sb)
            chosen_hue = h

        elif var == "pastel":
            # Luminous, airy pastel tone sampled from the wallpaper's distinct secondary harmonies
            fs_cands = [c for c in distinct_clusters if abs(c["h"] - dom_h) >= 0.18]
            target_cluster = fs_cands[0] if fs_cands else (distinct_clusters[1] if len(distinct_clusters) > 1 else dom_cluster)
            h = target_cluster["h"]
            r, g, b = [int(x * 255) for x in colorsys.hls_to_rgb(h, 0.74, min(0.70, max(0.45, target_cluster["s"] * 1.6)))]
            primary = rgb_to_hex(r, g, b)

            sec_h = (h + 0.08) % 1.0
            sr, sg, sb = [int(x * 255) for x in colorsys.hls_to_rgb(sec_h, 0.70, 0.50)]
            secondary = rgb_to_hex(sr, sg, sb)
            chosen_hue = h

        else:
            # Vibrant (Default): Samples the highest-chroma color cluster found in the wallpaper and boosts vibrancy
            vib_cluster = sorted(distinct_clusters, key=lambda c: c["s"] * 2.0 + (c["pixels"] ** 0.15), reverse=True)[0]
            h = vib_cluster["h"]
            r, g, b = [int(x * 255) for x in colorsys.hls_to_rgb(h, 0.60, min(1.0, max(0.72, vib_cluster["s"] * 2.4)))]
            primary = rgb_to_hex(r, g, b)

            sec_cluster = distinct_clusters[1] if len(distinct_clusters) > 1 else vib_cluster
            sh = sec_cluster["h"]
            if abs(sh - h) < 0.08:
                sh = (h + 0.12) % 1.0
            sr, sg, sb = [int(x * 255) for x in colorsys.hls_to_rgb(sh, 0.58, min(1.0, max(0.65, sec_cluster["s"] * 2.0)))]
            secondary = rgb_to_hex(sr, sg, sb)
            chosen_hue = h

        # 4. Deep obsidian surface, background, and dark tints harmonized with the chosen variant's hue
        br, bg, bb = [int(x * 255) for x in colorsys.hls_to_rgb(chosen_hue, 0.07, 0.18)]
        sr, sg, sb = [int(x * 255) for x in colorsys.hls_to_rgb(chosen_hue, 0.11, 0.16)]
        cr, cg, cb = [int(x * 255) for x in colorsys.hls_to_rgb(chosen_hue, 0.16, 0.14)]

        background = rgb_to_hex(br, bg, bb)
        surface = rgb_to_hex(sr, sg, sb)
        color0 = rgb_to_hex(cr, cg, cb)
        accent = primary
        on_primary = "#12151c"

        colors = {
            "primary": primary,
            "secondary": secondary,
            "accent": accent,
            "surface": surface,
            "background": background,
            "foreground": "#f2f2f3",
            "on_primary": on_primary,
            "on_secondary": on_primary,
            "on_surface": "#f2f2f3",
            "error": "#fd4663",
            "on_error": "#181f25",
            "muted": "#6b6372",
            "color0": color0,
            "color1": "#fd4663",
            "color2": primary,
            "color3": secondary,
            "color4": primary,
            "color5": secondary,
            "color6": primary,
            "color7": "#f2f2f3",
            "color8": "#6b6372",
            "color9": "#fd4663",
            "color10": primary,
            "color11": secondary,
            "color12": primary,
            "color13": secondary,
            "color14": primary,
            "color15": "#ffffff",
            "cursor": "#f2f2f3",
            "cursor_text_color": background,
            "selection_foreground": "#f2f2f3",
            "selection_background": color0,
            "active_border_color": primary,
            "inactive_border_color": color0,
            "url_color": primary,
            "active_tab_foreground": on_primary,
            "active_tab_background": primary,
            "inactive_tab_foreground": "#afb3b6",
            "inactive_tab_background": color0,
            "cursor_trail_color": primary,
            "variant": var,
        }
        return colors
    except Exception as e:
        print(f"Warning: Failed to extract palette from {wallpaper_path}: {e}", file=sys.stderr)
        return None


def get_fallback_colors():
    """Default obsidian dark theme colors when no wallpaper is available."""
    colors_file = QS_DIR / "colors.json"
    if colors_file.exists():
        try:
            return json.loads(colors_file.read_text())
        except Exception:
            pass

    return {
        "primary": "#48bbf2",
        "secondary": "#676fac",
        "accent": "#48bbf2",
        "surface": "#171d20",
        "background": "#0e1315",
        "foreground": "#f2f2f3",
        "on_primary": "#12151c",
        "on_secondary": "#12151c",
        "on_surface": "#f2f2f3",
        "error": "#fd4663",
        "on_error": "#181f25",
        "muted": "#6b6372",
    }


def generate_hypr_lua(colors):
    """Write hypr/theme.lua so Hyprland window borders stay synchronized."""
    theme_file = Path(HOME) / ".hyprconf/hypr/theme.lua"
    legacy_noctalia = Path(HOME) / ".hyprconf/hypr/noctalia.lua"
    legacy_config_noctalia = Path(HOME) / ".config/hypr/noctalia.lua"

    def strip_hash(h):
        return str(h).lstrip("#")

    content = f"""-- Auto-generated by hypr-colors.py

local primary = "rgb({strip_hash(colors.get('primary', '#67aae4'))})"
local surface = "rgb({strip_hash(colors.get('surface', '#161f27'))})"
local on_surface = "rgb({strip_hash(colors.get('on_surface', '#f2f2f3'))})"
local secondary = "rgb({strip_hash(colors.get('secondary', '#5c60d6'))})"
local on_secondary = "rgb({strip_hash(colors.get('on_secondary', '#1f1825'))})"
local error = "rgb({strip_hash(colors.get('error', '#fd4663'))})"
local on_error = "rgb({strip_hash(colors.get('on_error', '#1f1825'))})"

local function apply_theme()
    hl.config({{
        general = {{
            col = {{
                active_border = primary,
                inactive_border = surface,
            }},
        }},
        group = {{
            col = {{
                border_active = secondary,
                border_inactive = surface,
                border_locked_active = error,
                border_locked_inactive = surface,
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
        surface = surface,
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
    """Write kitty/themes/theme.conf and kitty/themes/noctalia.conf so Kitty stays synchronized."""
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
        noctalia_file.write_text(content)
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
        src_legacy.write_text(content)
        dst_dir.mkdir(parents=True, exist_ok=True)
        dst.write_text(content)
        dst_legacy.write_text(content)
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



def generate_btop_theme(colors):
    """Write btop/themes/theme.theme and btop/themes/noctalia.theme so btop stays synchronized."""
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
        noctalia_file.write_text(content)
        config_themes = Path(HOME) / ".config/btop/themes"
        if config_themes.exists() and not config_themes.is_symlink():
            (config_themes / "theme.theme").write_text(content)
            (config_themes / "noctalia.theme").write_text(content)
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

    theme_qml_content = f"""pragma Singleton
import QtQuick

QtObject {{
    // Dynamic Obsidian Glassmorphism Palette
    readonly property color primary: "{colors.get('primary', '#48bbf2')}"
    readonly property color secondary: "{colors.get('secondary', '#676fac')}"
    readonly property color accent: "{colors.get('accent', '#48bbf2')}"
    readonly property color surface: "{colors.get('surface', '#171d20')}"
    readonly property color background: "{colors.get('background', '#0e1315')}"
    readonly property color foreground: "{colors.get('foreground', '#f2f2f3')}"
    readonly property color on_primary: "{colors.get('on_primary', '#12151c')}"
    readonly property color on_secondary: "{colors.get('on_secondary', '#12151c')}"
    readonly property color on_surface: "{colors.get('on_surface', '#f2f2f3')}"
    readonly property color error: "{colors.get('error', '#fd4663')}"
    readonly property color on_error: "{colors.get('on_error', '#181f25')}"
    readonly property color muted: "{colors.get('muted', '#6b6372')}"

    // Color helper functions
    function alpha(c, a) {{
        return Qt.rgba(c.r, c.g, c.b, a)
    }}
}}
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
""",
            "dock": """singleton Theme 1.0 Theme.qml
DockItem 1.0 DockItem.qml
DockContextMenu 1.0 DockContextMenu.qml
""",
            "launcher": """singleton Theme 1.0 Theme.qml
Style1 1.0 Style1.qml
Style2 1.0 Style2.qml
""",
            "launcher-theme": """singleton Theme 1.0 Theme.qml
""",
            "emoji": """singleton Theme 1.0 Theme.qml
""",
            "updater": """singleton Theme 1.0 Theme.qml
""",
            "welcome": """singleton Theme 1.0 Theme.qml
""",
            "widgets": """singleton Theme 1.0 Theme.qml
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
""",
            "lockscreen": """singleton Theme 1.0 Theme.qml
LockscreenSystemGraph 1.0 LockscreenSystemGraph.qml
LockscreenAudioVisualizer 1.0 LockscreenAudioVisualizer.qml
""",
            "bar": """singleton Theme 1.0 Theme.qml
Bar 1.0 Bar.qml
BarPopup 1.0 BarPopup.qml
Pill 1.0 Pill.qml
ActionButton 1.0 ActionButton.qml
MonoText 1.0 MonoText.qml
SvgIcon 1.0 SvgIcon.qml
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

        # Touch main entry points to trigger hot-reload in running daemons
        try:
            (QS_DIR / "island/shell.qml").touch()
            (QS_DIR / "dock/shell.qml").touch()
        except Exception:
            pass

        print(f"Quickshell colors synced: {QS_DIR}/Theme.qml")
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


def get_saved_variant():
    """Retrieve user-selected color variant from wallpaper_config.json."""
    user_cfg = Path.home() / ".local" / "share" / "hyprconf" / "wallpaper_config.json"
    cfg_file = user_cfg if user_cfg.exists() else (CACHE_DIR / "wallpaper_config.json")
    if cfg_file.exists():
        try:
            data = json.loads(cfg_file.read_text())
            if isinstance(data, dict) and data.get("color_variant"):
                return str(data["color_variant"]).lower()
        except Exception:
            pass
    return "vibrant"


def sync_theme(wallpaper_path=None, variant=None):
    # Auto-resolve current wallpaper if none provided
    if not wallpaper_path and CURRENT_WALLPAPER.exists():
        try:
            wallpaper_path = str(CURRENT_WALLPAPER.resolve())
        except Exception:
            pass

    if not variant:
        variant = get_saved_variant()
    else:
        # Persist chosen variant into wallpaper_config.json
        user_cfg = Path.home() / ".local" / "share" / "hyprconf" / "wallpaper_config.json"
        cfg_file = user_cfg if user_cfg.parent.exists() else (CACHE_DIR / "wallpaper_config.json")
        try:
            cfg_data = json.loads(cfg_file.read_text()) if cfg_file.exists() else {}
            if not isinstance(cfg_data, dict):
                cfg_data = {}
            if cfg_data.get("color_variant") != variant:
                cfg_data["color_variant"] = variant
                cfg_file.parent.mkdir(parents=True, exist_ok=True)
                cfg_file.write_text(json.dumps(cfg_data, indent=2))
        except Exception:
            pass

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

    # Reload Hyprland configuration to update border colors
    subprocess.run(["hyprctl", "reload", "config-only"], capture_output=True)

    # Send SIGUSR1 to reload running Kitty and Neovim instances
    subprocess.run("killall -SIGUSR1 kitty 2>/dev/null || true", shell=True)
    subprocess.run("killall -SIGUSR1 nvim 2>/dev/null || true", shell=True)

    # Notify KDE/Qt apps (Dolphin, etc.) to reload their color palette via DBus
    notify_kde_reload()

    # Sync Quickshell components (Theme.qml, qmldir, colors.json) and trigger hot-reload
    sync_quickshell_colors(colors)

    print(f"Theme colors applied ({variant}): primary={colors.get('primary')} accent={colors.get('accent')} surface={colors.get('surface')}")


def main():
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
        wall = None
        variant = None

        # Parse CLI arguments: supports `hypr-colors.py <wall> [variant]` or `--variant <var>`
        args = sys.argv[1:]
        idx = 0
        while idx < len(args):
            arg = args[idx]
            if arg in ("--variant", "-v") and idx + 1 < len(args):
                variant = args[idx + 1].strip().lower()
                idx += 2
            elif arg.startswith("--variant="):
                variant = arg.split("=", 1)[1].strip().lower()
                idx += 1
            elif not wall and os.path.exists(arg):
                wall = arg
                idx += 1
            elif not variant and arg.lower() in ("vibrant", "muted", "original", "warm", "cool", "pastel"):
                variant = arg.lower()
                idx += 1
            else:
                idx += 1

        if not wall and CURRENT_WALLPAPER.exists():
            wall = str(CURRENT_WALLPAPER.resolve())

        sync_theme(wall, variant=variant)
    finally:
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_UN)
            os.close(lock_fd)
        except Exception:
            pass


if __name__ == "__main__":
    main()
