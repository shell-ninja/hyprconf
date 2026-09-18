#!/usr/bin/env python3

import concurrent.futures
import glob
import hashlib
import json
import math
import os
import re
import signal
import subprocess
import sys
import threading
import time

import cairo
import gi
import requests

gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
gi.require_version('PangoCairo', '1.0')

from gi.repository import (Gdk, GdkPixbuf, GLib, Gtk, GtkLayerShell, Pango,
                           PangoCairo)

# ---- Paths & Defaults ------------------------------------------------------
DEFAULT_WALLPAPER_DIR = os.path.expanduser("~/.hyprconf/hypr/Wallpaper")
CACHE_DIR = os.path.expanduser("~/.hyprconf/hypr/.cache")
STREAM_CACHE_DIR = os.path.join(CACHE_DIR, "stream")
CONFIG_FILE = os.path.join(CACHE_DIR, "wallpaper_config.json")
WALL_CACHE_FILE = os.path.join(CACHE_DIR, ".wallpaper")
CURRENT_WALL_LINK = os.path.join(CACHE_DIR, "current_wallpaper.png")
SCRIPTS_DIR = os.path.expanduser("~/.hyprconf/hypr/scripts")
COLORS_SCRIPT = os.path.join(SCRIPTS_DIR, "noctalia-colors.py")

THUMB_CACHE_DIR = os.path.expanduser("~/.cache/noctalia-wallpaper-panel/thumbnails")
THUMB_W, THUMB_H = 400, 230

CARD_W, CARD_H = 196, 112
CARD_RADIUS = 14
SPACING = 160
SCALE_STEP = 0.13
MIN_SCALE = 0.48
OPACITY_STEP = 0.18
MIN_OPACITY = 0.25
SHEAR = 0.50
MAX_VISIBLE_OFFSET = 5

NOCTALIA_COLORS_FILE = os.path.expanduser("~/.config/noctalia/colors.json")

DEFAULT_PALETTE = {
    "mPrimary": "#cba6f7",
    "mOnPrimary": "#1e1e2e",
    "mSecondary": "#b4befe",
    "mOnSecondary": "#1e1e2e",
    "mTertiary": "#f5c2e7",
    "mOnTertiary": "#1e1e2e",
    "mError": "#f38ba8",
    "mOnError": "#1e1e2e",
    "mSurface": "#12121a",
    "mOnSurface": "#cdd6f4",
    "mSurfaceVariant": "#1e1e2e",
    "mOnSurfaceVariant": "#a6adc8",
    "mOutline": "#6c7086",
    "mShadow": "#000000",
    "mHover": "#b4befe",
    "mOnHover": "#1e1e2e",
}

DEFAULT_CONFIG = {
    "wallpaper_dir": DEFAULT_WALLPAPER_DIR,
    "wallhaven_api_key": "",
    "wallhaven_username": "",
    "wallhaven_sync_dir": os.path.join(DEFAULT_WALLPAPER_DIR, "wallhaven"),
    "wallhaven_last_col_id": "",
    "wallhaven_purity": "100",
    "wallhaven_categories": "110",
    "wallhaven_sorting": "toplist",
    "wallhaven_resolution": "all",
    "wallhaven_sync_limit": 48,
    "active_mode": "local",
}

WALLHAVEN_API_BASE = "https://wallhaven.cc/api/v1"
USER_AGENT = "NoctaliaWallpaperPanel/2.0"


def load_config():
    cfg = dict(DEFAULT_CONFIG)
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r") as f:
                data = json.load(f)
                if isinstance(data, dict):
                    cfg.update(data)
        except Exception:
            pass
    cfg["wallpaper_dir"] = os.path.expanduser(cfg.get("wallpaper_dir") or DEFAULT_WALLPAPER_DIR)
    cfg["wallhaven_sync_dir"] = os.path.expanduser(cfg.get("wallhaven_sync_dir") or os.path.join(DEFAULT_WALLPAPER_DIR, "wallhaven"))
    cfg["wallhaven_purity"] = "100"
    return cfg


def save_config(cfg):
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        with open(CONFIG_FILE, "w") as f:
            json.dump(cfg, f, indent=2)
    except Exception as e:
        print(f"Error saving config: {e}", file=sys.stderr)


# ---- Wallhaven API Client --------------------------------------------------
def wh_fetch_collections(api_key="", username=""):
    headers = {"User-Agent": USER_AGENT}
    api_key = (api_key or "").strip()
    username = (username or "").strip()

    if api_key:
        url = f"{WALLHAVEN_API_BASE}/collections"
        params = {"apikey": api_key}
    elif username:
        url = f"{WALLHAVEN_API_BASE}/collections/{username}"
        params = {}
    else:
        return False, [], "Enter your API Key or Username"

    try:
        r = requests.get(url, headers=headers, params=params, timeout=12)
        if r.status_code == 200:
            data = r.json().get("data", [])
            return True, data, f"Found {len(data)} collections"
        elif r.status_code == 401:
            return False, [], "Unauthorized: Invalid API Key"
        elif r.status_code == 404:
            return False, [], "User or collection not found"
        elif r.status_code == 429:
            return False, [], "Rate limit reached (45 req/min)"
        else:
            return False, [], f"Wallhaven error (HTTP {r.status_code})"
    except Exception as e:
        return False, [], f"Connection error: {e}"


def wh_fetch_collection_wallpapers(username, col_id, api_key="", max_count=48):
    headers = {"User-Agent": USER_AGENT}
    username = (username or "").strip()
    api_key = (api_key or "").strip()

    if not username:
        return False, [], "Username is required"

    url = f"{WALLHAVEN_API_BASE}/collections/{username}/{col_id}"
    page = 1
    collected = []

    while len(collected) < max_count:
        params = {"page": page}
        if api_key:
            params["apikey"] = api_key
        try:
            r = requests.get(url, headers=headers, params=params, timeout=12)
            if r.status_code != 200:
                if r.status_code == 401:
                    return False, collected, "Unauthorized: Private collection requires valid API Key"
                elif r.status_code == 429:
                    return False, collected, "Rate limit reached"
                return False, collected, f"Error {r.status_code} fetching page {page}"

            data = r.json()
            items = data.get("data", [])
            # Filter strictly: only safe / SFW wallpapers allowed
            sfw_items = [it for it in items if str(it.get("purity", "")).lower() == "sfw"]
            if not sfw_items and not items:
                break
            collected.extend(sfw_items)

            meta = data.get("meta", {})
            last_page = meta.get("last_page", page)
            if page >= last_page or len(collected) >= max_count:
                break
            page += 1
            time.sleep(0.15)
        except Exception as e:
            return False, collected, f"Connection error: {e}"

    return True, collected[:max_count], f"Found {len(collected[:max_count])} wallpapers"


def wh_search_wallpapers(query="", sorting="toplist", categories="110", purity="100", resolution="all", api_key="", page=1, seed=""):
    headers = {"User-Agent": USER_AGENT}
    url = f"{WALLHAVEN_API_BASE}/search"
    params = {
        "q": query,
        "sorting": sorting,
        "categories": categories,
        "purity": "100",  # Enforce strict SFW only
        "page": page
    }
    if seed and sorting == "random":
        params["seed"] = seed

    api_key = (api_key or "").strip()
    if api_key:
        params["apikey"] = api_key

    # Resolution & Ratio
    if resolution == "1080p":
        params["atleast"] = "1920x1080"
    elif resolution == "1440p":
        params["atleast"] = "2560x1440"
    elif resolution == "4k":
        params["atleast"] = "3840x2160"
    elif resolution == "ultrawide":
        params["ratios"] = "21x9,32x9"

    try:
        r = requests.get(url, headers=headers, params=params, timeout=12)
        if r.status_code == 200:
            res = r.json()
            raw_items = res.get("data", [])
            items = [x for x in raw_items if str(x.get("purity", "")).lower() == "sfw"]
            meta = res.get("meta", {})
            return True, items, f"Found {len(items)} wallpapers", meta
        elif r.status_code == 401:
            return False, [], "Invalid API Key", {}
        elif r.status_code == 429:
            retry_after = r.headers.get("Retry-After") or "5"
            return False, [], f"Rate limit reached (wait {retry_after}s)", {"retry_after": retry_after}
        else:
            return False, [], f"HTTP {r.status_code}", {}
    except Exception as e:
        return False, [], f"Connection error: {e}", {}


def wh_download_file(url, target_dir):
    os.makedirs(target_dir, exist_ok=True)
    filename = os.path.basename(url.split("?")[0])
    target_path = os.path.join(target_dir, filename)

    if os.path.exists(target_path) and os.path.getsize(target_path) > 0:
        return True, "exists", filename

    tmp_path = target_path + ".tmp"
    headers = {"User-Agent": USER_AGENT}
    try:
        r = requests.get(url, headers=headers, stream=True, timeout=25)
        if r.status_code == 200:
            with open(tmp_path, "wb") as f:
                for chunk in r.iter_content(chunk_size=65536):
                    if chunk:
                        f.write(chunk)
            os.replace(tmp_path, target_path)
            return True, "downloaded", filename
        else:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
            return False, f"HTTP {r.status_code}", filename
    except Exception as e:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
        return False, str(e), filename


# ---- Theme Parsing & Palette Loading ---------------------------------------
def load_noctalia_palette():
    palette = dict(DEFAULT_PALETTE)
    try:
        with open(NOCTALIA_COLORS_FILE, "r") as f:
            data = json.load(f)
        if isinstance(data, dict) and ("dark" in data or "light" in data):
            data = data.get("dark") or data.get("light") or {}
        if isinstance(data, dict):
            for key in palette:
                value = data.get(key)
                if isinstance(value, str) and value.startswith("#"):
                    palette[key] = value
    except Exception:
        pass
    return palette


ADW_GTK_USER_CSS = [
    os.path.expanduser("~/.config/gtk-4.0/gtk.css"),
    os.path.expanduser("~/.config/gtk-3.0/gtk.css"),
]

SYSTEM_THEME_DIRS = [
    os.path.expanduser("~/.local/share/themes"),
    os.path.expanduser("~/.themes"),
    "/usr/share/themes",
]

_DEFINE_COLOR_RE = re.compile(r'@define-color\s+([A-Za-z0-9_\-]+)\s+([^;]+);')
_IMPORT_RE = re.compile(r'@import\s+url\(\s*["\']?([^"\')]+)["\']?\s*\)\s*;?')
_COMMENT_RE = re.compile(r'/\*.*?\*/', re.DOTALL)

ADW_ROLE_CANDIDATES = {
    "mPrimary":          ["accent_color", "accent_bg_color"],
    "mOnPrimary":        ["accent_fg_color"],
    "mSecondary":        ["accent_bg_color", "accent_color"],
    "mOnSecondary":      ["accent_fg_color"],
    "mTertiary":         ["accent_color"],
    "mOnTertiary":       ["accent_fg_color"],
    "mError":            ["destructive_color", "destructive_bg_color", "error_color"],
    "mOnError":          ["destructive_fg_color", "error_fg_color"],
    "mSurface":          ["window_bg_color"],
    "mOnSurface":        ["window_fg_color"],
    "mSurfaceVariant":   ["view_bg_color", "card_bg_color"],
    "mOnSurfaceVariant": ["view_fg_color", "card_fg_color"],
    "mOutline":          ["border_color", "headerbar_border_color", "shade_color"],
    "mShadow":           ["shade_color"],
    "mHover":            ["accent_bg_color", "accent_color"],
    "mOnHover":          ["accent_fg_color"],
}


def _resolve_color_value(value, known, depth=0):
    if depth > 8 or not value:
        return None
    value = value.strip()
    if value.startswith("@"):
        return _resolve_color_value(known.get(value[1:].strip()), known, depth + 1)
    m = re.match(r'^(?:alpha|shade|mix|lighter|darker)\(\s*([^,)]+)', value)
    if m:
        return _resolve_color_value(m.group(1), known, depth + 1)
    if re.match(r'^#[0-9a-fA-F]{3,8}$', value):
        return value
    return None


def parse_gtk_css_colors(path, _seen=None):
    if _seen is None:
        _seen = set()
    real_path = os.path.realpath(path)
    if real_path in _seen or not os.path.isfile(real_path):
        return {}
    _seen.add(real_path)

    try:
        with open(real_path, "r", errors="ignore") as f:
            text = _COMMENT_RE.sub("", f.read())
    except OSError:
        return {}

    colors = {}
    base_dir = os.path.dirname(real_path)
    for m in _IMPORT_RE.finditer(text):
        imp_path = m.group(1)
        if not os.path.isabs(imp_path):
            imp_path = os.path.join(base_dir, imp_path)
        colors.update(parse_gtk_css_colors(imp_path, _seen))

    for m in _DEFINE_COLOR_RE.finditer(text):
        name, raw_value = m.group(1), m.group(2)
        resolved = _resolve_color_value(raw_value, colors)
        if resolved:
            colors[name] = resolved
    return colors


def _gsettings_get(schema, key):
    try:
        out = subprocess.run(
            ["gsettings", "get", schema, key],
            capture_output=True, text=True, timeout=1.5,
        )
        if out.returncode == 0:
            return out.stdout.strip().strip("'\"")
    except Exception:
        pass
    return None


def _prefers_dark():
    scheme = _gsettings_get("org.gnome.desktop.interface", "color-scheme")
    if scheme:
        return "dark" in scheme
    return True


def _find_system_adw_theme_css():
    theme_name = _gsettings_get("org.gnome.desktop.interface", "gtk-theme") or "adw-gtk3"
    variant_names = [theme_name]
    if _prefers_dark() and not theme_name.endswith("-dark"):
        variant_names.insert(0, theme_name + "-dark")
    for base in SYSTEM_THEME_DIRS:
        for name in variant_names:
            for gtk_ver in ("gtk-4.0", "gtk-3.0"):
                candidate = os.path.join(base, name, gtk_ver, "gtk.css")
                if os.path.isfile(candidate):
                    return candidate
    return None


def load_adw_gtk_colors():
    raw = {}
    system_css = _find_system_adw_theme_css()
    if system_css:
        raw.update(parse_gtk_css_colors(system_css))
    for path in reversed(ADW_GTK_USER_CSS):
        raw.update(parse_gtk_css_colors(path))
    return raw


def adw_colors_to_material(raw):
    out = {}
    for role, candidates in ADW_ROLE_CANDIDATES.items():
        for name in candidates:
            value = raw.get(name)
            if value:
                out[role] = value
                break
    return out


def load_palette():
    palette = load_noctalia_palette()
    try:
        adw_material = adw_colors_to_material(load_adw_gtk_colors())
        palette.update(adw_material)
    except Exception:
        pass
    return palette


def _hex_to_rgb(hexcolor):
    h = hexcolor.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    try:
        return (int(h[0:2], 16) / 255.0, int(h[2:4], 16) / 255.0, int(h[4:6], 16) / 255.0)
    except (ValueError, IndexError):
        return (1.0, 1.0, 1.0)


def _rgba_css(hexcolor, alpha):
    r, g, b = (round(c * 255) for c in _hex_to_rgb(hexcolor))
    return f"rgba({r}, {g}, {b}, {alpha})"


def build_css(p):
    return f"""
* {{
    all: unset;
    font-family: 'JetBrainsMono Nerd Font', 'Fira Code', sans-serif;
}}

window:not(.popup),
window.background:not(.popup),
overlay {{
    background-color: transparent;
}}

/* Solid background and styling for ComboBox popup menus and dropdowns */
window.popup,
window.popup.background,
window.popup decoration,
menu,
.menu,
combobox menu,
combobox window.popup {{
    background-color: {p['mSurfaceVariant']};
    color: {p['mOnSurface']};
    border: 1px solid {_rgba_css(p['mOutline'], 0.35)};
    border-radius: 10px;
    padding: 4px;
    box-shadow: 0 12px 32px rgba(0, 0, 0, 0.85);
}}

menuitem,
combobox menuitem {{
    background-color: transparent;
    color: {p['mOnSurface']};
    border-radius: 6px;
    padding: 6px 14px;
    font-size: 11px;
    font-weight: 500;
}}

menuitem:hover,
combobox menuitem:hover {{
    background-color: {_rgba_css(p['mPrimary'], 0.25)};
    color: {p['mPrimary']};
}}

menuitem:active,
menuitem:selected,
combobox menuitem:active,
combobox menuitem:selected {{
    background-color: {_rgba_css(p['mPrimary'], 0.35)};
    color: {p['mPrimary']};
    font-weight: bold;
}}

menuitem label,
combobox menuitem label {{
    color: inherit;
}}

.main-container {{
    background-color: {_rgba_css(p['mSurface'], 0.92)};
    border: 1px solid {_rgba_css(p['mOutline'], 0.30)};
    border-radius: 22px;
    padding: 12px 18px 12px 18px;
    box-shadow: none;
}}

/* Wallhaven Options & Filter Bar */
.filter-bar {{
    padding: 0 4px;
    margin-top: 2px;
    margin-bottom: 4px;
}}

.filter-btn {{
    background-color: {_rgba_css(p['mSurfaceVariant'], 0.60)};
    border: 1px solid {_rgba_css(p['mOutline'], 0.22)};
    border-radius: 8px;
    padding: 3px 11px;
    color: {p['mOnSurfaceVariant']};
    font-size: 11px;
    font-weight: 500;
    transition: all 180ms ease;
}}

.filter-btn:hover {{
    color: {p['mOnSurface']};
    background-color: {_rgba_css(p['mSurfaceVariant'], 0.85)};
    border-color: {_rgba_css(p['mPrimary'], 0.5)};
}}

.filter-btn:checked, .filter-btn.active, .filter-btn-active {{
    background-color: {_rgba_css(p['mPrimary'], 0.25)};
    border: 1px solid {p['mPrimary']};
    color: {p['mPrimary']};
    font-weight: bold;
    box-shadow: 0 0 10px {_rgba_css(p['mPrimary'], 0.30)};
}}

/* Purity toggles with Wallhaven signature colors */
.purity-btn-sfw {{
    background-color: rgba(106, 176, 76, 0.15);
    border: 1px solid rgba(106, 176, 76, 0.35);
    border-radius: 8px;
    padding: 3px 10px;
    color: rgba(166, 227, 161, 0.7);
    font-size: 11px;
    font-weight: 500;
    transition: all 180ms ease;
}}

.purity-btn-sfw:checked, .purity-btn-sfw.active {{
    background-color: rgba(106, 176, 76, 0.35);
    border: 1px solid #6ab04c;
    color: #a6e3a1;
    font-weight: bold;
    box-shadow: 0 0 10px rgba(106, 176, 76, 0.35);
}}

.purity-btn-sketchy {{
    background-color: rgba(240, 147, 43, 0.15);
    border: 1px solid rgba(240, 147, 43, 0.35);
    border-radius: 8px;
    padding: 3px 10px;
    color: rgba(249, 226, 175, 0.7);
    font-size: 11px;
    font-weight: 500;
    transition: all 180ms ease;
}}

.purity-btn-sketchy:checked, .purity-btn-sketchy.active {{
    background-color: rgba(240, 147, 43, 0.35);
    border: 1px solid #f0932b;
    color: #f9e2af;
    font-weight: bold;
    box-shadow: 0 0 10px rgba(240, 147, 43, 0.35);
}}

.purity-btn-nsfw {{
    background-color: rgba(235, 77, 75, 0.15);
    border: 1px solid rgba(235, 77, 75, 0.35);
    border-radius: 8px;
    padding: 3px 10px;
    color: rgba(243, 139, 168, 0.7);
    font-size: 11px;
    font-weight: 500;
    transition: all 180ms ease;
}}

.purity-btn-nsfw:checked, .purity-btn-nsfw.active {{
    background-color: rgba(235, 77, 75, 0.35);
    border: 1px solid #eb4d4b;
    color: #f38ba8;
    font-weight: bold;
    box-shadow: 0 0 10px rgba(235, 77, 75, 0.35);
}}

/* Carousel bottom control bar */
.search-bar {{
    background-color: {_rgba_css(p['mSurfaceVariant'], 0.75)};
    border: 1px solid {_rgba_css(p['mOutline'], 0.3)};
    border-radius: 10px;
    padding: 6px 12px;
    transition: border-color 240ms ease, box-shadow 240ms ease;
}}

.search-bar:focus-within {{
    border-color: {_rgba_css(p['mPrimary'], 0.5)};
    box-shadow: 0 0 16px {_rgba_css(p['mPrimary'], 0.25)};
}}

.search-icon {{
    color: {p['mPrimary']};
    font-size: 13px;
    margin-right: 6px;
}}

.search-entry {{
    color: {p['mOnSurface']};
    font-size: 12px;
    background: transparent;
    border: none;
}}

.search-entry:focus {{
    outline: none;
}}

.clear-btn {{
    color: {p['mOnSurfaceVariant']};
    font-size: 12px;
    padding: 2px 6px;
    border-radius: 6px;
}}

.clear-btn:hover {{
    color: {p['mError']};
    background-color: {_rgba_css(p['mError'], 0.15)};
}}

/* Action buttons */
.control-btn {{
    background-color: {_rgba_css(p['mSurfaceVariant'], 0.75)};
    border: 1px solid {_rgba_css(p['mOutline'], 0.3)};
    border-radius: 10px;
    padding: 6px 14px;
    color: {p['mOnSurface']};
    font-size: 12px;
    font-weight: bold;
    transition: all 200ms ease;
}}

.control-btn:hover {{
    border-color: {_rgba_css(p['mPrimary'], 0.6)};
    color: {p['mPrimary']};
    background-color: {_rgba_css(p['mSurfaceVariant'], 0.95)};
}}

.mode-btn-active {{
    background-color: {_rgba_css(p['mPrimary'], 0.20)};
    border: 1px solid {p['mPrimary']};
    border-radius: 10px;
    padding: 6px 14px;
    color: {p['mPrimary']};
    font-size: 12px;
    font-weight: bold;
    box-shadow: 0 0 12px {_rgba_css(p['mPrimary'], 0.30)};
}}

.mode-btn-active:hover {{
    background-color: {_rgba_css(p['mPrimary'], 0.35)};
}}

.apply-btn {{
    background-color: {p['mPrimary']};
    color: {p['mOnPrimary']};
    border-radius: 10px;
    padding: 7px 22px;
    font-size: 12px;
    font-weight: bold;
    box-shadow: 0 4px 14px {_rgba_css(p['mPrimary'], 0.40)};
    transition: all 180ms ease;
}}

.apply-btn:hover {{
    background-color: {p.get('mHover') or p['mSecondary']};
    box-shadow: 0 0 20px {_rgba_css(p['mPrimary'], 0.70)};
}}

.apply-btn:active {{
    opacity: 0.85;
}}

.wh-accent-btn {{
    background-color: {_rgba_css(p['mPrimary'], 0.15)};
    border: 1px solid {_rgba_css(p['mPrimary'], 0.45)};
    border-radius: 10px;
    padding: 6px 14px;
    color: {p['mPrimary']};
    font-size: 12px;
    font-weight: bold;
    transition: all 200ms ease;
}}

.wh-accent-btn:hover {{
    background-color: {_rgba_css(p['mPrimary'], 0.30)};
    border-color: {p['mPrimary']};
    box-shadow: 0 0 12px {_rgba_css(p['mPrimary'], 0.35)};
}}

/* Wallhaven Hub View styling */
.wh-card {{
    background-color: {_rgba_css(p['mSurfaceVariant'], 0.52)};
    border: 1px solid {_rgba_css(p['mOutline'], 0.25)};
    border-radius: 12px;
    padding: 10px 14px;
}}

.wh-hub-title {{
    color: {p['mPrimary']};
    font-size: 14px;
    font-weight: bold;
}}

.wh-card-title {{
    color: {p['mOnSurface']};
    font-size: 12px;
    font-weight: bold;
}}

.wh-label {{
    color: {p['mOnSurfaceVariant']};
    font-size: 11px;
}}

.wh-entry {{
    background-color: {_rgba_css(p['mSurface'], 0.85)};
    border: 1px solid {_rgba_css(p['mOutline'], 0.3)};
    border-radius: 8px;
    padding: 5px 9px;
    color: {p['mOnSurface']};
    font-size: 11px;
}}

.wh-entry:focus {{
    border-color: {p['mPrimary']};
}}

.wh-combo {{
    background-color: {_rgba_css(p['mSurface'], 0.85)};
    border: 1px solid {_rgba_css(p['mOutline'], 0.3)};
    border-radius: 8px;
    padding: 3px 8px;
    color: {p['mOnSurface']};
    font-size: 11px;
}}

.wh-btn-primary {{
    background-color: {p['mPrimary']};
    color: {p['mOnPrimary']};
    border-radius: 8px;
    padding: 6px 12px;
    font-size: 11px;
    font-weight: bold;
    transition: all 180ms ease;
}}

.wh-btn-primary:hover {{
    background-color: {p.get('mHover') or p['mSecondary']};
    box-shadow: 0 0 10px {_rgba_css(p['mPrimary'], 0.4)};
}}

.wh-btn-secondary {{
    background-color: {_rgba_css(p['mSurfaceVariant'], 0.85)};
    border: 1px solid {_rgba_css(p['mOutline'], 0.35)};
    color: {p['mOnSurface']};
    border-radius: 8px;
    padding: 5px 10px;
    font-size: 11px;
    font-weight: 500;
    transition: all 180ms ease;
}}

.wh-btn-secondary:hover {{
    border-color: {p['mPrimary']};
    color: {p['mPrimary']};
}}

.wh-status-label {{
    color: {p['mOnSurfaceVariant']};
    font-size: 11px;
}}

progressbar trough {{
    background-color: {_rgba_css(p['mSurface'], 0.8)};
    border: 1px solid {_rgba_css(p['mOutline'], 0.25)};
    border-radius: 6px;
    min-height: 8px;
}}

progressbar progress {{
    background-color: {p['mPrimary']};
    border-radius: 6px;
    min-height: 8px;
}}
""".encode()


# ---- CoverFlow Cairo Carousel ----------------------------------------------
class CoverFlow(Gtk.DrawingArea):
    def __init__(self, on_activate, palette, on_near_end=None):
        super().__init__()
        self.on_activate = on_activate
        self.on_near_end = on_near_end

        self.update_palette(palette, redraw=False)

        self.items = []
        self.selected_index = 0
        self.visual_position = 0.0
        self.hover_index = None

        self._pixbuf_cache = {}
        self._loading = set()
        self._tick_id = None
        self._last_frame_time = None
        self._glow_phase = 0.0

        os.makedirs(THUMB_CACHE_DIR, exist_ok=True)
        os.makedirs(STREAM_CACHE_DIR, exist_ok=True)
        self._executor = concurrent.futures.ThreadPoolExecutor(max_workers=6, thread_name_prefix="thumb-load")

        self.set_size_request(-1, 310)
        self.set_can_focus(False)

        # Continuous glow animation (~30fps)
        GLib.timeout_add(33, self._glow_tick)

        self.add_events(
            Gdk.EventMask.POINTER_MOTION_MASK
            | Gdk.EventMask.BUTTON_PRESS_MASK
            | Gdk.EventMask.LEAVE_NOTIFY_MASK
            | Gdk.EventMask.SCROLL_MASK
        )
        self.connect("draw", self.on_draw)
        self.connect("motion-notify-event", self.on_motion)
        self.connect("button-press-event", self.on_button_press)
        self.connect("leave-notify-event", self.on_leave)
        self.connect("scroll-event", self.on_scroll)

    def _glow_tick(self):
        self._glow_phase += 0.04
        if self._glow_phase > 2 * math.pi:
            self._glow_phase -= 2 * math.pi
        self.queue_draw()
        return True

    def _get_item_key(self, item):
        if isinstance(item, dict):
            return item.get("id") or item.get("url")
        return item

    def _get_item_title(self, item):
        if isinstance(item, dict):
            return item.get("title") or f"wallhaven-{item.get('id', '')}"
        return os.path.splitext(os.path.basename(item))[0]

    def update_palette(self, palette, redraw=True):
        self.color_selected = _hex_to_rgb(palette["mPrimary"])
        self.color_hover = _hex_to_rgb(palette.get("mHover") or palette["mSecondary"])
        self.color_title = _hex_to_rgb(palette["mOnSurface"])
        self.color_muted = _hex_to_rgb(palette["mOnSurfaceVariant"])
        self.color_surface_variant = _hex_to_rgb(palette["mSurfaceVariant"])
        self.color_outline = _hex_to_rgb(palette["mOutline"])
        if redraw:
            self.queue_draw()

    def set_items(self, items, keep_path=None, is_append=False):
        self.items = items
        if not items:
            self.selected_index = 0
            self.visual_position = 0.0
            self.queue_draw()
            return

        if is_append:
            self.selected_index = max(0, min(self.selected_index, len(items) - 1))
            self._request_pixbuf(self.items[self.selected_index])
            self.queue_draw()
            return

        idx = 0
        if keep_path:
            target_key = self._get_item_key(keep_path)
            for i, p in enumerate(items):
                key = self._get_item_key(p)
                if key == target_key or os.path.basename(str(key)) == os.path.basename(str(target_key)):
                    idx = i
                    break
        self.selected_index = max(0, min(idx, len(items) - 1))
        self.visual_position = float(self.selected_index)
        self._request_pixbuf(self.items[self.selected_index])
        self.queue_draw()

    def set_selected(self, index, animate=True):
        if not self.items:
            return
        index = max(0, min(index, len(self.items) - 1))
        self.selected_index = index
        if not animate:
            self.visual_position = float(index)
        self._request_pixbuf(self.items[index])
        self._ensure_animating()
        self.queue_draw()
        if self.on_near_end and index >= len(self.items) - 4:
            self.on_near_end()

    def get_selected_item(self):
        if self.items and 0 <= self.selected_index < len(self.items):
            return self.items[self.selected_index]
        return None

    def _thumb_cache_path(self, item):
        if isinstance(item, dict):
            thumb_url = item.get("thumb") or item.get("url", "")
            digest = hashlib.sha1(thumb_url.encode()).hexdigest()
            return os.path.join(THUMB_CACHE_DIR, f"wh_online_{item['id']}_{digest[:10]}.png")
        else:
            try:
                mtime = int(os.path.getmtime(item))
            except OSError:
                mtime = 0
            digest = hashlib.sha1(f"{item}:{mtime}:{THUMB_W}x{THUMB_H}".encode()).hexdigest()
            return os.path.join(THUMB_CACHE_DIR, f"{digest}.png")

    def _request_pixbuf(self, item):
        key = self._get_item_key(item)
        if key in self._pixbuf_cache or key in self._loading:
            return
        self._loading.add(key)
        self._executor.submit(self._load_pixbuf_worker, item)

    def _load_pixbuf_worker(self, item):
        key = self._get_item_key(item)
        pb = None
        try:
            thumb_path = self._thumb_cache_path(item)
            if not os.path.exists(thumb_path):
                if isinstance(item, dict):
                    thumb_url = item.get("thumb") or item.get("url")
                    r = requests.get(thumb_url, headers={"User-Agent": USER_AGENT}, timeout=10)
                    if r.status_code == 200:
                        with open(thumb_path + ".tmp", "wb") as f:
                            f.write(r.content)
                        os.replace(thumb_path + ".tmp", thumb_path)
                else:
                    pb_orig = GdkPixbuf.Pixbuf.new_from_file_at_scale(item, THUMB_W, THUMB_H, False)
                    try:
                        pb_orig.savev(thumb_path, "png", [], [])
                    except Exception:
                        pass

            if os.path.exists(thumb_path):
                pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(thumb_path, THUMB_W, THUMB_H, False)
        except Exception:
            pb = None
        GLib.idle_add(self._on_pixbuf_ready, key, pb)

    def _on_pixbuf_ready(self, key, pb):
        self._pixbuf_cache[key] = pb
        self._loading.discard(key)
        self.queue_draw()
        return False

    def _ensure_animating(self):
        if self._tick_id is not None:
            return
        self._last_frame_time = None
        self._tick_id = self.add_tick_callback(self._on_tick)

    def _on_tick(self, widget, frame_clock):
        now = frame_clock.get_frame_time()
        dt = 1 / 60.0 if self._last_frame_time is None else max(0.0, (now - self._last_frame_time) / 1_000_000.0)
        self._last_frame_time = now

        target = float(self.selected_index)
        diff = target - self.visual_position
        if abs(diff) < 0.002:
            self.visual_position = target
            self.queue_draw()
            self._tick_id = None
            self._last_frame_time = None
            return False

        speed = 1 - math.exp(-dt * 14.0)
        self.visual_position += diff * speed
        self.queue_draw()
        return True

    def _card_transform(self, offset):
        alloc = self.get_allocation()
        cx = alloc.width / 2.0
        cy = 168.0

        dist = abs(offset)
        # Scaled hero card at center (scale ~1.40), smoothly tapering to neighbors (~0.86)
        if dist < 1.0:
            t = (1.0 + math.cos(dist * math.pi)) / 2.0
            scale = 0.86 + t * 0.54  # 1.40 at center (dist=0), 0.86 at dist=1
            y_lift = t * -28.0      # Float upward into the air, surpassing the top border
        else:
            scale = max(MIN_SCALE, 0.86 - (dist - 1.0) * SCALE_STEP)
            y_lift = 0.0

        opacity = max(MIN_OPACITY, 1.0 - dist * OPACITY_STEP)
        shear = 0.0 if dist < 0.001 else math.copysign(SHEAR, offset) * min(1.0, dist)

        x = cx + offset * SPACING
        y = cy + y_lift
        return x, y, scale, shear, opacity

    def _visible_offsets(self):
        alloc = self.get_allocation()
        half = alloc.width / 2.0 + CARD_W
        max_offset = max(1, int(half / SPACING) + 1, MAX_VISIBLE_OFFSET)
        lo = int(math.floor(self.visual_position - max_offset))
        hi = int(math.ceil(self.visual_position + max_offset))
        return range(lo, hi + 1)

    def _hit_test(self, mx, my):
        candidates = [i for i in self._visible_offsets() if 0 <= i < len(self.items)]
        candidates.sort(key=lambda i: abs(i - self.visual_position))
        for i in candidates:
            offset = i - self.visual_position
            x, y, scale, shear, _ = self._card_transform(offset)
            if scale <= 0.001:
                continue
            py = (my - y) / scale
            px = (mx - x) / scale - shear * py
            if -CARD_W / 2 <= px <= CARD_W / 2 and -CARD_H / 2 <= py <= CARD_H / 2:
                return i
        return None

    @staticmethod
    def _rounded_rect(cr, w, h, r):
        cr.new_sub_path()
        cr.arc(w / 2 - r, -h / 2 + r, r, -math.pi / 2, 0)
        cr.arc(w / 2 - r, h / 2 - r, r, 0, math.pi / 2)
        cr.arc(-w / 2 + r, h / 2 - r, r, math.pi / 2, math.pi)
        cr.arc(-w / 2 + r, -h / 2 + r, r, math.pi, 3 * math.pi / 2)
        cr.close_path()

    def on_draw(self, widget, cr):
        alloc = self.get_allocation()
        if not self.items:
            layout = PangoCairo.create_layout(cr)
            layout.set_text("No wallpapers found for current filters (Check settings or press +24 More)", -1)
            _, h = layout.get_pixel_size()
            cr.move_to(24, alloc.height / 2 - h / 2)
            cr.set_source_rgba(*self.color_muted, 0.85)
            PangoCairo.show_layout(cr, layout)
            return

        offsets = [i for i in self._visible_offsets() if 0 <= i < len(self.items)]
        offsets.sort(key=lambda i: -abs(i - self.visual_position))
        for i in offsets:
            self._draw_card(cr, i, i - self.visual_position)

    def _draw_card(self, cr, index, offset):
        item = self.items[index]
        key = self._get_item_key(item)
        x, y, scale, shear, opacity = self._card_transform(offset)
        is_selected = index == self.selected_index
        is_hover = index == self.hover_index

        cr.save()
        cr.translate(x, y)
        cr.scale(scale, scale)
        cr.transform(cairo.Matrix(1, 0, shear, 1, 0, 0))

        if is_selected:
            glow = self.color_hover if (is_hover and self.hover_index != self.selected_index) else self.color_selected
            # Outward-rippling animated weave with defined luminous rings
            ph = self._glow_phase
            for i, (pad, base_alpha) in enumerate(((30, 0.035), (22, 0.065), (15, 0.11), (9, 0.17), (3, 0.25))):
                wave = 0.5 + 0.5 * math.sin(ph - i * 0.9)  # outward propagating ripple
                alpha = base_alpha * (0.6 + 0.4 * wave)
                pad_anim = pad + wave * 4.0  # organic wave breathing
                cr.save()
                self._rounded_rect(cr, CARD_W + pad_anim * 2, CARD_H + pad_anim * 2, CARD_RADIUS + pad_anim / 2)
                cr.set_source_rgba(*glow, alpha)
                cr.fill_preserve()
                cr.set_source_rgba(*glow, min(1.0, alpha * 1.5))
                cr.set_line_width(1.0)
                cr.stroke()
                cr.restore()

        cr.save()
        self._rounded_rect(cr, CARD_W, CARD_H, CARD_RADIUS)
        cr.clip()
        cr.set_source_rgba(*self.color_surface_variant, 1.0)
        cr.paint()
        pb = self._pixbuf_cache.get(key)
        if pb is None:
            self._request_pixbuf(item)
        if pb is not None:
            s = max(CARD_W / pb.get_width(), CARD_H / pb.get_height())
            cr.save()
            cr.scale(s, s)
            Gdk.cairo_set_source_pixbuf(cr, pb, -pb.get_width() / 2, -pb.get_height() / 2)
            cr.paint_with_alpha(opacity)
            cr.restore()
        elif key in self._pixbuf_cache:
            layout = PangoCairo.create_layout(cr)
            layout.set_text("?", -1)
            w, h = layout.get_pixel_size()
            cr.move_to(-w / 2, -h / 2)
            cr.set_source_rgba(*self.color_muted, opacity)
            PangoCairo.show_layout(cr, layout)
        cr.restore()

        self._rounded_rect(cr, CARD_W, CARD_H, CARD_RADIUS)
        if is_selected:
            cr.set_source_rgba(*self.color_selected, min(1.0, opacity + 0.3))
            cr.set_line_width(2.8)
        elif is_hover:
            cr.set_source_rgba(*self.color_hover, min(1.0, opacity + 0.25))
            cr.set_line_width(2.0)
        else:
            cr.set_source_rgba(*self.color_outline, 0.4 * opacity)
            cr.set_line_width(1.2)
        cr.stroke()
        cr.restore()

        if is_selected:
            title = self._get_item_title(item)
            layout = PangoCairo.create_layout(cr)
            layout.set_text(title, -1)
            layout.set_font_description(Pango.FontDescription("JetBrainsMono Nerd Font Bold 10"))
            tw, th = layout.get_pixel_size()
            ty = y + (CARD_H / 2) * scale + 13
            pill_pad_x, pill_pad_y = 14, 5
            pill_w, pill_h = tw + pill_pad_x * 2, th + pill_pad_y * 2

            cr.save()
            cr.translate(x, ty + th / 2)
            self._rounded_rect(cr, pill_w, pill_h, pill_h / 2)
            cr.set_source_rgba(*self.color_surface_variant, 0.88)
            cr.fill_preserve()
            cr.set_source_rgba(*self.color_selected, 0.50)
            cr.set_line_width(1.2)
            cr.stroke()

            cr.move_to(-tw / 2, -th / 2)
            cr.set_source_rgba(*self.color_title, 1.0)
            PangoCairo.show_layout(cr, layout)
            cr.restore()

    def on_motion(self, widget, event):
        idx = self._hit_test(event.x, event.y)
        if idx != self.hover_index:
            self.hover_index = idx
            self.queue_draw()
        return False

    def on_leave(self, widget, event):
        if self.hover_index is not None:
            self.hover_index = None
            self.queue_draw()
        return False

    def on_button_press(self, widget, event):
        idx = self._hit_test(event.x, event.y)
        if idx is not None:
            if idx == self.selected_index:
                if self.on_activate:
                    self.on_activate(self.items[idx])
            else:
                self.set_selected(idx, animate=True)
        return False

    def on_scroll(self, widget, event):
        if not self.items:
            return False
        direction = 0
        if event.direction == Gdk.ScrollDirection.UP:
            direction = -1
        elif event.direction == Gdk.ScrollDirection.DOWN:
            direction = 1
        elif event.direction == Gdk.ScrollDirection.SMOOTH:
            direction = 1 if event.delta_y > 0 else (-1 if event.delta_y < 0 else 0)
        if direction != 0:
            new_index = max(0, min(self.selected_index + direction, len(self.items) - 1))
            if new_index != self.selected_index:
                self.set_selected(new_index)
        return True


# ---- Main Window Panel -----------------------------------------------------
class WallpaperPanel(Gtk.Window):
    THEME_POLL_INTERVAL_MS = 1000

    def __init__(self):
        super().__init__()

        self.config = load_config()
        self.wallpaper_dir = self.config.get("wallpaper_dir") or DEFAULT_WALLPAPER_DIR
        if not os.path.isdir(self.wallpaper_dir):
            self.wallpaper_dir = DEFAULT_WALLPAPER_DIR

        self.mode = self.config.get("active_mode", "local")
        self.online_items = []
        self._search_timeout_id = None

        # Filter states
        self.wh_active_sort = self.config.get("wallhaven_sorting", "toplist")
        self.wh_current_page = 1
        self.wh_random_seed = None
        self._last_autoload_time = 0
        self.wh_is_loading = False

        self.engine = "awww" if self.cmd_exists("awww") else ("swww" if self.cmd_exists("swww") else None)

        self.original_wallpaper = self.get_current_wallpaper()
        self.active_wallpaper = self.original_wallpaper
        self.confirmed = False

        self.palette = load_palette()

        self.wallpapers = self.scan_wallpapers()
        self.filtered_wallpapers = list(self.wallpapers)

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.BOTTOM, 24)
        GtkLayerShell.set_namespace(self, "noctalia-wallpaper-panel")

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        self.set_default_size(1120, 426)
        self.set_resizable(False)

        self.apply_css()
        self.build_ui()

        self.connect("key-press-event", self.on_key_press)
        self.connect("destroy", self.on_destroy)

        if self.mode == "wallhaven":
            self.set_mode_ui("wallhaven")
            self.fetch_online_wallpapers("", page=1)
        else:
            self.set_mode_ui("local")
            self.coverflow.set_items(self.filtered_wallpapers, keep_path=self.original_wallpaper)

        self.start_theme_watch()

    def cmd_exists(self, cmd):
        return subprocess.call(f"type {cmd}", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE) == 0

    def get_current_wallpaper(self):
        if os.path.islink(CURRENT_WALL_LINK):
            return os.path.realpath(CURRENT_WALL_LINK)
        if os.path.exists(WALL_CACHE_FILE):
            try:
                with open(WALL_CACHE_FILE, "r") as f:
                    name = f.read().strip()
                    matches = glob.glob(os.path.join(self.wallpaper_dir, f"{name}.*"))
                    if matches:
                        return matches[0]
            except Exception:
                pass
        return None

    def scan_wallpapers(self, target_dir=None):
        directory = target_dir or self.wallpaper_dir
        exts = ("*.jpg", "*.jpeg", "*.png", "*.gif", "*.webp")
        walls = []
        if os.path.isdir(directory):
            for ext in exts:
                walls.extend(glob.glob(os.path.join(directory, ext)))
        walls.sort(key=lambda x: os.path.basename(x).lower())
        return walls

    def set_wallpaper_directory(self, new_dir):
        if not new_dir or not os.path.isdir(new_dir):
            return
        self.wallpaper_dir = new_dir
        self.config["wallpaper_dir"] = new_dir
        save_config(self.config)

        if self.mode == "local":
            self.wallpapers = self.scan_wallpapers()
            self.on_search_changed(self.entry)

    def apply_css(self):
        if getattr(self, "_css_provider", None) is None:
            self._css_provider = Gtk.CssProvider()
            screen = Gdk.Screen.get_default()
            Gtk.StyleContext.add_provider_for_screen(
                screen, self._css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )
        self._css_provider.load_from_data(build_css(self.palette))

    def start_theme_watch(self):
        self._theme_watch_paths = [NOCTALIA_COLORS_FILE] + list(ADW_GTK_USER_CSS)
        self._theme_watch_state = {p: self._path_fingerprint(p) for p in self._theme_watch_paths}
        self._theme_watch_source = GLib.timeout_add(self.THEME_POLL_INTERVAL_MS, self._poll_theme_files)

    @staticmethod
    def _path_fingerprint(path):
        try:
            st = os.stat(path)
            return (st.st_mtime_ns, st.st_size)
        except OSError:
            return None

    def _poll_theme_files(self):
        changed = False
        for path in self._theme_watch_paths:
            fp = self._path_fingerprint(path)
            if fp != self._theme_watch_state.get(path):
                self._theme_watch_state[path] = fp
                changed = True
        if changed:
            self._reload_theme()
        return True

    def _reload_theme(self):
        self.palette = load_palette()
        self.apply_css()
        self.coverflow.update_palette(self.palette)

    def stop_theme_watch(self):
        if getattr(self, "_theme_watch_source", None) is not None:
            try:
                GLib.source_remove(self._theme_watch_source)
            except Exception:
                pass
            self._theme_watch_source = None

    # -- UI Construction --------------------------------------------------
    def build_ui(self):
        self.overlay = Gtk.Overlay()
        self.add(self.overlay)

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        main_box.get_style_context().add_class("main-container")
        main_box.set_margin_top(70)
        self.overlay.add(main_box)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.stack.set_transition_duration(200)
        main_box.pack_start(self.stack, True, True, 0)

        carousel_page = self.build_carousel_view()
        self.stack.add_named(carousel_page, "carousel")

        wallhaven_page = self.build_wallhaven_view()
        self.stack.add_named(wallhaven_page, "wallhaven")

        self.stack.set_visible_child_name("carousel")

        # Mount CoverFlow on top overlay so cards and wave rings surpass and overlap the panel's main border
        self.coverflow.set_valign(Gtk.Align.START)
        self.coverflow.set_size_request(-1, 310)
        self.overlay.add_overlay(self.coverflow)

    def build_carousel_view(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)

        # CoverFlow is rendered as an overlay child; spacer maintains vertical rhythm inside the panel
        self.coverflow = CoverFlow(on_activate=self.confirm_wallpaper, palette=self.palette, on_near_end=self.maybe_autoload_more)
        self.carousel_spacer = Gtk.Box()
        self.carousel_spacer.set_size_request(-1, 236)
        box.pack_start(self.carousel_spacer, False, False, 0)

        # --- Wallhaven Options & Filter Toolbar ---
        self.filter_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.filter_bar.get_style_context().add_class("filter-bar")

        # 1. Sorting group (Toplist, Hot, Latest, Random)
        self.sort_btns = {}
        for s_id, s_name in [("toplist", "Toplist"), ("hot", "Hot"), ("date_added", "Latest"), ("random", "Random")]:
            btn = Gtk.Button(label=s_name)
            btn.get_style_context().add_class("filter-btn")
            btn.connect("clicked", lambda b, sid=s_id: self.on_sort_clicked(sid))
            self.filter_bar.pack_start(btn, False, False, 0)
            self.sort_btns[s_id] = btn

        sep1 = Gtk.Separator(orientation=Gtk.Orientation.VERTICAL)
        self.filter_bar.pack_start(sep1, False, False, 2)

        # 2. Categories group (General, Anime, People)
        cat_conf = self.config.get("wallhaven_categories", "110")
        self.cat_general_btn = Gtk.ToggleButton(label="General")
        self.cat_general_btn.get_style_context().add_class("filter-btn")
        self.cat_general_btn.set_active(cat_conf[0] == "1")
        self.cat_general_btn.connect("toggled", lambda b: self.on_filter_changed())
        self.filter_bar.pack_start(self.cat_general_btn, False, False, 0)

        self.cat_anime_btn = Gtk.ToggleButton(label="Anime")
        self.cat_anime_btn.get_style_context().add_class("filter-btn")
        self.cat_anime_btn.set_active(cat_conf[1] == "1" if len(cat_conf) > 1 else True)
        self.cat_anime_btn.connect("toggled", lambda b: self.on_filter_changed())
        self.filter_bar.pack_start(self.cat_anime_btn, False, False, 0)

        self.cat_people_btn = Gtk.ToggleButton(label="People")
        self.cat_people_btn.get_style_context().add_class("filter-btn")
        self.cat_people_btn.set_active(cat_conf[2] == "1" if len(cat_conf) > 2 else False)
        self.cat_people_btn.connect("toggled", lambda b: self.on_filter_changed())
        self.filter_bar.pack_start(self.cat_people_btn, False, False, 0)

        sep2 = Gtk.Separator(orientation=Gtk.Orientation.VERTICAL)
        self.filter_bar.pack_start(sep2, False, False, 2)

        # 3. Resolution ComboBox
        self.res_combo = Gtk.ComboBoxText()
        self.res_combo.get_style_context().add_class("wh-combo")
        for res_id, res_label in [("all", "All Res"), ("1080p", "1080p+"), ("1440p", "1440p+"), ("4k", "4K+"), ("ultrawide", "21:9 Ultrawide")]:
            self.res_combo.append(res_id, res_label)
        saved_res = self.config.get("wallhaven_resolution", "all")
        self.res_combo.set_active_id(saved_res)
        self.res_combo.connect("changed", lambda c: self.on_filter_changed())
        self.filter_bar.pack_start(self.res_combo, False, False, 0)

        # 5. Load More Button
        self.load_more_btn = Gtk.Button(label="󰑮 +24 More")
        self.load_more_btn.get_style_context().add_class("filter-btn")
        self.load_more_btn.set_tooltip_text("Load next 24 wallpapers from Wallhaven")
        self.load_more_btn.connect("clicked", self.on_load_more_clicked)
        self.filter_bar.pack_end(self.load_more_btn, False, False, 0)

        box.pack_start(self.filter_bar, False, False, 2)

        # --- Bottom Control Bar ---
        bottom_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        bottom_bar.set_margin_top(4)

        # Mode toggle button
        self.mode_btn = Gtk.Button()
        self.mode_btn.connect("clicked", lambda b: self.toggle_source_mode())
        bottom_bar.pack_start(self.mode_btn, False, False, 0)


        # Search Bar
        self.search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        search_box = self.search_box
        search_box.get_style_context().add_class("search-bar")

        self.search_icon_label = Gtk.Label(label="󰍉")
        self.search_icon_label.get_style_context().add_class("search-icon")
        search_box.pack_start(self.search_icon_label, False, False, 0)

        self.entry = Gtk.Entry()
        self.entry.get_style_context().add_class("search-entry")
        self.entry.set_hexpand(True)
        self.entry.connect("changed", self.on_search_changed)
        search_box.pack_start(self.entry, True, True, 0)

        clear_btn = Gtk.Button(label="✕")
        clear_btn.get_style_context().add_class("clear-btn")
        clear_btn.connect("clicked", lambda b: self.entry.set_text(""))
        search_box.pack_end(clear_btn, False, False, 0)

        bottom_bar.pack_start(search_box, True, True, 0)

        # Apply Button (Primary action)
        self.apply_btn = Gtk.Button(label="󰄬 Apply")
        self.apply_btn.get_style_context().add_class("apply-btn")
        self.apply_btn.set_tooltip_text("Apply selected wallpaper to desktop (Enter)")
        self.apply_btn.connect("clicked", self.on_apply_clicked)
        bottom_bar.pack_end(self.apply_btn, False, False, 0)

        # Wallhaven Hub Button
        self.wh_hub_btn = Gtk.Button(label="󰸉 Hub")
        self.wh_hub_btn.get_style_context().add_class("wh-accent-btn")
        self.wh_hub_btn.set_tooltip_text("Open Wallhaven Account & Sync Hub (Ctrl+W)")
        self.wh_hub_btn.connect("clicked", lambda b: self.show_wallhaven_view())
        bottom_bar.pack_end(self.wh_hub_btn, False, False, 0)

        box.pack_end(bottom_bar, False, False, 0)
        return box

    def on_apply_clicked(self, widget=None):
        item = self.coverflow.get_selected_item()
        if not item:
            return
        self.apply_btn.set_label("󰑮 Applying...")
        self.apply_btn.set_sensitive(False)
        self.confirm_wallpaper(item)

    def set_mode_ui(self, mode):
        self.mode = mode
        self.config["active_mode"] = mode
        save_config(self.config)

        if mode == "wallhaven":
            self.mode_btn.set_label("󰸉 Online")
            self.mode_btn.get_style_context().remove_class("control-btn")
            self.mode_btn.get_style_context().add_class("mode-btn-active")
            self.mode_btn.set_tooltip_text("Mode: Wallhaven Online Stream (Click or Ctrl+O to switch to Local)")
            self.filter_bar.show_all()
            self.entry.set_placeholder_text(">search wallhaven (e.g. anime, 4k, nature)...")
            self.update_sort_buttons_ui()
        else:
            self.mode_btn.set_label("󰋜 Local")
            self.mode_btn.get_style_context().remove_class("mode-btn-active")
            self.mode_btn.get_style_context().add_class("control-btn")
            self.mode_btn.set_tooltip_text("Mode: Local Folders (Click or Ctrl+O to switch to Wallhaven Online)")
            self.filter_bar.hide()
            self.entry.set_placeholder_text(">wallpaper")

    def update_sort_buttons_ui(self):
        for sid, btn in self.sort_btns.items():
            ctx = btn.get_style_context()
            if sid == self.wh_active_sort:
                ctx.add_class("filter-btn-active")
            else:
                ctx.remove_class("filter-btn-active")

    def on_sort_clicked(self, sort_id):
        self.wh_active_sort = sort_id
        self.config["wallhaven_sorting"] = sort_id
        save_config(self.config)
        self.update_sort_buttons_ui()
        self.wh_current_page = 1
        self.wh_random_seed = None
        self.load_more_btn.set_sensitive(True)
        self.load_more_btn.set_label("󰑮 +24 More")
        self.fetch_online_wallpapers(self.entry.get_text().strip(), page=1)

    def on_filter_changed(self):
        # Build category & purity strings
        c1 = "1" if self.cat_general_btn.get_active() else "0"
        c2 = "1" if self.cat_anime_btn.get_active() else "0"
        c3 = "1" if self.cat_people_btn.get_active() else "0"
        categories = f"{c1}{c2}{c3}" if (c1 == "1" or c2 == "1" or c3 == "1") else "111"

        purity = "100"

        res_id = self.res_combo.get_active_id() or "all"

        self.config["wallhaven_categories"] = categories
        self.config["wallhaven_purity"] = purity
        self.config["wallhaven_resolution"] = res_id
        save_config(self.config)

        self.wh_current_page = 1
        self.wh_random_seed = None
        self.load_more_btn.set_sensitive(True)
        self.load_more_btn.set_label("󰑮 +24 More")
        self.fetch_online_wallpapers(self.entry.get_text().strip(), page=1)

    def maybe_autoload_more(self):
        if self.mode != "wallhaven" or self.wh_is_loading:
            return
        now = time.time()
        if now - self._last_autoload_time < 1.5:
            return
        self._last_autoload_time = now
        self.on_load_more_clicked()

    def on_load_more_clicked(self, widget=None):
        if self.wh_is_loading:
            return
        now = time.time()
        if now - self._last_autoload_time < 0.6:
            return
        self._last_autoload_time = now
        self.wh_current_page += 1
        self.load_more_btn.set_label("󰑮 Loading...")
        self.fetch_online_wallpapers(self.entry.get_text().strip(), page=self.wh_current_page, append=True)

    def toggle_source_mode(self):
        if self.mode == "local":
            self.set_mode_ui("wallhaven")
            self.entry.set_text("")
            self.wh_current_page = 1
            self.wh_random_seed = None
            self.load_more_btn.set_sensitive(True)
            self.load_more_btn.set_label("󰑮 +24 More")
            self.fetch_online_wallpapers("", page=1)
        else:
            self.set_mode_ui("local")
            self.entry.set_text("")
            self.wallpapers = self.scan_wallpapers()
            self.filtered_wallpapers = list(self.wallpapers)
            self.coverflow.set_items(self.filtered_wallpapers)

    def fetch_online_wallpapers(self, query="", page=1, append=False):
        self.wh_is_loading = True
        api_key = self.config.get("wallhaven_api_key", "")
        sorting = self.wh_active_sort
        categories = self.config.get("wallhaven_categories", "110")
        purity = self.config.get("wallhaven_purity", "100")
        resolution = self.config.get("wallhaven_resolution", "all")

        if page == 1 and not append:
            self.wh_random_seed = None

        seed_to_use = self.wh_random_seed or ""

        def _worker():
            all_raw_items = []
            seed_found = seed_to_use
            last_page = 1

            success, items, msg, meta = wh_search_wallpapers(
                query=query,
                sorting=sorting if not query else "relevance",
                categories=categories,
                purity=purity,
                resolution=resolution,
                api_key=api_key,
                page=page,
                seed=seed_found
            )

            if success:
                all_raw_items.extend(items)
                if meta.get("seed"):
                    seed_found = meta.get("seed")
                last_page = meta.get("last_page", 1)

                # If initial load (page 1) and not appending, fetch page 2 for 48 wallpapers!
                if page == 1 and not append and len(items) >= 24 and last_page > 1:
                    time.sleep(0.2)
                    ok2, items2, _, meta2 = wh_search_wallpapers(
                        query=query,
                        sorting=sorting if not query else "relevance",
                        categories=categories,
                        purity=purity,
                        resolution=resolution,
                        api_key=api_key,
                        page=2,
                        seed=seed_found
                    )
                    if ok2 and items2:
                        all_raw_items.extend(items2)

            parsed = []
            for x in all_raw_items:
                # Extra layer of security: filter out anything not strictly SFW
                if str(x.get("purity", "")).lower() != "sfw":
                    continue
                parsed.append({
                    "id": x["id"],
                    "url": x["path"],
                    "thumb": x.get("thumbs", {}).get("small") or x.get("thumbs", {}).get("large") or x.get("thumbs", {}).get("original"),
                    "title": f"wallhaven-{x['id']}"
                })

            def _update():
                self.wh_is_loading = False
                if seed_found:
                    self.wh_random_seed = seed_found

                if not success:
                    if append:
                        self.wh_current_page = max(1, self.wh_current_page - 1)
                    if "Rate limit" in msg or "wait" in msg:
                        self.load_more_btn.set_label("󰑮 Rate Limit (Wait)")
                        GLib.timeout_add_seconds(3, lambda: (self.load_more_btn.set_label("󰑮 +24 More"), False)[1])
                    else:
                        self.load_more_btn.set_label("󰑮 Retry +24")
                    return False

                # If initial 2-page load succeeded, advance current_page to 2
                if page == 1 and not append and len(all_raw_items) > 24:
                    self.wh_current_page = 2

                if append:
                    existing_ids = {item["id"] for item in self.online_items if isinstance(item, dict)}
                    new_unique = [it for it in parsed if it["id"] not in existing_ids]
                    self.online_items.extend(new_unique)
                    if not new_unique and page >= last_page:
                        self.load_more_btn.set_label("󰄬 All Loaded")
                        self.load_more_btn.set_sensitive(False)
                    else:
                        self.load_more_btn.set_label("󰑮 +24 More")
                        self.load_more_btn.set_sensitive(True)
                else:
                    self.online_items = parsed
                    self.load_more_btn.set_label("󰑮 +24 More")
                    self.load_more_btn.set_sensitive(True)

                if self.mode == "wallhaven":
                    current_sel = self.coverflow.get_selected_item()
                    self.coverflow.set_items(self.online_items, keep_path=current_sel, is_append=append)
                return False

            GLib.idle_add(_update)

        threading.Thread(target=_worker, daemon=True).start()

    def build_wallhaven_view(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_margin_top(2)

        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)

        back_btn = Gtk.Button(label="← Carousel")
        back_btn.get_style_context().add_class("control-btn")
        back_btn.set_tooltip_text("Return to Wallpaper Carousel (Esc)")
        back_btn.connect("clicked", lambda b: self.show_carousel_view())
        header.pack_start(back_btn, False, False, 0)

        title = Gtk.Label(label="󰸉 Wallhaven Hub")
        title.get_style_context().add_class("wh-hub-title")
        header.pack_start(title, False, False, 0)

        self.wh_header_status = Gtk.Label(label="Manage account credentials & bulk offline downloads")
        self.wh_header_status.get_style_context().add_class("wh-label")
        header.pack_start(self.wh_header_status, False, False, 4)

        box.pack_start(header, False, False, 0)

        cards_grid = Gtk.Grid()
        cards_grid.set_column_spacing(12)
        cards_grid.set_row_spacing(8)
        cards_grid.set_column_homogeneous(True)
        box.pack_start(cards_grid, True, True, 0)

        # Card 1: User Account & Collections Sync
        col_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        col_card.get_style_context().add_class("wh-card")

        col_title = Gtk.Label(label="󰡉 User Collections", xalign=0)
        col_title.get_style_context().add_class("wh-card-title")
        col_card.pack_start(col_title, False, False, 0)

        acc_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.wh_user_entry = Gtk.Entry()
        self.wh_user_entry.set_placeholder_text("Username")
        self.wh_user_entry.get_style_context().add_class("wh-entry")
        self.wh_user_entry.set_text(self.config.get("wallhaven_username", ""))
        self.wh_user_entry.set_hexpand(True)
        acc_box.pack_start(self.wh_user_entry, True, True, 0)

        self.wh_key_entry = Gtk.Entry()
        self.wh_key_entry.set_placeholder_text("API Key")
        self.wh_key_entry.set_visibility(False)
        self.wh_key_entry.get_style_context().add_class("wh-entry")
        self.wh_key_entry.set_text(self.config.get("wallhaven_api_key", ""))
        self.wh_key_entry.set_hexpand(True)
        acc_box.pack_start(self.wh_key_entry, True, True, 0)

        key_vis_btn = Gtk.Button(label="👁")
        key_vis_btn.get_style_context().add_class("wh-btn-secondary")
        key_vis_btn.set_tooltip_text("Toggle API key visibility")
        key_vis_btn.connect("clicked", lambda b: self.wh_key_entry.set_visibility(not self.wh_key_entry.get_visibility()))
        acc_box.pack_start(key_vis_btn, False, False, 0)

        col_card.pack_start(acc_box, False, False, 0)

        col_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.wh_col_combo = Gtk.ComboBoxText()
        self.wh_col_combo.get_style_context().add_class("wh-combo")
        self.wh_col_combo.set_hexpand(True)
        self.wh_col_combo.append("default", "Connect to load collections...")
        self.wh_col_combo.set_active(0)
        col_row.pack_start(self.wh_col_combo, True, True, 0)

        self.wh_connect_btn = Gtk.Button(label="󰌷 Load")
        self.wh_connect_btn.get_style_context().add_class("wh-btn-secondary")
        self.wh_connect_btn.set_tooltip_text("Fetch collections from Wallhaven")
        self.wh_connect_btn.connect("clicked", self.on_load_collections_clicked)
        col_row.pack_start(self.wh_connect_btn, False, False, 0)

        col_card.pack_start(col_row, False, False, 0)

        sync_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.wh_sync_btn = Gtk.Button(label="󰁪 Download Collection")
        self.wh_sync_btn.get_style_context().add_class("wh-btn-primary")
        self.wh_sync_btn.set_hexpand(True)
        self.wh_sync_btn.connect("clicked", self.on_sync_collection_clicked)
        sync_row.pack_start(self.wh_sync_btn, True, True, 0)

        col_card.pack_start(sync_row, False, False, 0)

        cards_grid.attach(col_card, 0, 0, 1, 1)

        # Card 2: Quick Search & Offline Target
        search_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        search_card.get_style_context().add_class("wh-card")

        search_title = Gtk.Label(label="󰍉 Bulk Search & Offline Download", xalign=0)
        search_title.get_style_context().add_class("wh-card-title")
        search_card.pack_start(search_title, False, False, 0)

        s_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.wh_search_entry = Gtk.Entry()
        self.wh_search_entry.set_placeholder_text("Query (or leave blank for Toplist)")
        self.wh_search_entry.get_style_context().add_class("wh-entry")
        self.wh_search_entry.set_hexpand(True)
        self.wh_search_entry.connect("activate", lambda e: self.on_search_sync_clicked(None))
        s_row.pack_start(self.wh_search_entry, True, True, 0)

        self.wh_search_sort_combo = Gtk.ComboBoxText()
        self.wh_search_sort_combo.get_style_context().add_class("wh-combo")
        for sort_id, sort_name in [("toplist", "Toplist"), ("hot", "Hot"), ("views", "Views"), ("random", "Random")]:
            self.wh_search_sort_combo.append(sort_id, sort_name)
        self.wh_search_sort_combo.set_active(0)
        s_row.pack_start(self.wh_search_sort_combo, False, False, 0)

        self.wh_search_btn = Gtk.Button(label="󰍉 Download")
        self.wh_search_btn.get_style_context().add_class("wh-btn-secondary")
        self.wh_search_btn.connect("clicked", self.on_search_sync_clicked)
        s_row.pack_start(self.wh_search_btn, False, False, 0)

        search_card.pack_start(s_row, False, False, 0)

        self.wh_progress_bar = Gtk.ProgressBar()
        self.wh_progress_bar.set_fraction(0.0)
        search_card.pack_start(self.wh_progress_bar, False, False, 2)

        status_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.wh_status_label = Gtk.Label(label="Tip: Use 'Online Stream' mode in the carousel to browse directly!", xalign=0)
        self.wh_status_label.get_style_context().add_class("wh-status-label")
        self.wh_status_label.set_hexpand(True)
        self.wh_status_label.set_ellipsize(Pango.EllipsizeMode.END)
        status_row.pack_start(self.wh_status_label, True, True, 0)

        self.wh_dest_btn = Gtk.Button(label="󰉋 Target Folder")
        self.wh_dest_btn.get_style_context().add_class("wh-btn-secondary")
        self.wh_dest_btn.set_tooltip_text(f"Offline download target: {self.config.get('wallhaven_sync_dir')}\nClick to change destination folder")
        self.wh_dest_btn.connect("clicked", self.on_choose_sync_dest_clicked)
        status_row.pack_end(self.wh_dest_btn, False, False, 0)

        search_card.pack_start(status_row, False, False, 0)

        cards_grid.attach(search_card, 1, 0, 1, 1)
        return box

    def show_carousel_view(self):
        self.stack.set_visible_child_name("carousel")
        self.coverflow.set_visible(True)
        self.entry.grab_focus()

    def show_wallhaven_view(self):
        self.coverflow.set_visible(False)
        self.stack.set_visible_child_name("wallhaven")
        if self.config.get("wallhaven_api_key") or self.config.get("wallhaven_username"):
            if self.wh_col_combo.get_model() is None or len(self.wh_col_combo.get_model()) <= 1:
                self.on_load_collections_clicked(None)

    def toggle_wallhaven_view(self):
        if self.stack.get_visible_child_name() == "wallhaven":
            self.show_carousel_view()
        else:
            self.show_wallhaven_view()

    # -- Directory Selection ----------------------------------------------
    def on_choose_directory_clicked(self, widget=None):
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)

        dialog = Gtk.FileChooserDialog(
            title="Select Wallpaper Directory",
            parent=None,
            action=Gtk.FileChooserAction.SELECT_FOLDER
        )
        dialog.add_button("_Cancel", Gtk.ResponseType.CANCEL)
        dialog.add_button("_Select Folder", Gtk.ResponseType.OK)
        dialog.set_default_response(Gtk.ResponseType.OK)
        dialog.set_current_folder(self.wallpaper_dir)

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            chosen = dialog.get_filename()
            if chosen and os.path.isdir(chosen):
                self.set_wallpaper_directory(chosen)
        dialog.destroy()

        while Gtk.events_pending():
            Gtk.main_iteration()
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)

    def on_choose_sync_dest_clicked(self, widget=None):
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)

        dialog = Gtk.FileChooserDialog(
            title="Select Wallhaven Download Directory",
            parent=None,
            action=Gtk.FileChooserAction.SELECT_FOLDER
        )
        dialog.add_button("_Cancel", Gtk.ResponseType.CANCEL)
        dialog.add_button("_Select Folder", Gtk.ResponseType.OK)
        dialog.set_default_response(Gtk.ResponseType.OK)

        current_sync_dir = self.config.get("wallhaven_sync_dir") or os.path.join(self.wallpaper_dir, "wallhaven")
        dialog.set_current_folder(current_sync_dir)

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            chosen = dialog.get_filename()
            if chosen and os.path.isdir(chosen):
                self.config["wallhaven_sync_dir"] = chosen
                save_config(self.config)
                base = os.path.basename(chosen) or chosen
                self.wh_dest_btn.set_label(f"󰉋 Target: {base}")
                self.wh_dest_btn.set_tooltip_text(f"Sync destination: {chosen}\nClick to change destination folder")
        dialog.destroy()

        while Gtk.events_pending():
            Gtk.main_iteration()
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)

    # -- Wallhaven Hub Actions --------------------------------------------
    def on_load_collections_clicked(self, widget=None):
        username = self.wh_user_entry.get_text().strip()
        api_key = self.wh_key_entry.get_text().strip()

        self.config["wallhaven_username"] = username
        self.config["wallhaven_api_key"] = api_key
        save_config(self.config)

        self.wh_status_label.set_text("Connecting to Wallhaven...")
        self.wh_connect_btn.set_sensitive(False)

        def _worker():
            success, cols, msg = wh_fetch_collections(api_key=api_key, username=username)

            def _update():
                self.wh_connect_btn.set_sensitive(True)
                if success and cols:
                    self.wh_col_combo.remove_all()
                    for col in cols:
                        col_id = str(col.get("id", ""))
                        label = col.get("label", "Collection")
                        count = col.get("count", 0)
                        public = " [Public]" if col.get("public") == 1 else " [Private]"
                        self.wh_col_combo.append(col_id, f"{label} ({count}){public}")
                    self.wh_col_combo.set_active(0)
                    total_walls = sum(col.get("count", 0) for col in cols)
                    if total_walls == 0:
                        self.wh_status_label.set_text("✓ Connected! (Note: 'Default' has 0 favorites. Favorite items on wallhaven.cc to sync)")
                    else:
                        self.wh_status_label.set_text(f"✓ Loaded {len(cols)} collections ({total_walls} wallpapers)")
                else:
                    self.wh_status_label.set_text(f"⚠ {msg}")
                return False

            GLib.idle_add(_update)

        threading.Thread(target=_worker, daemon=True).start()

    def on_sync_collection_clicked(self, widget=None):
        username = self.wh_user_entry.get_text().strip()
        api_key = self.wh_key_entry.get_text().strip()
        col_id = self.wh_col_combo.get_active_id()

        if not username:
            self.wh_status_label.set_text("⚠ Enter username to fetch collections")
            return

        if not col_id or col_id == "default":
            self.wh_status_label.set_text("⚠ Select a valid collection first")
            return

        self.config["wallhaven_username"] = username
        self.config["wallhaven_api_key"] = api_key
        save_config(self.config)

        target_dir = self.config.get("wallhaven_sync_dir") or os.path.join(self.wallpaper_dir, "wallhaven")
        os.makedirs(target_dir, exist_ok=True)

        self.wh_sync_btn.set_sensitive(False)
        self.wh_progress_bar.set_fraction(0.0)
        self.wh_status_label.set_text("Fetching collection wallpapers metadata...")

        def _sync_worker():
            success, items, msg = wh_fetch_collection_wallpapers(
                username=username,
                col_id=col_id,
                api_key=api_key,
                max_count=self.config.get("wallhaven_sync_limit", 48)
            )

            if not success or not items:
                err_msg = msg
                if success and not items:
                    err_msg = "⚠ Collection has 0 wallpapers on wallhaven.cc! Add favorites on the website first."
                GLib.idle_add(lambda: self._sync_finished(False, err_msg, 0, target_dir))
                return

            total = len(items)
            downloaded = 0
            existing = 0

            for i, item in enumerate(items):
                url = item.get("path")
                if not url:
                    continue

                frac = (i + 1) / float(total)
                filename = os.path.basename(url.split("?")[0])
                GLib.idle_add(self._update_sync_progress, frac, f"Downloading {i + 1}/{total}: {filename}...")

                ok, status, fname = wh_download_file(url, target_dir)
                if ok:
                    if status == "downloaded":
                        downloaded += 1
                    else:
                        existing += 1
                time.sleep(0.05)

            summary = f"✓ Downloaded {downloaded} new, {existing} existing ({total} total)"
            GLib.idle_add(lambda: self._sync_finished(True, summary, downloaded, target_dir))

        threading.Thread(target=_sync_worker, daemon=True).start()

    def on_search_sync_clicked(self, widget=None):
        query = self.wh_search_entry.get_text().strip()
        sorting = self.wh_search_sort_combo.get_active_id() or "toplist"
        api_key = self.wh_key_entry.get_text().strip()
        target_dir = self.config.get("wallhaven_sync_dir") or os.path.join(self.wallpaper_dir, "wallhaven")
        os.makedirs(target_dir, exist_ok=True)

        self.wh_search_btn.set_sensitive(False)
        self.wh_progress_bar.set_fraction(0.0)
        display_name = f"'{query}'" if query else f"{sorting.capitalize()} wallpapers"
        self.wh_status_label.set_text(f"Fetching {display_name} from Wallhaven...")

        def _search_worker():
            success, items, msg, _ = wh_search_wallpapers(
                query=query,
                sorting=sorting,
                categories="110",
                purity=self.config.get("wallhaven_purity", "100"),
                resolution="all",
                api_key=api_key,
                page=1
            )

            if not success or not items:
                GLib.idle_add(lambda: self._search_finished(False, msg, target_dir))
                return

            total = len(items)
            downloaded = 0
            existing = 0

            for i, item in enumerate(items):
                url = item.get("path")
                if not url:
                    continue
                frac = (i + 1) / float(total)
                filename = os.path.basename(url.split("?")[0])
                GLib.idle_add(self._update_sync_progress, frac, f"Downloading {i + 1}/{total}: {filename}...")

                ok, status, fname = wh_download_file(url, target_dir)
                if ok:
                    if status == "downloaded":
                        downloaded += 1
                    else:
                        existing += 1
                time.sleep(0.05)

            summary = f"✓ Downloaded {downloaded} new, {existing} existing ({total} total)"
            GLib.idle_add(lambda: self._search_finished(True, summary, target_dir))

        threading.Thread(target=_search_worker, daemon=True).start()

    def _update_sync_progress(self, fraction, message):
        self.wh_progress_bar.set_fraction(fraction)
        self.wh_status_label.set_text(message)
        return False

    def _sync_finished(self, success, message, count, target_dir):
        self.wh_sync_btn.set_sensitive(True)
        self.wh_status_label.set_text(message)
        if success:
            self.wh_progress_bar.set_fraction(1.0)
            self.set_wallpaper_directory(target_dir)
        return False

    def _search_finished(self, success, message, target_dir):
        self.wh_search_btn.set_sensitive(True)
        self.wh_status_label.set_text(message)
        if success:
            self.wh_progress_bar.set_fraction(1.0)
            self.set_wallpaper_directory(target_dir)
        return False

    # -- Preview & Confirmation -------------------------------------------
    def _resolve_item_file(self, item):
        if isinstance(item, dict):
            url = item.get("url")
            if not url:
                return None
            filename = os.path.basename(url.split("?")[0])
            cache_file = os.path.join(STREAM_CACHE_DIR, filename)
            if os.path.exists(cache_file) and os.path.getsize(cache_file) > 0:
                return cache_file
            ok, status, fname = wh_download_file(url, STREAM_CACHE_DIR)
            downloaded_file = os.path.join(STREAM_CACHE_DIR, fname)
            if ok and os.path.exists(downloaded_file) and os.path.getsize(downloaded_file) > 0:
                return downloaded_file
            return None
        if isinstance(item, str) and os.path.exists(item):
            return item
        return None

    def confirm_wallpaper(self, item):
        self.confirmed = True
        self.hide()

        def _apply():
            path = self._resolve_item_file(item)
            if not path:
                print(f"Error: Failed to resolve wallpaper path for: {item}", file=sys.stderr)
                GLib.idle_add(Gtk.main_quit)
                return
            self.active_wallpaper = path

            os.makedirs(CACHE_DIR, exist_ok=True)
            try:
                if os.path.exists(CURRENT_WALL_LINK) or os.path.islink(CURRENT_WALL_LINK):
                    os.remove(CURRENT_WALL_LINK)
                os.symlink(path, CURRENT_WALL_LINK)
                base_name = os.path.splitext(os.path.basename(path))[0]
                with open(WALL_CACHE_FILE, "w") as f:
                    f.write(base_name + "\n")
            except Exception as e:
                print("Error updating cache:", e, file=sys.stderr)

            if self.engine:
                params = "--transition-fps 120 --transition-type any --transition-duration 1.0 --transition-bezier .28,.58,.99,.37"
                subprocess.run(f"{self.engine} img '{path}' {params}", shell=True)

            subprocess.run(f"noctalia msg wallpaper-set '{path}' 2>/dev/null || true", shell=True)
            subprocess.run([COLORS_SCRIPT, path])

            GLib.idle_add(Gtk.main_quit)

        threading.Thread(target=_apply, daemon=False).start()

    def on_search_changed(self, entry):
        text = entry.get_text().strip()

        if self.mode == "wallhaven":
            if self._search_timeout_id is not None:
                GLib.source_remove(self._search_timeout_id)
            self._search_timeout_id = GLib.timeout_add(450, self._trigger_online_search, text)
        else:
            lower_text = text.lower()
            if not lower_text:
                self.filtered_wallpapers = list(self.wallpapers)
            else:
                self.filtered_wallpapers = [w for w in self.wallpapers if lower_text in os.path.basename(w).lower()]
            self.coverflow.set_items(self.filtered_wallpapers)

    def _trigger_online_search(self, query):
        self._search_timeout_id = None
        self.wh_current_page = 1
        self.wh_random_seed = None
        self.load_more_btn.set_sensitive(True)
        self.load_more_btn.set_label("󰑮 +24 More")
        self.fetch_online_wallpapers(query, page=1)
        return False

    def on_key_press(self, widget, event):
        key = event.keyval
        state = event.state

        if self.stack.get_visible_child_name() == "wallhaven":
            if key == Gdk.KEY_Escape:
                self.show_carousel_view()
                return True
            return False

        if key == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True

        # Ctrl+O: Toggle Local / Wallhaven Online
        if (state & Gdk.ModifierType.CONTROL_MASK) and key in (Gdk.KEY_o, Gdk.KEY_O):
            self.toggle_source_mode()
            return True

        # Ctrl+L: Focus Search Bar
        if (state & Gdk.ModifierType.CONTROL_MASK) and key in (Gdk.KEY_l, Gdk.KEY_L):
            self.entry.grab_focus()
            return True

        # Ctrl+W: Toggle Hub
        if (state & Gdk.ModifierType.CONTROL_MASK) and key in (Gdk.KEY_w, Gdk.KEY_W):
            self.toggle_wallhaven_view()
            return True

        # Ctrl+D: Choose Directory
        if (state & Gdk.ModifierType.CONTROL_MASK) and key in (Gdk.KEY_d, Gdk.KEY_D):
            if self.mode == "local":
                self.on_choose_directory_clicked()
            else:
                self.toggle_source_mode()
            return True

        is_entry_focused = self.entry.is_focus()

        # Return or Space (when not typing): Apply
        if key in (Gdk.KEY_Return, Gdk.KEY_KP_Enter) or (not is_entry_focused and key == Gdk.KEY_space):
            self.on_apply_clicked()
            return True

        # Left Navigation
        if key == Gdk.KEY_Left or (not is_entry_focused and key == Gdk.KEY_h):
            if self.coverflow.items:
                idx = max(0, self.coverflow.selected_index - 1)
                self.coverflow.set_selected(idx)
            return True

        # Right Navigation
        if key == Gdk.KEY_Right or (not is_entry_focused and key == Gdk.KEY_l):
            if self.coverflow.items:
                idx = min(len(self.coverflow.items) - 1, self.coverflow.selected_index + 1)
                self.coverflow.set_selected(idx)
            return True

        return False

    def on_destroy(self, widget):
        try:
            self.coverflow._executor.shutdown(wait=False, cancel_futures=True)
        except Exception:
            pass
        self.stop_theme_watch()
        if not self.confirmed and self.original_wallpaper and self.active_wallpaper != self.original_wallpaper:
            if self.engine:
                subprocess.run(f"{self.engine} img '{self.original_wallpaper}' --transition-fps 120 --transition-type any --transition-duration 0.5", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(f"noctalia msg wallpaper-set '{self.original_wallpaper}' 2>/dev/null || true", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        Gtk.main_quit()


def main():
    pid = os.getpid()
    script_name = os.path.basename(__file__)
    res = subprocess.run(
        f"pgrep -f '{script_name}' | grep -v '^{pid}$'; pgrep -f 'noctalia-wallpaper-panel.py' | grep -v '^{pid}$'",
        shell=True, stdout=subprocess.PIPE, text=True
    )
    pids = [p for p in res.stdout.strip().split('\n') if p]
    killed_any = False
    for p in set(pids):
        try:
            os.kill(int(p), signal.SIGKILL)
            killed_any = True
        except (ProcessLookupError, ValueError):
            pass
    if killed_any:
        sys.exit(0)

    win = WallpaperPanel()
    win.show_all()
    Gtk.main()


if __name__ == '__main__':
    main()
