#!/usr/bin/env python3
# =============================================================================
#  welcome.py — GTK4 / Libadwaita welcome app for Hyprconf
#
#  Theming: this app hardcodes no colors. Everything uses libadwaita's named
#  colors (@accent_color, @window_fg_color, @headerbar_bg_color, ...), so it
#  picks up whatever Noctalia writes to your GTK4 theme. The CSS provider is
#  loaded exactly as in the original script.
#
#  Icons: inline SVG, drawn through a mask so they take the current text color.
# =============================================================================

def _enable_hyprland_blur():
    """Ensure libhypr_gtkblur.so is loaded to enable Hyprland background blur."""
    import os
    import sys
    from pathlib import Path
    if os.environ.get("HYPR_GTKBLUR") == "1":
        return
    scripts_dir = Path(__file__).resolve().parent
    so_path = scripts_dir / "libhypr_gtkblur.so"
    c_path = scripts_dir / "hypr_gtkblur.c"
    if not so_path.exists() and c_path.exists():
        import subprocess
        try:
            subprocess.run(
                ["gcc", "-O2", "-shared", "-fPIC", str(c_path), "-o", str(so_path), "-ldl"],
                check=True,
                capture_output=True,
            )
        except Exception:
            pass
    if so_path.exists():
        env = os.environ.copy()
        env["HYPR_GTKBLUR"] = "1"
        preload = env.get("LD_PRELOAD", "")
        env["LD_PRELOAD"] = f"{so_path}:{preload}".strip(":")
        os.execve(sys.executable, [sys.executable] + sys.argv, env)


_enable_hyprland_blur()

import json
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("GdkPixbuf", "2.0")
gi.require_version("Graphene", "1.0")

from gi.repository import Adw, Gdk, GdkPixbuf, Gio, GLib, Graphene, Gsk, Gtk

STATE_FILE = Path.home() / ".hyprconf" / "hypr" / "welcome-app.json"
SCRIPTS_DIR = Path(__file__).resolve().parent
LOGO_PATH = SCRIPTS_DIR.parent / ".cache" / "shell-ninja.png"


def load_state():
    try:
        if STATE_FILE.is_file():
            return json.loads(STATE_FILE.read_text())
    except Exception:
        pass
    return {"show_on_startup": True}


def save_state(state):
    try:
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        STATE_FILE.write_text(json.dumps(state, indent=2))
    except Exception:
        pass


# =============================================================================
#  SVG icons
#  Each entry is the inside of a 24x24 stroke icon (Lucide-style).
# =============================================================================

ICONS = {
    "terminal": '<polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/>',
    "window": '<rect x="2.5" y="4" width="19" height="16" rx="2.5"/><rect x="10" y="10.5" width="8" height="6" rx="1.5"/>',
    "folder": '<path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z"/>',
    "search": '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
    "image": '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>',
    "palette": '<circle cx="13.5" cy="6.5" r=".5"/><circle cx="17.5" cy="10.5" r=".5"/><circle cx="8.5" cy="7.5" r=".5"/><circle cx="6.5" cy="12.5" r=".5"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/>',
    "sliders": '<line x1="21" y1="4" x2="14" y2="4"/><line x1="10" y1="4" x2="3" y2="4"/><line x1="21" y1="12" x2="12" y2="12"/><line x1="8" y1="12" x2="3" y2="12"/><line x1="21" y1="20" x2="16" y2="20"/><line x1="12" y1="20" x2="3" y2="20"/><line x1="14" y1="2" x2="14" y2="6"/><line x1="8" y1="10" x2="8" y2="14"/><line x1="16" y1="18" x2="16" y2="22"/>',
    "refresh": '<path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/>',
    "keyboard": '<rect x="2" y="4" width="20" height="16" rx="2"/><path d="M6 8h.01M10 8h.01M14 8h.01M18 8h.01M8 12h.01M12 12h.01M16 12h.01M7 16h10"/>',
    "sparkles": '<path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z"/><path d="M20 3v4"/><path d="M22 5h-4"/><path d="M4 17v2"/><path d="M5 18H3"/>',
    "book": '<path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/>',
    "git-branch": '<line x1="6" y1="3" x2="6" y2="15"/><circle cx="18" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M18 9a9 9 0 0 1-9 9"/>',
    "check": '<path d="M20 6 9 17l-5-5"/>',
    "info": '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
    "power": '<path d="M12 2v10"/><path d="M18.4 6.6a9 9 0 1 1-12.77.04"/>',
}

_TEXTURES = {}


def icon_texture(name, px, stroke):
    """Rasterise an icon once per (name, size, stroke) and cache the texture."""
    key = (name, px, stroke)
    if key in _TEXTURES:
        return _TEXTURES[key]
    texture = None
    body = ICONS.get(name)
    if body:
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
            'viewBox="0 0 24 24" fill="none" stroke="#000" '
            f'stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round">'
            f"{body}</svg>"
        )
        try:
            stream = Gio.MemoryInputStream.new_from_bytes(GLib.Bytes.new(svg.encode()))
            pixbuf = GdkPixbuf.Pixbuf.new_from_stream_at_scale(stream, px, px, True, None)
            texture = Gdk.Texture.new_for_pixbuf(pixbuf)
        except Exception as exc:  # e.g. librsvg's pixbuf loader is missing
            print(f"welcome.py: could not render icon '{name}': {exc}", file=sys.stderr)
    _TEXTURES[key] = texture
    return texture


def widget_color(widget):
    """The widget's current CSS `color`, so icons follow the theme."""
    try:
        return widget.get_color()  # GTK 4.10+
    except AttributeError:
        return widget.get_style_context().get_color()


class SvgIcon(Gtk.Widget):
    __gtype_name__ = "HcSvgIcon"

    def __init__(self, name, size=20, stroke=1.8):
        super().__init__()
        self._name = name
        self._size = size
        self._stroke = stroke
        self.set_halign(Gtk.Align.CENTER)
        self.set_valign(Gtk.Align.CENTER)

    def do_measure(self, orientation, for_size):
        return (self._size, self._size, -1, -1)

    def do_snapshot(self, snapshot):
        width, height = self.get_width(), self.get_height()
        if width <= 0 or height <= 0:
            return
        px = int(round(min(width, height) * max(1, self.get_scale_factor())))
        texture = icon_texture(self._name, px, self._stroke)
        if texture is None:
            return
        rect = Graphene.Rect().init(0, 0, width, height)
        snapshot.push_mask(Gsk.MaskMode.ALPHA)   # the shape ...
        snapshot.append_texture(texture, rect)
        snapshot.pop()
        snapshot.append_color(widget_color(self), rect)  # ... filled with the CSS color
        snapshot.pop()


# =============================================================================
#  Theme (named colors only, so Noctalia's GTK colors apply)
# =============================================================================

CSS = """
* { font-family: 'Inter', system-ui, sans-serif; }

window, .background {
    background-color: alpha(@window_bg_color, 0.82);
}

headerbar {
    background-color: transparent;
}

.keycap {
    background-color: alpha(@window_fg_color, 0.08);
    border: 1px solid alpha(@window_fg_color, 0.16);
    border-radius: 6px;
    padding: 3px 8px;
    font-family: monospace;
    font-size: 0.82em;
    font-weight: 700;
    color: @accent_color;
}

.keycap-separator {
    color: alpha(@window_fg_color, 0.35);
    font-size: 0.8em;
    font-weight: bold;
}

.nav-bar {
    background-color: alpha(@headerbar_bg_color, 0.6);
    border-top: 1px solid alpha(@window_fg_color, 0.08);
    padding: 12px 24px;
}

.hero-icon {
    color: @accent_color;
    margin-bottom: 8px;
}

.welcome-logo {
    margin-bottom: 8px;
    border: 3px solid alpha(@accent_color, 0.4);
    box-shadow: 0 4px 18px alpha(black, 0.25);
    border-radius: 9999px;
}

/* icons take the accent color, like the keycaps */
.row-icon { color: @accent_color; }

/* small hover feedback on list rows */
list.boxed-list > row { transition: background-color 150ms ease; }
"""

# =============================================================================
#  Content
# =============================================================================

# (icon, title, description, keys, fallback)
# The real command is looked up from your live Hyprland binds. `fallback` is only
# used if that lookup fails (for example when Hyprland isn't running): a command
# list, a script in this folder, or None.
KEYBIND_SECTIONS = [
    ("Launch", [
        ("terminal", "Terminal", "Launch Kitty terminal", ["SUPER", "Return"], ["kitty"]),
        ("window", "Floating Terminal", "Launch Kitty in floating window", ["SUPER", "SHIFT", "Return"], None),
        ("folder", "File Manager", "Open Dolphin file manager", ["SUPER", "E"], ["dolphin"]),
        ("search", "App Launcher", "Open application menu", ["SUPER", "D"], None),
    ]),
    ("Appearance", [
        ("image", "Wallpaper Picker", "Select and apply wallpaper", ["SUPER", "SHIFT", "W"], None),
        ("palette", "Bar Theme", "Switch status bar theme", ["SUPER", "CTRL", "W"], None),
    ]),
    ("System", [
        ("sliders", "Settings", "Open Hyprconf settings panel", ["SUPER", "S"], "settings.py"),
        ("refresh", "Package Updater", "Check and apply system updates", ["CTRL", "U"], "pkgupdate-gui.py"),
        ("keyboard", "Keybinds Cheatsheet", "Show all configured shortcuts", ["SUPER", "SHIFT", "H"], None),
    ]),
]

APPS = [
    {
        "icon": "refresh",
        "name": "Package Updater",
        "file": "pkgupdate-gui.py",
        "desc": "Check and install updates for pacman, AUR helpers, and Flatpak packages.",
        "shortcut": ["CTRL", "U"],
    },
    {
        "icon": "sliders",
        "name": "Settings",
        "file": "settings.py",
        "desc": "Customize borders, animations, display resolution, input devices, and keybindings.",
        "shortcut": ["SUPER", "S"],
    },
]

LINKS = [
    ("book", "Hyprland Wiki", "wiki.hypr.land", "https://wiki.hypr.land/"),
    ("book", "Noctalia Docs", "docs.noctalia.dev", "https://docs.noctalia.dev/"),
    ("git-branch", "Hyprconf on GitHub", "shell-ninja/hyprconf", "https://github.com/shell-ninja/hyprconf/tree/noct"),
]


# =============================================================================
#  Helpers
# =============================================================================

def row_icon(name, size=20):
    icon = SvgIcon(name, size)
    icon.add_css_class("row-icon")
    return icon


def make_kbd(keys):
    box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
    box.set_valign(Gtk.Align.CENTER)
    for i, k in enumerate(keys):
        if i > 0:
            sep = Gtk.Label(label="+")
            sep.add_css_class("keycap-separator")
            box.append(sep)
        key_label = Gtk.Label(label=k)
        key_label.add_css_class("keycap")
        box.append(key_label)
    return box


def launch_script(script_name):
    script_path = SCRIPTS_DIR / script_name
    if script_path.exists():
        subprocess.Popen([sys.executable, str(script_path)])


# Hyprland modifier bits, as reported by `hyprctl binds -j`
MOD_BITS = {"SHIFT": 1, "CTRL": 4, "ALT": 8, "SUPER": 64}
IGNORED_MODS = 2 | 16  # caps lock and num lock don't change which bind matches


def find_bind(keys):
    """Find the live Hyprland bind for a key combo like ["SUPER", "SHIFT", "W"]."""
    *mods, key = keys
    wanted = 0
    for mod in mods:
        wanted |= MOD_BITS.get(mod.upper(), 0)
    try:
        result = subprocess.run(
            ["hyprctl", "binds", "-j"], capture_output=True, text=True, timeout=3
        )
        binds = json.loads(result.stdout)
    except Exception:
        return None
    for bind in binds:
        if bind.get("submap") or bind.get("mouse") or bind.get("release"):
            continue
        if (bind.get("modmask", 0) & ~IGNORED_MODS) != wanted:
            continue
        if str(bind.get("key", "")).lower() == key.lower():
            return bind
    return None


def run_bind(bind):
    """Run a bind's dispatcher (usually `exec <command>`) through Hyprland."""
    cmd = ["hyprctl", "dispatch", bind["dispatcher"]]
    if bind.get("arg"):
        cmd.append(bind["arg"])
    subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def run_fallback(fallback):
    """Start the fallback program. Returns False if it can't be started."""
    try:
        if isinstance(fallback, str):
            if not (SCRIPTS_DIR / fallback).exists():
                return False
            launch_script(fallback)
        else:
            subprocess.Popen(fallback, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except OSError:
        return False


def build_page_wrap(inner, valign=Gtk.Align.CENTER):
    clamp = Adw.Clamp()
    clamp.set_maximum_size(620)
    clamp.set_tightening_threshold(420)
    clamp.set_child(inner)

    page_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    page_box.set_valign(valign)
    page_box.set_margin_top(28)
    page_box.set_margin_bottom(28)
    page_box.set_margin_start(24)
    page_box.set_margin_end(24)
    page_box.append(clamp)

    scroller = Gtk.ScrolledWindow()
    scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
    scroller.set_vexpand(True)
    scroller.set_hexpand(True)
    scroller.set_child(page_box)
    return scroller


def get_logo_paintable():
    candidate_paths = [
        LOGO_PATH,
        Path.home() / ".hyprconf" / "hypr" / ".cache" / "shell-ninja.png",
        Path.home() / ".config" / "hypr" / ".cache" / "shell-ninja.png",
    ]
    for path in candidate_paths:
        if path.is_file():
            try:
                return Gdk.Texture.new_from_filename(str(path))
            except Exception:
                pass
    return None


# =============================================================================
#  Pages
# =============================================================================

def page_welcome():
    hero_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
    hero_box.set_halign(Gtk.Align.CENTER)
    hero_box.set_margin_top(8)
    hero_box.set_margin_bottom(12)

    logo = get_logo_paintable()
    avatar = Adw.Avatar(size=160)
    avatar.set_halign(Gtk.Align.CENTER)
    avatar.add_css_class("welcome-logo")
    if logo:
        avatar.set_custom_image(logo)
    else:
        avatar.set_icon_name("preferences-desktop-display-symbolic")
    hero_box.append(avatar)

    title_label = Gtk.Label(label="Welcome to Hyprconf")
    title_label.add_css_class("title-1")
    title_label.set_justify(Gtk.Justification.CENTER)
    title_label.set_wrap(True)
    hero_box.append(title_label)

    desc_label = Gtk.Label(
        label="A customized Hyprland desktop environment with dynamic wallpaper theming, "
        "curated keyboard shortcuts, and built-in system tools."
    )
    desc_label.add_css_class("body")
    desc_label.add_css_class("dim-label")
    desc_label.set_justify(Gtk.Justification.CENTER)
    desc_label.set_wrap(True)
    desc_label.set_max_width_chars(50)
    hero_box.append(desc_label)

    group = Adw.PreferencesGroup()
    group.set_title("Overview")
    group.set_margin_top(8)

    for icon_name, title, subtitle in (
        ("sparkles", "Dynamic Theming", "Colors adapt automatically based on your current wallpaper."),
        ("sliders", "Custom Controls", "Quickly adjust animations, monitors, input, and keybinds in Settings."),
        ("refresh", "Integrated Updates", "Maintain pacman, AUR, and Flatpak packages with the package updater."),
    ):
        row = Adw.ActionRow(title=title, subtitle=subtitle)
        row.add_prefix(row_icon(icon_name))
        group.add(row)

    container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
    container.append(hero_box)
    container.append(group)

    return build_page_wrap(container, valign=Gtk.Align.START)


def page_keybinds(on_activate):
    container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)

    for i, (section_title, entries) in enumerate(KEYBIND_SECTIONS):
        group = Adw.PreferencesGroup()
        group.set_title(section_title)
        if i == 0:
            group.set_description(
                "Click a shortcut to open it. Press Super + Shift + H anytime for the full list."
            )
        for icon_name, title, desc, keys, fallback in entries:
            row = Adw.ActionRow(title=title, subtitle=desc)
            row.add_prefix(row_icon(icon_name))
            row.add_suffix(make_kbd(keys))
            row.set_activatable(True)
            row.set_tooltip_text("Click to open")
            row.connect(
                "activated",
                lambda _row, k=keys, f=fallback, t=title: on_activate(k, f, t),
            )
            group.add(row)
        container.append(group)

    return build_page_wrap(container, valign=Gtk.Align.START)


def page_apps():
    container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)

    group = Adw.PreferencesGroup()
    group.set_title("Built-in Applications")
    group.set_description("Desktop utilities included with your configuration.")

    for app in APPS:
        row = Adw.ActionRow(title=app["name"], subtitle=app["desc"])
        row.add_prefix(row_icon(app["icon"]))

        btn = Gtk.Button(label="Open")
        btn.set_valign(Gtk.Align.CENTER)
        btn.add_css_class("flat")
        btn.connect("clicked", lambda _, f=app["file"]: launch_script(f))

        row.add_suffix(make_kbd(app["shortcut"]))
        row.add_suffix(btn)
        group.add(row)

    container.append(group)

    links_group = Adw.PreferencesGroup()
    links_group.set_title("References")
    links_group.set_description("Helpful documentation and project links.")
    links_group.set_margin_top(8)

    for icon_name, title, subtitle, uri in LINKS:
        row = Adw.ActionRow(title=title, subtitle=subtitle)
        row.add_prefix(row_icon(icon_name))

        link_btn = Gtk.LinkButton.new_with_label(uri, "Visit")
        link_btn.set_valign(Gtk.Align.CENTER)
        link_btn.add_css_class("flat")

        row.add_suffix(link_btn)
        row.set_activatable_widget(link_btn)
        links_group.add(row)

    container.append(links_group)
    return build_page_wrap(container, valign=Gtk.Align.START)


def page_final(on_startup_toggle, initial_show_startup):
    check = SvgIcon("check", 64, 1.6)
    check.add_css_class("hero-icon")
    check.set_margin_top(24)

    title = Gtk.Label(label="You're Ready to Go")
    title.add_css_class("title-1")
    title.set_justify(Gtk.Justification.CENTER)
    title.set_wrap(True)

    desc = Gtk.Label(label="You can explore more shortcuts or customize your desktop at any time.")
    desc.add_css_class("body")
    desc.add_css_class("dim-label")
    desc.set_justify(Gtk.Justification.CENTER)
    desc.set_wrap(True)
    desc.set_max_width_chars(50)

    hero = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
    hero.set_halign(Gtk.Align.CENTER)
    hero.append(check)
    hero.append(title)
    hero.append(desc)

    group = Adw.PreferencesGroup()
    group.set_title("Preferences")
    group.set_margin_top(16)

    switch_row = Adw.SwitchRow()
    switch_row.set_title("Show on startup")
    switch_row.set_subtitle("Launch this welcome app when logging in")
    switch_row.set_active(initial_show_startup)
    switch_row.add_prefix(row_icon("power"))
    switch_row.connect("notify::active", lambda row, _: on_startup_toggle(row.get_active()))
    group.add(switch_row)

    tips_group = Adw.PreferencesGroup()
    tips_group.set_title("Quick Reference")
    tips_group.set_margin_top(12)

    for icon_name, tip_title, subtitle in (
        ("sliders", "Settings Panel", "Press Super + S to modify system appearance and keybinds."),
        ("keyboard", "Keybind Reference", "Press Super + Shift + H to see all active keybindings."),
        ("info", "Reopen Welcome Guide", "Run 'welcome.py' from terminal or app launcher whenever needed."),
    ):
        row = Adw.ActionRow(title=tip_title, subtitle=subtitle)
        row.add_prefix(row_icon(icon_name))
        tips_group.add(row)

    container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
    container.append(hero)
    container.append(group)
    container.append(tips_group)

    return build_page_wrap(container, valign=Gtk.Align.START)


# =============================================================================
#  Window
# =============================================================================

class WelcomeWindow(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(
            application=app,
            title="Welcome to Hyprconf",
            default_width=720,
            default_height=640,
        )
        self.set_size_request(460, 480)
        self.state = load_state()
        self._build_ui()

    def _build_ui(self):
        tv = Adw.ToolbarView()
        self.toasts = Adw.ToastOverlay()
        self.toasts.set_child(tv)
        self.set_content(self.toasts)

        hb = Adw.HeaderBar()
        hb.set_title_widget(Adw.WindowTitle(title="Welcome to Hyprconf", subtitle="Getting Started"))
        hb.set_show_end_title_buttons(True)
        tv.add_top_bar(hb)

        self.carousel = Adw.Carousel()
        self.carousel.set_vexpand(True)
        self.carousel.set_hexpand(True)
        self.carousel.set_spacing(0)
        # Disable scroll wheel page-switching to avoid unexpected transitions when scrolling content
        self.carousel.set_allow_scroll_wheel(False)
        self.carousel.set_allow_mouse_drag(False)
        self.carousel.set_allow_long_swipes(True)
        self.carousel.connect("page-changed", self._on_page_changed)

        self.carousel.append(page_welcome())
        self.carousel.append(page_keybinds(self._on_keybind_activated))
        self.carousel.append(page_apps())
        self.carousel.append(
            page_final(
                self._on_startup_toggle,
                self.state.get("show_on_startup", True),
            )
        )

        tv.set_content(self.carousel)

        nav = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        nav.add_css_class("nav-bar")

        self.skip_btn = Gtk.Button(label="Skip")
        self.skip_btn.add_css_class("flat")
        self.skip_btn.connect("clicked", lambda _: self.close())
        nav.append(self.skip_btn)

        dots = Adw.CarouselIndicatorDots()
        dots.set_carousel(self.carousel)
        dots.set_hexpand(True)
        dots.set_halign(Gtk.Align.CENTER)
        nav.append(dots)

        self.back_btn = Gtk.Button(label="Back")
        self.back_btn.connect("clicked", self._go_back)
        self.back_btn.set_sensitive(False)
        nav.append(self.back_btn)

        self.next_btn = Gtk.Button(label="Next")
        self.next_btn.add_css_class("suggested-action")
        self.next_btn.connect("clicked", self._go_next)
        nav.append(self.next_btn)

        tv.add_bottom_bar(nav)

        keys = Gtk.EventControllerKey()
        keys.connect("key-pressed", self._on_key)
        self.add_controller(keys)

    def _current_index(self):
        return int(round(self.carousel.get_position()))

    def _on_page_changed(self, carousel, index):
        n = carousel.get_n_pages()
        self.back_btn.set_sensitive(index > 0)
        if index == n - 1:
            self.next_btn.set_label("Done")
            self.skip_btn.set_visible(False)
        else:
            self.next_btn.set_label("Next")
            self.skip_btn.set_visible(True)

    def _go_next(self, _btn):
        idx = self._current_index()
        n = self.carousel.get_n_pages()
        if idx >= n - 1:
            self.close()
            return
        target = self.carousel.get_nth_page(idx + 1)
        self.carousel.scroll_to(target, True)

    def _go_back(self, _btn):
        idx = self._current_index()
        if idx <= 0:
            return
        target = self.carousel.get_nth_page(idx - 1)
        self.carousel.scroll_to(target, True)

    def _on_key(self, _controller, keyval, _keycode, state):
        if state & (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.ALT_MASK):
            return False
        idx = self._current_index()
        n = self.carousel.get_n_pages()
        if keyval == Gdk.KEY_Right and idx < n - 1:
            self._go_next(None)
            return True
        if keyval == Gdk.KEY_Left and idx > 0:
            self._go_back(None)
            return True
        if keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    def _on_keybind_activated(self, keys, fallback, title):
        bind = find_bind(keys)
        if bind:
            run_bind(bind)
        elif fallback and run_fallback(fallback):
            pass
        else:
            self.toasts.add_toast(
                Adw.Toast.new(f"Couldn't find the {title} shortcut in your Hyprland config")
            )

    def _on_startup_toggle(self, show_on_startup):
        self.state["show_on_startup"] = show_on_startup
        save_state(self.state)


class WelcomeApp(Adw.Application):
    def __init__(self):
        super().__init__(
            application_id="dev.shellninja.welcome",
            flags=Gio.ApplicationFlags.FLAGS_NONE,
        )
        self.connect("activate", self.on_activate)

    def on_activate(self, app):
        provider = Gtk.CssProvider()
        provider.load_from_string(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )
        win = WelcomeWindow(app)
        win.present()


def main():
    if "--autostart" in sys.argv:
        if not load_state().get("show_on_startup", True):
            return
    app = WelcomeApp()
    sys.exit(app.run([a for a in sys.argv if a != "--autostart"]))


if __name__ == "__main__":
    main()
