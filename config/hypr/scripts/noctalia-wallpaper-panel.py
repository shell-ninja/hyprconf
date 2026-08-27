#!/usr/bin/env python3
"""
noctalia-wallpaper-panel.py
Caelestia-styled floating bottom wallpaper selection panel for Noctalia Shell.
Features:
- Live wallpaper switching on hover / keyboard selection (similar to Caelestia Shell)
- Dark glassmorphism card aesthetic matching Caelestia shell
- 5-column horizontal thumbnail carousel with glowing active border
- Bottom search bar with '>wallpaper' placeholder and instant filtering
- Escape restores original wallpaper; Enter/Click confirms and applies dynamic colors
"""

import os
import sys
import glob
import subprocess
import threading
import gi

gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
gi.require_version('GtkLayerShell', '0.1')

from gi.repository import Gtk, Gdk, GdkPixbuf, GtkLayerShell, GLib, Pango

WALLPAPER_DIR = os.path.expanduser("~/.hyprconf/hypr/Wallpaper")
CACHE_DIR = os.path.expanduser("~/.hyprconf/hypr/.cache")
WALL_CACHE_FILE = os.path.join(CACHE_DIR, ".wallpaper")
CURRENT_WALL_LINK = os.path.join(CACHE_DIR, "current_wallpaper.png")
SCRIPTS_DIR = os.path.expanduser("~/.hyprconf/hypr/scripts")
COLORS_SCRIPT = os.path.join(SCRIPTS_DIR, "noctalia-colors.sh")

# CSS Styling matching Caelestia Shell Wallpaper Panel
CSS = b"""
* {
    all: unset;
    font-family: 'JetBrainsMono Nerd Font', 'Fira Code', sans-serif;
}

window {
    background-color: transparent;
}

.main-container {
    background-color: rgba(18, 18, 26, 0.92);
    border: 1px solid rgba(255, 255, 255, 0.10);
    border-radius: 20px;
    padding: 14px 18px 12px 18px;
    box-shadow: 0 16px 40px rgba(0, 0, 0, 0.65);
}

.wallpaper-card {
    border-radius: 14px;
    padding: 4px;
    margin: 4px 6px;
    transition: all 150ms ease;
    background-color: transparent;
}

.wallpaper-image-box {
    border-radius: 12px;
    border: 2px solid transparent;
    transition: all 180ms cubic-bezier(0.2, 0.8, 0.2, 1);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.35);
}

.wallpaper-card:hover .wallpaper-image-box,
.wallpaper-card.selected .wallpaper-image-box {
    border: 2px solid #b4befe;
    box-shadow: 0 0 16px rgba(180, 190, 254, 0.55), 0 6px 16px rgba(0, 0, 0, 0.5);
}

.wallpaper-title {
    color: #a6adc8;
    font-size: 11px;
    font-weight: 500;
    margin-top: 6px;
    margin-bottom: 2px;
    transition: color 150ms ease;
}

.wallpaper-card:hover .wallpaper-title,
.wallpaper-card.selected .wallpaper-title {
    color: #cdd6f4;
    font-weight: 700;
}

.search-bar {
    background-color: rgba(30, 30, 46, 0.75);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 10px;
    padding: 6px 12px;
    margin-top: 10px;
}

.search-icon {
    color: #89b4fa;
    font-size: 13px;
    margin-right: 8px;
}

.search-entry {
    color: #cdd6f4;
    font-size: 12px;
    background: transparent;
    border: none;
}

.search-entry:focus {
    outline: none;
}

.clear-btn {
    color: #6c7086;
    font-size: 12px;
    padding: 2px 6px;
    border-radius: 6px;
}

.clear-btn:hover {
    color: #f38ba8;
    background-color: rgba(243, 139, 168, 0.15);
}

scrollbar, scrollbar trough {
    background: transparent;
    border: none;
}

scrollbar slider {
    background: rgba(255, 255, 255, 0.15);
    border-radius: 4px;
    min-height: 4px;
    min-width: 4px;
}

scrollbar slider:hover {
    background: rgba(180, 190, 254, 0.4);
}
"""

class WallpaperPanel(Gtk.Window):
    def __init__(self):
        super().__init__()
        
        # Determine current wallpaper for preview restoration on Esc
        self.original_wallpaper = self.get_current_wallpaper()
        self.active_wallpaper = self.original_wallpaper
        self.confirmed = False
        
        # Detect wallpaper engine (awww or swww)
        self.engine = "awww" if self.cmd_exists("awww") else ("swww" if self.cmd_exists("swww") else None)
        
        # Load wallpapers
        self.wallpapers = self.scan_wallpapers()
        self.filtered_wallpapers = list(self.wallpapers)
        
        self.card_widgets = []
        self.selected_index = 0

        # Initialize Window & LayerShell
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.BOTTOM, 24)
        GtkLayerShell.set_namespace(self, "noctalia-wallpaper-panel")

        self.set_default_size(940, 230)
        self.set_resizable(False)

        # Apply CSS
        self.apply_css()

        # Build UI
        self.build_ui()

        # Connect Events
        self.connect("key-press-event", self.on_key_press)
        self.connect("destroy", self.on_destroy)

        # Find initially selected wallpaper
        for i, w in enumerate(self.filtered_wallpapers):
            if self.original_wallpaper and os.path.basename(w) == os.path.basename(self.original_wallpaper):
                self.selected_index = i
                break

        GLib.idle_add(self.update_selection_highlight)

    def cmd_exists(self, cmd):
        return subprocess.call(f"type {cmd}", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE) == 0

    def get_current_wallpaper(self):
        if os.path.islink(CURRENT_WALL_LINK):
            return os.path.realpath(CURRENT_WALL_LINK)
        if os.path.exists(WALL_CACHE_FILE):
            with open(WALL_CACHE_FILE, "r") as f:
                name = f.read().strip()
                matches = glob.glob(os.path.join(WALLPER_DIR := WALLPAPER_DIR, f"{name}.*"))
                if matches:
                    return matches[0]
        return None

    def scan_wallpapers(self):
        exts = ("*.jpg", "*.jpeg", "*.png", "*.gif", "*.webp")
        walls = []
        for ext in exts:
            walls.extend(glob.glob(os.path.join(WALLPAPER_DIR, ext)))
        walls.sort(key=lambda x: os.path.basename(x).lower())
        return walls

    def apply_css(self):
        screen = Gdk.Screen.get_default()
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def build_ui(self):
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        main_box.get_style_context().add_class("main-container")
        self.add(main_box)

        # Horizontal Scroll Area for Thumbnails
        self.scroll = Gtk.ScrolledWindow()
        self.scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.NEVER)
        self.scroll.set_min_content_width(900)
        self.scroll.set_min_content_height(148)
        self.scroll.set_shadow_type(Gtk.ShadowType.NONE)

        self.cards_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.cards_box.set_halign(Gtk.Align.CENTER)
        self.scroll.add(self.cards_box)
        main_box.pack_start(self.scroll, True, True, 0)

        # Populate Cards
        self.populate_cards()

        # Bottom Search Bar
        search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        search_box.get_style_context().add_class("search-bar")

        icon_label = Gtk.Label(label="")
        icon_label.get_style_context().add_class("search-icon")
        search_box.pack_start(icon_label, False, False, 0)

        self.entry = Gtk.Entry()
        self.entry.set_placeholder_text(">wallpaper")
        self.entry.get_style_context().add_class("search-entry")
        self.entry.set_hexpand(True)
        self.entry.connect("changed", self.on_search_changed)
        search_box.pack_start(self.entry, True, True, 0)

        clear_btn = Gtk.Button(label="✕")
        clear_btn.get_style_context().add_class("clear-btn")
        clear_btn.connect("clicked", lambda b: self.entry.set_text(""))
        search_box.pack_end(clear_btn, False, False, 0)

        main_box.pack_end(search_box, False, False, 0)

    def populate_cards(self):
        for child in self.cards_box.get_children():
            self.cards_box.remove(child)
        self.card_widgets.clear()

        for idx, wall_path in enumerate(self.filtered_wallpapers):
            card = Gtk.EventBox()
            card.set_above_child(True)
            card.get_style_context().add_class("wallpaper-card")

            inner_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            inner_box.set_halign(Gtk.Align.CENTER)

            # Thumbnail Image Box
            img_box = Gtk.EventBox()
            img_box.get_style_context().add_class("wallpaper-image-box")
            
            # Load Scaled Pixbuf (160x90 - 16:9 ratio)
            try:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(wall_path, 160, 92, False)
                image = Gtk.Image.new_from_pixbuf(pixbuf)
            except Exception:
                image = Gtk.Image.new_from_icon_name("image-missing", Gtk.IconSize.DIALOG)

            img_box.add(image)
            inner_box.pack_start(img_box, False, False, 0)

            # Wallpaper title underneath
            base_name = os.path.splitext(os.path.basename(wall_path))[0]
            title_label = Gtk.Label(label=base_name)
            title_label.get_style_context().add_class("wallpaper-title")
            title_label.set_ellipsize(Pango.EllipsizeMode.END)
            title_label.set_max_width_chars(18)
            inner_box.pack_start(title_label, False, False, 0)

            card.add(inner_box)

            # Hover & Click handling
            card.connect("enter-notify-event", self.on_card_hover, idx)
            card.connect("button-press-event", self.on_card_clicked, idx)

            self.cards_box.pack_start(card, False, False, 0)
            self.card_widgets.append((card, wall_path))

        self.cards_box.show_all()

    def update_selection_highlight(self):
        if not self.card_widgets:
            return
        self.selected_index = max(0, min(self.selected_index, len(self.card_widgets) - 1))
        for i, (card, _) in enumerate(self.card_widgets):
            ctx = card.get_style_context()
            if i == self.selected_index:
                ctx.add_class("selected")
                # Scroll into view
                adj = self.scroll.get_hadjustment()
                alloc = card.get_allocation()
                if alloc.x > 0:
                    val = alloc.x - (self.scroll.get_allocated_width() / 2) + (alloc.width / 2)
                    adj.set_value(max(0, val))
            else:
                ctx.remove_class("selected")

    def preview_wallpaper(self, path):
        if not path or not os.path.exists(path) or path == self.active_wallpaper:
            return
        self.active_wallpaper = path
        
        # Fast live preview via awww or swww
        def _preview():
            if self.engine:
                params = "--transition-fps 120 --transition-type any --transition-duration 0.5 --transition-bezier .28,.58,.99,.37"
                subprocess.run(f"{self.engine} img '{path}' {params}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            # Notify Noctalia shell
            subprocess.run(f"noctalia msg wallpaper-set '{path}' 2>/dev/null || true", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        threading.Thread(target=_preview, daemon=True).start()

    def confirm_wallpaper(self, path):
        self.confirmed = True
        self.active_wallpaper = path
        
        # Save cache and apply colors asynchronously
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

        # Notify Noctalia & run colors script
        def _apply():
            if self.engine:
                params = "--transition-fps 120 --transition-type any --transition-duration 1.0 --transition-bezier .28,.58,.99,.37"
                subprocess.run(f"{self.engine} img '{path}' {params}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(f"noctalia msg wallpaper-set '{path}' 2>/dev/null || true", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(f"'{COLORS_SCRIPT}' '{path}' &>/dev/null &", shell=True)

        threading.Thread(target=_apply, daemon=True).start()
        Gtk.main_quit()

    def on_card_hover(self, widget, event, idx):
        self.selected_index = idx
        self.update_selection_highlight()
        if idx < len(self.card_widgets):
            _, path = self.card_widgets[idx]
            self.preview_wallpaper(path)

    def on_card_clicked(self, widget, event, idx):
        if idx < len(self.card_widgets):
            _, path = self.card_widgets[idx]
            self.confirm_wallpaper(path)

    def on_search_changed(self, entry):
        text = entry.get_text().strip().lower()
        if not text:
            self.filtered_wallpapers = list(self.wallpapers)
        else:
            self.filtered_wallpapers = [
                w for w in self.wallpapers if text in os.path.basename(w).lower()
            ]
        self.selected_index = 0
        self.populate_cards()
        self.update_selection_highlight()
        if self.card_widgets:
            _, path = self.card_widgets[0]
            self.preview_wallpaper(path)

    def on_key_press(self, widget, event):
        key = event.keyval
        
        # Escape: cancel and restore original
        if key == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True

        # Return: confirm selection
        if key in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            if self.card_widgets and self.selected_index < len(self.card_widgets):
                _, path = self.card_widgets[self.selected_index]
                self.confirm_wallpaper(path)
            return True

        # Left / Right Arrow Navigation
        if key in (Gdk.KEY_Left, Gdk.KEY_h):
            if self.card_widgets:
                self.selected_index = (self.selected_index - 1) % len(self.card_widgets)
                self.update_selection_highlight()
                _, path = self.card_widgets[self.selected_index]
                self.preview_wallpaper(path)
            return True

        if key in (Gdk.KEY_Right, Gdk.KEY_l):
            if self.card_widgets:
                self.selected_index = (self.selected_index + 1) % len(self.card_widgets)
                self.update_selection_highlight()
                _, path = self.card_widgets[self.selected_index]
                self.preview_wallpaper(path)
            return True

        return False

    def on_destroy(self, widget):
        # If user closed without confirming, restore the original wallpaper
        if not self.confirmed and self.original_wallpaper and self.active_wallpaper != self.original_wallpaper:
            if self.engine:
                subprocess.run(f"{self.engine} img '{self.original_wallpaper}' --transition-fps 120 --transition-type any --transition-duration 0.5", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(f"noctalia msg wallpaper-set '{self.original_wallpaper}' 2>/dev/null || true", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        Gtk.main_quit()

def main():
    # Toggle behavior: if already running, kill existing instance and exit
    pid = os.getpid()
    res = subprocess.run(f"pgrep -f 'noctalia-wallpaper-panel.py' | grep -v '^{pid}$'", shell=True, stdout=subprocess.PIPE, text=True)
    if res.stdout.strip():
        for p in res.stdout.strip().split('\n'):
            if p:
                subprocess.run(f"kill -9 {p}", shell=True)
        sys.exit(0)

    win = WallpaperPanel()
    win.show_all()
    Gtk.main()

if __name__ == '__main__':
    main()
