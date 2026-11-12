#!/usr/bin/env python3
"""
hypr-settings-backend.py — CLI/JSON backend engine for Quickshell Settings.
Parses, updates, and manages Hyprland Lua configurations, displays,
animations, keybinds, and SDDM avatars without requiring GTK/Adwaita.
"""

import os
import sys
import re
import json
import shlex
import shutil
import getpass
import subprocess
from datetime import datetime
from pathlib import Path

# ─── Config file paths ────────────────────────────────────────────────────
_CONFIG_HYPR = Path.home() / ".config" / "hypr" / "configs"
_HYPRCONF = Path.home() / ".hyprconf" / "hypr" / "configs"
CONFIGS_DIR = _CONFIG_HYPR if _CONFIG_HYPR.exists() else _HYPRCONF

CONFIGS_LUA = CONFIGS_DIR / "configs.lua"
DECORATION_LUA = CONFIGS_DIR / "decoration.lua"
MONITOR_LUA = CONFIGS_DIR / "monitor.lua"
ANIMATION_LUA = CONFIGS_DIR / "animation.lua"
SETTINGS_LUA = CONFIGS_DIR / "settings.lua"
ENVIRONMENT_LUA = CONFIGS_DIR / "environment.lua"
KEYBINDS_LUA = CONFIGS_DIR / "keybinds.lua"

# Updated in the background, never shown in the UI.
_KITTY_CFG = Path.home() / ".config" / "kitty" / "kitty.conf"
_HYPR_KITTY = Path.home() / ".hyprconf" / "kitty" / "kitty.conf"
KITTY_CONF = _KITTY_CFG if _KITTY_CFG.exists() else _HYPR_KITTY
GTK3_CSS = Path.home() / ".config" / "gtk-3.0" / "gtk.css"
GTK4_CSS = Path.home() / ".config" / "gtk-4.0" / "gtk.css"

BACKUP_DIR = (
    Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
    / "hypr-settings"
    / "backups"
)

# ─── SDDM avatar (Login Avatar section) ───────────────────────────────────
SDDM_FACES_DIR = Path("/usr/share/sddm/faces")

CACHE_HOME = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))


KITTY_BIN = shutil.which("kitty") or "kitty"


# =============================================================================
#  Low-level Lua text helpers
# =============================================================================


def backup(src: Path):
    if not src.is_file():
        return
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    shutil.copy2(src, BACKUP_DIR / f"{src.name}.{stamp}.bak")


def lua_set(path: Path, key: str, value: str):
    """Set a numeric (possibly negative/float) top-level, dot-access, or
    local Lua variable, mirroring the original script's sed patterns."""
    if not path.is_file():
        return
    text = path.read_text()
    k = re.escape(key)
    num = r"-?[0-9]+(?:\.[0-9]+)?"
    patterns = [
        (rf"^(\s*{k}\s*=\s*){num}", rf"\g<1>{value}"),
        (rf"^(\s*[a-zA-Z_]+\.{k}\s*=\s*){num}", rf"\g<1>{value}"),
        (rf"^(\s*local\s+{k}\s*=\s*){num}", rf"\g<1>{value}"),
    ]
    for pattern, repl in patterns:
        text = re.sub(pattern, repl, text, flags=re.MULTILINE)
    path.write_text(text)


def lua_get(path: Path, key: str):
    """Read back a numeric value set by lua_set(). Returns a string or None."""
    if not path.is_file():
        return None
    text = path.read_text()
    k = re.escape(key)
    num = r"(-?[0-9]+(?:\.[0-9]+)?)"
    patterns = [
        rf"^\s*{k}\s*=\s*{num}",
        rf"^\s*[a-zA-Z_]+\.{k}\s*=\s*{num}",
        rf"^\s*local\s+{k}\s*=\s*{num}",
    ]
    for p in patterns:
        m = re.search(p, text, re.MULTILINE)
        if m:
            return m.group(1)
    return None


def lua_set_bool(path: Path, key: str, value: bool):
    if not path.is_file():
        return
    text = path.read_text()
    text = re.sub(
        rf"(\b{re.escape(key)}\s*=\s*)(true|false)",
        rf"\g<1>{'true' if value else 'false'}",
        text,
    )
    path.write_text(text)


def lua_get_bool(path: Path, key: str, default=None):
    if not path.is_file():
        return default
    text = path.read_text()
    m = re.search(rf"\b{re.escape(key)}\s*=\s*(true|false)", text)
    return (m.group(1) == "true") if m else default


def raw_sub(path: Path, pattern: str, repl: str, flags=re.MULTILINE):
    if not path.is_file():
        return
    text = path.read_text()
    text = re.sub(pattern, repl, text, flags=flags)
    path.write_text(text)


def get_field(block_text: str, field: str, quoted: bool = False):
    """Read one field's value out of an already-extracted `{ ... }` block."""
    if quoted:
        m = re.search(rf'{re.escape(field)}\s*=\s*"([^"]*)"', block_text)
    else:
        m = re.search(rf"{re.escape(field)}\s*=\s*(-?[0-9]+(?:\.[0-9]+)?)", block_text)
    return m.group(1) if m else None


def apply_block_fields(text: str, header_regex: str, fields):
    """
    Find the first `<header>....})` block (non-greedy DOTALL — safe as long
    as the file uses trailing commas and only the block's own closing brace
    is immediately followed by ')'), then set each (field, value, quoted)
    inside just that block. Returns (new_text, found_bool).
    """
    m = re.search(header_regex + r".*?\}\)", text, re.DOTALL)
    if not m:
        return text, False
    block = m.group(0)
    for field, value, quoted in fields:
        # Matches the field's CURRENT value whether it's on disk as a quoted
        # string or a bare number, so a field can switch forms (e.g. Hyprland's
        # `scale = "auto"` vs `scale = 1.25`) and still be found and replaced.
        pattern = rf'({re.escape(field)}\s*=\s*)(?:"[^"]*"|-?[0-9]+(?:\.[0-9]+)?)'
        repl = rf'\g<1>"{value}"' if quoted else rf"\g<1>{value}"
        block = re.sub(pattern, repl, block, count=1)
    return text[: m.start()] + block + text[m.end() :], True


class ApplyResult:
    def __init__(self):
        self.lines: list[tuple[str, str]] = []

    def ok(self, msg):
        self.lines.append(("ok", msg))

    def skip(self, msg):
        self.lines.append(("skip", msg))

    def err(self, msg):
        self.lines.append(("err", msg))




# =============================================================================
#  SDDM avatar — crop/resize a chosen image with ImageMagick and install it
#  as the user's SDDM face icon. Mirrors sddm_avatar.sh, but run through a
#  privileged helper script so the GUI can do it without a manual terminal.
# =============================================================================


def build_avatar_apply_script(username: str, src_image: str) -> str:
    """Bash script (run as root) that backs up any existing face icon, then
    crops `src_image` to a square, resizes it to 256x256, and installs it as
    `<username>.face.icon`. Every path is shell-quoted since src_image comes
    straight from a user-picked file and may contain spaces or other
    special characters."""
    q = shlex.quote
    faces_dir = str(SDDM_FACES_DIR)
    face_icon = f"{faces_dir}/{username}.face.icon"
    backup_icon = f"{face_icon}.bkp"
    tmp_face = f"{faces_dir}/.tmp_face_{os.getpid()}"

    return f"""set -e
mkdir -p {q(faces_dir)}
if [ -f {q(face_icon)} ]; then
    cp -f {q(face_icon)} {q(backup_icon)}
fi
cp {q(src_image)} {q(tmp_face)}
mogrify -gravity center -crop 1:1 +repage {q(tmp_face)}
mogrify -resize 256x256 {q(tmp_face)}
mv -f {q(tmp_face)} {q(face_icon)}
chmod 644 {q(face_icon)}
"""


# =============================================================================
#  Reading current values (fixes the "always shows defaults" bug — every
#  control below is seeded from these instead of a hard-coded number)
# =============================================================================


def extract_lua_table(text, table_name):
    """Finds `table_name = { ... }` handling nested braces properly."""
    m = re.search(rf"\b{table_name}\s*=\s*\{{", text)
    if not m:
        return None, -1, -1
    start_idx = m.end() - 1
    depth = 0
    in_string = None
    i = start_idx
    while i < len(text):
        c = text[i]
        if in_string:
            if c == "\\":
                i += 2
                continue
            elif c == in_string:
                in_string = None
        else:
            if c in ('"', "'"):
                in_string = c
            elif c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    return text[m.start():i+1], m.start(), i+1
        i += 1
    return None, -1, -1


def _read_dual_tone_border() -> bool:
    """Return dual_tone_border preference from wallpaper_config.json (default True)."""
    cfg_file = Path.home() / ".local" / "share" / "hyprconf" / "wallpaper_config.json"
    if cfg_file.exists():
        try:
            data = json.loads(cfg_file.read_text())
            if isinstance(data, dict) and isinstance(data.get("dual_tone_border"), bool):
                return data["dual_tone_border"]
        except Exception:
            pass
    return True


def read_appearance():
    layout = "scrolling"
    col_width = 1.0
    motion_blur_enabled = False
    motion_blur_samples = 7
    wobble_enabled = False
    wobble_mesh = 12
    wobble_stiffness = 200.0
    wobble_damping = 12.0
    wobble_mass = 1.0
    wobble_intensity = 0.2
    wobble_value_epsilon = 0.25
    wobble_velocity_epsilon = 2.0

    glow_enabled = False
    glow_range = 15
    glow_render_power = 2

    blur_enabled = True
    blur_size = 8
    blur_passes = 1
    blur_ignore_opacity = True
    blur_new_optimizations = True
    blur_xray = False
    blur_noise = 0.0117
    blur_contrast = 0.8916
    blur_brightness = 1.0
    blur_vibrancy = 0.1696
    blur_vibrancy_darkness = 0.0
    blur_special = False
    blur_popups = False
    blur_popups_ignorealpha = 0.2
    blur_input_methods = False
    blur_input_methods_ignorealpha = 0.2
    blur_proportional = False
    blur_variant = "kawase"

    blur_acrylic_aberration = 0.025
    blur_acrylic_bulb = 48.0
    blur_acrylic_clarity = 0.82
    blur_acrylic_refraction = 24.0

    blur_aurora_intensity = 0.35
    blur_aurora_speed = 1.0

    blur_drops_speed = 3.0

    blur_fluid_jar_distortion = 8.0
    blur_fluid_jar_fill_amount = 0.5
    blur_fluid_jar_mass = 1.4
    blur_fluid_jar_precision = 2.0
    blur_fluid_jar_speed = 3.7
    blur_fluid_jar_turbulence = 1.2

    blur_glass_refraction = 20.0
    blur_glass_roughness = 1.0
    blur_glass_size = 40.0

    blur_haze_intensity = 0.35
    blur_haze_iridescence = 0.7

    blur_heat_shimmer_speed = 1.0

    blur_ripple_duration = 0.45
    blur_ripple_radius = 400.0
    blur_ripple_strength = 30.0
    blur_ripple_width = 32.0

    blur_water_damping = 0.95
    blur_water_duration = 12.0
    blur_water_radius = 20.0
    blur_water_speed = 0.76
    blur_water_strength = 32.0

    bsize_cfg = lua_get(CONFIGS_LUA, "blur_size")
    if bsize_cfg:
        try:
            blur_size = int(float(bsize_cfg))
        except ValueError:
            pass

    bpass_cfg = lua_get(CONFIGS_LUA, "blur_pass")
    if bpass_cfg:
        try:
            blur_passes = int(float(bpass_cfg))
        except ValueError:
            pass

    if DECORATION_LUA.is_file():
        text = DECORATION_LUA.read_text()
        m_layout = re.search(r'layout\s*=\s*"([^"]+)"', text)
        if m_layout:
            layout = m_layout.group(1)
        m_col = re.search(
            r"scrolling\s*=\s*\{.*?column_width\s*=\s*([0-9.]+)", text, re.DOTALL
        )
        if m_col:
            col_width = float(m_col.group(1))
        else:
            m_col2 = re.search(r"column_width\s*=\s*([0-9.]+)", text)
            if m_col2:
                col_width = float(m_col2.group(1))

        # Glow
        tbl_glow, _, _ = extract_lua_table(text, "glow")
        if tbl_glow:
            m_en = re.search(r'\benabled\s*=\s*(true|false)', tbl_glow)
            if m_en:
                glow_enabled = (m_en.group(1) == "true")
            m_rng = re.search(r'\brange\s*=\s*([0-9]+)', tbl_glow)
            if m_rng:
                glow_range = int(m_rng.group(1))
            m_rp = re.search(r'\brender_power\s*=\s*([0-9]+)', tbl_glow)
            if m_rp:
                glow_render_power = int(m_rp.group(1))

        # Blur
        tbl_blur, _, _ = extract_lua_table(text, "blur")
        if tbl_blur:
            m_en = re.search(r'\benabled\s*=\s*(true|false)', tbl_blur)
            if m_en:
                blur_enabled = (m_en.group(1) == "true")
            m_sz = re.search(r'\bsize\s*=\s*([0-9]+)', tbl_blur)
            if m_sz:
                blur_size = int(m_sz.group(1))
            m_ps = re.search(r'\bpasses\s*=\s*([0-9]+)', tbl_blur)
            if m_ps:
                blur_passes = int(m_ps.group(1))
            m_io = re.search(r'\bignore_opacity\s*=\s*(true|false)', tbl_blur)
            if m_io:
                blur_ignore_opacity = (m_io.group(1) == "true")
            m_no = re.search(r'\bnew_optimizations\s*=\s*(true|false)', tbl_blur)
            if m_no:
                blur_new_optimizations = (m_no.group(1) == "true")
            m_xr = re.search(r'\bxray\s*=\s*(true|false)', tbl_blur)
            if m_xr:
                blur_xray = (m_xr.group(1) == "true")
            m_sp = re.search(r'\bspecial\s*=\s*(true|false)', tbl_blur)
            if m_sp:
                blur_special = (m_sp.group(1) == "true")
            m_pop = re.search(r'\bpopups\s*=\s*(true|false)', tbl_blur)
            if m_pop:
                blur_popups = (m_pop.group(1) == "true")
            m_im = re.search(r'\binput_methods\s*=\s*(true|false)', tbl_blur)
            if m_im:
                blur_input_methods = (m_im.group(1) == "true")
            m_pr = re.search(r'\bproportional\s*=\s*(true|false)', tbl_blur)
            if m_pr:
                blur_proportional = (m_pr.group(1) == "true")

            m_var = re.search(r'\bvariant\s*=\s*["\x27]?([a-zA-Z0-9_]+)["\x27]?', tbl_blur)
            if m_var:
                blur_variant = m_var.group(1)

            for prop, target_var in [
                ("noise", "blur_noise"),
                ("contrast", "blur_contrast"),
                ("brightness", "blur_brightness"),
                ("vibrancy", "blur_vibrancy"),
                ("vibrancy_darkness", "blur_vibrancy_darkness"),
                ("popups_ignorealpha", "blur_popups_ignorealpha"),
                ("input_methods_ignorealpha", "blur_input_methods_ignorealpha"),
            ]:
                m = re.search(rf'\b{prop}\s*=\s*([0-9.]+)', tbl_blur)
                if m:
                    if target_var == "blur_noise": blur_noise = float(m.group(1))
                    elif target_var == "blur_contrast": blur_contrast = float(m.group(1))
                    elif target_var == "blur_brightness": blur_brightness = float(m.group(1))
                    elif target_var == "blur_vibrancy": blur_vibrancy = float(m.group(1))
                    elif target_var == "blur_vibrancy_darkness": blur_vibrancy_darkness = float(m.group(1))
                    elif target_var == "blur_popups_ignorealpha": blur_popups_ignorealpha = float(m.group(1))
                    elif target_var == "blur_input_methods_ignorealpha": blur_input_methods_ignorealpha = float(m.group(1))

            tbl_acr, _, _ = extract_lua_table(tbl_blur, "acrylic")
            if tbl_acr:
                m = re.search(r'\baberration\s*=\s*([0-9.]+)', tbl_acr)
                if m: blur_acrylic_aberration = float(m.group(1))
                m = re.search(r'\bbulb\s*=\s*([0-9.]+)', tbl_acr)
                if m: blur_acrylic_bulb = float(m.group(1))
                m = re.search(r'\bclarity\s*=\s*([0-9.]+)', tbl_acr)
                if m: blur_acrylic_clarity = float(m.group(1))
                m = re.search(r'\brefraction\s*=\s*([0-9.]+)', tbl_acr)
                if m: blur_acrylic_refraction = float(m.group(1))

            tbl_aur, _, _ = extract_lua_table(tbl_blur, "aurora")
            if tbl_aur:
                m = re.search(r'\bintensity\s*=\s*([0-9.]+)', tbl_aur)
                if m: blur_aurora_intensity = float(m.group(1))
                m = re.search(r'\bspeed\s*=\s*([0-9.]+)', tbl_aur)
                if m: blur_aurora_speed = float(m.group(1))

            tbl_drp, _, _ = extract_lua_table(tbl_blur, "drops")
            if tbl_drp:
                m = re.search(r'\bspeed\s*=\s*([0-9.]+)', tbl_drp)
                if m: blur_drops_speed = float(m.group(1))

            tbl_fj, _, _ = extract_lua_table(tbl_blur, "fluid_jar")
            if tbl_fj:
                m = re.search(r'\bdistortion\s*=\s*([0-9.]+)', tbl_fj)
                if m: blur_fluid_jar_distortion = float(m.group(1))
                m = re.search(r'\bfill_amount\s*=\s*([0-9.]+)', tbl_fj)
                if m: blur_fluid_jar_fill_amount = float(m.group(1))
                m = re.search(r'\bmass\s*=\s*([0-9.]+)', tbl_fj)
                if m: blur_fluid_jar_mass = float(m.group(1))
                m = re.search(r'\bprecision\s*=\s*([0-9.]+)', tbl_fj)
                if m: blur_fluid_jar_precision = float(m.group(1))
                m = re.search(r'\bspeed\s*=\s*([0-9.]+)', tbl_fj)
                if m: blur_fluid_jar_speed = float(m.group(1))
                m = re.search(r'\bturbulence\s*=\s*([0-9.]+)', tbl_fj)
                if m: blur_fluid_jar_turbulence = float(m.group(1))

            tbl_gls, _, _ = extract_lua_table(tbl_blur, "glass")
            if tbl_gls:
                m = re.search(r'\brefraction\s*=\s*([0-9.]+)', tbl_gls)
                if m: blur_glass_refraction = float(m.group(1))
                m = re.search(r'\broughness\s*=\s*([0-9.]+)', tbl_gls)
                if m: blur_glass_roughness = float(m.group(1))
                m = re.search(r'\bsize\s*=\s*([0-9.]+)', tbl_gls)
                if m: blur_glass_size = float(m.group(1))

            tbl_hz, _, _ = extract_lua_table(tbl_blur, "haze")
            if tbl_hz:
                m = re.search(r'\bintensity\s*=\s*([0-9.]+)', tbl_hz)
                if m: blur_haze_intensity = float(m.group(1))
                m = re.search(r'\biridescence\s*=\s*([0-9.]+)', tbl_hz)
                if m: blur_haze_iridescence = float(m.group(1))

            tbl_hs, _, _ = extract_lua_table(tbl_blur, "heat_shimmer")
            if tbl_hs:
                m = re.search(r'\bspeed\s*=\s*([0-9.]+)', tbl_hs)
                if m: blur_heat_shimmer_speed = float(m.group(1))

            tbl_rp, _, _ = extract_lua_table(tbl_blur, "ripple")
            if tbl_rp:
                m = re.search(r'\bduration\s*=\s*([0-9.]+)', tbl_rp)
                if m: blur_ripple_duration = float(m.group(1))
                m = re.search(r'\bradius\s*=\s*([0-9.]+)', tbl_rp)
                if m: blur_ripple_radius = float(m.group(1))
                m = re.search(r'\bstrength\s*=\s*([0-9.]+)', tbl_rp)
                if m: blur_ripple_strength = float(m.group(1))
                m = re.search(r'\bwidth\s*=\s*([0-9.]+)', tbl_rp)
                if m: blur_ripple_width = float(m.group(1))

            tbl_wt, _, _ = extract_lua_table(tbl_blur, "water")
            if tbl_wt:
                m = re.search(r'\bdamping\s*=\s*([0-9.]+)', tbl_wt)
                if m: blur_water_damping = float(m.group(1))
                m = re.search(r'\bduration\s*=\s*([0-9.]+)', tbl_wt)
                if m: blur_water_duration = float(m.group(1))
                m = re.search(r'\bradius\s*=\s*([0-9.]+)', tbl_wt)
                if m: blur_water_radius = float(m.group(1))
                m = re.search(r'\bspeed\s*=\s*([0-9.]+)', tbl_wt)
                if m: blur_water_speed = float(m.group(1))
                m = re.search(r'\bstrength\s*=\s*([0-9.]+)', tbl_wt)
                if m: blur_water_strength = float(m.group(1))

        # Motion blur
        m_mb = re.search(r'motion_blur\s*=\s*\{([^}]*)\}', text, re.DOTALL)
        if m_mb:
            mb_text = m_mb.group(1)
            m_en = re.search(r'\benabled\s*=\s*(true|false)', mb_text)
            if m_en:
                motion_blur_enabled = (m_en.group(1) == "true")
            m_samp = re.search(r'\bsamples\s*=\s*([0-9]+)', mb_text)
            if m_samp:
                motion_blur_samples = int(m_samp.group(1))

        # Wobble
        m_wob = re.search(r'wobble\s*=\s*\{([^}]*)\}', text, re.DOTALL)
        if m_wob:
            wob_text = m_wob.group(1)
            m_en = re.search(r'\benabled\s*=\s*(true|false)', wob_text)
            if m_en:
                wobble_enabled = (m_en.group(1) == "true")
            m_mesh = re.search(r'\bmesh\s*=\s*([0-9]+)', wob_text)
            if m_mesh:
                wobble_mesh = int(m_mesh.group(1))
            m_stiff = re.search(r'\bstiffness\s*=\s*([0-9.]+)', wob_text)
            if m_stiff:
                wobble_stiffness = float(m_stiff.group(1))
            m_damp = re.search(r'\bdamping\s*=\s*([0-9.]+)', wob_text)
            if m_damp:
                wobble_damping = float(m_damp.group(1))
            m_mass = re.search(r'\bmass\s*=\s*([0-9.]+)', wob_text)
            if m_mass:
                wobble_mass = float(m_mass.group(1))
            m_inten = re.search(r'\bintensity\s*=\s*([0-9.]+)', wob_text)
            if m_inten:
                wobble_intensity = float(m_inten.group(1))
            m_veps = re.search(r'\bvalue_epsilon\s*=\s*([0-9.]+)', wob_text)
            if m_veps:
                wobble_value_epsilon = float(m_veps.group(1))
            m_vleps = re.search(r'\bvelocity_epsilon\s*=\s*([0-9.]+)', wob_text)
            if m_vleps:
                wobble_velocity_epsilon = float(m_vleps.group(1))

    return {
        "border": float(lua_get(CONFIGS_LUA, "border") or 2),
        "dual_tone_border": _read_dual_tone_border(),
        "rounding": float(lua_get(CONFIGS_LUA, "rounding") or 8),
        "inner_gap": float(lua_get(CONFIGS_LUA, "inner_gap") or 4),
        "outer_gap": float(lua_get(CONFIGS_LUA, "outer_gap") or 8),
        "blur_size": float(blur_size),
        "blur_pass": float(blur_passes),
        "opacity_act": float(lua_get(CONFIGS_LUA, "opacity_act") or 0.95),
        "opacity_deact": float(lua_get(CONFIGS_LUA, "opacity_deact") or 0.75),
        "shadow_range": float(lua_get(CONFIGS_LUA, "shadow_range") or 12),
        "layout": layout,
        "column_width": col_width,
        "glow_enabled": glow_enabled,
        "glow_range": glow_range,
        "glow_render_power": glow_render_power,
        "blur_enabled": blur_enabled,
        "blur_passes": blur_passes,
        "blur_ignore_opacity": blur_ignore_opacity,
        "blur_new_optimizations": blur_new_optimizations,
        "blur_xray": blur_xray,
        "blur_noise": blur_noise,
        "blur_contrast": blur_contrast,
        "blur_brightness": blur_brightness,
        "blur_vibrancy": blur_vibrancy,
        "blur_vibrancy_darkness": blur_vibrancy_darkness,
        "blur_special": blur_special,
        "blur_popups": blur_popups,
        "blur_popups_ignorealpha": blur_popups_ignorealpha,
        "blur_input_methods": blur_input_methods,
        "blur_input_methods_ignorealpha": blur_input_methods_ignorealpha,
        "blur_proportional": blur_proportional,
        "blur_variant": blur_variant,
        "blur_acrylic_aberration": blur_acrylic_aberration,
        "blur_acrylic_bulb": blur_acrylic_bulb,
        "blur_acrylic_clarity": blur_acrylic_clarity,
        "blur_acrylic_refraction": blur_acrylic_refraction,
        "blur_aurora_intensity": blur_aurora_intensity,
        "blur_aurora_speed": blur_aurora_speed,
        "blur_drops_speed": blur_drops_speed,
        "blur_fluid_jar_distortion": blur_fluid_jar_distortion,
        "blur_fluid_jar_fill_amount": blur_fluid_jar_fill_amount,
        "blur_fluid_jar_mass": blur_fluid_jar_mass,
        "blur_fluid_jar_precision": blur_fluid_jar_precision,
        "blur_fluid_jar_speed": blur_fluid_jar_speed,
        "blur_fluid_jar_turbulence": blur_fluid_jar_turbulence,
        "blur_glass_refraction": blur_glass_refraction,
        "blur_glass_roughness": blur_glass_roughness,
        "blur_glass_size": blur_glass_size,
        "blur_haze_intensity": blur_haze_intensity,
        "blur_haze_iridescence": blur_haze_iridescence,
        "blur_heat_shimmer_speed": blur_heat_shimmer_speed,
        "blur_ripple_duration": blur_ripple_duration,
        "blur_ripple_radius": blur_ripple_radius,
        "blur_ripple_strength": blur_ripple_strength,
        "blur_ripple_width": blur_ripple_width,
        "blur_water_damping": blur_water_damping,
        "blur_water_duration": blur_water_duration,
        "blur_water_radius": blur_water_radius,
        "blur_water_speed": blur_water_speed,
        "blur_water_strength": blur_water_strength,
        "motion_blur_enabled": motion_blur_enabled,
        "motion_blur_samples": motion_blur_samples,
        "wobble_enabled": wobble_enabled,
        "wobble_mesh": wobble_mesh,
        "wobble_stiffness": wobble_stiffness,
        "wobble_damping": wobble_damping,
        "wobble_mass": wobble_mass,
        "wobble_intensity": wobble_intensity,
        "wobble_value_epsilon": wobble_value_epsilon,
        "wobble_velocity_epsilon": wobble_velocity_epsilon,
    }


def read_input():
    return {
        "sensitivity": float(lua_get(SETTINGS_LUA, "sensitivity") or 0.0),
        "natural_scroll": lua_get_bool(SETTINGS_LUA, "natural_scroll", True),
        "tap_to_click": lua_get_bool(SETTINGS_LUA, "tap_to_click", True),
        "disable_while_typing": lua_get_bool(SETTINGS_LUA, "disable_while_typing", True),
        "left_handed": lua_get_bool(SETTINGS_LUA, "left_handed", False),
        "numlock_by_default": lua_get_bool(SETTINGS_LUA, "numlock_by_default", True),
    }


def _get_monitor_scale(block: str):
    """Hyprland's `scale` is either the string "auto" or a bare float —
    read whichever form is present. Returns "auto" or a float."""
    m = re.search(r'scale\s*=\s*"([^"]*)"', block)
    if m:
        return m.group(1) or "auto"
    m = re.search(r"scale\s*=\s*(-?[0-9]+(?:\.[0-9]+)?)", block)
    if m:
        return float(m.group(1))
    return "auto"


def parse_monitors():
    if not MONITOR_LUA.is_file():
        return []
    text = MONITOR_LUA.read_text()
    monitors = []
    for m in re.finditer(r"hl\.monitor\(\{.*?\}\)", text, re.DOTALL):
        block = m.group(0)
        # `output` may legitimately be "" (Hyprland's catch-all default
        # monitor block) — only skip if the key is missing entirely.
        out_match = re.search(r'output\s*=\s*"([^"]*)"', block)
        if out_match is None:
            continue
        output = out_match.group(1)
        monitors.append(
            {
                "output": output,
                "mode": get_field(block, "mode", quoted=True) or "preferred",
                "position": get_field(block, "position", quoted=True) or "auto",
                "scale": _get_monitor_scale(block),
            }
        )
    return monitors


# Static fallback used only when the live compositor can't be queried
# (e.g. running this app outside a Hyprland session).
FALLBACK_RESOLUTIONS = [
    (7680, 4320), (3840, 2160), (3440, 1440), (2560, 1600), (2560, 1440),
    (2560, 1080), (1920, 1200), (1920, 1080), (1680, 1050), (1600, 900),
    (1440, 900), (1366, 768), (1280, 1024), (1280, 800), (1280, 720),
    (1024, 768),
]
FALLBACK_REFRESH = [
    360.0, 240.0, 180.0, 165.0, 144.0, 120.0, 100.0, 90.0, 75.0,
    60.0, 59.94, 50.0, 48.0, 30.0,
]


def _query_hyprctl_modes(output_name: str):
    """Best-effort list of (width, height, hz) tuples from the running
    compositor. Returns [] on any failure (hyprctl missing, not in a
    Hyprland session, timeout, bad JSON) so callers can fall back cleanly."""
    try:
        proc = subprocess.run(
            ["hyprctl", "monitors", "-j"], capture_output=True, text=True, timeout=2
        )
        if proc.returncode != 0 or not proc.stdout.strip():
            return []
        data = json.loads(proc.stdout)
    except Exception:
        return []
    modes = []
    for mon in data:
        if output_name and mon.get("name") != output_name:
            continue
        for m in mon.get("availableModes", []) or []:
            mm = re.match(r"(\d+)x(\d+)@([\d.]+)", str(m))
            if mm:
                modes.append((int(mm.group(1)), int(mm.group(2)), float(mm.group(3))))
    return modes


def get_resolution_options(output_name: str):
    """Returns (resolutions, refresh_by_res): resolutions is a list of
    (w, h) tuples sorted largest-first; refresh_by_res maps (w, h) to a
    Hz-descending list. Prefers live data from `hyprctl monitors -j`,
    falling back to a static common list when that's unavailable."""
    modes = _query_hyprctl_modes(output_name)
    if modes:
        res_set = sorted({(w, h) for w, h, _ in modes}, key=lambda wh: -(wh[0] * wh[1]))
        refresh_by_res: dict = {}
        for w, h, r in modes:
            refresh_by_res.setdefault((w, h), set()).add(r)
        refresh_by_res = {k: sorted(v, reverse=True) for k, v in refresh_by_res.items()}
        return res_set, refresh_by_res
    refresh_by_res = {wh: list(FALLBACK_REFRESH) for wh in FALLBACK_RESOLUTIONS}
    return list(FALLBACK_RESOLUTIONS), refresh_by_res


def fmt_hz(v: float) -> str:
    return f"{int(v)} Hz" if float(v).is_integer() else f"{v:g} Hz"


def fmt_hz_value(v: float) -> str:
    return f"{v:.2f}".rstrip("0").rstrip(".")


def parse_curves():
    if not ANIMATION_LUA.is_file():
        return {}
    text = ANIMATION_LUA.read_text()
    curves = {}
    for m in re.finditer(r'hl\.curve\(\s*"([^"]+)"\s*,\s*\{.*?\}\)', text, re.DOTALL):
        name = m.group(1)
        pts = re.findall(r"\{\s*(-?[0-9.]+)\s*,\s*(-?[0-9.]+)\s*\}", m.group(0))
        if len(pts) >= 2:
            curves[name] = (
                (float(pts[0][0]), float(pts[0][1])),
                (float(pts[1][0]), float(pts[1][1])),
            )
    return curves


def parse_animations():
    if not ANIMATION_LUA.is_file():
        return []
    text = ANIMATION_LUA.read_text()
    anims = []
    for m in re.finditer(
        r'hl\.animation\(\{\s*leaf\s*=\s*"([^"]+)".*?\}\)', text, re.DOTALL
    ):
        block = m.group(0)
        speed = get_field(block, "speed")
        bezier = get_field(block, "bezier", quoted=True)
        style = get_field(block, "style", quoted=True)
        enabled_val = get_field(block, "enabled")
        is_enabled = (enabled_val != "0") if enabled_val is not None else True
        anims.append(
            {
                "leaf": m.group(1),
                "speed": float(speed) if speed else 1.0,
                "bezier": bezier or "",
                "style": style or "",
                "enabled": is_enabled,
            }
        )
    return anims



def parse_anim_global_enabled():
    if not ANIMATION_LUA.is_file():
        return True
    text = ANIMATION_LUA.read_text()
    m = re.search(r"hl\.config\(\{\s*animations\s*=\s*\{.*?\}\)", text, re.DOTALL)
    if not m:
        return True
    val = get_field(m.group(0), "enabled")
    return val != "0"


def parse_env_vars():
    if not ENVIRONMENT_LUA.is_file():
        return []
    out = []
    for line in ENVIRONMENT_LUA.read_text().splitlines():
        s = line.strip()
        if s.startswith("--"):
            continue
        m = re.match(r'hl\.env\(\s*"([^"]+)"\s*,\s*"([^"]*)"\s*\)', s)
        if m:
            out.append((m.group(1), m.group(2)))
    return out


def split_top_level(s: str):
    """Split a Lua argument list on top-level commas, respecting nested
    brackets and string literals."""
    parts, buf, depth, in_str, str_ch = [], [], 0, False, ""
    i = 0
    while i < len(s):
        c = s[i]
        if in_str:
            buf.append(c)
            if c == "\\" and i + 1 < len(s):
                buf.append(s[i + 1])
                i += 2
                continue
            if c == str_ch:
                in_str = False
            i += 1
            continue
        if c in "\"'":
            in_str, str_ch = True, c
            buf.append(c)
        elif c in "({[":
            depth += 1
            buf.append(c)
        elif c in ")}]":
            depth -= 1
            buf.append(c)
        elif c == "," and depth == 0:
            parts.append("".join(buf).strip())
            buf = []
        else:
            buf.append(c)
        i += 1
    if buf:
        parts.append("".join(buf).strip())
    return parts


def iter_keybind_statements():
    """Extract every *active* (non-commented) `hl.bind(...)` statement from
    keybinds.lua as raw, paren-balanced Lua source (handles multi-line
    statements), along with a human-readable preview."""
    if not KEYBINDS_LUA.is_file():
        return []
    text = KEYBINDS_LUA.read_text()
    results = []
    for m in re.finditer(r"hl\.bind\s*\(", text):
        start = m.start()
        line_start = text.rfind("\n", 0, start) + 1
        if "--" in text[line_start:start]:
            continue  # commented out
        depth, in_str, str_ch = 0, False, ""
        j = m.end() - 1  # position of the opening '('
        n = len(text)
        while j < n:
            c = text[j]
            if in_str:
                if c == "\\":
                    j += 2
                    continue
                if c == str_ch:
                    in_str = False
            else:
                if c in "\"'":
                    in_str, str_ch = True, c
                elif c == "(":
                    depth += 1
                elif c == ")":
                    depth -= 1
                    if depth == 0:
                        j += 1
                        break
            j += 1
        raw = text[start:j]
        inner = raw[raw.index("(") + 1 : -1]
        args = split_top_level(inner)
        combo = args[0] if args else ""
        action = args[1] if len(args) > 1 else ""
        results.append({"raw": raw, "combo": combo, "action": action})
    return results


# =============================================================================
#  Apply — writes every pending change to disk
# =============================================================================


def apply_all(pending: dict, result: ApplyResult):
    _apply_appearance(pending, result)
    _apply_monitor(pending, result)
    _apply_animations(pending, result)
    _apply_input(pending, result)
    _apply_environment(pending, result)
    _apply_keybinds(pending, result)
    try:
        subprocess.run(["hyprctl", "reload"], capture_output=True, timeout=2)
    except Exception:
        pass


def _apply_appearance(pending, result):
    need_hypr = any(
        k in pending
        for k in (
            "border_size",
            "roundness",
            "inner_gap",
            "outer_gap",
            "blur",
            "opacity",
            "shadow",
        )
    )
    need_decoration = any(
        k in pending
        for k in (
            "layout",
            "column_width",
            "glow",
            "glow_enabled",
            "glow_range",
            "glow_render_power",
            "blur",
            "blur_enabled",
            "blur_size",
            "blur_passes",
            "blur_ignore_opacity",
            "blur_new_optimizations",
            "blur_xray",
            "blur_noise",
            "blur_contrast",
            "blur_brightness",
            "blur_vibrancy",
            "blur_vibrancy_darkness",
            "blur_special",
            "blur_popups",
            "blur_popups_ignorealpha",
            "blur_input_methods",
            "blur_input_methods_ignorealpha",
            "blur_proportional",
            "blur_variant",
            "blur_acrylic_aberration",
            "blur_acrylic_bulb",
            "blur_acrylic_clarity",
            "blur_acrylic_refraction",
            "blur_aurora_intensity",
            "blur_aurora_speed",
            "blur_drops_speed",
            "blur_fluid_jar_distortion",
            "blur_fluid_jar_fill_amount",
            "blur_fluid_jar_mass",
            "blur_fluid_jar_precision",
            "blur_fluid_jar_speed",
            "blur_fluid_jar_turbulence",
            "blur_glass_refraction",
            "blur_glass_roughness",
            "blur_glass_size",
            "blur_haze_intensity",
            "blur_haze_iridescence",
            "blur_heat_shimmer_speed",
            "blur_ripple_duration",
            "blur_ripple_radius",
            "blur_ripple_strength",
            "blur_ripple_width",
            "blur_water_damping",
            "blur_water_duration",
            "blur_water_radius",
            "blur_water_speed",
            "blur_water_strength",
            "motion_blur",
            "motion_blur_enabled",
            "motion_blur_samples",
            "wobble",
            "wobble_enabled",
            "wobble_mesh",
            "wobble_stiffness",
            "wobble_damping",
            "wobble_mass",
            "wobble_intensity",
            "wobble_value_epsilon",
            "wobble_velocity_epsilon",
        )
    )
    need_kitty = "opacity" in pending
    need_gtk = "opacity" in pending

    if need_hypr:
        backup(CONFIGS_LUA)
    if need_decoration:
        backup(DECORATION_LUA)
    if need_kitty:
        backup(KITTY_CONF)
    if need_gtk:
        backup(GTK3_CSS)
        backup(GTK4_CSS)

    if "layout" in pending:
        val = str(pending["layout"])
        if DECORATION_LUA.is_file():
            text = DECORATION_LUA.read_text()
            text, found = apply_block_fields(
                text,
                r"general\s*=\s*\{",
                [("layout", val, True)],
            )
            if not found:
                text, n = re.subn(
                    r'(layout\s*=\s*)"[^"]*"', rf'\g<1>"{val}"', text, count=1
                )
                found = n > 0
            if found:
                DECORATION_LUA.write_text(text)
                result.ok(f"layout           → {val}")
            else:
                result.err("layout field not found in decoration.lua")
        else:
            result.err("decoration.lua not found — layout skipped")

    if "column_width" in pending:
        val = float(pending["column_width"])
        if DECORATION_LUA.is_file():
            text = DECORATION_LUA.read_text()
            if "scrolling" in text:
                text, found = apply_block_fields(
                    text,
                    r"scrolling\s*=\s*\{",
                    [("column_width", val, False)],
                )
                if not found:
                    text, n = re.subn(
                        r'(column_width\s*=\s*)[0-9.]+', rf'\g<1>{val}', text, count=1
                    )
                    found = n > 0
            else:
                text += f'\n-- Scrolling layout\nhl.config({{\n    scrolling = {{\n        column_width = {val},\n    }},\n}})\n'
                found = True
            if found:
                DECORATION_LUA.write_text(text)
                result.ok(f"column_width     → {val}")
            else:
                result.err("column_width field not found in decoration.lua")
        else:
            result.err("decoration.lua not found — column_width skipped")

    if "border_size" in pending:
        val = str(pending["border_size"])
        if CONFIGS_LUA.is_file():
            lua_set(CONFIGS_LUA, "border", val)
            result.ok(f"border-size      → {val}")
        else:
            result.err("configs.lua not found — border size skipped")

    if "dual_tone_border" in pending:
        enabled = bool(pending["dual_tone_border"])
        hypr_colors_py = Path(__file__).resolve().parent / "hypr-colors.py"
        if not hypr_colors_py.is_file():
            hypr_colors_py = Path.home() / ".hyprconf" / "hypr" / "scripts" / "py" / "hypr-colors.py"
        if hypr_colors_py.is_file():
            r = subprocess.run(
                [sys.executable, str(hypr_colors_py), "--dual-border", "on" if enabled else "off"],
                capture_output=True,
                text=True,
                timeout=8,
            )
            if r.returncode == 0:
                result.ok(f"dual-tone-border → {'on' if enabled else 'off'}")
            else:
                result.err(f"dual-tone-border failed: {r.stderr.strip() or r.returncode}")
        else:
            result.err("hypr-colors.py not found — dual-tone border skipped")

    if "roundness" in pending:
        val = str(pending["roundness"])
        if CONFIGS_LUA.is_file():
            lua_set(CONFIGS_LUA, "rounding", val)
            result.ok(f"rounding         → {val}")
        else:
            result.err("configs.lua not found — roundness skipped")

    if "inner_gap" in pending:
        val = str(pending["inner_gap"])
        if CONFIGS_LUA.is_file():
            lua_set(CONFIGS_LUA, "inner_gap", val)
            result.ok(f"inner-gap        → {val}")
        else:
            result.err("configs.lua not found — inner gap skipped")

    if "outer_gap" in pending:
        val = str(pending["outer_gap"])
        if CONFIGS_LUA.is_file():
            lua_set(CONFIGS_LUA, "outer_gap", val)
            result.ok(f"outer-gap        → {val}")
        else:
            result.err("configs.lua not found — outer gap skipped")

    # Glow
    glow_keys = ("glow", "glow_enabled", "glow_range", "glow_render_power")
    if any(k in pending for k in glow_keys):
        if DECORATION_LUA.is_file():
            text = DECORATION_LUA.read_text()
            cur_app = read_appearance()
            glow_enabled = cur_app["glow_enabled"]
            glow_range = cur_app["glow_range"]
            glow_render_power = cur_app["glow_render_power"]

            if "glow" in pending:
                val = pending["glow"]
                if isinstance(val, dict):
                    glow_enabled = val.get("enabled", glow_enabled)
                    glow_range = val.get("range", glow_range)
                    glow_render_power = val.get("render_power", glow_render_power)
                elif isinstance(val, bool):
                    glow_enabled = val
            if "glow_enabled" in pending:
                glow_enabled = bool(pending["glow_enabled"])
            if "glow_range" in pending:
                glow_range = int(pending["glow_range"])
            if "glow_render_power" in pending:
                glow_render_power = int(pending["glow_render_power"])

            glow_block = (
                "glow             = {\n"
                f"            enabled        = {'true' if glow_enabled else 'false'},\n"
                "            color          = act_border,\n"
                "            color_inactive = inact_border,\n"
                f"            range          = {int(glow_range)},\n"
                f"            render_power   = {int(glow_render_power)},\n"
                "        },"
            )
            tbl_glow, s, e = extract_lua_table(text, "glow")
            if tbl_glow:
                if e < len(text) and text[e] == ",":
                    e += 1
                text = text[:s] + glow_block + text[e:]
            else:
                text = re.sub(r'(decoration\s*=\s*\{)', r'\1\n        ' + glow_block, text)

            DECORATION_LUA.write_text(text)
            result.ok(f"glow             → enabled:{glow_enabled} range:{glow_range} power:{glow_render_power}")

            try:
                subprocess.run(
                    [
                        "hyprctl",
                        "eval",
                        f"hl.config({{ decoration = {{ glow = {{ enabled = {'true' if glow_enabled else 'false'}, range = {int(glow_range)}, render_power = {int(glow_render_power)} }} }} }})",
                    ],
                    capture_output=True,
                    timeout=2,
                )
            except Exception:
                pass
        else:
            result.err("decoration.lua not found — glow skipped")

    # Comprehensive Blur
    blur_keys = (
        "blur",
        "blur_enabled",
        "blur_size",
        "blur_passes",
        "blur_ignore_opacity",
        "blur_new_optimizations",
        "blur_xray",
        "blur_noise",
        "blur_contrast",
        "blur_brightness",
        "blur_vibrancy",
        "blur_vibrancy_darkness",
        "blur_special",
        "blur_popups",
        "blur_popups_ignorealpha",
        "blur_input_methods",
        "blur_input_methods_ignorealpha",
        "blur_proportional",
        "blur_variant",
        "blur_acrylic_aberration",
        "blur_acrylic_bulb",
        "blur_acrylic_clarity",
        "blur_acrylic_refraction",
        "blur_aurora_intensity",
        "blur_aurora_speed",
        "blur_drops_speed",
        "blur_fluid_jar_distortion",
        "blur_fluid_jar_fill_amount",
        "blur_fluid_jar_mass",
        "blur_fluid_jar_precision",
        "blur_fluid_jar_speed",
        "blur_fluid_jar_turbulence",
        "blur_glass_refraction",
        "blur_glass_roughness",
        "blur_glass_size",
        "blur_haze_intensity",
        "blur_haze_iridescence",
        "blur_heat_shimmer_speed",
        "blur_ripple_duration",
        "blur_ripple_radius",
        "blur_ripple_strength",
        "blur_ripple_width",
        "blur_water_damping",
        "blur_water_duration",
        "blur_water_radius",
        "blur_water_speed",
        "blur_water_strength",
    )
    if any(k in pending for k in blur_keys):
        cur_app = read_appearance()
        blur_enabled = cur_app["blur_enabled"]
        blur_size = cur_app["blur_size"]
        blur_passes = cur_app["blur_passes"]
        blur_ignore_opacity = cur_app["blur_ignore_opacity"]
        blur_new_optimizations = cur_app["blur_new_optimizations"]
        blur_xray = cur_app["blur_xray"]
        blur_noise = cur_app["blur_noise"]
        blur_contrast = cur_app["blur_contrast"]
        blur_brightness = cur_app["blur_brightness"]
        blur_vibrancy = cur_app["blur_vibrancy"]
        blur_vibrancy_darkness = cur_app["blur_vibrancy_darkness"]
        blur_special = cur_app["blur_special"]
        blur_popups = cur_app["blur_popups"]
        blur_popups_ignorealpha = cur_app["blur_popups_ignorealpha"]
        blur_input_methods = cur_app["blur_input_methods"]
        blur_input_methods_ignorealpha = cur_app["blur_input_methods_ignorealpha"]
        blur_proportional = cur_app["blur_proportional"]
        blur_variant = cur_app["blur_variant"]

        blur_acrylic_aberration = cur_app["blur_acrylic_aberration"]
        blur_acrylic_bulb = cur_app["blur_acrylic_bulb"]
        blur_acrylic_clarity = cur_app["blur_acrylic_clarity"]
        blur_acrylic_refraction = cur_app["blur_acrylic_refraction"]

        blur_aurora_intensity = cur_app["blur_aurora_intensity"]
        blur_aurora_speed = cur_app["blur_aurora_speed"]
        blur_drops_speed = cur_app["blur_drops_speed"]

        blur_fluid_jar_distortion = cur_app["blur_fluid_jar_distortion"]
        blur_fluid_jar_fill_amount = cur_app["blur_fluid_jar_fill_amount"]
        blur_fluid_jar_mass = cur_app["blur_fluid_jar_mass"]
        blur_fluid_jar_precision = cur_app["blur_fluid_jar_precision"]
        blur_fluid_jar_speed = cur_app["blur_fluid_jar_speed"]
        blur_fluid_jar_turbulence = cur_app["blur_fluid_jar_turbulence"]

        blur_glass_refraction = cur_app["blur_glass_refraction"]
        blur_glass_roughness = cur_app["blur_glass_roughness"]
        blur_glass_size = cur_app["blur_glass_size"]

        blur_haze_intensity = cur_app["blur_haze_intensity"]
        blur_haze_iridescence = cur_app["blur_haze_iridescence"]
        blur_heat_shimmer_speed = cur_app["blur_heat_shimmer_speed"]

        blur_ripple_duration = cur_app["blur_ripple_duration"]
        blur_ripple_radius = cur_app["blur_ripple_radius"]
        blur_ripple_strength = cur_app["blur_ripple_strength"]
        blur_ripple_width = cur_app["blur_ripple_width"]

        blur_water_damping = cur_app["blur_water_damping"]
        blur_water_duration = cur_app["blur_water_duration"]
        blur_water_radius = cur_app["blur_water_radius"]
        blur_water_speed = cur_app["blur_water_speed"]
        blur_water_strength = cur_app["blur_water_strength"]

        if "blur" in pending:
            val = pending["blur"]
            if isinstance(val, (list, tuple)) and len(val) >= 2:
                blur_size = int(val[0])
                blur_passes = int(val[1])
            elif isinstance(val, bool):
                blur_enabled = val

        if "blur_enabled" in pending: blur_enabled = bool(pending["blur_enabled"])
        if "blur_size" in pending: blur_size = int(pending["blur_size"])
        if "blur_passes" in pending: blur_passes = int(pending["blur_passes"])
        if "blur_ignore_opacity" in pending: blur_ignore_opacity = bool(pending["blur_ignore_opacity"])
        if "blur_new_optimizations" in pending: blur_new_optimizations = bool(pending["blur_new_optimizations"])
        if "blur_xray" in pending: blur_xray = bool(pending["blur_xray"])
        if "blur_noise" in pending: blur_noise = float(pending["blur_noise"])
        if "blur_contrast" in pending: blur_contrast = float(pending["blur_contrast"])
        if "blur_brightness" in pending: blur_brightness = float(pending["blur_brightness"])
        if "blur_vibrancy" in pending: blur_vibrancy = float(pending["blur_vibrancy"])
        if "blur_vibrancy_darkness" in pending: blur_vibrancy_darkness = float(pending["blur_vibrancy_darkness"])
        if "blur_special" in pending: blur_special = bool(pending["blur_special"])
        if "blur_popups" in pending: blur_popups = bool(pending["blur_popups"])
        if "blur_popups_ignorealpha" in pending: blur_popups_ignorealpha = float(pending["blur_popups_ignorealpha"])
        if "blur_input_methods" in pending: blur_input_methods = bool(pending["blur_input_methods"])
        if "blur_input_methods_ignorealpha" in pending: blur_input_methods_ignorealpha = float(pending["blur_input_methods_ignorealpha"])
        if "blur_proportional" in pending: blur_proportional = bool(pending["blur_proportional"])
        if "blur_variant" in pending: blur_variant = str(pending["blur_variant"])

        if "blur_acrylic_aberration" in pending: blur_acrylic_aberration = float(pending["blur_acrylic_aberration"])
        if "blur_acrylic_bulb" in pending: blur_acrylic_bulb = float(pending["blur_acrylic_bulb"])
        if "blur_acrylic_clarity" in pending: blur_acrylic_clarity = float(pending["blur_acrylic_clarity"])
        if "blur_acrylic_refraction" in pending: blur_acrylic_refraction = float(pending["blur_acrylic_refraction"])

        if "blur_aurora_intensity" in pending: blur_aurora_intensity = float(pending["blur_aurora_intensity"])
        if "blur_aurora_speed" in pending: blur_aurora_speed = float(pending["blur_aurora_speed"])
        if "blur_drops_speed" in pending: blur_drops_speed = float(pending["blur_drops_speed"])

        if "blur_fluid_jar_distortion" in pending: blur_fluid_jar_distortion = float(pending["blur_fluid_jar_distortion"])
        if "blur_fluid_jar_fill_amount" in pending: blur_fluid_jar_fill_amount = float(pending["blur_fluid_jar_fill_amount"])
        if "blur_fluid_jar_mass" in pending: blur_fluid_jar_mass = float(pending["blur_fluid_jar_mass"])
        if "blur_fluid_jar_precision" in pending: blur_fluid_jar_precision = float(pending["blur_fluid_jar_precision"])
        if "blur_fluid_jar_speed" in pending: blur_fluid_jar_speed = float(pending["blur_fluid_jar_speed"])
        if "blur_fluid_jar_turbulence" in pending: blur_fluid_jar_turbulence = float(pending["blur_fluid_jar_turbulence"])

        if "blur_glass_refraction" in pending: blur_glass_refraction = float(pending["blur_glass_refraction"])
        if "blur_glass_roughness" in pending: blur_glass_roughness = float(pending["blur_glass_roughness"])
        if "blur_glass_size" in pending: blur_glass_size = float(pending["blur_glass_size"])

        if "blur_haze_intensity" in pending: blur_haze_intensity = float(pending["blur_haze_intensity"])
        if "blur_haze_iridescence" in pending: blur_haze_iridescence = float(pending["blur_haze_iridescence"])
        if "blur_heat_shimmer_speed" in pending: blur_heat_shimmer_speed = float(pending["blur_heat_shimmer_speed"])

        if "blur_ripple_duration" in pending: blur_ripple_duration = float(pending["blur_ripple_duration"])
        if "blur_ripple_radius" in pending: blur_ripple_radius = float(pending["blur_ripple_radius"])
        if "blur_ripple_strength" in pending: blur_ripple_strength = float(pending["blur_ripple_strength"])
        if "blur_ripple_width" in pending: blur_ripple_width = float(pending["blur_ripple_width"])

        if "blur_water_damping" in pending: blur_water_damping = float(pending["blur_water_damping"])
        if "blur_water_duration" in pending: blur_water_duration = float(pending["blur_water_duration"])
        if "blur_water_radius" in pending: blur_water_radius = float(pending["blur_water_radius"])
        if "blur_water_speed" in pending: blur_water_speed = float(pending["blur_water_speed"])
        if "blur_water_strength" in pending: blur_water_strength = float(pending["blur_water_strength"])

        if CONFIGS_LUA.is_file():
            lua_set(CONFIGS_LUA, "blur_size", str(blur_size))
            lua_set(CONFIGS_LUA, "blur_pass", str(blur_passes))

        if DECORATION_LUA.is_file():
            text = DECORATION_LUA.read_text()
            blur_block = (
                "blur             = {\n"
                f"            enabled                   = {'true' if blur_enabled else 'false'},\n"
                f"            size                      = {int(blur_size)},\n"
                f"            passes                    = {int(blur_passes)},\n"
                f"            ignore_opacity            = {'true' if blur_ignore_opacity else 'false'},\n"
                f"            new_optimizations         = {'true' if blur_new_optimizations else 'false'},\n"
                f"            xray                      = {'true' if blur_xray else 'false'},\n"
                f"            noise                     = {float(blur_noise)},\n"
                f"            contrast                  = {float(blur_contrast)},\n"
                f"            brightness                = {float(blur_brightness)},\n"
                f"            vibrancy                  = {float(blur_vibrancy)},\n"
                f"            vibrancy_darkness         = {float(blur_vibrancy_darkness)},\n"
                f"            special                   = {'true' if blur_special else 'false'},\n"
                f"            popups                    = {'true' if blur_popups else 'false'},\n"
                f"            popups_ignorealpha        = {float(blur_popups_ignorealpha)},\n"
                f"            input_methods             = {'true' if blur_input_methods else 'false'},\n"
                f"            input_methods_ignorealpha = {float(blur_input_methods_ignorealpha)},\n"
                f"            proportional              = {'true' if blur_proportional else 'false'},\n"
                f"            variant                   = \"{blur_variant}\",\n"
                "\n"
                "            acrylic = {\n"
                f"                aberration = {float(blur_acrylic_aberration)},\n"
                f"                bulb       = {float(blur_acrylic_bulb)},\n"
                f"                clarity    = {float(blur_acrylic_clarity)},\n"
                f"                refraction = {float(blur_acrylic_refraction)},\n"
                "            },\n"
                "\n"
                "            aurora = {\n"
                "                color1    = 0x29F0A0FF,\n"
                "                color2    = 0x7A4DFFFF,\n"
                f"                intensity = {float(blur_aurora_intensity)},\n"
                f"                speed     = {float(blur_aurora_speed)},\n"
                "            },\n"
                "\n"
                "            drops = {\n"
                f"                speed = {float(blur_drops_speed)},\n"
                "            },\n"
                "\n"
                "            fluid_jar = {\n"
                "                color       = 0xCC3399FF,\n"
                f"                distortion  = {float(blur_fluid_jar_distortion)},\n"
                f"                fill_amount = {float(blur_fluid_jar_fill_amount)},\n"
                f"                mass        = {float(blur_fluid_jar_mass)},\n"
                f"                precision   = {float(blur_fluid_jar_precision)},\n"
                f"                speed       = {float(blur_fluid_jar_speed)},\n"
                f"                turbulence  = {float(blur_fluid_jar_turbulence)},\n"
                "            },\n"
                "\n"
                "            glass = {\n"
                f"                refraction = {float(blur_glass_refraction)},\n"
                f"                roughness  = {float(blur_glass_roughness)},\n"
                f"                size       = {float(blur_glass_size)},\n"
                "            },\n"
                "\n"
                "            haze = {\n"
                f"                intensity   = {float(blur_haze_intensity)},\n"
                f"                iridescence = {float(blur_haze_iridescence)},\n"
                "            },\n"
                "\n"
                "            heat_shimmer = {\n"
                f"                speed = {float(blur_heat_shimmer_speed)},\n"
                "            },\n"
                "\n"
                "            ripple = {\n"
                f"                duration = {float(blur_ripple_duration)},\n"
                f"                radius   = {float(blur_ripple_radius)},\n"
                f"                strength = {float(blur_ripple_strength)},\n"
                f"                width    = {float(blur_ripple_width)},\n"
                "            },\n"
                "\n"
                "            water = {\n"
                f"                damping  = {float(blur_water_damping)},\n"
                f"                duration = {float(blur_water_duration)},\n"
                f"                radius   = {float(blur_water_radius)},\n"
                f"                speed    = {float(blur_water_speed)},\n"
                f"                strength = {float(blur_water_strength)},\n"
                "            },\n"
                "        },"
            )
            tbl_blur, s, e = extract_lua_table(text, "blur")
            if tbl_blur:
                if e < len(text) and text[e] == ",":
                    e += 1
                text = text[:s] + blur_block + text[e:]
            else:
                text = re.sub(r'(decoration\s*=\s*\{)', r'\1\n        ' + blur_block, text)

            DECORATION_LUA.write_text(text)
            result.ok(f"blur             → enabled:{blur_enabled} variant:{blur_variant} size:{blur_size} passes:{blur_passes}")

            try:
                subprocess.run(
                    [
                        "hyprctl",
                        "eval",
                        f"hl.config({{ decoration = {{ blur = {{ enabled = {'true' if blur_enabled else 'false'}, size = {int(blur_size)}, passes = {int(blur_passes)}, ignore_opacity = {'true' if blur_ignore_opacity else 'false'}, new_optimizations = {'true' if blur_new_optimizations else 'false'}, xray = {'true' if blur_xray else 'false'}, noise = {float(blur_noise)}, contrast = {float(blur_contrast)}, brightness = {float(blur_brightness)}, vibrancy = {float(blur_vibrancy)}, vibrancy_darkness = {float(blur_vibrancy_darkness)}, special = {'true' if blur_special else 'false'}, popups = {'true' if blur_popups else 'false'}, popups_ignorealpha = {float(blur_popups_ignorealpha)}, input_methods = {'true' if blur_input_methods else 'false'}, input_methods_ignorealpha = {float(blur_input_methods_ignorealpha)}, proportional = {'true' if blur_proportional else 'false'}, variant = \"{blur_variant}\", acrylic = {{ aberration = {float(blur_acrylic_aberration)}, bulb = {float(blur_acrylic_bulb)}, clarity = {float(blur_acrylic_clarity)}, refraction = {float(blur_acrylic_refraction)} }}, aurora = {{ intensity = {float(blur_aurora_intensity)}, speed = {float(blur_aurora_speed)} }}, drops = {{ speed = {float(blur_drops_speed)} }}, fluid_jar = {{ distortion = {float(blur_fluid_jar_distortion)}, fill_amount = {float(blur_fluid_jar_fill_amount)}, mass = {float(blur_fluid_jar_mass)}, precision = {float(blur_fluid_jar_precision)}, speed = {float(blur_fluid_jar_speed)}, turbulence = {float(blur_fluid_jar_turbulence)} }}, glass = {{ refraction = {float(blur_glass_refraction)}, roughness = {float(blur_glass_roughness)}, size = {float(blur_glass_size)} }}, haze = {{ intensity = {float(blur_haze_intensity)}, iridescence = {float(blur_haze_iridescence)} }}, heat_shimmer = {{ speed = {float(blur_heat_shimmer_speed)} }}, ripple = {{ duration = {float(blur_ripple_duration)}, radius = {float(blur_ripple_radius)}, strength = {float(blur_ripple_strength)}, width = {float(blur_ripple_width)} }}, water = {{ damping = {float(blur_water_damping)}, duration = {float(blur_water_duration)}, radius = {float(blur_water_radius)}, speed = {float(blur_water_speed)}, strength = {float(blur_water_strength)} }} }} }} }})",
                    ],
                    capture_output=True,
                    timeout=2,
                )
            except Exception:
                pass
        else:
            result.err("decoration.lua not found — blur skipped")

    if "opacity" in pending:
        act, deact = pending["opacity"]
        act, deact = str(act), str(deact)
        if CONFIGS_LUA.is_file():
            lua_set(CONFIGS_LUA, "opacity_act", act)
            lua_set(CONFIGS_LUA, "opacity_deact", deact)
            result.ok(f"opacity          → active:{act}  inactive:{deact}")
        else:
            result.err("configs.lua not found — opacity skipped")

        if KITTY_CONF.is_file():
            raw_sub(
                KITTY_CONF, r"^(background_opacity\s+)[0-9]+(\.[0-9]+)?", rf"\g<1>{act}"
            )
            try:
                subprocess.run(
                    ["pkill", "-SIGUSR1", "kitty"], capture_output=True, timeout=3
                )
            except Exception:
                pass
            result.ok("Kitty background_opacity updated (live reloaded)")

        if GTK3_CSS.is_file():
            raw_sub(
                GTK3_CSS,
                r"rgba\(([0-9]+),\s*([0-9]+),\s*([0-9]+),\s*[0-9.]+\)",
                rf"rgba(\1, \2, \3, {act})",
            )
            result.ok("GTK3 css alpha updated")

        if GTK4_CSS.is_file():
            raw_sub(
                GTK4_CSS,
                r"alpha\(@[a-zA-Z]+,\s*[0-9.]+\)",
                rf"alpha(@background, {act})",
            )
            result.ok("GTK4 css alpha updated")

    if "shadow" in pending:
        try:
            shadow_val = max(0, int(round(float(pending["shadow"]))))
        except Exception:
            shadow_val = 0
        val = str(shadow_val)
        shadow_enabled = shadow_val > 0
        if CONFIGS_LUA.is_file():
            lua_set(CONFIGS_LUA, "shadow_range", val)
            if DECORATION_LUA.is_file():
                dtext = DECORATION_LUA.read_text()
                dtext = re.sub(
                    r"(shadow\s*=\s*\{\s*enabled\s*=\s*)(true|false)",
                    rf"\g<1>{'true' if shadow_enabled else 'false'}",
                    dtext,
                    flags=re.DOTALL,
                )
                DECORATION_LUA.write_text(dtext)
            try:
                subprocess.run(
                    [
                        "hyprctl",
                        "eval",
                        f"hl.config({{ decoration = {{ shadow = {{ enabled = {'true' if shadow_enabled else 'false'}, range = {shadow_val} }} }} }})",
                    ],
                    capture_output=True,
                    timeout=2,
                )
            except Exception:
                pass
            result.ok(f"shadow-range     → {val} (enabled={shadow_enabled})")
        else:
            result.err("configs.lua not found — shadow skipped")

    # Motion Blur
    mb_keys = ("motion_blur", "motion_blur_enabled", "motion_blur_samples")
    if any(k in pending for k in mb_keys):
        if DECORATION_LUA.is_file():
            text = DECORATION_LUA.read_text()
            cur_app = read_appearance()
            mb_enabled = cur_app["motion_blur_enabled"]
            mb_samples = cur_app["motion_blur_samples"]

            if "motion_blur" in pending:
                val = pending["motion_blur"]
                if isinstance(val, dict):
                    mb_enabled = val.get("enabled", mb_enabled)
                    mb_samples = val.get("samples", mb_samples)
                elif isinstance(val, bool):
                    mb_enabled = val
            if "motion_blur_enabled" in pending:
                mb_enabled = bool(pending["motion_blur_enabled"])
            if "motion_blur_samples" in pending:
                mb_samples = int(pending["motion_blur_samples"])

            mb_block = (
                "motion_blur      = {\n"
                f"            enabled = {'true' if mb_enabled else 'false'},\n"
                f"            samples = {int(mb_samples)},\n"
                "        },"
            )
            mb_pattern = r'motion_blur\s*=\s*\{.*?\},?'
            if re.search(mb_pattern, text, re.DOTALL):
                text = re.sub(mb_pattern, mb_block, text, flags=re.DOTALL)
            else:
                text = re.sub(r'(decoration\s*=\s*\{)', r'\1\n        ' + mb_block, text)

            DECORATION_LUA.write_text(text)
            result.ok(f"motion_blur      → enabled:{mb_enabled} samples:{mb_samples}")

            try:
                subprocess.run(
                    [
                        "hyprctl",
                        "eval",
                        f"hl.config({{ decoration = {{ motion_blur = {{ enabled = {'true' if mb_enabled else 'false'}, samples = {int(mb_samples)} }} }} }})",
                    ],
                    capture_output=True,
                    timeout=2,
                )
            except Exception:
                pass
        else:
            result.err("decoration.lua not found — motion_blur skipped")

    # Wobble Physics
    wob_keys = (
        "wobble",
        "wobble_enabled",
        "wobble_mesh",
        "wobble_stiffness",
        "wobble_damping",
        "wobble_mass",
        "wobble_intensity",
        "wobble_value_epsilon",
        "wobble_velocity_epsilon",
    )
    if any(k in pending for k in wob_keys):
        if DECORATION_LUA.is_file():
            text = DECORATION_LUA.read_text()
            cur_app = read_appearance()
            wob_enabled = cur_app["wobble_enabled"]
            wob_mesh = cur_app["wobble_mesh"]
            wob_stiffness = cur_app["wobble_stiffness"]
            wob_damping = cur_app["wobble_damping"]
            wob_mass = cur_app["wobble_mass"]
            wob_intensity = cur_app["wobble_intensity"]
            wob_val_eps = cur_app["wobble_value_epsilon"]
            wob_vel_eps = cur_app["wobble_velocity_epsilon"]

            if "wobble" in pending:
                val = pending["wobble"]
                if isinstance(val, dict):
                    wob_enabled = val.get("enabled", wob_enabled)
                    wob_mesh = val.get("mesh", wob_mesh)
                    wob_stiffness = val.get("stiffness", wob_stiffness)
                    wob_damping = val.get("damping", wob_damping)
                    wob_mass = val.get("mass", wob_mass)
                    wob_intensity = val.get("intensity", wob_intensity)
                    wob_val_eps = val.get("value_epsilon", wob_val_eps)
                    wob_vel_eps = val.get("velocity_epsilon", wob_vel_eps)
                elif isinstance(val, bool):
                    wob_enabled = val

            if "wobble_enabled" in pending:
                wob_enabled = bool(pending["wobble_enabled"])
            if "wobble_mesh" in pending:
                wob_mesh = int(pending["wobble_mesh"])
            if "wobble_stiffness" in pending:
                wob_stiffness = float(pending["wobble_stiffness"])
            if "wobble_damping" in pending:
                wob_damping = float(pending["wobble_damping"])
            if "wobble_mass" in pending:
                wob_mass = float(pending["wobble_mass"])
            if "wobble_intensity" in pending:
                wob_intensity = float(pending["wobble_intensity"])
            if "wobble_value_epsilon" in pending:
                wob_val_eps = float(pending["wobble_value_epsilon"])
            if "wobble_velocity_epsilon" in pending:
                wob_vel_eps = float(pending["wobble_velocity_epsilon"])

            wob_block = (
                "wobble           = {\n"
                f"            enabled          = {'true' if wob_enabled else 'false'},\n"
                f"            mesh             = {int(wob_mesh)},\n"
                f"            stiffness        = {float(wob_stiffness)},\n"
                f"            damping          = {float(wob_damping)},\n"
                f"            mass             = {float(wob_mass)},\n"
                f"            intensity        = {float(wob_intensity)},\n"
                f"            value_epsilon    = {float(wob_val_eps)},\n"
                f"            velocity_epsilon = {float(wob_vel_eps)},\n"
                "        },"
            )
            wob_pattern = r'wobble\s*=\s*\{.*?\},?'
            if re.search(wob_pattern, text, re.DOTALL):
                text = re.sub(wob_pattern, wob_block, text, flags=re.DOTALL)
            else:
                text = re.sub(r'(decoration\s*=\s*\{)', r'\1\n        ' + wob_block, text)

            DECORATION_LUA.write_text(text)
            result.ok(
                f"wobble           → enabled:{wob_enabled} mesh:{wob_mesh} stiffness:{wob_stiffness} damping:{wob_damping}"
            )

            try:
                subprocess.run(
                    [
                        "hyprctl",
                        "eval",
                        f"hl.config({{ decoration = {{ wobble = {{ enabled = {'true' if wob_enabled else 'false'}, mesh = {int(wob_mesh)}, stiffness = {float(wob_stiffness)}, damping = {float(wob_damping)}, mass = {float(wob_mass)}, intensity = {float(wob_intensity)}, value_epsilon = {float(wob_val_eps)}, velocity_epsilon = {float(wob_vel_eps)} }} }} }})",
                    ],
                    capture_output=True,
                    timeout=2,
                )
            except Exception:
                pass
        else:
            result.err("decoration.lua not found — wobble skipped")


def _apply_monitor(pending, result):
    monitors = pending.get("monitor")
    if not monitors:
        return
    if not MONITOR_LUA.is_file():
        result.err("monitor.lua not found — display changes skipped")
        return
    backup(MONITOR_LUA)
    text = MONITOR_LUA.read_text()
    for output, cfg in monitors.items():
        header = rf'hl\.monitor\(\{{\s*output\s*=\s*"{re.escape(output)}"'
        scale_val = cfg["scale"]
        scale_quoted = not isinstance(scale_val, (int, float))
        fields = [
            ("mode", cfg["mode"], True),
            ("scale", scale_val, scale_quoted),
            ("position", cfg["position"], True),
        ]
        text, found = apply_block_fields(text, header, fields)
        if found:
            result.ok(f"monitor {output:<10} → {cfg['mode']}  scale {cfg['scale']}  @ {cfg['position']}")
        else:
            result.err(f"monitor {output} block not found — skipped")
    MONITOR_LUA.write_text(text)


def _apply_animations(pending, result):
    if not any(k in pending for k in ("anim_global", "anim_leaf", "curve")):
        return
    if not ANIMATION_LUA.is_file():
        result.err("animation.lua not found — animation changes skipped")
        return
    backup(ANIMATION_LUA)
    text = ANIMATION_LUA.read_text()

    if "anim_global" in pending:
        text, found = apply_block_fields(
            text,
            r"hl\.config\(\{\s*animations\s*=\s*\{",
            [("enabled", pending["anim_global"], False)],
        )
        if found:
            result.ok(f"animations enabled → {pending['anim_global']}")

    for leaf, cfg in pending.get("anim_leaf", {}).items():
        header = rf'hl\.animation\(\{{\s*leaf\s*=\s*"{re.escape(leaf)}"'
        fields = []
        if "speed" in cfg:
            fields.append(("speed", cfg["speed"], False))
        if "bezier" in cfg:
            fields.append(("bezier", cfg["bezier"], True))
        if "style" in cfg and cfg["style"] is not None:
            fields.append(("style", cfg["style"], True))
        if "enabled" in cfg and cfg["enabled"] is not None:
            fields.append(("enabled", 1 if cfg["enabled"] else 0, False))
        text, found = apply_block_fields(text, header, fields)
        if found:
            result.ok(f"animation {leaf:<16} → {cfg}")
        else:
            result.err(f"animation leaf {leaf} not found — skipped")

    for name, (p1, p2) in pending.get("curve", {}).items():
        m = re.search(
            rf'hl\.curve\(\s*"{re.escape(name)}"\s*,\s*\{{.*?\}}\)', text, re.DOTALL
        )
        new_block = (
            f'hl.curve("{name}", {{\n'
            f'    type = "bezier",\n'
            f"    points = {{\n"
            f"        {{ {p1[0]}, {p1[1]} }},\n"
            f"        {{ {p2[0]}, {p2[1]} }},\n"
            f"    }},\n"
            f"}})"
        )
        if m:
            text = text[: m.start()] + new_block + text[m.end() :]
            result.ok(f"curve {name:<16} → ({p1[0]}, {p1[1]}) / ({p2[0]}, {p2[1]})")
        else:
            # New custom curve: insert before the Animations section or append
            anim_match = re.search(r'--+\s*Animations', text)
            if anim_match:
                insert_idx = anim_match.start()
                text = text[:insert_idx] + new_block + "\n\n" + text[insert_idx:]
            else:
                text = text.rstrip() + "\n\n" + new_block + "\n"
            result.ok(f"curve {name:<16} (created) → ({p1[0]}, {p1[1]}) / ({p2[0]}, {p2[1]})")

    for name in pending.get("delete_curve", []):
        m = re.search(
            rf'\n*hl\.curve\(\s*"{re.escape(name)}"\s*,\s*\{{.*?\}}\)\n*', text, re.DOTALL
        )
        if m:
            text = text[: m.start()] + "\n" + text[m.end() :]
            result.ok(f"curve {name:<16} (deleted)")

    ANIMATION_LUA.write_text(text)


def _apply_input(pending, result):
    if "input_sensitivity" not in pending and "input_bool" not in pending:
        return
    if not SETTINGS_LUA.is_file():
        result.err("settings.lua not found — input changes skipped")
        return
    backup(SETTINGS_LUA)

    if "input_sensitivity" in pending:
        val = pending["input_sensitivity"]
        lua_set(SETTINGS_LUA, "sensitivity", str(val))
        result.ok(f"mouse sensitivity → {val}")

    for key, val in pending.get("input_bool", {}).items():
        lua_set_bool(SETTINGS_LUA, key, val)
        result.ok(f"{key:<20} → {val}")


def _apply_environment(pending, result):
    edits = pending.get("env_edit", {})
    removes = pending.get("env_remove", set())
    adds = pending.get("env_add", [])
    if not (edits or removes or adds):
        return
    if not ENVIRONMENT_LUA.is_file():
        result.err("environment.lua not found — environment changes skipped")
        return
    backup(ENVIRONMENT_LUA)
    text = ENVIRONMENT_LUA.read_text()

    for key, val in edits.items():
        text, n = re.subn(
            rf'(hl\.env\(\s*"{re.escape(key)}"\s*,\s*")[^"]*(")',
            rf"\g<1>{val}\g<2>",
            text,
            count=1,
        )
        if n:
            result.ok(f"env {key} → {val}")
        else:
            result.err(f"env {key} not found — edit skipped")

    for key in removes:
        text, n = re.subn(
            rf'^.*hl\.env\(\s*"{re.escape(key)}"\s*,.*\n?', "", text, flags=re.MULTILINE
        )
        if n:
            result.ok(f"env {key} removed")
        else:
            result.err(f"env {key} not found — removal skipped")

    if adds:
        lines = text.splitlines(keepends=True)
        insert_at = len(lines)
        for i, line in enumerate(lines):
            if re.match(r'^\s*hl\.env\(', line):
                insert_at = i + 1
        new_lines = [f'hl.env("{k}", "{v}")\n' for k, v in adds]
        lines[insert_at:insert_at] = new_lines
        text = "".join(lines)
        for k, v in adds:
            result.ok(f"env {k} added → {v}")

    ENVIRONMENT_LUA.write_text(text)


def _apply_keybinds(pending, result):
    edits = pending.get("keybind_edit", {})
    removes = pending.get("keybind_remove", [])
    adds = pending.get("keybind_add", [])
    if not (edits or removes or adds):
        return
    if not KEYBINDS_LUA.is_file():
        result.err("keybinds.lua not found — keybind changes skipped")
        return
    backup(KEYBINDS_LUA)
    text = KEYBINDS_LUA.read_text()

    for original, new_raw in edits.items():
        idx = text.find(original)
        if idx == -1:
            result.err("a keybind edit could not be located — skipped")
            continue
        text = text[:idx] + new_raw + text[idx + len(original) :]
        result.ok("keybind updated")

    for original in removes:
        idx = text.find(original)
        if idx == -1:
            result.err("a keybind removal could not be located — skipped")
            continue
        line_start = text.rfind("\n", 0, idx) + 1
        end_pos = idx + len(original)
        line_end = text.find("\n", end_pos)
        line_end = line_end + 1 if line_end != -1 else len(text)
        text = text[:line_start] + text[line_end:]
        result.ok("keybind removed")

    if adds:
        if not text.endswith("\n"):
            text += "\n"
        for raw in adds:
            clean_raw = str(raw).strip()
            if clean_raw:
                text += clean_raw + "\n"
                result.ok(f"keybind added → {clean_raw.splitlines()[0][:60]}")

    KEYBINDS_LUA.write_text(text)


# =============================================================================
#  Widget helpers
# =============================================================================




def get_all_settings():
    monitors_data = parse_monitors()
    monitors_with_options = []
    for m in monitors_data:
        out_name = m.get("output", "")
        res_list, hz_map = get_resolution_options(out_name)
        # Format resolutions as list of strings "1920x1080"
        formatted_res = [f"{w}x{h}" for w, h in res_list]
        formatted_hz = {}
        for (w, h), rates in hz_map.items():
            formatted_hz[f"{w}x{h}"] = [fmt_hz(r) for r in rates]
        
        m_copy = dict(m)
        m_copy["available_resolutions"] = formatted_res
        m_copy["available_refresh"] = formatted_hz
        monitors_with_options.append(m_copy)

    # Keybinds list
    try:
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        from keybinds_catalog import CATALOG
    except Exception:
        CATALOG = []

    catalog_map = {item["combo"].lower().replace(" ", ""): item for item in CATALOG}
    
    var_map = {
        "terminal": "kitty",
        "file_man": "dolphin || thunar",
        "term_file_man": "yazi",
        "volumeCTRL": "volumecontrol.sh",
        "brightnessCTRL": "brightness.sh",
        "qsLauncher": "qs-launcher.sh",
        "qsLauncherTheme": "qs-launcher-theme.sh",
        "qsIsland": "qs-island.sh",
        "qsWallpaper": "qs-wallpaper.sh",
        "qsPower": "qs-power.sh",
        "qsScreenshot": "qs-screenshot.sh",
        "qsClipboard": "qs-clipboard.sh",
        "qsEmoji": "qs-emoji.sh",
        "qsKeybinds": "qs-keybinds.sh",
        "qsReload": "qs-reload.sh",
        "qsBar": "qs-bar.sh",
        "inputMethodCTRL": "input-method.sh",
    }

    keybinds_list = []
    for kb in iter_keybind_statements():
        raw_combo = kb.get("combo", "").strip().strip('"\'')
        display_combo = (raw_combo
            .replace('.. "', '+ ')
            .replace('.. \'', '+ ')
            .replace('"', '')
            .replace("'", '')
            .replace("mainMod", "SUPER")
            .replace("ctrl", "CTRL")
            .replace("alt", "ALT")
            .replace("shift", "SHIFT")
            .strip())
        display_combo = re.sub(r"\+\s*\+", "+", display_combo).strip()
        if display_combo.startswith(","):
            display_combo = display_combo.lstrip(", ")
        display_combo = display_combo.strip()

        parts = [p.strip() for p in display_combo.split("+")]
        mods = [p for p in parts if p in ("SUPER", "CTRL", "ALT", "SHIFT")]
        keys = [p for p in parts if p not in ("SUPER", "CTRL", "ALT", "SHIFT")]
        key = "+".join(keys) if keys else ""

        raw_action = kb.get("action", "").strip()
        display_action = raw_action
        if display_action.startswith("hl.dsp."):
            display_action = display_action[7:]

        action_type = "custom"
        command = ""
        m_exec = re.search(r"exec_cmd\((.+)\)", raw_action)
        if m_exec:
            action_type = "exec"
            inner = m_exec.group(1).strip()
            cmd_resolved = inner
            for var_k, var_v in var_map.items():
                cmd_resolved = re.sub(r"\b" + var_k + r"\b", var_v, cmd_resolved)
            cmd_resolved = cmd_resolved.replace("..", "").replace('"', '').replace("'", '').strip()
            cmd_resolved = re.sub(r"\s+", " ", cmd_resolved)
            command = cmd_resolved
        elif "window.close" in raw_action:
            action_type = "window_close"
        elif "window.float" in raw_action:
            action_type = "window_float"
        elif "window.fullscreen" in raw_action:
            action_type = "window_fullscreen"
        elif "window.pseudo" in raw_action:
            action_type = "window_pseudo"
        elif "window.move" in raw_action:
            action_type = "window_move"
        elif "window.resize" in raw_action:
            action_type = "window_resize"
        elif "focus" in raw_action:
            action_type = "focus"
        elif "workspace" in raw_action:
            action_type = "workspace"
        elif "group" in raw_action:
            action_type = "group"
        elif "layout" in raw_action:
            action_type = "layout"

        norm = display_combo.lower().replace(" ", "")
        cat_item = catalog_map.get(norm, {})

        if cat_item:
            category = cat_item.get("category", "General")
            title = cat_item.get("action", display_combo)
            desc = cat_item.get("desc", "")
            icon = cat_item.get("icon", "keyboard")
        else:
            icon = "command" if action_type == "exec" else "window"
            if "workspace" in raw_action:
                category = "Workspaces"
                title = "Workspace Navigation"
                desc = display_action
            elif any(k in raw_action for k in ("window.", "focus", "layout", "group.")):
                category = "Window Management"
                title = "Window Manipulation"
                desc = display_action
            elif any(k in raw_action for k in ("volume", "brightness", "playerctl", "Audio", "Brightness")):
                category = "Media & Hardware"
                title = "Audio / Brightness Control"
                desc = display_action
            elif action_type == "exec":
                category = "Apps & Launchers"
                title = f"Run: {command[:35]}" if command else "Custom Command"
                desc = command
            else:
                category = "General"
                title = display_combo
                desc = display_action

        if category in ("Apps", "Applications", "Quickshell"):
            category = "Apps & Launchers"
        elif category in ("Windows", "Window Management"):
            category = "Window Management"
        elif category in ("Media", "Audio"):
            category = "Media & Hardware"

        keybinds_list.append({
            "combo": display_combo or "(bind)",
            "key": key,
            "mods": mods,
            "action": display_action,
            "raw_action": raw_action,
            "raw": kb.get("raw", ""),
            "action_type": action_type,
            "command": command,
            "category": category,
            "title": title,
            "desc": desc,
            "icon": icon,
        })

    # Files status
    files_status = [
        {"name": "Appearance (configs.lua)", "path": str(CONFIGS_LUA), "exists": CONFIGS_LUA.is_file()},
        {"name": "Decoration (decoration.lua)", "path": str(DECORATION_LUA), "exists": DECORATION_LUA.is_file()},
        {"name": "Display (monitor.lua)", "path": str(MONITOR_LUA), "exists": MONITOR_LUA.is_file()},
        {"name": "Animations (animation.lua)", "path": str(ANIMATION_LUA), "exists": ANIMATION_LUA.is_file()},
        {"name": "Input (lua)", "path": str(SETTINGS_LUA), "exists": SETTINGS_LUA.is_file()},
    ]

    # Avatar paths
    user = getpass.getuser()
    sddm_face = SDDM_FACES_DIR / f"{user}.face.icon"
    local_face = Path.home() / ".face"
    cache_face = Path.home() / ".hyprconf" / "hypr" / ".cache" / ".face"

    current_sddm_theme = get_current_sddm_theme()
    silent_sddm_available = Path("/usr/share/sddm/themes/SilentSDDM").is_dir()
    is_silent_sddm = (current_sddm_theme.strip().lower() == "silentsddm")

    data = {
        "appearance": read_appearance(),
        "input": read_input(),
        "monitors": monitors_with_options,
        "animations": parse_animations(),
        "curves": parse_curves(),
        "anim_global": parse_anim_global_enabled(),
        "env_vars": parse_env_vars(),
        "keybinds": keybinds_list,
        "files": files_status,
        "sddm": {
            "current_theme": current_sddm_theme,
            "is_silent_sddm": is_silent_sddm,
            "silent_sddm_available": silent_sddm_available,
        },
        "avatar": {
            "username": user,
            "sddm_face_path": str(sddm_face),
            "sddm_face_exists": sddm_face.is_file(),
            "sddm_face_backup_exists": (SDDM_FACES_DIR / f"{user}.face.icon.bkp").is_file(),
            "local_face_path": str(local_face),
            "local_face_exists": local_face.is_file(),
            "cache_face_path": str(cache_face),
            "cache_face_exists": cache_face.is_file(),
        }
    }
    return data


def get_current_sddm_theme():
    candidate_paths = [
        Path("/etc/sddm.conf.d/theme.conf.user"),
        Path("/etc/sddm.conf.d/theme.conf"),
        Path("/etc/sddm.conf"),
    ]
    theme_name = ""
    for p in candidate_paths:
        if p.is_file():
            try:
                content = p.read_text(errors="replace")
                in_theme_sec = False
                for line in content.splitlines():
                    stripped = line.strip()
                    if stripped.startswith("[") and stripped.endswith("]"):
                        in_theme_sec = (stripped.lower() == "[theme]")
                    elif in_theme_sec and stripped.startswith("Current="):
                        val = stripped.split("=", 1)[1].strip()
                        if val:
                            theme_name = val
                            break
            except Exception:
                pass
            if theme_name:
                break
    return theme_name or "default"


def launch_terminal(cmd_args, title="Hyprconf", wait=True):
    """
    Launch an interactive command inside kitty (or fallback terminal) with LD_PRELOAD
    stripped from the environment to prevent dynamic linker errors with libhypr_gtkblur.
    If wait is True, blocks until the terminal window is closed so Quickshell's Process
    handler receives the exit notification and refreshes UI state.
    """
    clean_env = os.environ.copy()
    clean_env.pop("LD_PRELOAD", None)
    
    kitty_bin = shutil.which("kitty")
    if kitty_bin:
        full_cmd = [kitty_bin]
        if title:
            full_cmd.extend(["--title", title])
        full_cmd.extend(cmd_args)
    else:
        for term in ["alacritty", "foot", "xterm", "gnome-terminal"]:
            term_bin = shutil.which(term)
            if term_bin:
                full_cmd = [term_bin, "-e"] + cmd_args
                break
        else:
            full_cmd = cmd_args

    proc = subprocess.Popen(
        full_cmd,
        env=clean_env,
        start_new_session=True,
    )
    if wait:
        proc.wait()
    return proc


def set_sddm_theme(theme_name="SilentSDDM"):
    target_dir = Path("/usr/share/sddm/themes") / theme_name
    if not target_dir.is_dir():
        return {"status": "error", "message": f"Theme '{theme_name}' not found in /usr/share/sddm/themes/"}
    
    cache_dir = CACHE_HOME / "hypr-settings"
    cache_dir.mkdir(parents=True, exist_ok=True)
    helper_path = cache_dir / "priv-set-sddm-theme.sh"
    
    script_content = (
        "#!/usr/bin/env bash\n"
        "set -e\n"
        f"echo '==> Switching SDDM Theme to {theme_name} (requires sudo)...'\n"
        "sudo mkdir -p /etc/sddm.conf.d\n"
        f"sudo tee /etc/sddm.conf.d/theme.conf >/dev/null << 'EOF'\n"
        "[Theme]\n"
        f"Current={theme_name}\n"
        "\n"
        "[General]\n"
        "InputMethod=\n"
        "EOF\n"
        f"sudo tee /etc/sddm.conf.d/theme.conf.user >/dev/null << 'EOF'\n"
        "[Theme]\n"
        f"Current={theme_name}\n"
        "\n"
        "[General]\n"
        "InputMethod=\n"
        "EOF\n"
        "echo\n"
        f"echo '==> SDDM Theme successfully switched to {theme_name}!'\n"
        "echo 'Press Enter to close.'\n"
        "read -r\n"
    )
    helper_path.write_text(script_content)
    helper_path.chmod(0o755)
    
    launch_terminal(["bash", str(helper_path)], title="Set SDDM Theme", wait=True)
    return {"status": "ok", "message": f"Terminal launched to set SDDM theme to {theme_name}."}


def install_sddm_avatar():
    import shlex
    user = getpass.getuser()
    cache_face = Path.home() / ".hyprconf" / "hypr" / ".cache" / ".face"
    if not cache_face.is_file():
        return {"status": "error", "message": "No local avatar found. Choose an avatar first."}
    
    script_text = build_avatar_apply_script(user, str(cache_face))
    cache_dir = CACHE_HOME / "hypr-settings"
    cache_dir.mkdir(parents=True, exist_ok=True)
    script_path = cache_dir / "priv-helper.sh"
    wrapper_path = cache_dir / "priv-helper-sddm.sh"
    
    script_path.write_text(script_text)
    script_path.chmod(0o755)
    
    wrapper_path.write_text(
        "#!/usr/bin/env bash\n"
        "set -e\n"
        f"echo '==> Installing SDDM Login Avatar for {user} (requires sudo)...'\n"
        f"sudo bash {shlex.quote(str(script_path))}\n"
        "echo\n"
        "echo '==> SDDM Avatar successfully installed!'\n"
        "echo 'Press Enter to close.'\n"
        "read -r\n"
    )
    wrapper_path.chmod(0o755)
    
    launch_terminal(["bash", str(wrapper_path)], title="Set SDDM Avatar", wait=True)
    return {"status": "ok", "message": "Terminal launched to install SDDM avatar."}


def restore_sddm_avatar():
    import shlex
    user = getpass.getuser()
    backup_icon = SDDM_FACES_DIR / f"{user}.face.icon.bkp"
    face_icon = SDDM_FACES_DIR / f"{user}.face.icon"
    if not backup_icon.is_file():
        return {"status": "error", "message": "No SDDM avatar backup found."}
    
    cache_dir = CACHE_HOME / "hypr-settings"
    cache_dir.mkdir(parents=True, exist_ok=True)
    wrapper_path = cache_dir / "priv-restore-sddm.sh"
    q = shlex.quote
    wrapper_path.write_text(
        "#!/usr/bin/env bash\n"
        "set -e\n"
        f"echo '==> Restoring previous SDDM Login Avatar backup for {user}...'\n"
        f"sudo cp -f {q(str(backup_icon))} {q(str(face_icon))}\n"
        "echo\n"
        "echo '==> SDDM Avatar backup restored successfully!'\n"
        "echo 'Press Enter to close.'\n"
        "read -r\n"
    )
    wrapper_path.chmod(0o755)
    
    launch_terminal(["bash", str(wrapper_path)], title="Restore SDDM Avatar", wait=True)
    return {"status": "ok", "message": "Terminal launched to restore SDDM avatar."}


def apply_settings(pending_dict):
    result = ApplyResult()
    apply_all(pending_dict, result)
    errors = sum(1 for status, _ in result.lines if status == "err")
    return {
        "status": "ok" if errors == 0 else "error",
        "errors": errors,
        "messages": [f"[{status.upper()}] {msg}" for status, msg in result.lines],
    }


def main():
    if len(sys.argv) < 2 or sys.argv[1] == "get":
        data = get_all_settings()
        print(json.dumps(data, indent=2))
        sys.exit(0)

    cmd = sys.argv[1]
    if cmd == "apply":
        # Read JSON pending from stdin or argument
        if len(sys.argv) > 2:
            raw_json = sys.argv[2]
        else:
            raw_json = sys.stdin.read()
        
        try:
            pending = json.loads(raw_json)
        except Exception as e:
            print(json.dumps({"status": "error", "errors": 1, "messages": [f"Invalid JSON: {e}"]}))
            sys.exit(1)
            
        res = apply_settings(pending)
        print(json.dumps(res, indent=2))
        sys.exit(0 if res["status"] == "ok" else 1)

    elif cmd == "install-sddm-avatar":
        res = install_sddm_avatar()
        print(json.dumps(res))
        sys.exit(0)

    elif cmd == "restore-sddm-avatar":
        res = restore_sddm_avatar()
        print(json.dumps(res))
        sys.exit(0)

    elif cmd == "set-sddm-theme":
        theme = sys.argv[2] if len(sys.argv) > 2 else "SilentSDDM"
        res = set_sddm_theme(theme)
        print(json.dumps(res))
        sys.exit(0)


    else:
        print(json.dumps({"error": f"Unknown command: {cmd}"}))
        sys.exit(1)


if __name__ == "__main__":
    main()

