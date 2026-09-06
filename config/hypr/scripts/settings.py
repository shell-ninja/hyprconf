#!/usr/bin/env python3
# =============================================================================
#  hypr-settings-gui.py — GTK4 / libadwaita GUI for the Hyprland Lua config
#  living in ~/.config/hypr/configs (symlink target of ~/.hyprconf/hypr/configs).
#
#  Sidebar-navigated settings app covering:
#    - Appearance   (configs.lua: border, rounding, gaps, blur, opacity, shadow)
#    - Display      (monitor.lua: resolution, refresh rate, scale, position)
#    - Animations   (animation.lua: global toggle, per-animation speed/curve,
#                     bezier control points via sliders)
#    - Input        (settings.lua: pointer sensitivity, touchpad toggles)
#    - Environment  (environment.lua: add/edit/remove hl.env() variables)
#    - Keybinds     (keybinds.lua: add/edit/remove hl.bind() statements)
#    - Login Avatar (SDDM face icon: pick an image, crop/resize it with
#                     ImageMagick, and install it via an in-app sudo prompt)
#
#  Kitty and GTK3/4 CSS are still updated in the background whenever opacity
#  changes (same as before) but are no longer shown in the UI.
#
#  Depends: python3-gobject, libadwaita-1 (>= 1.4 for Adw.NavigationSplitView,
#           Adw.SwitchRow, Adw.EntryRow, Adw.ExpanderRow)
#           sudo pacman -S python-gobject libadwaita
#           imagemagick (mogrify) — required by the Login Avatar page
#           sudo — the Login Avatar page asks for your password in its own
#           dialog and pipes it to `sudo -S` (no polkit agent required);
#           falls back to a kitty + sudo terminal prompt if sudo is missing
#
#  Usage:   python3 hypr-settings-gui.py
# =============================================================================

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("Gdk", "4.0")

import getpass
import json
import os
import re
import shlex
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

from gi.repository import Adw, Gdk, Gio, GLib, Gtk

# ─── Config file paths ────────────────────────────────────────────────────
CONFIGS_DIR = Path.home() / ".config" / "hypr" / "configs"

CONFIGS_LUA = CONFIGS_DIR / "configs.lua"
DECORATION_LUA = CONFIGS_DIR / "decoration.lua"
MONITOR_LUA = CONFIGS_DIR / "monitor.lua"
ANIMATION_LUA = CONFIGS_DIR / "animation.lua"
SETTINGS_LUA = CONFIGS_DIR / "settings.lua"
ENVIRONMENT_LUA = CONFIGS_DIR / "environment.lua"
KEYBINDS_LUA = CONFIGS_DIR / "keybinds.lua"

# Updated in the background, never shown in the UI.
KITTY_CONF = Path.home() / ".config" / "kitty" / "kitty.conf"
GTK3_CSS = Path.home() / ".config" / "gtk-3.0" / "gtk.css"
GTK4_CSS = Path.home() / ".config" / "gtk-4.0" / "gtk.css"

BACKUP_DIR = (
    Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
    / "hypr-settings"
    / "backups"
)

# ─── SDDM avatar (Login Avatar section) ───────────────────────────────────
SDDM_FACES_DIR = Path("/usr/share/sddm/faces")

# ─── Dotfiles repo (Dotfiles Update section) ──────────────────────────────
DOTFILES_REPO_OWNER = "shell-ninja"
DOTFILES_REPO_NAME = "hyprconf"
DOTFILES_BRANCH = "main"  # change later once the branch is finalized

CACHE_HOME = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
DOTFILES_CACHE_DIR = CACHE_HOME / "hypr-settings" / "dotfiles"
DOTFILES_CLONE_DIR = DOTFILES_CACHE_DIR / DOTFILES_REPO_NAME
DOTFILES_TARBALL = DOTFILES_CACHE_DIR / f"{DOTFILES_REPO_NAME}.tar.gz"

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
#  Dotfiles Update — fetch the repo tarball with curl into ~/.cache, extract
#  it, then hand off to the repo's own setup.sh inside a kitty window.
# =============================================================================


def build_dotfiles_update_script() -> str:
    """
    Returns a bash script (as a string) that:
      1. Downloads the current DOTFILES_BRANCH tarball via curl into
         DOTFILES_CACHE_DIR (no git required).
      2. Extracts it, replacing any previous checkout.
      3. Runs the repo's own setup.sh.
    Meant to be launched inside a kitty window so the user sees setup.sh's
    own prompts/output live, exactly like running it by hand.
    """
    owner = DOTFILES_REPO_OWNER
    repo = DOTFILES_REPO_NAME
    branch = DOTFILES_BRANCH
    cache_dir = str(DOTFILES_CACHE_DIR)
    clone_dir = str(DOTFILES_CLONE_DIR)
    tarball = str(DOTFILES_TARBALL)
    tarball_url = f"https://github.com/{owner}/{repo}/archive/refs/heads/{branch}.tar.gz"

    return f"""set -e
mkdir -p {cache_dir!r}
echo "==> Fetching {owner}/{repo}@{branch}"
curl -fL --progress-bar -o {tarball!r} {tarball_url!r}

echo "==> Extracting"
rm -rf {clone_dir!r}
mkdir -p {clone_dir!r}
tar -xzf {tarball!r} -C {clone_dir!r} --strip-components=1
rm -f {tarball!r}

cd {clone_dir!r}
chmod +x setup.sh
echo "==> Running setup.sh"
echo
./setup.sh

echo
echo "Done. Press Enter to close."
read
"""


def launch_dotfiles_update():
    """Writes the update script to a temp file in the cache dir and opens
    it inside a new kitty window, so setup.sh's own interactive prompts and
    output are visible to the user exactly as if they'd run it by hand."""
    DOTFILES_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    script_path = DOTFILES_CACHE_DIR / "run-update.sh"
    script_path.write_text(build_dotfiles_update_script())
    script_path.chmod(0o755)

    subprocess.Popen(
        [KITTY_BIN, "--title", "Dotfiles Update", "bash", str(script_path)],
        start_new_session=True,
    )


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
        anims.append(
            {
                "leaf": m.group(1),
                "speed": float(speed) if speed else 1.0,
                "bezier": bezier or "",
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
        fields = [("speed", cfg["speed"], False), ("bezier", cfg["bezier"], True)]
        text, found = apply_block_fields(text, header, fields)
        if found:
            result.ok(f"animation {leaf:<16} → speed {cfg['speed']}  curve {cfg['bezier']}")
        else:
            result.err(f"animation leaf {leaf} not found — skipped")

    for name, (p1, p2) in pending.get("curve", {}).items():
        m = re.search(
            rf'hl\.curve\(\s*"{re.escape(name)}"\s*,\s*\{{.*?\}}\)', text, re.DOTALL
        )
        if not m:
            result.err(f"curve {name} not found — skipped")
            continue
        new_block = (
            f'hl.curve("{name}", {{\n'
            f'    type = "bezier",\n'
            f"    points = {{\n"
            f"        {{ {p1[0]}, {p1[1]} }},\n"
            f"        {{ {p2[0]}, {p2[1]} }},\n"
            f"    }},\n"
            f"}})"
        )
        text = text[: m.start()] + new_block + text[m.end() :]
        result.ok(f"curve {name:<16} → ({p1[0]}, {p1[1]}) / ({p2[0]}, {p2[1]})")

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
    removes = pending.get("keybind_remove", set())
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


def make_spin_row(title, subtitle, lower, upper, step, digits, value):
    row = Adw.ActionRow(title=title, subtitle=subtitle)
    adj = Gtk.Adjustment(
        value=value, lower=lower, upper=upper, step_increment=step,
        page_increment=step * 5,
    )
    spin = Gtk.SpinButton(adjustment=adj, digits=digits, valign=Gtk.Align.CENTER)
    spin.set_numeric(True)
    row.add_suffix(spin)
    row.set_activatable_widget(spin)
    return row, spin


def make_scale_row(title, lower, upper, step, digits, value):
    row = Adw.ActionRow(title=title)
    scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, lower, upper, step)
    scale.set_value(value)
    scale.set_digits(digits)
    scale.set_draw_value(True)
    scale.set_hexpand(True)
    scale.set_size_request(220, -1)
    scale.set_valign(Gtk.Align.CENTER)
    row.add_suffix(scale)
    return row, scale


def make_group(title=None, description=None):
    g = Adw.PreferencesGroup()
    if title:
        g.set_title(title)
    if description:
        g.set_description(description)
    return g


def file_status_icon(path: Path):
    if path.is_file():
        icon = Gtk.Image.new_from_icon_name("emblem-ok-symbolic")
        icon.set_tooltip_text(f"Found: {path}")
        icon.add_css_class("success")
    else:
        icon = Gtk.Image.new_from_icon_name("dialog-warning-symbolic")
        icon.set_tooltip_text(f"Not found, will be skipped: {path}")
        icon.add_css_class("warning")
    return icon


def wrap_page(*groups):
    scrolled = Gtk.ScrolledWindow(vexpand=True, hexpand=True)
    page = Adw.PreferencesPage()
    for g in groups:
        page.add(g)
    scrolled.set_child(page)
    return scrolled


# =============================================================================
#  A little visual polish — kept intentionally small so it layers on top of
#  the system theme instead of fighting it. Two keyframe animations (image
#  fade-in when picking a new avatar, a success "glow" pulse once it's
#  applied) plus a smooth crossfade between sidebar pages.
# =============================================================================

CUSTOM_CSS = """
@keyframes avatar-pop-in {
    from { opacity: 0; }
    to   { opacity: 1; }
}
.avatar-pop-in {
    animation: avatar-pop-in 350ms ease-out;
}

@keyframes avatar-success-glow {
    0%   { box-shadow: 0 0 0 0 alpha(@success_color, 0.55); }
    70%  { box-shadow: 0 0 0 12px alpha(@success_color, 0); }
    100% { box-shadow: 0 0 0 0 alpha(@success_color, 0); }
}
.avatar-success-pulse {
    animation: avatar-success-glow 900ms ease-out;
    border-radius: 9999px;
}
"""


def load_custom_css():
    provider = Gtk.CssProvider()
    provider.load_from_data(CUSTOM_CSS.encode("utf-8"))
    display = Gdk.Display.get_default()
    if display:
        Gtk.StyleContext.add_provider_for_display(
            display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )


# =============================================================================
#  Application window
# =============================================================================


class HyprSettingsWindow(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(
            application=app,
            title="Hyprland Settings",
            default_width=920,
            default_height=680,
        )

        self.pending: dict[str, object] = {}
        self.monitor_widgets: dict[str, dict] = {}
        self.anim_leaf_widgets: dict[str, dict] = {}
        self.curve_widgets: dict[str, dict] = {}
        self.env_rows: dict[str, Adw.EntryRow] = {}
        self.keybind_rows: dict[str, dict] = {}
        self.avatar_username = getpass.getuser()
        self.avatar_selected_path: str | None = None

        split = Adw.NavigationSplitView()
        self.set_content(split)

        # ── Sidebar ──────────────────────────────────────────────────────
        sidebar_page = Adw.NavigationPage(title="Hyprland Settings")
        split.set_sidebar(sidebar_page)
        sidebar_tv = Adw.ToolbarView()
        sidebar_page.set_child(sidebar_tv)
        sidebar_tv.add_top_bar(Adw.HeaderBar(show_end_title_buttons=False))

        self.nav_list = Gtk.ListBox()
        self.nav_list.add_css_class("navigation-sidebar")
        sidebar_tv.set_content(self.nav_list)

        self.sections = [
            ("files", "Overview", "document-properties-symbolic"),
            ("appearance", "Appearance", "applications-graphics-symbolic"),
            ("monitor", "Display", "video-display-symbolic"),
            ("animations", "Animations", "view-refresh-symbolic"),
            ("input", "Input", "input-mouse-symbolic"),
            ("environment", "Environment", "utilities-terminal-symbolic"),
            ("keybinds", "Keybinds", "input-keyboard-symbolic"),
            ("sddm-avatar", "Login Avatar", "avatar-default-symbolic"),
            ("dotfiles-update", "Dotfiles Update", "software-update-available-symbolic"),
        ]
        for key, label, icon in self.sections:
            row = Adw.ActionRow(title=label)
            row.add_prefix(Gtk.Image.new_from_icon_name(icon))
            row.set_name(key)
            self.nav_list.append(row)
        self.nav_list.connect("row-selected", self.on_nav_selected)

        # ── Content ──────────────────────────────────────────────────────
        content_page = Adw.NavigationPage(title="Settings")
        split.set_content(content_page)
        content_tv = Adw.ToolbarView()
        content_page.set_child(content_tv)

        header = Adw.HeaderBar()
        content_tv.add_top_bar(header)

        self.discard_btn = Gtk.Button(label="Discard")
        self.discard_btn.connect("clicked", self.on_discard)
        self.discard_btn.set_sensitive(False)
        header.pack_start(self.discard_btn)

        self.apply_btn = Gtk.Button(label="Apply")
        self.apply_btn.add_css_class("suggested-action")
        self.apply_btn.connect("clicked", self.on_apply)
        self.apply_btn.set_sensitive(False)
        header.pack_end(self.apply_btn)

        self.toast_overlay = Adw.ToastOverlay()
        content_tv.set_content(self.toast_overlay)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(260)
        self.toast_overlay.set_child(self.stack)

        self.stack.add_named(self._build_files_page(), "files")
        self.stack.add_named(self._build_appearance_page(), "appearance")
        self.stack.add_named(self._build_monitor_page(), "monitor")
        self.stack.add_named(self._build_animations_page(), "animations")
        self.stack.add_named(self._build_input_page(), "input")
        self.stack.add_named(self._build_environment_page(), "environment")
        self.stack.add_named(self._build_keybinds_page(), "keybinds")
        self.stack.add_named(self._build_sddm_avatar_page(), "sddm-avatar")
        self.stack.add_named(self._build_dotfiles_update_page(), "dotfiles-update")

        self.nav_list.select_row(self.nav_list.get_row_at_index(0))

        self.connect("close-request", self.on_close_request)

    def on_nav_selected(self, _listbox, row):
        if row is not None:
            self.stack.set_visible_child_name(row.get_name())

    # ── Overview page ────────────────────────────────────────────────────

    def _build_files_page(self):
        g = make_group(
            "Config files",
            "Hyprland Lua files this app edits. Missing files are skipped. "
            "Kitty and GTK theme files are also kept in sync in the "
            "background whenever opacity changes.",
        )
        for label, path in [
            ("Appearance (configs.lua)", CONFIGS_LUA),
            ("Decoration (decoration.lua)", DECORATION_LUA),
            ("Display (monitor.lua)", MONITOR_LUA),
            ("Animations (animation.lua)", ANIMATION_LUA),
            ("Input (settings.lua)", SETTINGS_LUA),
            ("Environment (environment.lua)", ENVIRONMENT_LUA),
            ("Keybinds (keybinds.lua)", KEYBINDS_LUA),
        ]:
            row = Adw.ActionRow(title=label, subtitle=str(path))
            row.add_suffix(file_status_icon(path))
            g.add(row)
        return wrap_page(g)

    # ── Appearance page ──────────────────────────────────────────────────

    def _build_appearance_page(self):
        cur = read_appearance()

        g0 = make_group("Layout", "Tiling layout and scrolling configuration.")
        layout_keys = ["scrolling", "dwindle", "master", "monocle"]
        layout_labels = ["Scrolling", "Dwindle", "Master", "Monocle"]

        row_layout = Adw.ActionRow(title="Window layout", subtitle="Active tiling layout")
        self.dropdown_layout = Gtk.DropDown.new_from_strings(layout_labels)
        self.dropdown_layout.set_valign(Gtk.Align.CENTER)

        cur_layout = cur.get("layout", "scrolling")
        if cur_layout in layout_keys:
            self.dropdown_layout.set_selected(layout_keys.index(cur_layout))
        else:
            self.dropdown_layout.set_selected(0)

        row_layout.add_suffix(self.dropdown_layout)
        g0.add(row_layout)

        row_col, self.spin_col_width = make_spin_row(
            "Column width", "Default column width for scrolling layout (0.1 – 1.0, 1.0 = full width)",
            0.1, 1.0, 0.05, 2, cur.get("column_width", 1.0),
        )
        g0.add(row_col)

        def on_layout_selected(w, _p):
            idx = w.get_selected()
            if 0 <= idx < len(layout_keys):
                chosen = layout_keys[idx]
                self.mark("layout", chosen)
                self.spin_col_width.set_sensitive(chosen == "scrolling")

        self.dropdown_layout.connect("notify::selected", on_layout_selected)
        self.spin_col_width.set_sensitive(cur_layout == "scrolling")
        self.spin_col_width.connect(
            "value-changed", lambda w: self.mark("column_width", round(w.get_value(), 2))
        )

        g1 = make_group("Window Decoration")
        row, self.spin_border = make_spin_row(
            "Border size", "Width of window borders, in pixels",
            0, 20, 1, 0, cur["border"],
        )
        g1.add(row)
        self.spin_border.connect(
            "value-changed", lambda w: self.mark("border_size", int(w.get_value()))
        )

        row, self.spin_round = make_spin_row(
            "Corner rounding", "Corner radius, in pixels",
            0, 30, 1, 0, cur["rounding"],
        )
        g1.add(row)
        self.spin_round.connect(
            "value-changed", lambda w: self.mark("roundness", int(w.get_value()))
        )

        g2 = make_group("Gaps")
        row, self.spin_inner = make_spin_row(
            "Inner gap", "Gap between tiled windows, in pixels",
            0, 40, 1, 0, cur["inner_gap"],
        )
        g2.add(row)
        self.spin_inner.connect(
            "value-changed", lambda w: self.mark("inner_gap", int(w.get_value()))
        )

        row, self.spin_outer = make_spin_row(
            "Outer gap", "Gap between windows and screen edge, in pixels",
            0, 60, 1, 0, cur["outer_gap"],
        )
        g2.add(row)
        self.spin_outer.connect(
            "value-changed", lambda w: self.mark("outer_gap", int(w.get_value()))
        )

        g3 = make_group("Blur", "Recommended: size 2–8, passes 2–4.")
        row, self.spin_blur_size = make_spin_row(
            "Blur size", "Spread radius of the blur kernel",
            0, 20, 1, 0, cur["blur_size"],
        )
        g3.add(row)
        self.spin_blur_size.connect("value-changed", lambda w: self.mark_blur())

        row, self.spin_blur_passes = make_spin_row(
            "Blur passes", "More passes = smoother blur, higher GPU cost",
            1, 8, 1, 0, cur["blur_pass"],
        )
        g3.add(row)
        self.spin_blur_passes.connect("value-changed", lambda w: self.mark_blur())

        g4 = make_group("Opacity", "Also applied to Kitty background, GTK3, and GTK4.")
        row, self.spin_opacity_act = make_spin_row(
            "Active window opacity", "Opacity of the focused window",
            0.0, 1.0, 0.05, 2, cur["opacity_act"],
        )
        g4.add(row)
        self.spin_opacity_act.connect("value-changed", lambda w: self.mark_opacity())

        row, self.spin_opacity_deact = make_spin_row(
            "Inactive window opacity", "Opacity of unfocused windows",
            0.0, 1.0, 0.05, 2, cur["opacity_deact"],
        )
        g4.add(row)
        self.spin_opacity_deact.connect("value-changed", lambda w: self.mark_opacity())

        g5 = make_group("Shadow")
        self.switch_shadow = Adw.SwitchRow(
            title="Enable drop shadow",
            subtitle="Off sets shadow range to 0",
        )
        self.switch_shadow.set_active(cur["shadow_range"] > 0)
        g5.add(self.switch_shadow)
        self.switch_shadow.connect("notify::active", self.on_shadow_toggled)

        row, self.spin_shadow = make_spin_row(
            "Shadow range", "Drop shadow radius, in pixels. 0 disables shadows.",
            0, 60, 1, 0, cur["shadow_range"] if cur["shadow_range"] > 0 else 12,
        )
        g5.add(row)
        self.spin_shadow.set_sensitive(cur["shadow_range"] > 0)
        self.spin_shadow.connect("value-changed", self.on_shadow_range_changed)

        self.results_group = make_group("Last apply")
        self.results_group.set_visible(False)
        self._result_rows = []

        return wrap_page(g0, g1, g2, g3, g4, g5, self.results_group)

    def mark(self, key, value):
        self.pending[key] = value
        self._refresh_buttons()

    def mark_blur(self):
        self.pending["blur"] = (
            int(self.spin_blur_size.get_value()),
            int(self.spin_blur_passes.get_value()),
        )
        self._refresh_buttons()

    def mark_opacity(self):
        self.pending["opacity"] = (
            round(self.spin_opacity_act.get_value(), 2),
            round(self.spin_opacity_deact.get_value(), 2),
        )
        self._refresh_buttons()

    def on_shadow_toggled(self, switch, _pspec):
        active = switch.get_active()
        self.spin_shadow.set_sensitive(active)
        self.mark("shadow", int(self.spin_shadow.get_value()) if active else 0)

    def on_shadow_range_changed(self, w):
        if self.switch_shadow.get_active():
            self.mark("shadow", int(w.get_value()))

    # ── Display (monitor) page ──────────────────────────────────────────

    def _build_monitor_page(self):
        monitors = parse_monitors()
        if not monitors:
            g = make_group("Display", "No hl.monitor() blocks found in monitor.lua.")
            return wrap_page(g)

        groups = []
        for mon in monitors:
            output = mon["output"]
            title = output if output else "Default monitor (catch-all)"
            g = make_group(
                title,
                None if output else "Matches any monitor without its own hl.monitor() block above it.",
            )
            widgets = {}

            resolutions, refresh_by_res = get_resolution_options(output)

            is_preferred = mon["mode"].strip().lower() == "preferred"
            cur_w = cur_h = cur_hz = None
            if not is_preferred:
                mm = re.match(r"^(\d+)x(\d+)@([\d.]+)$", mon["mode"])
                if mm:
                    cur_w, cur_h, cur_hz = int(mm.group(1)), int(mm.group(2)), float(mm.group(3))
                else:
                    is_preferred = True  # unrecognised string — treat like "preferred"

            if cur_w is not None and (cur_w, cur_h) not in resolutions:
                resolutions.append((cur_w, cur_h))
                resolutions.sort(key=lambda wh: -(wh[0] * wh[1]))
            if cur_w is not None:
                rates = refresh_by_res.setdefault((cur_w, cur_h), list(FALLBACK_REFRESH))
                if cur_hz not in rates:
                    rates.append(cur_hz)
                    rates.sort(reverse=True)

            res_labels = ["Preferred"] + [f"{w} × {h}" for w, h in resolutions]
            row = Adw.ActionRow(title="Resolution")
            res_dropdown = Gtk.DropDown.new_from_strings(res_labels)
            res_dropdown.set_valign(Gtk.Align.CENTER)
            row.add_suffix(res_dropdown)
            g.add(row)

            refresh_row = Adw.ActionRow(title="Refresh rate")
            hz_dropdown = Gtk.DropDown.new_from_strings(["60 Hz"])
            hz_dropdown.set_valign(Gtk.Align.CENTER)
            refresh_row.add_suffix(hz_dropdown)
            g.add(refresh_row)

            widgets["res_dropdown"] = res_dropdown
            widgets["hz_dropdown"] = hz_dropdown
            widgets["refresh_row"] = refresh_row
            widgets["resolutions"] = resolutions
            widgets["refresh_by_res"] = refresh_by_res
            widgets["current_rates"] = []

            def set_refresh_options(w, h, widgets=widgets, preferred_hz=None):
                rates = widgets["refresh_by_res"].get((w, h)) or list(FALLBACK_REFRESH)
                widgets["current_rates"] = rates
                widgets["hz_dropdown"].set_model(Gtk.StringList.new([fmt_hz(r) for r in rates]))
                if preferred_hz is not None and preferred_hz in rates:
                    idx = rates.index(preferred_hz)
                elif 60.0 in rates:
                    idx = rates.index(60.0)
                else:
                    idx = 0
                widgets["hz_dropdown"].set_selected(idx)
                return idx

            if is_preferred:
                res_dropdown.set_selected(0)
                refresh_row.set_visible(False)
                default_wh = resolutions[0] if resolutions else (1920, 1080)
                set_refresh_options(*default_wh)
            else:
                res_dropdown.set_selected(resolutions.index((cur_w, cur_h)) + 1)
                refresh_row.set_visible(True)
                set_refresh_options(cur_w, cur_h, preferred_hz=cur_hz)

            def on_resolution_change(_w, output=output, widgets=widgets):
                idx = widgets["res_dropdown"].get_selected()
                if idx == 0:
                    widgets["refresh_row"].set_visible(False)
                    self.mark_monitor(output, "mode", "preferred")
                    return
                w, h = widgets["resolutions"][idx - 1]
                widgets["refresh_row"].set_visible(True)
                hz_idx = set_refresh_options(w, h, widgets)
                hz_val = widgets["current_rates"][hz_idx]
                self.mark_monitor(output, "mode", f"{w}x{h}@{fmt_hz_value(hz_val)}")

            def on_refresh_change(_w, output=output, widgets=widgets):
                res_idx = widgets["res_dropdown"].get_selected()
                if res_idx == 0:
                    return
                w, h = widgets["resolutions"][res_idx - 1]
                hz_idx = widgets["hz_dropdown"].get_selected()
                rates = widgets["current_rates"]
                if hz_idx < 0 or hz_idx >= len(rates):
                    return
                self.mark_monitor(output, "mode", f"{w}x{h}@{fmt_hz_value(rates[hz_idx])}")

            res_dropdown.connect(
                "notify::selected", lambda w, p, cb=on_resolution_change: cb(w)
            )
            hz_dropdown.connect(
                "notify::selected", lambda w, p, cb=on_refresh_change: cb(w)
            )

            is_auto = mon["scale"] == "auto"
            numeric_scale = mon["scale"] if isinstance(mon["scale"], float) else 1.0

            auto_row = Adw.SwitchRow(
                title="Automatic scaling", subtitle='Off lets you set an exact scale factor'
            )
            auto_row.set_active(is_auto)
            g.add(auto_row)

            row, spin_scale = make_spin_row(
                "Custom scale", "Used when automatic scaling is off",
                0.5, 3.0, 0.05, 2, numeric_scale,
            )
            spin_scale.set_sensitive(not is_auto)
            g.add(row)
            widgets["auto_row"] = auto_row
            widgets["spin_scale"] = spin_scale

            def on_scale_change(_w, output=output, widgets=widgets):
                auto = widgets["auto_row"].get_active()
                widgets["spin_scale"].set_sensitive(not auto)
                value = "auto" if auto else round(widgets["spin_scale"].get_value(), 2)
                self.mark_monitor(output, "scale", value)

            auto_row.connect("notify::active", lambda w, p, cb=on_scale_change: cb(w))
            spin_scale.connect("value-changed", on_scale_change)

            row = Adw.ActionRow(title="Position", subtitle='"auto" or "X,Y"')
            pos_entry = Gtk.Entry(text=mon["position"], valign=Gtk.Align.CENTER)
            row.add_suffix(pos_entry)
            g.add(row)
            widgets["pos_entry"] = pos_entry
            pos_entry.connect(
                "changed",
                lambda w, output=output: self.mark_monitor(output, "position", w.get_text()),
            )

            self.monitor_widgets[output] = {
                "mode": mon["mode"],
                "scale": mon["scale"],
                "position": mon["position"],
            }
            groups.append(g)

        return wrap_page(*groups)

    def mark_monitor(self, output, field, value):
        state = self.monitor_widgets.setdefault(
            output, {"mode": "", "scale": 1.0, "position": "auto"}
        )
        state[field] = value
        self.pending.setdefault("monitor", {})[output] = dict(state)
        self._refresh_buttons()

    # ── Animations page ──────────────────────────────────────────────────

    def _build_animations_page(self):
        groups = []

        g0 = make_group("Global")
        self.switch_anim = Adw.SwitchRow(title="Enable animations")
        self.switch_anim.set_active(parse_anim_global_enabled())
        g0.add(self.switch_anim)
        self.switch_anim.connect(
            "notify::active",
            lambda w, _p: self.mark("anim_global", 1 if w.get_active() else 0),
        )
        groups.append(g0)

        curves = parse_curves()
        curve_names = list(curves.keys()) or ["linear"]

        anims = parse_animations()
        if anims:
            g1 = make_group("Animations", "Speed is in Hyprland's 1–10 unit, not seconds.")
            for a in anims:
                leaf = a["leaf"]
                row = Adw.ActionRow(title=leaf)

                speed_box = Gtk.SpinButton(
                    adjustment=Gtk.Adjustment(
                        value=a["speed"], lower=0.5, upper=30, step_increment=0.5
                    ),
                    digits=1,
                    valign=Gtk.Align.CENTER,
                )
                row.add_suffix(speed_box)

                dropdown = Gtk.DropDown.new_from_strings(curve_names)
                if a["bezier"] in curve_names:
                    dropdown.set_selected(curve_names.index(a["bezier"]))
                dropdown.set_valign(Gtk.Align.CENTER)
                row.add_suffix(dropdown)

                self.anim_leaf_widgets[leaf] = {
                    "speed": speed_box, "bezier": dropdown, "names": curve_names,
                }

                def on_leaf_change(_w, leaf=leaf):
                    widgets = self.anim_leaf_widgets[leaf]
                    idx = widgets["bezier"].get_selected()
                    bezier_name = widgets["names"][idx] if idx < len(widgets["names"]) else ""
                    self.pending.setdefault("anim_leaf", {})[leaf] = {
                        "speed": round(widgets["speed"].get_value(), 2),
                        "bezier": bezier_name,
                    }
                    self._refresh_buttons()

                speed_box.connect("value-changed", on_leaf_change)
                dropdown.connect("notify::selected", lambda w, p, cb=on_leaf_change: cb(w))

                g1.add(row)
            groups.append(g1)

        if curves:
            g2 = make_group(
                "Bezier curves",
                "Control points as (x, y) pairs. X is typically 0–1; Y can exceed "
                "1 for overshoot/bounce curves.",
            )
            for name, (p1, p2) in curves.items():
                exp = Adw.ExpanderRow(title=name)
                sliders = {}
                for label, axis, val in [
                    ("Point 1 – X", "p1x", p1[0]),
                    ("Point 1 – Y", "p1y", p1[1]),
                    ("Point 2 – X", "p2x", p2[0]),
                    ("Point 2 – Y", "p2y", p2[1]),
                ]:
                    lo, hi = (0.0, 1.0) if axis.endswith("x") else (-0.5, 1.5)
                    row, scale = make_scale_row(label, lo, hi, 0.01, 2, val)
                    exp.add_row(row)
                    sliders[axis] = scale
                self.curve_widgets[name] = sliders

                def on_curve_change(_w, name=name):
                    s = self.curve_widgets[name]
                    p1 = (round(s["p1x"].get_value(), 2), round(s["p1y"].get_value(), 2))
                    p2 = (round(s["p2x"].get_value(), 2), round(s["p2y"].get_value(), 2))
                    self.pending.setdefault("curve", {})[name] = (p1, p2)
                    self._refresh_buttons()

                for scale in sliders.values():
                    scale.connect("value-changed", on_curve_change)
                g2.add(exp)
            groups.append(g2)

        if not anims and not curves:
            groups.append(make_group("Animations", "animation.lua not found."))

        return wrap_page(*groups)

    # ── Input page ───────────────────────────────────────────────────────

    def _build_input_page(self):
        cur = read_input()
        g1 = make_group("Pointer")
        row, self.scale_sensitivity = make_scale_row(
            "Mouse sensitivity", -1.0, 1.0, 0.05, 2, cur["sensitivity"]
        )
        g1.add(row)
        self.scale_sensitivity.connect(
            "value-changed",
            lambda w: self.mark("input_sensitivity", round(w.get_value(), 2)),
        )

        g2 = make_group("Touchpad")
        self.input_switches = {}
        for key, label in [
            ("natural_scroll", "Natural scrolling"),
            ("tap_to_click", "Tap to click"),
            ("disable_while_typing", "Disable while typing"),
            ("left_handed", "Left-handed mode"),
            ("numlock_by_default", "Numlock on by default"),
        ]:
            sw = Adw.SwitchRow(title=label)
            sw.set_active(bool(cur[key]))
            g2.add(sw)
            self.input_switches[key] = sw
            sw.connect(
                "notify::active",
                lambda w, _p, key=key: self.mark_input_bool(key, w.get_active()),
            )

        return wrap_page(g1, g2)

    def mark_input_bool(self, key, value):
        self.pending.setdefault("input_bool", {})[key] = value
        self._refresh_buttons()

    # ── Environment page ─────────────────────────────────────────────────

    def _build_environment_page(self):
        self.env_group = make_group(
            "Environment variables", "Applied via hl.env(KEY, VALUE) in environment.lua."
        )
        for key, value in parse_env_vars():
            self._add_env_row(key, value)

        add_group = make_group("Add variable")
        self.env_key_entry = Adw.EntryRow(title="Key")
        self.env_val_entry = Adw.EntryRow(title="Value")
        add_btn_row = Adw.ActionRow()
        add_btn = Gtk.Button(label="Add", valign=Gtk.Align.CENTER)
        add_btn.add_css_class("suggested-action")
        add_btn.connect("clicked", self.on_add_env)
        add_btn_row.add_suffix(add_btn)
        add_group.add(self.env_key_entry)
        add_group.add(self.env_val_entry)
        add_group.add(add_btn_row)

        return wrap_page(self.env_group, add_group)

    def _add_env_row(self, key, value):
        row = Adw.EntryRow(title=key, text=value)
        del_btn = Gtk.Button(icon_name="user-trash-symbolic", valign=Gtk.Align.CENTER)
        del_btn.add_css_class("flat")
        del_btn.connect("clicked", lambda _b, key=key: self.on_remove_env(key))
        row.add_suffix(del_btn)
        row.connect(
            "notify::text",
            lambda w, _p, key=key: self.mark_env_edit(key, w.get_text()),
        )
        self.env_group.add(row)
        self.env_rows[key] = row

    def mark_env_edit(self, key, value):
        if key in self.pending.get("env_remove", set()):
            return
        self.pending.setdefault("env_edit", {})[key] = value
        self._refresh_buttons()

    def on_remove_env(self, key):
        self.pending.setdefault("env_remove", set()).add(key)
        self.pending.get("env_edit", {}).pop(key, None)
        row = self.env_rows.pop(key, None)
        if row is not None:
            self.env_group.remove(row)
        self._refresh_buttons()
        self.toast_overlay.add_toast(Adw.Toast(title=f"{key} will be removed on Apply", timeout=2))

    def on_add_env(self, _btn):
        key = self.env_key_entry.get_text().strip()
        val = self.env_val_entry.get_text().strip()
        if not key:
            return
        self.pending.setdefault("env_add", []).append((key, val))
        self._add_env_row(key, val)
        self.env_rows[key].set_sensitive(False)  # new rows are edited via the add list, not inline
        self.env_key_entry.set_text("")
        self.env_val_entry.set_text("")
        self._refresh_buttons()

    # ── Keybinds page ────────────────────────────────────────────────────

    def _build_keybinds_page(self):
        self.keybind_group = make_group(
            "Keybinds", "Raw Lua statements from keybinds.lua — edited as text for reliability."
        )
        for kb in iter_keybind_statements():
            self._add_keybind_row(kb["raw"], kb["combo"], kb["action"])

        add_group = make_group("Add keybind")
        self.kb_combo_entry = Adw.EntryRow(title='Key combo, e.g. mainMod .. " + Y"')
        self.kb_cmd_entry = Adw.EntryRow(title="Shell command")
        row = Adw.ActionRow()
        self.kb_locked = Gtk.CheckButton(label="Locked")
        self.kb_repeating = Gtk.CheckButton(label="Repeating")
        row.add_suffix(self.kb_locked)
        row.add_suffix(self.kb_repeating)
        add_btn = Gtk.Button(label="Add", valign=Gtk.Align.CENTER)
        add_btn.add_css_class("suggested-action")
        add_btn.connect("clicked", self.on_add_keybind)
        row.add_suffix(add_btn)
        add_group.add(self.kb_combo_entry)
        add_group.add(self.kb_cmd_entry)
        add_group.add(row)

        return wrap_page(self.keybind_group, add_group)

    def _add_keybind_row(self, raw, combo, action):
        title = combo.strip('"') if combo else "(bind)"
        exp = Adw.ExpanderRow(title=title[:60], subtitle=action[:80])

        tv = Gtk.TextView(wrap_mode=Gtk.WrapMode.WORD_CHAR)
        tv.get_buffer().set_text(raw)
        tv.set_top_margin(6)
        tv.set_bottom_margin(6)
        tv.set_left_margin(6)
        tv.set_right_margin(6)
        scroller = Gtk.ScrolledWindow(min_content_height=80, max_content_height=200)
        scroller.set_child(tv)

        btn_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        btn_row.set_margin_top(6)
        btn_row.set_margin_bottom(6)
        btn_row.set_margin_start(6)
        btn_row.set_margin_end(6)
        save_btn = Gtk.Button(label="Save changes")
        save_btn.add_css_class("suggested-action")
        remove_btn = Gtk.Button(label="Remove")
        remove_btn.add_css_class("destructive-action")
        btn_row.append(save_btn)
        btn_row.append(remove_btn)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        box.append(scroller)
        box.append(btn_row)

        inner_row = Gtk.ListBoxRow(selectable=False, activatable=False)
        inner_row.set_child(box)
        exp.add_row(inner_row)

        state = {"raw": raw, "textview": tv, "exp": exp}
        self.keybind_rows[raw] = state

        save_btn.connect("clicked", lambda _b, raw=raw: self.on_save_keybind(raw))
        remove_btn.connect("clicked", lambda _b, raw=raw: self.on_remove_keybind(raw))

        self.keybind_group.add(exp)

    def on_save_keybind(self, original_raw):
        state = self.keybind_rows.get(original_raw)
        if not state:
            return
        buf = state["textview"].get_buffer()
        new_text = buf.get_text(buf.get_start_iter(), buf.get_end_iter(), True).strip()
        if new_text and new_text != original_raw:
            self.pending.setdefault("keybind_edit", {})[original_raw] = new_text
            self._refresh_buttons()
            self.toast_overlay.add_toast(Adw.Toast(title="Keybind change staged", timeout=2))

    def on_remove_keybind(self, original_raw):
        self.pending.setdefault("keybind_remove", set()).add(original_raw)
        self.pending.get("keybind_edit", {}).pop(original_raw, None)
        state = self.keybind_rows.pop(original_raw, None)
        if state:
            self.keybind_group.remove(state["exp"])
        self._refresh_buttons()
        self.toast_overlay.add_toast(Adw.Toast(title="Keybind will be removed on Apply", timeout=2))

    def on_add_keybind(self, _btn):
        combo = self.kb_combo_entry.get_text().strip()
        cmd = self.kb_cmd_entry.get_text().strip()
        if not combo or not cmd:
            return
        opts = []
        if self.kb_locked.get_active():
            opts.append("locked = true")
        if self.kb_repeating.get_active():
            opts.append("repeating = true")
        opts_str = f", {{ {', '.join(opts)} }}" if opts else ""
        raw = f'hl.bind({combo}, hl.dsp.exec_cmd("{cmd}"){opts_str})'
        self.pending.setdefault("keybind_add", []).append(raw)
        self._add_keybind_row(raw, combo, f'hl.dsp.exec_cmd("{cmd}")')
        self.kb_combo_entry.set_text("")
        self.kb_cmd_entry.set_text("")
        self.kb_locked.set_active(False)
        self.kb_repeating.set_active(False)
        self._refresh_buttons()

    # ── Login Avatar (SDDM) page ────────────────────────────────────────

    def _prompt_sudo_password(self, on_password):
        """Shows a small in-app dialog asking for the sudo password.

        Calls on_password(password) if the user confirms, or
        on_password(None) if they cancel. Doesn't rely on any external
        polkit agent — this dialog *is* the prompt."""
        dialog = Adw.MessageDialog(
            transient_for=self,
            heading="Authentication Required",
            body="Enter your password to apply this system change.",
        )
        entry = Gtk.PasswordEntry(show_peek_icon=True)
        entry.set_margin_top(8)
        dialog.set_extra_child(entry)
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("auth", "Authenticate")
        dialog.set_response_appearance("auth", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_default_response("auth")
        dialog.set_close_response("cancel")
        # Gtk.PasswordEntry has no activates-default property (unlike plain
        # Gtk.Entry), so Enter is wired up manually via its "activate"
        # signal, which it does emit.
        entry.connect("activate", lambda _e: dialog.response("auth"))

        def _on_response(_d, response):
            on_password(entry.get_text() if response == "auth" else None)
            dialog.close()

        dialog.connect("response", _on_response)
        dialog.present()

        # grab_focus() right after present() is too early — the dialog
        # isn't mapped yet, so the entry never actually gets keyboard
        # focus and Enter has nothing to activate. Defer it one idle
        # cycle so it runs once the dialog is really on screen.
        def _focus_entry():
            entry.grab_focus()
            return False

        GLib.idle_add(_focus_entry)


    def _run_with_sudo_password(self, sudo, bash, script_path, password, on_done):
        if password is None:
            on_done(False, "", "Authentication cancelled")
            return
        try:
            proc = Gio.Subprocess.new(
                [sudo, "-S", "-p", "", bash, str(script_path)],
                Gio.SubprocessFlags.STDIN_PIPE
                | Gio.SubprocessFlags.STDOUT_PIPE
                | Gio.SubprocessFlags.STDERR_PIPE,
            )
        except GLib.Error as e:
            on_done(False, "", str(e))
            return

        def _finish(p, result):
            try:
                _, out, err = p.communicate_utf8_finish(result)
            except GLib.Error as e:
                on_done(False, "", str(e))
                return
            ok = p.get_exit_status() == 0
            if not ok and "incorrect password" in (err or "").lower():
                err = "Incorrect password"
            on_done(ok, out or "", err or "")

        proc.communicate_utf8_async(password + "\n", None, _finish)

    def _run_privileged_script(self, script_text: str, title: str, on_done):
        """Runs `script_text` as root by asking for the sudo password in an
        in-app dialog and piping it straight to `sudo -S` — no dependency
        on an external polkit agent being installed or running, which is
        what left `pkexec` hanging with no visible prompt on some setups.
        Falls back to a kitty window with an interactive `sudo` prompt if
        `sudo` itself isn't installed.

        `on_done(ok, stdout, stderr)` is called once the run finishes.
        There's no reliable completion signal for the kitty fallback, so
        callers should ask the user to hit refresh instead — on_done is
        not called in that case.

        Returns "sudo", "kitty", or None (nothing usable is installed, in
        which case on_done has already been called with ok=False).
        """
        cache_dir = CACHE_HOME / "hypr-settings"
        cache_dir.mkdir(parents=True, exist_ok=True)
        script_path = cache_dir / "priv-helper.sh"
        script_path.write_text(script_text)
        script_path.chmod(0o755)

        bash = shutil.which("bash") or "/bin/bash"
        sudo = shutil.which("sudo")

        if sudo:
            self._prompt_sudo_password(
                lambda password: self._run_with_sudo_password(
                    sudo, bash, script_path, password, on_done
                )
            )
            return "sudo"

        if shutil.which("kitty"):
            wrapper = cache_dir / "priv-helper-sudo.sh"
            wrapper.write_text(
                "set -e\n"
                f"sudo bash {shlex.quote(str(script_path))}\n"
                'echo\necho "Done. Press Enter to close."\nread\n'
            )
            wrapper.chmod(0o755)
            subprocess.Popen(
                [KITTY_BIN, "--title", title, "bash", str(wrapper)],
                start_new_session=True,
            )
            return "kitty"

        on_done(False, "", "Neither sudo nor kitty was found — install sudo (or kitty)")
        return None

    def _build_sddm_avatar_page(self):
        g = make_group(
            "SDDM Login Avatar",
            f"Sets the face icon shown on the SDDM login screen for "
            f"'{self.avatar_username}'. The image is cropped to a square and "
            f"resized to 256×256 with ImageMagick, then installed to "
            f"{SDDM_FACES_DIR} — this needs your password.",
        )

        # Current avatar preview
        self.avatar_current_preview = Adw.Avatar(
            size=64, text=self.avatar_username, show_initials=True
        )
        current_row = Adw.ActionRow(title="Current avatar")
        current_row.add_prefix(self.avatar_current_preview)
        refresh_btn = Gtk.Button(icon_name="view-refresh-symbolic", valign=Gtk.Align.CENTER)
        refresh_btn.set_tooltip_text("Refresh preview from disk")
        refresh_btn.add_css_class("flat")
        refresh_btn.connect("clicked", lambda _b: self._load_current_avatar_preview())
        current_row.add_suffix(refresh_btn)
        self.avatar_current_row = current_row
        g.add(current_row)

        # Backup row — only shown once a backup actually exists on disk
        self.avatar_backup_row = Adw.ActionRow(
            title="Backup available",
            subtitle="A previous avatar was backed up before the last change.",
        )
        self.avatar_backup_row.add_prefix(Gtk.Image.new_from_icon_name("edit-undo-symbolic"))
        restore_btn = Gtk.Button(label="Restore Backup", valign=Gtk.Align.CENTER)
        restore_btn.connect("clicked", self.on_restore_avatar_backup)
        self.avatar_backup_row.add_suffix(restore_btn)
        self.avatar_backup_row.set_visible(False)
        g.add(self.avatar_backup_row)

        # New image picker
        self.avatar_new_preview = Adw.Avatar(
            size=48, icon_name="image-x-generic-symbolic", show_initials=False
        )
        new_row = Adw.ActionRow(title="New image", subtitle="No image selected yet")
        new_row.add_prefix(self.avatar_new_preview)
        choose_btn = Gtk.Button(label="Choose Image…", valign=Gtk.Align.CENTER)
        choose_btn.connect("clicked", self.on_pick_avatar_image)
        new_row.add_suffix(choose_btn)
        self.avatar_new_row = new_row
        g.add(new_row)

        # Apply
        apply_row = Adw.ActionRow(
            title="Set as SDDM Avatar",
            subtitle="Crops to a square, resizes to 256×256, backs up the "
            "old icon, and installs the new one.",
        )
        apply_row.add_prefix(Gtk.Image.new_from_icon_name("emblem-photos-symbolic"))
        action_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        action_box.set_valign(Gtk.Align.CENTER)
        self.avatar_spinner = Gtk.Spinner()
        self.avatar_spinner.set_visible(False)
        self.avatar_apply_btn = Gtk.Button(label="Set as SDDM Avatar")
        self.avatar_apply_btn.set_sensitive(False)
        self.avatar_apply_btn.add_css_class("suggested-action")
        self.avatar_apply_btn.connect("clicked", self.on_apply_avatar)
        action_box.append(self.avatar_spinner)
        action_box.append(self.avatar_apply_btn)
        apply_row.add_suffix(action_box)
        g.add(apply_row)

        if not shutil.which("mogrify"):
            warn_row = Adw.ActionRow(
                title="ImageMagick not found",
                subtitle="Install the 'imagemagick' package to enable "
                "cropping and resizing.",
            )
            icon = Gtk.Image.new_from_icon_name("dialog-warning-symbolic")
            icon.add_css_class("warning")
            warn_row.add_prefix(icon)
            g.add(warn_row)

        self._load_current_avatar_preview()

        return wrap_page(g)

    def _load_current_avatar_preview(self):
        face_icon = SDDM_FACES_DIR / f"{self.avatar_username}.face.icon"
        if face_icon.is_file():
            try:
                texture = Gdk.Texture.new_from_filename(str(face_icon))
                self.avatar_current_preview.set_custom_image(texture)
            except GLib.Error:
                self.avatar_current_preview.set_custom_image(None)
            self.avatar_current_row.set_subtitle(str(face_icon))
        else:
            self.avatar_current_preview.set_custom_image(None)
            self.avatar_current_row.set_subtitle(
                "No avatar set yet — SDDM will show the default icon"
            )
        backup_icon = SDDM_FACES_DIR / f"{self.avatar_username}.face.icon.bkp"
        self.avatar_backup_row.set_visible(backup_icon.is_file())

    def on_pick_avatar_image(self, _btn):
        dialog = Gtk.FileDialog(title="Choose an avatar image")
        img_filter = Gtk.FileFilter()
        img_filter.set_name("Images")
        img_filter.add_mime_type("image/png")
        img_filter.add_mime_type("image/jpeg")
        img_filter.add_mime_type("image/webp")
        img_filter.add_mime_type("image/bmp")
        img_filter.add_mime_type("image/gif")
        filters = Gio.ListStore.new(Gtk.FileFilter)
        filters.append(img_filter)
        dialog.set_filters(filters)
        dialog.set_default_filter(img_filter)
        dialog.open(self, None, self._on_avatar_file_chosen)

    def _on_avatar_file_chosen(self, dialog, result):
        try:
            file = dialog.open_finish(result)
        except GLib.Error:
            return  # cancelled — nothing to do
        if not file:
            return
        path = file.get_path()
        if not path:
            return
        self.avatar_selected_path = path
        self._refresh_avatar_selection_ui(path)

    def _refresh_avatar_selection_ui(self, path):
        self.avatar_new_row.set_subtitle(path)
        try:
            texture = Gdk.Texture.new_from_filename(path)
            self.avatar_new_preview.set_custom_image(texture)
        except GLib.Error:
            self.avatar_new_preview.set_custom_image(None)
        self.avatar_apply_btn.set_sensitive(True)
        self.avatar_new_preview.add_css_class("avatar-pop-in")
        GLib.timeout_add(400, self._clear_avatar_pop_in)

    def _clear_avatar_pop_in(self):
        self.avatar_new_preview.remove_css_class("avatar-pop-in")
        return False

    def _clear_avatar_success_pulse(self):
        self.avatar_current_preview.remove_css_class("avatar-success-pulse")
        return False

    def on_apply_avatar(self, _btn):
        if not self.avatar_selected_path:
            return
        if not shutil.which("mogrify"):
            self.toast_overlay.add_toast(
                Adw.Toast(
                    title="ImageMagick not found — install 'imagemagick' and try again",
                    timeout=4,
                )
            )
            return

        self.avatar_apply_btn.set_sensitive(False)
        self.avatar_spinner.set_visible(True)
        self.avatar_spinner.start()
        self.toast_overlay.add_toast(Adw.Toast(title="Waiting for authentication…", timeout=5))

        script = build_avatar_apply_script(self.avatar_username, self.avatar_selected_path)

        def done(ok, out, err):
            self.avatar_spinner.stop()
            self.avatar_spinner.set_visible(False)
            self.avatar_apply_btn.set_sensitive(True)
            if ok:
                self.toast_overlay.add_toast(Adw.Toast(title="SDDM avatar updated", timeout=3))
                self._load_current_avatar_preview()
                self.avatar_current_preview.add_css_class("avatar-success-pulse")
                GLib.timeout_add(900, self._clear_avatar_success_pulse)
            else:
                lines = (err or out or "Failed to set avatar").strip().splitlines()
                self.toast_overlay.add_toast(
                    Adw.Toast(title=lines[-1] if lines else "Failed to set avatar", timeout=4)
                )

        mode = self._run_privileged_script(script, "Set SDDM Avatar", done)
        if mode == "kitty":
            self.avatar_spinner.stop()
            self.avatar_spinner.set_visible(False)
            self.avatar_apply_btn.set_sensitive(True)
            self.toast_overlay.add_toast(
                Adw.Toast(
                    title="Enter your password in the terminal, then press the refresh icon above",
                    timeout=6,
                )
            )

    def on_restore_avatar_backup(self, _btn):
        face_icon = SDDM_FACES_DIR / f"{self.avatar_username}.face.icon"
        backup_icon = SDDM_FACES_DIR / f"{self.avatar_username}.face.icon.bkp"
        if not backup_icon.is_file():
            return
        q = shlex.quote
        script = f"set -e\ncp -f {q(str(backup_icon))} {q(str(face_icon))}\n"

        def done(ok, out, err):
            if ok:
                self.toast_overlay.add_toast(Adw.Toast(title="Backup restored", timeout=3))
                self._load_current_avatar_preview()
            else:
                lines = (err or out or "Failed to restore backup").strip().splitlines()
                self.toast_overlay.add_toast(
                    Adw.Toast(title=lines[-1] if lines else "Failed to restore backup", timeout=4)
                )

        mode = self._run_privileged_script(script, "Restore SDDM Avatar", done)
        if mode == "kitty":
            self.toast_overlay.add_toast(
                Adw.Toast(
                    title="Enter your password in the terminal, then press the refresh icon above",
                    timeout=6,
                )
            )

    # ── Dotfiles Update page ────────────────────────────────────────────

    def _build_dotfiles_update_page(self):
        repo_url = f"https://github.com/{DOTFILES_REPO_OWNER}/{DOTFILES_REPO_NAME}"

        g = make_group(
            "Dotfiles Update",
            "Downloads the latest dotfiles from GitHub and runs the repo's "
            "own setup.sh to apply them. This does not touch the individual "
            "settings on the other pages — it's a full re-sync from upstream.",
        )

        repo_row = Adw.ActionRow(title="Repository", subtitle=repo_url)
        repo_row.add_prefix(Gtk.Image.new_from_icon_name("folder-remote-symbolic"))
        g.add(repo_row)

        branch_row = Adw.ActionRow(title="Branch", subtitle=DOTFILES_BRANCH)
        branch_row.add_prefix(Gtk.Image.new_from_icon_name("emblem-shared-symbolic"))
        g.add(branch_row)

        cache_row = Adw.ActionRow(
            title="Cache location", subtitle=str(DOTFILES_CACHE_DIR)
        )
        cache_row.add_prefix(Gtk.Image.new_from_icon_name("folder-symbolic"))
        g.add(cache_row)

        action_row = Adw.ActionRow(
            title="Update now",
            subtitle="Fetches the branch via curl, extracts it, then runs "
            "setup.sh in a new kitty window.",
        )
        action_row.add_prefix(Gtk.Image.new_from_icon_name("software-update-available-symbolic"))
        update_btn = Gtk.Button(label="Update Dotfiles", valign=Gtk.Align.CENTER)
        update_btn.add_css_class("suggested-action")
        update_btn.connect("clicked", self.on_update_dotfiles)
        action_row.add_suffix(update_btn)
        g.add(action_row)

        return wrap_page(g)

    def on_update_dotfiles(self, _btn):
        if not shutil.which("curl"):
            self.toast_overlay.add_toast(
                Adw.Toast(title="curl not found — install curl and try again", timeout=4)
            )
            return
        if not shutil.which("kitty"):
            self.toast_overlay.add_toast(
                Adw.Toast(title="kitty not found — install kitty and try again", timeout=4)
            )
            return
        try:
            launch_dotfiles_update()
            self.toast_overlay.add_toast(
                Adw.Toast(title="Opening kitty to run setup.sh…", timeout=3)
            )
        except Exception as e:
            self.toast_overlay.add_toast(
                Adw.Toast(title=f"Couldn't start update: {e}", timeout=4)
            )

    # ── Apply / Discard ─────────────────────────────────────────────────

    def _refresh_buttons(self):
        has_pending = bool(self.pending)
        self.apply_btn.set_sensitive(has_pending)
        self.discard_btn.set_sensitive(has_pending)

    def on_apply(self, _btn):
        result = ApplyResult()
        apply_all(self.pending, result)
        self.pending.clear()
        self._refresh_buttons()
        self._show_results(result)

        errors = [m for lvl, m in result.lines if lvl == "err"]
        if errors:
            self.toast_overlay.add_toast(
                Adw.Toast(title="Applied with errors — see log below", timeout=4)
            )
        else:
            self.toast_overlay.add_toast(
                Adw.Toast(title="Settings written to disk", timeout=3)
            )

    def on_discard(self, _btn):
        self.pending.clear()
        self._refresh_buttons()
        self.toast_overlay.add_toast(Adw.Toast(title="Changes discarded", timeout=2))

    def _show_results(self, result: ApplyResult):
        for row in list(self._result_rows):
            self.results_group.remove(row)
        self._result_rows = []

        icon_map = {
            "ok": "emblem-ok-symbolic",
            "skip": "dialog-information-symbolic",
            "err": "dialog-warning-symbolic",
        }
        css_map = {"ok": "success", "skip": "dim-label", "err": "warning"}

        for level, msg in result.lines:
            row = Adw.ActionRow(title=msg)
            icon = Gtk.Image.new_from_icon_name(icon_map[level])
            icon.add_css_class(css_map[level])
            row.add_prefix(icon)
            self.results_group.add(row)
            self._result_rows.append(row)

        self.results_group.set_visible(bool(result.lines))

    def on_close_request(self, _win):
        if not self.pending:
            return False

        dialog = Adw.MessageDialog(
            transient_for=self,
            heading="Unapplied changes",
            body="You have changes that haven't been written to disk. "
            "Apply them before closing?",
        )
        dialog.add_response("discard", "Discard")
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("apply", "Apply & Close")
        dialog.set_response_appearance("apply", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_response_appearance("discard", Adw.ResponseAppearance.DESTRUCTIVE)
        dialog.set_default_response("apply")
        dialog.set_close_response("cancel")
        dialog.connect("response", self._on_close_response)
        dialog.present()
        return True

    def _on_close_response(self, _dialog, response):
        if response == "apply":
            result = ApplyResult()
            apply_all(self.pending, result)
            self.pending.clear()
            self.destroy()
        elif response == "discard":
            self.pending.clear()
            self.destroy()


class HyprSettingsApp(Adw.Application):
    def __init__(self):
        super().__init__(
            application_id="dev.shellninja.hypr-settings",
            flags=Gio.ApplicationFlags.FLAGS_NONE,
        )
        self.connect("activate", self.on_activate)

    def on_activate(self, app):
        load_custom_css()
        win = HyprSettingsWindow(app)
        win.present()


def main():
    import sys

    app = HyprSettingsApp()
    sys.exit(app.run(sys.argv))


if __name__ == "__main__":
    main()
