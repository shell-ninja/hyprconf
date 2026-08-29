#!/usr/bin/env python3
"""
noctalia-wallpaper-panel.py
Caelestia-styled floating bottom wallpaper selection panel for Noctalia Shell.
Features:
- Live wallpaper switching on hover / keyboard selection (similar to Caelestia Shell)
- Dark glassmorphism card aesthetic matching Caelestia shell
- Cover Flow style carousel: focused wallpaper sits flat & glowing in the
  centre, flanking wallpapers lean away (sheared), shrink and fade with
  distance, and everything eases smoothly between selections
- Bottom search bar with '>wallpaper' placeholder and instant filtering
- Colours (accents, glow, chrome) follow Noctalia's currently active colour
  scheme (~/.config/noctalia/colors.json) - preset or wallpaper-generated
- Escape restores original wallpaper; Enter/Click confirms and applies dynamic colors
"""

import os
import sys
import glob
import json
import math
import signal
import hashlib
import subprocess
import threading
import concurrent.futures
import cairo
import gi

gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
gi.require_version('PangoCairo', '1.0')

from gi.repository import Gtk, Gdk, GdkPixbuf, GtkLayerShell, GLib, Pango, PangoCairo

WALLPAPER_DIR = os.path.expanduser("~/.hyprconf/hypr/Wallpaper")
CACHE_DIR = os.path.expanduser("~/.hyprconf/hypr/.cache")
WALL_CACHE_FILE = os.path.join(CACHE_DIR, ".wallpaper")
CURRENT_WALL_LINK = os.path.join(CACHE_DIR, "current_wallpaper.png")
SCRIPTS_DIR = os.path.expanduser("~/.hyprconf/hypr/scripts")
COLORS_SCRIPT = os.path.join(SCRIPTS_DIR, "noctalia-colors.sh")

# On-disk thumbnail cache so repeat launches don't re-decode full-resolution
# wallpapers - only the (much smaller/cheaper) cached thumbnail is read.
THUMB_CACHE_DIR = os.path.expanduser("~/.cache/noctalia-wallpaper-panel/thumbnails")
THUMB_W, THUMB_H = 336, 192  # 2x the base card size, for sharpness on the centre card

# ---- Cover flow layout tuning ----------------------------------------------
CARD_W, CARD_H = 168, 96      # base (centre) thumbnail size in px
CARD_RADIUS = 12              # thumbnail corner radius
SPACING = 128                 # horizontal distance between card centres
SCALE_STEP = 0.14             # size falloff per step away from centre
MIN_SCALE = 0.46
OPACITY_STEP = 0.20           # fade falloff per step away from centre
MIN_OPACITY = 0.22
SHEAR = 0.55                  # how strongly flanking cards lean
MAX_VISIBLE_OFFSET = 5        # cards drawn on each side of centre

# Noctalia writes its currently-active, resolved colour scheme here -
# whether it came from a predefined palette or was generated from the
# wallpaper (matugen). It's a flat set of Material-style role -> hex colour.
NOCTALIA_COLORS_FILE = os.path.expanduser("~/.config/noctalia/colors.json")

# Bundled fallback, used only if colors.json is missing/unreadable so the
# panel still looks reasonable before Noctalia has ever generated a scheme.
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


def load_noctalia_palette():
    """Read Noctalia's currently-applied colour scheme. Falls back to
    DEFAULT_PALETTE (in whole or per-key) on any error."""
    palette = dict(DEFAULT_PALETTE)
    try:
        with open(NOCTALIA_COLORS_FILE, "r") as f:
            data = json.load(f)
        # Saved *palette definitions* (predefined/community schemes) nest
        # colours under "dark"/"light"; the live "currently applied" file
        # Noctalia maintains at runtime is flat. Handle both shapes.
        if isinstance(data, dict) and ("dark" in data or "light" in data):
            data = data.get("dark") or data.get("light") or {}
        if isinstance(data, dict):
            for key in palette:
                value = data.get(key)
                if isinstance(value, str) and value.startswith("#"):
                    palette[key] = value
    except Exception:
        pass  # keep the bundled default
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

window {{
    background-color: transparent;
}}

.main-container {{
    background-color: {_rgba_css(p['mSurface'], 0.92)};
    border: 1px solid {_rgba_css(p['mOutline'], 0.35)};
    border-radius: 20px;
    padding: 14px 18px 12px 18px;
    box-shadow: 0 16px 40px rgba(0, 0, 0, 0.65);
}}

.search-bar {{
    background-color: {_rgba_css(p['mSurfaceVariant'], 0.75)};
    border: 1px solid {_rgba_css(p['mOutline'], 0.3)};
    border-radius: 10px;
    padding: 6px 12px;
    margin-top: 10px;
    transition: border-color 260ms ease, box-shadow 260ms ease;
}}

.search-bar:focus-within {{
    border-color: {_rgba_css(p['mPrimary'], 0.45)};
    box-shadow: 0 0 16px {_rgba_css(p['mPrimary'], 0.25)};
}}

.search-icon {{
    color: {p['mPrimary']};
    font-size: 13px;
    margin-right: 8px;
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
""".encode()


class CoverFlow(Gtk.DrawingArea):
    """Custom-drawn cover-flow carousel: the focused thumbnail sits flat and
    highlighted in the centre, everything else leans away (sheared), shrinks
    and fades the further it is from the centre - similar to iTunes' old
    Cover Flow. Pure 2D Cairo affine transforms (no perspective needed)."""

    def __init__(self, on_preview, on_activate, palette):
        super().__init__()
        self.on_preview = on_preview
        self.on_activate = on_activate

        self.color_selected = _hex_to_rgb(palette["mPrimary"])
        self.color_hover = _hex_to_rgb(palette.get("mHover") or palette["mSecondary"])
        self.color_title = _hex_to_rgb(palette["mOnSurface"])
        self.color_muted = _hex_to_rgb(palette["mOnSurfaceVariant"])
        self.color_surface_variant = _hex_to_rgb(palette["mSurfaceVariant"])
        self.color_outline = _hex_to_rgb(palette["mOutline"])

        self.items = []             # file paths currently shown
        self.selected_index = 0     # authoritative index (keyboard/hover/click target)
        self.visual_position = 0.0  # animated float that eases towards selected_index
        self.hover_index = None

        self._pixbuf_cache = {}   # path -> Pixbuf (loaded) or None (confirmed failed)
        self._loading = set()     # paths with a background decode already in flight
        self._tick_id = None
        self._last_frame_time = None

        os.makedirs(THUMB_CACHE_DIR, exist_ok=True)
        self._executor = concurrent.futures.ThreadPoolExecutor(max_workers=4, thread_name_prefix="thumb-load")

        self.set_size_request(-1, 190)
        self.set_can_focus(False)

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

    # -- data -----------------------------------------------------------
    def set_items(self, items, keep_path=None):
        self.items = items
        if not items:
            self.selected_index = 0
            self.visual_position = 0.0
            self.queue_draw()
            return
        idx = 0
        if keep_path:
            for i, p in enumerate(items):
                if os.path.basename(p) == os.path.basename(keep_path):
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

    def get_selected_path(self):
        if self.items and 0 <= self.selected_index < len(self.items):
            return self.items[self.selected_index]
        return None

    # -- pixbuf cache (async, backed by an on-disk thumbnail cache) --------
    def _thumb_cache_path(self, path):
        try:
            mtime = int(os.path.getmtime(path))
        except OSError:
            mtime = 0
        digest = hashlib.sha1(f"{path}:{mtime}:{THUMB_W}x{THUMB_H}".encode()).hexdigest()
        return os.path.join(THUMB_CACHE_DIR, f"{digest}.png")

    def _request_pixbuf(self, path):
        """Kick off a background load for `path` if it isn't cached or already
        loading. Never blocks - the main thread must not decode images itself,
        that's what made opening the panel feel slow."""
        if path in self._pixbuf_cache or path in self._loading:
            return
        self._loading.add(path)
        self._executor.submit(self._load_pixbuf_worker, path)

    def _load_pixbuf_worker(self, path):
        pb = None
        try:
            thumb_path = self._thumb_cache_path(path)
            if os.path.exists(thumb_path):
                pb = GdkPixbuf.Pixbuf.new_from_file(thumb_path)
            else:
                pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, THUMB_W, THUMB_H, False)
                try:
                    pb.savev(thumb_path, "png", [], [])
                except Exception:
                    pass  # cache write failing is fine, just slower next time
        except Exception:
            pb = None
        GLib.idle_add(self._on_pixbuf_ready, path, pb)

    def _on_pixbuf_ready(self, path, pb):
        self._pixbuf_cache[path] = pb
        self._loading.discard(path)
        self.queue_draw()
        return False

    # -- animation --------------------------------------------------------
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

        speed = 1 - math.exp(-dt * 14.0)  # framerate-independent ease-out
        self.visual_position += diff * speed
        self.queue_draw()
        return True

    # -- geometry helpers ---------------------------------------------------
    def _card_transform(self, offset):
        alloc = self.get_allocation()
        cx = alloc.width / 2.0
        cy = alloc.height / 2.0 - 6

        dist = abs(offset)
        scale = max(MIN_SCALE, 1.0 - dist * SCALE_STEP)
        opacity = max(MIN_OPACITY, 1.0 - dist * OPACITY_STEP)
        shear = 0.0 if dist < 0.001 else math.copysign(SHEAR, offset) * min(1.0, dist)

        x = cx + offset * SPACING
        y = cy
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

    # -- drawing ------------------------------------------------------------
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
            layout.set_text("No wallpapers found", -1)
            _, h = layout.get_pixel_size()
            cr.move_to(16, alloc.height / 2 - h / 2)
            cr.set_source_rgba(*self.color_muted, 0.75)
            PangoCairo.show_layout(cr, layout)
            return

        offsets = [i for i in self._visible_offsets() if 0 <= i < len(self.items)]
        # painter's algorithm: farthest-from-centre cards first, centre drawn last (on top)
        offsets.sort(key=lambda i: -abs(i - self.visual_position))
        for i in offsets:
            self._draw_card(cr, i, i - self.visual_position)

    def _draw_card(self, cr, index, offset):
        path = self.items[index]
        x, y, scale, shear, opacity = self._card_transform(offset)
        is_selected = index == self.selected_index
        is_hover = index == self.hover_index

        cr.save()
        cr.translate(x, y)
        cr.scale(scale, scale)
        cr.transform(cairo.Matrix(1, 0, shear, 1, 0, 0))

        # Soft glow behind the focused card only
        if is_selected:
            glow = self.color_hover if (is_hover and self.hover_index != self.selected_index) else self.color_selected
            for pad, alpha in ((14, 0.05), (8, 0.10), (3, 0.16)):
                cr.save()
                self._rounded_rect(cr, CARD_W + pad * 2, CARD_H + pad * 2, CARD_RADIUS + pad / 2)
                cr.set_source_rgba(*glow, alpha)
                cr.fill()
                cr.restore()

        # Thumbnail, clipped to a rounded rect
        cr.save()
        self._rounded_rect(cr, CARD_W, CARD_H, CARD_RADIUS)
        cr.clip()
        cr.set_source_rgba(*self.color_surface_variant, 1.0)
        cr.paint()
        pb = self._pixbuf_cache.get(path)
        if pb is None:
            self._request_pixbuf(path)  # no-op if already cached/loading
        if pb is not None:
            s = max(CARD_W / pb.get_width(), CARD_H / pb.get_height())
            cr.save()
            cr.scale(s, s)
            Gdk.cairo_set_source_pixbuf(cr, pb, -pb.get_width() / 2, -pb.get_height() / 2)
            cr.paint_with_alpha(opacity)
            cr.restore()
        elif path in self._pixbuf_cache:
            # background load finished but the image genuinely failed to decode
            layout = PangoCairo.create_layout(cr)
            layout.set_text("?", -1)
            w, h = layout.get_pixel_size()
            cr.move_to(-w / 2, -h / 2)
            cr.set_source_rgba(*self.color_muted, opacity)
            PangoCairo.show_layout(cr, layout)
        # else: still loading in the background - leave the plain fill as a placeholder
        cr.restore()

        # Border
        self._rounded_rect(cr, CARD_W, CARD_H, CARD_RADIUS)
        if is_selected:
            cr.set_source_rgba(*self.color_selected, min(1.0, opacity + 0.2))
            cr.set_line_width(2.4)
        elif is_hover:
            cr.set_source_rgba(*self.color_hover, min(1.0, opacity + 0.2))
            cr.set_line_width(2.0)
        else:
            cr.set_source_rgba(*self.color_outline, 0.4 * opacity)
            cr.set_line_width(1.2)
        cr.stroke()
        cr.restore()

        # Title only for the focused card, drawn flat (unsheared) beneath it
        if is_selected:
            title = os.path.splitext(os.path.basename(path))[0]
            layout = PangoCairo.create_layout(cr)
            layout.set_text(title, -1)
            layout.set_font_description(Pango.FontDescription("JetBrainsMono Nerd Font Bold 10"))
            w, h = layout.get_pixel_size()
            cr.save()
            cr.move_to(x - w / 2, y + CARD_H / 2 * scale + 10)
            cr.set_source_rgba(*self.color_title, 1.0)
            PangoCairo.show_layout(cr, layout)
            cr.restore()

    # -- events ---------------------------------------------------------
    def on_motion(self, widget, event):
        idx = self._hit_test(event.x, event.y)
        if idx != self.hover_index:
            self.hover_index = idx
            self.queue_draw()
        if idx is not None and idx != self.selected_index:
            self.set_selected(idx)
            if self.on_preview:
                self.on_preview(self.items[idx])
        return False

    def on_leave(self, widget, event):
        if self.hover_index is not None:
            self.hover_index = None
            self.queue_draw()
        return False

    def on_button_press(self, widget, event):
        idx = self._hit_test(event.x, event.y)
        if idx is not None:
            self.set_selected(idx, animate=(idx != self.selected_index))
            if self.on_activate:
                self.on_activate(self.items[idx])
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
                if self.on_preview:
                    self.on_preview(self.items[new_index])
        return True


class WallpaperPanel(Gtk.Window):
    def __init__(self):
        super().__init__()

        # Determine current wallpaper for preview restoration on Esc
        self.original_wallpaper = self.get_current_wallpaper()
        self.active_wallpaper = self.original_wallpaper
        self.confirmed = False

        # Detect wallpaper engine (awww or swww)
        self.engine = "awww" if self.cmd_exists("awww") else ("swww" if self.cmd_exists("swww") else None)

        # Load Noctalia's current colour scheme (preset or wallpaper-generated)
        self.palette = load_noctalia_palette()

        # Load wallpapers
        self.wallpapers = self.scan_wallpapers()
        self.filtered_wallpapers = list(self.wallpapers)

        # Initialize Window & LayerShell
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.BOTTOM, 24)
        GtkLayerShell.set_namespace(self, "noctalia-wallpaper-panel")

        self.set_default_size(940, 250)
        self.set_resizable(False)

        # Apply CSS
        self.apply_css()

        # Build UI
        self.build_ui()

        # Connect Events
        self.connect("key-press-event", self.on_key_press)
        self.connect("destroy", self.on_destroy)

        # Seed the cover flow, focused on whatever wallpaper is currently active
        self.coverflow.set_items(self.filtered_wallpapers, keep_path=self.original_wallpaper)

    def cmd_exists(self, cmd):
        return subprocess.call(f"type {cmd}", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE) == 0

    def get_current_wallpaper(self):
        if os.path.islink(CURRENT_WALL_LINK):
            return os.path.realpath(CURRENT_WALL_LINK)
        if os.path.exists(WALL_CACHE_FILE):
            with open(WALL_CACHE_FILE, "r") as f:
                name = f.read().strip()
                matches = glob.glob(os.path.join(WALLPAPER_DIR, f"{name}.*"))
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
        provider.load_from_data(build_css(self.palette))
        Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def build_ui(self):
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        main_box.get_style_context().add_class("main-container")
        self.add(main_box)

        # Cover-flow carousel
        self.coverflow = CoverFlow(on_preview=self.preview_wallpaper, on_activate=self.confirm_wallpaper, palette=self.palette)
        main_box.pack_start(self.coverflow, True, True, 0)

        # Bottom Search Bar
        search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        search_box.get_style_context().add_class("search-bar")

        icon_label = Gtk.Label(label="")
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

    def preview_wallpaper(self, path):
        if not path or not os.path.exists(path) or path == self.active_wallpaper:
            return
        self.active_wallpaper = path

        def _preview():
            if self.engine:
                params = "--transition-fps 120 --transition-type any --transition-duration 0.5 --transition-bezier .28,.58,.99,.37"
                subprocess.run(f"{self.engine} img '{path}' {params}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(f"noctalia msg wallpaper-set '{path}' 2>/dev/null || true", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        threading.Thread(target=_preview, daemon=True).start()

    def confirm_wallpaper(self, path):
        self.confirmed = True
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

        def _apply():
            if self.engine:
                params = "--transition-fps 120 --transition-type any --transition-duration 1.0 --transition-bezier .28,.58,.99,.37"
                subprocess.run(f"{self.engine} img '{path}' {params}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(f"noctalia msg wallpaper-set '{path}' 2>/dev/null || true", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(f"'{COLORS_SCRIPT}' '{path}' &>/dev/null &", shell=True)

        threading.Thread(target=_apply, daemon=True).start()
        Gtk.main_quit()

    def on_search_changed(self, entry):
        text = entry.get_text().strip().lower()
        if not text:
            self.filtered_wallpapers = list(self.wallpapers)
        else:
            self.filtered_wallpapers = [w for w in self.wallpapers if text in os.path.basename(w).lower()]
        self.coverflow.set_items(self.filtered_wallpapers)
        path = self.coverflow.get_selected_path()
        if path:
            self.preview_wallpaper(path)

    def on_key_press(self, widget, event):
        key = event.keyval

        # Escape: cancel and restore original
        if key == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True

        # Return: confirm selection
        if key in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            path = self.coverflow.get_selected_path()
            if path:
                self.confirm_wallpaper(path)
            return True

        # Left / Right Arrow Navigation
        if key in (Gdk.KEY_Left, Gdk.KEY_h):
            if self.coverflow.items:
                idx = max(0, self.coverflow.selected_index - 1)
                self.coverflow.set_selected(idx)
                path = self.coverflow.get_selected_path()
                if path:
                    self.preview_wallpaper(path)
            return True

        if key in (Gdk.KEY_Right, Gdk.KEY_l):
            if self.coverflow.items:
                idx = min(len(self.coverflow.items) - 1, self.coverflow.selected_index + 1)
                self.coverflow.set_selected(idx)
                path = self.coverflow.get_selected_path()
                if path:
                    self.preview_wallpaper(path)
            return True

        return False

    def on_destroy(self, widget):
        try:
            self.coverflow._executor.shutdown(wait=False, cancel_futures=True)
        except Exception:
            pass
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
    pids = [p for p in res.stdout.strip().split('\n') if p]
    killed_any = False
    for p in pids:
        try:
            os.kill(int(p), signal.SIGKILL)
            killed_any = True
        except (ProcessLookupError, ValueError):
            # Process already exited between pgrep and kill (race condition) - ignore
            pass
    if killed_any:
        sys.exit(0)

    win = WallpaperPanel()
    win.show_all()
    Gtk.main()

if __name__ == '__main__':
    main()
