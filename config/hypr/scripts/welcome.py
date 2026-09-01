#!/usr/bin/env python3
# =============================================================================
#  welcome.py — GTK4 / Libadwaita welcome app for Hyprconf
# =============================================================================

import json
import os
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Adw, Gdk, Gio, GLib, Gtk, Pango

STATE_FILE = Path.home() / ".hyprconf" / "hypr" / "welcome-app.json"
SCRIPTS_DIR = Path(__file__).resolve().parent


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


CSS = """
* { font-family: 'Inter', system-ui, sans-serif; }

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
"""

KEYBINDS = [
    ("utilities-terminal-symbolic", "Terminal", "Launch Kitty terminal", ["SUPER", "Return"]),
    ("view-restore-symbolic", "Floating Terminal", "Launch Kitty in floating window", ["SUPER", "SHIFT", "Return"]),
    ("system-file-manager-symbolic", "File Manager", "Open Dolphin file manager", ["SUPER", "E"]),
    ("system-search-symbolic", "App Launcher", "Open application menu", ["SUPER", "D"]),
    ("preferences-desktop-wallpaper-symbolic", "Wallpaper Picker", "Select and apply wallpaper", ["SUPER", "SHIFT", "W"]),
    ("preferences-desktop-theme-symbolic", "Bar Theme", "Switch status bar theme", ["SUPER", "CTRL", "W"]),
    ("preferences-system-symbolic", "Settings", "Open Hyprconf settings panel", ["SUPER", "S"]),
    ("software-update-available-symbolic", "Package Updater", "Check and apply system updates", ["CTRL", "U"]),
    ("help-about-symbolic", "Keybinds Cheatsheet", "Show all configured shortcuts", ["SUPER", "SHIFT", "H"]),
]

APPS = [
    {
        "icon": "software-update-available-symbolic",
        "name": "Package Updater",
        "file": "pkgupdate-gui.py",
        "desc": "Check and install updates for pacman, AUR helpers, and Flatpak packages.",
        "shortcut": ["CTRL", "U"],
    },
    {
        "icon": "preferences-system-symbolic",
        "name": "Settings",
        "file": "settings.py",
        "desc": "Customize borders, animations, display resolution, input devices, and keybindings.",
        "shortcut": ["SUPER", "S"],
    },
]


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


def page_welcome():
    status = Adw.StatusPage()
    status.set_icon_name("preferences-desktop-display-symbolic")
    status.set_title("Welcome to Hyprconf")
    status.set_description(
        "A customized Hyprland desktop environment with dynamic wallpaper theming, "
        "curated keyboard shortcuts, and built-in system tools."
    )

    group = Adw.PreferencesGroup()
    group.set_title("Overview")
    group.set_margin_top(18)

    row1 = Adw.ActionRow(
        title="Dynamic Theming",
        subtitle="Colors adapt automatically based on your current wallpaper.",
    )
    row1.add_prefix(Gtk.Image.new_from_icon_name("preferences-desktop-theme-symbolic"))
    group.add(row1)

    row2 = Adw.ActionRow(
        title="Custom Controls",
        subtitle="Quickly adjust animations, monitors, input, and keybinds in Settings.",
    )
    row2.add_prefix(Gtk.Image.new_from_icon_name("preferences-system-symbolic"))
    group.add(row2)

    row3 = Adw.ActionRow(
        title="Integrated Updates",
        subtitle="Maintain pacman, AUR, and Flatpak packages with the package updater.",
    )
    row3.add_prefix(Gtk.Image.new_from_icon_name("software-update-available-symbolic"))
    group.add(row3)

    container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
    container.append(status)
    container.append(group)

    return build_page_wrap(container, valign=Gtk.Align.START)


def page_keybinds():
    container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)

    group = Adw.PreferencesGroup()
    group.set_title("Essential Shortcuts")
    group.set_description("Frequently used shortcuts. Press Super + Shift + H anytime for the full list.")

    for icon, title, desc, keys in KEYBINDS:
        row = Adw.ActionRow(title=title, subtitle=desc)
        img = Gtk.Image.new_from_icon_name(icon)
        row.add_prefix(img)
        row.add_suffix(make_kbd(keys))
        group.add(row)

    container.append(group)
    return build_page_wrap(container, valign=Gtk.Align.START)


def page_apps():
    container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)

    group = Adw.PreferencesGroup()
    group.set_title("Built-in Applications")
    group.set_description("Desktop utilities included with your configuration.")

    for app in APPS:
        row = Adw.ActionRow(title=app["name"], subtitle=app["desc"])
        img = Gtk.Image.new_from_icon_name(app["icon"])
        row.add_prefix(img)

        btn = Gtk.Button(label="Open")
        btn.set_valign(Gtk.Align.CENTER)
        btn.add_css_class("flat")
        btn.connect("clicked", lambda _, f=app["file"]: launch_script(f))

        row.add_suffix(make_kbd(app["shortcut"]))
        row.add_suffix(btn)
        group.add(row)

    container.append(group)
    return build_page_wrap(container, valign=Gtk.Align.START)


def page_final(on_startup_toggle, initial_show_startup):
    status = Adw.StatusPage()
    status.set_icon_name("emblem-ok-symbolic")
    status.set_title("You're Ready to Go")
    status.set_description(
        "You can explore more shortcuts or customize your desktop at any time."
    )

    group = Adw.PreferencesGroup()
    group.set_title("Preferences")
    group.set_margin_top(16)

    switch_row = Adw.SwitchRow()
    switch_row.set_title("Show on startup")
    switch_row.set_subtitle("Launch this welcome app when logging in")
    switch_row.set_active(initial_show_startup)
    switch_row.connect("notify::active", lambda row, _: on_startup_toggle(row.get_active()))
    group.add(switch_row)

    tips_group = Adw.PreferencesGroup()
    tips_group.set_title("Quick Reference")
    tips_group.set_margin_top(12)

    tip1 = Adw.ActionRow(
        title="Settings Panel",
        subtitle="Press Super + S to modify system appearance and keybinds.",
    )
    tip1.add_prefix(Gtk.Image.new_from_icon_name("preferences-system-symbolic"))
    tips_group.add(tip1)

    tip2 = Adw.ActionRow(
        title="Keybind Reference",
        subtitle="Press Super + Shift + H to see all active keybindings.",
    )
    tip2.add_prefix(Gtk.Image.new_from_icon_name("help-about-symbolic"))
    tips_group.add(tip2)

    tip3 = Adw.ActionRow(
        title="Reopen Welcome Guide",
        subtitle="Run 'welcome.py' from terminal or app launcher whenever needed.",
    )
    tip3.add_prefix(Gtk.Image.new_from_icon_name("dialog-information-symbolic"))
    tips_group.add(tip3)

    container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
    container.append(status)
    container.append(group)
    container.append(tips_group)

    return build_page_wrap(container, valign=Gtk.Align.START)


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
        self.set_content(tv)

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
        self.carousel.append(page_keybinds())
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
