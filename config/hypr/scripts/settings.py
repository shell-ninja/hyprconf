#!/usr/bin/env python3
# =============================================================================
#  hypr-settings-gui.py — GTK4 / libadwaita GUI for hypr-settings.sh
#
#  A faithful GUI port of Shell Ninja's hypr-settings.sh:
#    - Same config targets, same sed/regex patterns, same collect-then-apply
#      flow, same backup behaviour. No hyprctl reload (Hyprland picks up
#      Lua config changes on its own).
#
#  Depends: python3-gobject, libadwaita-1
#           sudo pacman -S python-gobject libadwaita
#
#  Usage:   python3 hypr-settings-gui.py
# =============================================================================

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

import re
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

from gi.repository import Adw, Gio, GLib, Gtk

# ─── Config file paths — identical to hypr-settings.sh ───────────────────────
HYPR_LUA = Path.home() / ".config" / "hypr" / "configs" / "configs.lua"
KITTY_CONF = Path.home() / ".config" / "kitty" / "kitty.conf"
GTK3_CSS = Path.home() / ".config" / "gtk-3.0" / "gtk.css"
GTK4_CSS = Path.home() / ".config" / "gtk-4.0" / "gtk.css"

BACKUP_DIR = (
    Path(__import__("os").environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
    / "hypr-settings"
    / "backups"
)


# =============================================================================
#  Core logic — ported 1:1 from hypr-settings.sh
# =============================================================================


def backup(src: Path):
    """Mirror of _backup(): copy file to BACKUP_DIR with a timestamp suffix."""
    if not src.is_file():
        return
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    shutil.copy2(src, BACKUP_DIR / f"{src.name}.{stamp}.bak")


def lua_set(path: Path, key: str, value: str):
    """
    Mirror of _lua_set(): applies the same three sed -E patterns against a
    Lua config, in the same order. Each is a no-op if its pattern doesn't
    match. Operates on numeric (int/float) values only, same as the original.
    """
    if not path.is_file():
        return
    text = path.read_text()
    k = re.escape(key)
    patterns = [
        # bare table key:      rounding = 8
        (rf"^(\s*{k}\s*=\s*)[0-9]+(\.[0-9]+)?", rf"\g<1>{value}"),
        # dot-access:          decoration.rounding = 8
        (rf"^(\s*[a-zA-Z_]+\.{k}\s*=\s*)[0-9]+(\.[0-9]+)?", rf"\g<1>{value}"),
        # local variable:      local rounding = 8
        (rf"^(\s*local {k}\s*=\s*)[0-9]+(\.[0-9]+)?", rf"\g<1>{value}"),
    ]
    for pattern, repl in patterns:
        text = re.sub(pattern, repl, text, flags=re.MULTILINE)
    path.write_text(text)


def raw_sub(path: Path, pattern: str, repl: str, flags=re.MULTILINE):
    """One-off sed -E substitution, mirroring the extra sed lines in the
    original script that aren't covered by _lua_set (e.g. bare `border =`,
    `size =`, `passes =`, `range =`, active/inactive opacity key names)."""
    if not path.is_file():
        return
    text = path.read_text()
    text = re.sub(pattern, repl, text, flags=flags)
    path.write_text(text)


class ApplyResult:
    """Collects status lines the same way _status() printed them, so the UI
    can show a results log after Apply."""

    def __init__(self):
        self.lines: list[tuple[str, str]] = []  # (level, message)

    def ok(self, msg):
        self.lines.append(("ok", msg))

    def skip(self, msg):
        self.lines.append(("skip", msg))

    def err(self, msg):
        self.lines.append(("err", msg))


def apply_all(pending: dict, result: ApplyResult):
    """
    Mirror of _apply_all(): backs up every file that will be touched, then
    writes every pending setting to disk. `pending` uses the same keys as
    the bash PENDING array: border_size, roundness, inner_gap, outer_gap,
    blur (tuple), opacity (tuple), shadow.
    """
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
    need_kitty = "opacity" in pending
    need_gtk = "opacity" in pending

    if need_hypr:
        backup(HYPR_LUA)
    if need_kitty:
        backup(KITTY_CONF)
    if need_gtk:
        backup(GTK3_CSS)
        backup(GTK4_CSS)

    # ── border size ──────────────────────────────────────────────────────
    if "border_size" in pending:
        val = str(pending["border_size"])
        if HYPR_LUA.is_file():
            lua_set(HYPR_LUA, "border", val)
            raw_sub(HYPR_LUA, r"^(border\s*=\s*)[0-9]+", rf"\g<1>{val}")
        else:
            result.err("Hyprland Lua config not found — border size skipped")
        result.ok(f"border-size      → {val}")

    # ── roundness ────────────────────────────────────────────────────────
    if "roundness" in pending:
        val = str(pending["roundness"])
        if HYPR_LUA.is_file():
            lua_set(HYPR_LUA, "rounding", val)
        else:
            result.err("Hyprland Lua config not found — roundness skipped")
        result.ok(f"rounding         → {val}")

    # ── inner gap ────────────────────────────────────────────────────────
    if "inner_gap" in pending:
        val = str(pending["inner_gap"])
        if HYPR_LUA.is_file():
            lua_set(HYPR_LUA, "inner_gap", val)
            result.ok(f"inner-gap        → {val}")
        else:
            result.err("Hyprland Lua config not found — inner gap skipped")

    # ── outer gap ────────────────────────────────────────────────────────
    if "outer_gap" in pending:
        val = str(pending["outer_gap"])
        if HYPR_LUA.is_file():
            lua_set(HYPR_LUA, "outer_gap", val)
            result.ok(f"outer-gap        → {val}")
        else:
            result.err("Hyprland Lua config not found — outer gap skipped")

    # ── blur ─────────────────────────────────────────────────────────────
    if "blur" in pending:
        bsize, bpass = pending["blur"]
        bsize, bpass = str(bsize), str(bpass)
        if HYPR_LUA.is_file():
            lua_set(HYPR_LUA, "blur_size", bsize)
            lua_set(HYPR_LUA, "blur_passes", bpass)
            raw_sub(HYPR_LUA, r"^(\s*size\s*=\s*)[0-9]+", rf"\g<1>{bsize}")
            raw_sub(HYPR_LUA, r"^(\s*passes\s*=\s*)[0-9]+", rf"\g<1>{bpass}")
            result.ok(f"blur             → size:{bsize}  passes:{bpass}")
        else:
            result.err("Hyprland Lua config not found — blur skipped")

    # ── opacity ──────────────────────────────────────────────────────────
    if "opacity" in pending:
        act, deact = pending["opacity"]
        act, deact = str(act), str(deact)

        if HYPR_LUA.is_file():
            lua_set(HYPR_LUA, "opacity_act", act)
            lua_set(HYPR_LUA, "opacity_deact", deact)
            raw_sub(
                HYPR_LUA,
                r"^(\s*active_opacity\s*=\s*)[0-9]+(\.[0-9]+)?",
                rf"\g<1>{act}",
            )
            raw_sub(
                HYPR_LUA,
                r"^(\s*inactive_opacity\s*=\s*)[0-9]+(\.[0-9]+)?",
                rf"\g<1>{deact}",
            )
            result.ok(f"Hyprland  active:{act}  inactive:{deact}")
        else:
            result.err("Hyprland Lua config not found — opacity skipped")

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
            result.ok(f"Kitty     background_opacity → {act}  (live reloaded)")
        else:
            result.skip("Kitty     config not found, skipped")

        if GTK3_CSS.is_file():
            raw_sub(
                GTK3_CSS,
                r"rgba\(([0-9]+),\s*([0-9]+),\s*([0-9]+),\s*[0-9.]+\)",
                rf"rgba(\1, \2, \3, {act})",
            )
            result.ok(f"GTK3      rgba alpha → {act}")
        else:
            result.skip("GTK3      css not found, skipped")

        if GTK4_CSS.is_file():
            raw_sub(
                GTK4_CSS,
                r"alpha\(@[a-zA-Z]+,\s*[0-9.]+\)",
                rf"alpha(@background, {act})",
            )
            result.ok(f"GTK4      alpha → {act}")
        else:
            result.skip("GTK4      css not found, skipped")

    # ── shadow ───────────────────────────────────────────────────────────
    if "shadow" in pending:
        val = str(pending["shadow"])
        if HYPR_LUA.is_file():
            lua_set(HYPR_LUA, "shadow_range", val)
            raw_sub(HYPR_LUA, r"^(\s*range\s*=\s*)[0-9]+(\.[0-9]+)?", rf"\g<1>{val}")
            result.ok(f"shadow-range     → {val}")
        else:
            result.err("Hyprland Lua config not found — shadow skipped")


# =============================================================================
#  Widget helpers
# =============================================================================


def make_spin_row(title: str, subtitle: str, lower, upper, step, digits, value):
    row = Adw.ActionRow(title=title, subtitle=subtitle)
    adj = Gtk.Adjustment(
        value=value,
        lower=lower,
        upper=upper,
        step_increment=step,
        page_increment=step * 5,
    )
    spin = Gtk.SpinButton(adjustment=adj, digits=digits, valign=Gtk.Align.CENTER)
    spin.set_numeric(True)
    row.add_suffix(spin)
    row.set_activatable_widget(spin)
    return row, spin


def make_group(title: str, description: str = None):
    g = Adw.PreferencesGroup(title=title)
    if description:
        g.set_description(description)
    return g


def file_status_icon(path: Path) -> Gtk.Image:
    """Small icon indicating whether a target file exists, since the bash
    script silently skips missing files — the GUI should say so up front."""
    if path.is_file():
        icon = Gtk.Image.new_from_icon_name("emblem-ok-symbolic")
        icon.set_tooltip_text(f"Found: {path}")
        icon.add_css_class("success")
    else:
        icon = Gtk.Image.new_from_icon_name("dialog-warning-symbolic")
        icon.set_tooltip_text(f"Not found, will be skipped: {path}")
        icon.add_css_class("warning")
    return icon


# =============================================================================
#  Application
# =============================================================================


class HyprSettingsWindow(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(
            application=app,
            title="Hyprland Settings",
            default_width=560,
            default_height=680,
        )

        self.pending: dict[str, object] = {}
        self.dirty_rows: set[str] = set()

        toolbar_view = Adw.ToolbarView()
        self.set_content(toolbar_view)

        header = Adw.HeaderBar()
        toolbar_view.add_top_bar(header)

        self.discard_btn = Gtk.Button(label="Discard")
        self.discard_btn.connect("clicked", self.on_discard)
        self.discard_btn.set_sensitive(False)
        header.pack_start(self.discard_btn)

        self.apply_btn = Gtk.Button(label="Apply")
        self.apply_btn.add_css_class("suggested-action")
        self.apply_btn.connect("clicked", self.on_apply)
        self.apply_btn.set_sensitive(False)
        header.pack_end(self.apply_btn)

        # Toast overlay wraps the scrollable content
        self.toast_overlay = Adw.ToastOverlay()
        toolbar_view.set_content(self.toast_overlay)

        scrolled = Gtk.ScrolledWindow(vexpand=True)
        self.toast_overlay.set_child(scrolled)

        page = Adw.PreferencesPage()
        scrolled.set_child(page)

        # ── File status group ───────────────────────────────────────────
        g = make_group(
            "Config files",
            "Files this app can write to. Missing files are "
            "skipped, same as the original script.",
        )
        page.add(g)
        for label, path in [
            ("Hyprland config", HYPR_LUA),
            ("Kitty config", KITTY_CONF),
            ("GTK 3 css", GTK3_CSS),
            ("GTK 4 css", GTK4_CSS),
        ]:
            row = Adw.ActionRow(title=label, subtitle=str(path))
            row.add_suffix(file_status_icon(path))
            g.add(row)

        # ── Window decoration ───────────────────────────────────────────
        g = make_group("Window Decoration")
        page.add(g)

        row, self.spin_border = make_spin_row(
            "Border size", "Width of window borders, in pixels", 0, 20, 1, 0, 2
        )
        g.add(row)
        self.spin_border.connect(
            "value-changed", lambda w: self.mark("border_size", int(w.get_value()))
        )

        row, self.spin_round = make_spin_row(
            "Corner rounding", "Corner radius, in pixels", 0, 30, 1, 0, 8
        )
        g.add(row)
        self.spin_round.connect(
            "value-changed", lambda w: self.mark("roundness", int(w.get_value()))
        )

        # ── Gaps ─────────────────────────────────────────────────────────
        g = make_group("Gaps")
        page.add(g)

        row, self.spin_inner = make_spin_row(
            "Inner gap", "Gap between tiled windows, in pixels", 0, 40, 1, 0, 4
        )
        g.add(row)
        self.spin_inner.connect(
            "value-changed", lambda w: self.mark("inner_gap", int(w.get_value()))
        )

        row, self.spin_outer = make_spin_row(
            "Outer gap",
            "Gap between windows and screen edge, in pixels",
            0,
            60,
            1,
            0,
            8,
        )
        g.add(row)
        self.spin_outer.connect(
            "value-changed", lambda w: self.mark("outer_gap", int(w.get_value()))
        )

        # ── Blur ─────────────────────────────────────────────────────────
        g = make_group("Blur", "Recommended: size 2–8, passes 2–4.")
        page.add(g)

        row, self.spin_blur_size = make_spin_row(
            "Blur size", "Spread radius of the blur kernel", 0, 20, 1, 0, 4
        )
        g.add(row)
        self.spin_blur_size.connect("value-changed", lambda w: self.mark_blur())

        row, self.spin_blur_passes = make_spin_row(
            "Blur passes", "More passes = smoother blur, higher GPU cost", 1, 8, 1, 0, 3
        )
        g.add(row)
        self.spin_blur_passes.connect("value-changed", lambda w: self.mark_blur())

        # ── Opacity ──────────────────────────────────────────────────────
        g = make_group("Opacity", "Also applied to Kitty background, GTK3, and GTK4.")
        page.add(g)

        row, self.spin_opacity_act = make_spin_row(
            "Active window opacity",
            "Opacity of the focused window",
            0.0,
            1.0,
            0.05,
            2,
            0.95,
        )
        g.add(row)
        self.spin_opacity_act.connect("value-changed", lambda w: self.mark_opacity())

        row, self.spin_opacity_deact = make_spin_row(
            "Inactive window opacity",
            "Opacity of unfocused windows",
            0.0,
            1.0,
            0.05,
            2,
            0.75,
        )
        g.add(row)
        self.spin_opacity_deact.connect("value-changed", lambda w: self.mark_opacity())

        # ── Shadow ───────────────────────────────────────────────────────
        g = make_group("Shadow")
        page.add(g)

        self.switch_shadow = Adw.SwitchRow(
            title="Enable drop shadow",
            subtitle="Off sets shadow range to 0",
            active=True,
        )
        g.add(self.switch_shadow)
        self.switch_shadow.connect("notify::active", self.on_shadow_toggled)

        row, self.spin_shadow = make_spin_row(
            "Shadow range",
            "Drop shadow radius, in pixels. 0 disables shadows.",
            0,
            60,
            1,
            0,
            12,
        )
        g.add(row)
        self.spin_shadow.connect("value-changed", self.on_shadow_range_changed)

        # ── Results group (hidden until first Apply) ────────────────────
        self.results_group = make_group("Last apply")
        self.results_group.set_visible(False)
        page.add(self.results_group)

        self.connect("close-request", self.on_close_request)

    # ── Pending-change tracking ─────────────────────────────────────────

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

    def _refresh_buttons(self):
        has_pending = bool(self.pending)
        self.apply_btn.set_sensitive(has_pending)
        self.discard_btn.set_sensitive(has_pending)

    # ── Apply / Discard ─────────────────────────────────────────────────

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
        # Clear old rows
        child = self.results_group.get_first_child()
        # PreferencesGroup doesn't give an easy "clear all rows" API, so
        # rebuild the group's rows by removing known ones.
        for row in list(getattr(self, "_result_rows", [])):
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

        self.results_group.set_visible(True)

    def on_close_request(self, _win):
        if not self.pending:
            return False  # allow close

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
        return True  # block default close until dialog resolves

    def _on_close_response(self, _dialog, response):
        if response == "apply":
            result = ApplyResult()
            apply_all(self.pending, result)
            self.pending.clear()
            self.destroy()
        elif response == "discard":
            self.pending.clear()
            self.destroy()
        # "cancel" → do nothing, window stays open


class HyprSettingsApp(Adw.Application):
    def __init__(self):
        super().__init__(
            application_id="dev.shellninja.hypr-settings",
            flags=Gio.ApplicationFlags.FLAGS_NONE,
        )
        self.connect("activate", self.on_activate)

    def on_activate(self, app):
        win = HyprSettingsWindow(app)
        win.present()


def main():
    import sys

    app = HyprSettingsApp()
    sys.exit(app.run(sys.argv))


if __name__ == "__main__":
    main()
