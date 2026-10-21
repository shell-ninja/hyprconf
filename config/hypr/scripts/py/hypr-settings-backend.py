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

_USER_STATE_DIR = Path.home() / ".local" / "share" / "hyprconf"
_USER_MONITOR = _USER_STATE_DIR / "monitor.lua"
_USER_KEYBINDS = _USER_STATE_DIR / "keybinds.lua"

CONFIGS_LUA = CONFIGS_DIR / "configs.lua"
DECORATION_LUA = CONFIGS_DIR / "decoration.lua"
MONITOR_LUA = _USER_MONITOR if _USER_MONITOR.exists() else (CONFIGS_DIR / "monitor.lua")
ANIMATION_LUA = CONFIGS_DIR / "animation.lua"
SETTINGS_LUA = CONFIGS_DIR / "settings.lua"
ENVIRONMENT_LUA = CONFIGS_DIR / "environment.lua"
KEYBINDS_LUA = _USER_KEYBINDS if _USER_KEYBINDS.exists() else (CONFIGS_DIR / "keybinds.lua")

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


def read_appearance():
    layout = "scrolling"
    col_width = 1.0
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

    return {
        "border": float(lua_get(CONFIGS_LUA, "border") or 2),
        "rounding": float(lua_get(CONFIGS_LUA, "rounding") or 8),
        "inner_gap": float(lua_get(CONFIGS_LUA, "inner_gap") or 4),
        "outer_gap": float(lua_get(CONFIGS_LUA, "outer_gap") or 8),
        "blur_size": float(lua_get(CONFIGS_LUA, "blur_size") or 4),
        "blur_pass": float(lua_get(CONFIGS_LUA, "blur_pass") or 3),
        "opacity_act": float(lua_get(CONFIGS_LUA, "opacity_act") or 0.95),
        "opacity_deact": float(lua_get(CONFIGS_LUA, "opacity_deact") or 0.75),
        "shadow_range": float(lua_get(CONFIGS_LUA, "shadow_range") or 12),
        "layout": layout,
        "column_width": col_width,
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
    need_decoration = any(k in pending for k in ("layout", "column_width"))
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

    if "blur" in pending:
        bsize, bpass = pending["blur"]
        bsize, bpass = str(bsize), str(bpass)
        if CONFIGS_LUA.is_file():
            lua_set(CONFIGS_LUA, "blur_size", bsize)
            lua_set(CONFIGS_LUA, "blur_pass", bpass)
            result.ok(f"blur             → size:{bsize}  passes:{bpass}")
        else:
            result.err("configs.lua not found — blur skipped")

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
        val = str(pending["shadow"])
        if CONFIGS_LUA.is_file():
            lua_set(CONFIGS_LUA, "shadow_range", val)
            result.ok(f"shadow-range     → {val}")
        else:
            result.err("configs.lua not found — shadow skipped")


def _apply_monitor(pending, result):
    global MONITOR_LUA
    monitors = pending.get("monitor")
    if not monitors:
        return
    if not MONITOR_LUA.is_file():
        if _USER_STATE_DIR.is_dir() and (CONFIGS_DIR / "monitor.lua").is_file():
            shutil.copy(CONFIGS_DIR / "monitor.lua", _USER_MONITOR)
            MONITOR_LUA = _USER_MONITOR
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
    global KEYBINDS_LUA
    edits = pending.get("keybind_edit", {})
    removes = pending.get("keybind_remove", set())
    adds = pending.get("keybind_add", [])
    if not (edits or removes or adds):
        return
    if not KEYBINDS_LUA.is_file():
        if _USER_STATE_DIR.is_dir() and (CONFIGS_DIR / "keybinds.lua").is_file():
            shutil.copy(CONFIGS_DIR / "keybinds.lua", _USER_KEYBINDS)
            KEYBINDS_LUA = _USER_KEYBINDS
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
        line_end = text.find("\n", idx)
        line_end = line_end + 1 if line_end != -1 else len(text)
        text = text[:line_start] + text[line_end:]
        result.ok("keybind removed")

    if adds:
        if not text.endswith("\n"):
            text += "\n"
        text += "\n".join(adds) + "\n"
        for raw in adds:
            result.ok(f"keybind added → {raw.splitlines()[0][:60]}")

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
    keybinds_list = []
    for kb in iter_keybind_statements():
        raw_combo = kb.get("combo", "").strip().strip('"\'')
        display_combo = raw_combo.replace('.. "', '+ ').replace('.. \'', '+ ').replace('"', '').replace("'", '').replace("mainMod", "SUPER").strip()
        import re
        display_combo = re.sub(r"\+\s*\+", "+", display_combo).strip()
        if display_combo.startswith(","):
            display_combo = display_combo.lstrip(", ")
        display_combo = display_combo.strip()
        
        raw_action = kb.get("action", "").strip()
        display_action = raw_action
        if display_action.startswith("hl.dsp."):
            display_action = display_action[7:]
        
        keybinds_list.append({
            "combo": display_combo or "(bind)",
            "action": display_action,
            "raw": kb.get("raw", ""),
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

