#!/usr/bin/env python3
# =============================================================================
#  pkgupdate-gui.py — GTK4 / libadwaita package update manager
#
#  Detects pacman + AUR helper (yay/paru) and shows separate counts for
#  official repo updates (via checkupdates) and AUR updates (via yay/paru -Qua).
#  Runs privileged updates through pkexec / polkit so a GUI auth dialog appears.
#
#  Depends: python3-gobject, libadwaita >= 1.4, vte3
#           sudo pacman -S python-gobject libadwaita vte3
#
#  Usage:   python3 pkgupdate-gui.py
# =============================================================================

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

# vte4 (GTK4-compatible) registers as version "3.91".
# vte3 (GTK3-only) registers as "2.91" — importing it after GTK4 is loaded
# causes a namespace conflict, so we only attempt the GTK4 version.
HAVE_VTE = False
try:
    gi.require_version("Vte", "3.91")   # succeeds only with vte4 installed
    HAVE_VTE = True
except ValueError:
    pass  # vte4 not installed → use TextView fallback

import os
import shutil
import subprocess
import threading
from pathlib import Path

from gi.repository import Adw, Gio, GLib, Gtk

if HAVE_VTE:
    try:
        from gi.repository import Vte
    except Exception:
        HAVE_VTE = False

# =============================================================================
#  CSS — deep dark theme with cyan/purple accent palette
# =============================================================================

CSS = """
* { font-family: 'Inter', system-ui, sans-serif; }

window, .background {
    background-color: @window_bg_color;
    color: @window_fg_color;
}

headerbar {
    background-color: @headerbar_bg_color;
    border-bottom: 1px solid alpha(@window_fg_color, 0.08);
    box-shadow: none;
    min-height: 48px;
}

headerbar windowtitle label.title {
    font-weight: 800;
    font-size: 1.0em;
    letter-spacing: 0.3px;
    color: @window_fg_color;
}

headerbar windowtitle label.subtitle {
    font-size: 0.78em;
    color: alpha(@window_fg_color, 0.6);
    font-weight: 500;
}

scrollbar slider {
    background-color: alpha(@window_fg_color, 0.2);
    border-radius: 8px;
    min-width: 4px;
    min-height: 4px;
}
scrollbar slider:hover { background-color: alpha(@accent_color, 0.5); }

.hero-title {
    font-size: 1.85em;
    font-weight: 800;
    letter-spacing: -0.4px;
    color: @window_fg_color;
}

.hero-subtitle {
    color: alpha(@window_fg_color, 0.6);
    font-size: 0.95em;
    font-weight: 400;
}

/* Stats bar */
.stats-bar {
    background-color: @card_bg_color;
    border: 1px solid alpha(@window_fg_color, 0.08);
    border-radius: 14px;
    padding: 14px 18px;
}

.stat-number {
    font-size: 1.8em;
    font-weight: 800;
    color: @accent_color;
}

.stat-number.stat-aur { color: alpha(@accent_color, 0.85); }
.stat-number.stat-zero {
    color: alpha(@window_fg_color, 0.3);
    font-size: 1.5em;
}

.stat-label {
    font-size: 0.72em;
    font-weight: 700;
    color: alpha(@window_fg_color, 0.45);
    letter-spacing: 0.8px;
    text-transform: uppercase;
}

/* PM Cards */
.pm-card {
    background-color: @card_bg_color;
    border-radius: 14px;
    border: 1px solid alpha(@window_fg_color, 0.08);
    padding: 14px 18px;
    transition: all 180ms ease;
}

.pm-card:hover {
    border-color: alpha(@accent_color, 0.35);
    background-color: shade(@card_bg_color, 1.05);
}

.pm-card.pm-selected {
    border-color: alpha(@accent_color, 0.45);
    background-color: alpha(@accent_bg_color, 0.06);
    box-shadow: 0 0 0 1px alpha(@accent_color, 0.16);
}

.pm-card.pm-missing { opacity: 0.35; }



/* Pills */
.pill {
    border-radius: 999px;
    padding: 3px 10px;
    font-size: 0.75em;
    font-weight: 700;
    letter-spacing: 0.2px;
}

.pill-checking {
    background: alpha(@window_fg_color, 0.06);
    color: alpha(@window_fg_color, 0.4);
    border: 1px solid alpha(@window_fg_color, 0.10);
}

.pill-ready {
    background: alpha(@success_color, 0.12);
    color: @success_color;
    border: 1px solid alpha(@success_color, 0.22);
}

.pill-updates {
    background: alpha(@accent_color, 0.14);
    color: @accent_color;
    border: 1px solid alpha(@accent_color, 0.28);
}

.pill-aur-updates {
    background: alpha(@accent_color, 0.14);
    color: @accent_color;
    border: 1px solid alpha(@accent_color, 0.28);
}

.pill-missing {
    background: alpha(@window_fg_color, 0.05);
    color: alpha(@window_fg_color, 0.3);
    border: 1px solid alpha(@window_fg_color, 0.08);
}

/* Count badge */
.count-badge {
    background: alpha(@accent_color, 0.12);
    border: 1px solid alpha(@accent_color, 0.25);
    border-radius: 10px;
    padding: 4px 10px;
    min-width: 38px;
}

.count-badge-text {
    font-size: 1.2em;
    font-weight: 800;
    color: @accent_color;
}

.count-badge.badge-aur {
    background: alpha(@accent_color, 0.12);
    border-color: alpha(@accent_color, 0.25);
}

.count-badge.badge-aur .count-badge-text { color: @accent_color; }

/* Buttons — Native GTK Colors */
.update-btn {
    background-color: @accent_bg_color;
    color: @accent_fg_color;
    font-weight: 700;
    font-size: 0.96em;
    border-radius: 10px;
    padding: 10px 22px;
    border: none;
    transition: all 150ms ease;
}

.update-btn:hover {
    background-color: alpha(@accent_bg_color, 0.90);
    box-shadow: 0 2px 10px alpha(@accent_bg_color, 0.3);
}

.update-btn:active {
    background-color: shade(@accent_bg_color, 0.85);
}

.update-btn:disabled {
    background-color: alpha(@window_fg_color, 0.08);
    color: alpha(@window_fg_color, 0.35);
    box-shadow: none;
}

.ghost-btn {
    background-color: alpha(@window_fg_color, 0.06);
    border: 1px solid alpha(@window_fg_color, 0.12);
    border-radius: 10px;
    padding: 10px 18px;
    color: @window_fg_color;
    font-weight: 600;
    font-size: 0.94em;
    transition: all 140ms ease;
}

.ghost-btn:hover {
    background-color: alpha(@window_fg_color, 0.10);
    border-color: alpha(@window_fg_color, 0.20);
}

.refresh-btn {
    background-color: alpha(@window_fg_color, 0.06);
    border: 1px solid alpha(@window_fg_color, 0.10);
    border-radius: 8px;
    color: @window_fg_color;
    transition: all 140ms ease;
    padding: 6px;
}

.refresh-btn:hover {
    background-color: alpha(@accent_bg_color, 0.15);
    border-color: alpha(@accent_color, 0.3);
    color: @accent_color;
}

/* Terminal */
.terminal-frame {
    background-color: @view_bg_color;
    border-radius: 12px;
    border: 1px solid alpha(@window_fg_color, 0.10);
}

.terminal-topbar {
    background-color: alpha(@window_fg_color, 0.04);
    border-radius: 12px 12px 0 0;
    border-bottom: 1px solid alpha(@window_fg_color, 0.08);
    padding: 8px 12px;
}

.terminal-dot-red   { background: #ff5f56; border-radius: 50%; min-width: 10px; min-height: 10px; }
.terminal-dot-amber { background: #ffbd2e; border-radius: 50%; min-width: 10px; min-height: 10px; }
.terminal-dot-green { background: #27c93f; border-radius: 50%; min-width: 10px; min-height: 10px; }

.terminal-label {
    font-size: 0.74em;
    font-weight: 600;
    color: alpha(@window_fg_color, 0.35);
    letter-spacing: 0.5px;
    text-transform: uppercase;
}

/* Status banners */
.banner-ok {
    background-color: alpha(@success_color, 0.10);
    border: 1px solid alpha(@success_color, 0.28);
    border-radius: 12px;
    padding: 12px 16px;
    color: @success_color;
    font-weight: 600;
}

.banner-warn {
    background-color: alpha(@warning_color, 0.10);
    border: 1px solid alpha(@warning_color, 0.28);
    border-radius: 12px;
    padding: 12px 16px;
    color: @warning_color;
    font-weight: 600;
}

/* Section labels */
.section-label {
    font-weight: 700;
    font-size: 0.76em;
    color: alpha(@window_fg_color, 0.4);
    letter-spacing: 0.8px;
    text-transform: uppercase;
}

.glow-dot { color: @accent_color; }

/* Progress */
progressbar trough {
    background-color: alpha(@window_fg_color, 0.08);
    border-radius: 4px;
    min-height: 4px;
}
progressbar progress {
    background-color: @accent_bg_color;
    border-radius: 4px;
}

/* Toast */
toast {
    background-color: @card_bg_color;
    border: 1px solid alpha(@window_fg_color, 0.15);
    border-radius: 10px;
    color: @window_fg_color;
}

/* Checkbutton */
checkbutton check {
    border-radius: 6px;
    border: 2px solid alpha(@window_fg_color, 0.3);
    background-color: transparent;
    min-width: 18px;
    min-height: 18px;
}
checkbutton:checked check {
    background-color: @accent_bg_color;
    border-color: @accent_bg_color;
    color: @accent_fg_color;
}
"""


# =============================================================================
#  Package source definitions
# =============================================================================


def which(cmd):
    return shutil.which(cmd)


class PMSource:
    """Represents one update source (e.g. pacman official repos, AUR, flatpak)."""

    def __init__(self, key, label, subtitle, is_aur,
                 check_cmd, update_cmd, needs_sudo=False):
        self.key = key
        self.label = label
        self.subtitle = subtitle
        self.is_aur = is_aur
        self.check_cmd = check_cmd
        self.update_cmd = update_cmd
        self.needs_sudo = needs_sudo


def detect_sources():
    sources = []

    if which("pacman"):
        aur_bin = which("yay") or which("paru")
        aur_name = os.path.basename(aur_bin) if aur_bin else None

        # Official pacman repos — use `checkupdates` (safe, no sudo needed)
        sources.append(PMSource(
            key="pacman",
            label="Pacman",
            subtitle="Official Arch Linux repositories",
            is_aur=False,
            check_cmd="checkupdates 2>/dev/null | wc -l",
            update_cmd="pacman -Syu --noconfirm --color=always",
            needs_sudo=True,
        ))

        # AUR — yay/paru -Qua only lists AUR upgrades (no --sync, very fast)
        if aur_bin:
            sources.append(PMSource(
                key="aur",
                label=f"AUR  ({aur_name})",
                subtitle=f"Arch User Repository via {aur_name}",
                is_aur=True,
                check_cmd=f"{aur_bin} -Qua 2>/dev/null | wc -l",
                update_cmd=f"{aur_bin} -Sua --noconfirm",
                needs_sudo=False,
            ))

    if which("dnf"):
        sources.append(PMSource(
            key="dnf", label="DNF",
            subtitle="Fedora / RHEL packages",
            is_aur=False,
            check_cmd="dnf check-update --quiet 2>/dev/null | grep -c '^[a-zA-Z0-9]' || true",
            update_cmd="dnf update -y && dnf upgrade -y",
            needs_sudo=True,
        ))

    if which("apt") or which("apt-get"):
        apt = which("apt-get") or which("apt")
        sources.append(PMSource(
            key="apt", label="APT",
            subtitle="Debian / Ubuntu packages",
            is_aur=False,
            check_cmd="apt list --upgradable 2>/dev/null | grep -c upgradable || true",
            update_cmd=f"{apt} update && {apt} upgrade -y",
            needs_sudo=True,
        ))

    if which("zypper"):
        sources.append(PMSource(
            key="zypper", label="Zypper",
            subtitle="openSUSE packages",
            is_aur=False,
            check_cmd="zypper lu 2>/dev/null | grep -c '^v ' || true",
            update_cmd="zypper up -y",
            needs_sudo=True,
        ))

    if which("flatpak"):
        sources.append(PMSource(
            key="flatpak", label="Flatpak",
            subtitle="Flathub application updates",
            is_aur=False,
            check_cmd="flatpak remote-ls --updates 2>/dev/null | wc -l",
            update_cmd="flatpak update -y",
            needs_sudo=False,
        ))

    return sources


def build_update_script(selected, password: str | None):
    """Build a shell script.

    If *password* is provided, privileged commands are prefixed with
    ``sudo -S`` and the password is written to the process stdin once
    before streaming begins.  Non-privileged commands (AUR helpers) run
    as the current user — AUR helpers refuse to run as root.

    NOTE: use printf (not echo '...') so that \\033 in the format string
    becomes a real ESC byte that VTE renders as colour.
    """
    parts = []
    for src in selected:
        # printf interprets \\033 as ESC; single-quoted echo does NOT.
        header = f"printf '\\033[1;36m\\n══ {src.label} ══\\033[0m\\n'"
        if src.needs_sudo and password is not None:
            # sudo -S reads one password line from stdin; subsequent sudo
            # calls in the same session reuse cached credentials.
            cmd = f"sudo -S {src.update_cmd} 2>&1"
        elif src.needs_sudo:
            cmd = src.update_cmd
        else:
            cmd = src.update_cmd
        parts.append(f"{header} && {cmd}")
    return " && printf '\\n' && ".join(parts)


# =============================================================================
#  Password dialog
# =============================================================================


class PasswordDialog(Adw.AlertDialog):
    """Styled modal password prompt shown before privileged updates."""

    def __init__(self, parent):
        super().__init__(
            heading="Authentication Required",
            body="Enter your sudo password to apply system updates.",
        )
        self.add_response("cancel", "Cancel")
        self.add_response("ok", "Authenticate")
        self.set_response_appearance("ok", Adw.ResponseAppearance.SUGGESTED)
        self.set_default_response("ok")
        self.set_close_response("cancel")

        # Use a plain Gtk.Entry with visibility=False — works on all GTK4 versions
        # and fully supports set_placeholder_text via the Editable interface.
        self._entry = Gtk.Entry()
        self._entry.set_visibility(False)          # hide characters
        self._entry.set_input_purpose(Gtk.InputPurpose.PASSWORD)
        self._entry.set_placeholder_text("Password…")
        self._entry.set_hexpand(True)
        self._entry.set_margin_top(8)
        # Add a show/hide icon to the right
        self._entry.set_icon_from_icon_name(
            Gtk.EntryIconPosition.SECONDARY, "view-conceal-symbolic"
        )
        self._entry.connect("icon-press", self._toggle_visibility)
        # Press Enter to confirm — Adw.AlertDialog has no .response() method;
        # emit the GObject signal directly instead.
        self._entry.connect("activate", lambda _: self.emit("response", "ok"))
        self.set_extra_child(self._entry)

    def _toggle_visibility(self, entry, _pos):
        vis = not entry.get_visibility()
        entry.set_visibility(vis)
        icon = "view-reveal-symbolic" if vis else "view-conceal-symbolic"
        entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, icon)

    def get_password(self) -> str:
        return self._entry.get_text()



# =============================================================================
#  Animated pulsing dots widget
# =============================================================================


class PulseDots(Gtk.Box):
    """Three dots that wave to indicate background activity."""

    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        self.set_halign(Gtk.Align.CENTER)
        self.set_valign(Gtk.Align.CENTER)
        self._dots = []
        self._timer_id = None
        self._frame = 0

        for _ in range(3):
            d = Gtk.Label(label="●")
            d.add_css_class("glow-dot")
            d.set_opacity(0.2)
            self._dots.append(d)
            self.append(d)

    def start(self):
        self.set_visible(True)
        if self._timer_id is None:
            self._frame = 0
            self._timer_id = GLib.timeout_add(170, self._tick)

    def stop(self):
        if self._timer_id is not None:
            GLib.source_remove(self._timer_id)
            self._timer_id = None
        for d in self._dots:
            d.set_opacity(0.2)
        self.set_visible(False)

    def _tick(self):
        active = self._frame % 3
        for i, d in enumerate(self._dots):
            dist = abs(i - active)
            d.set_opacity([1.0, 0.45, 0.15][dist])
        self._frame += 1
        return True


# =============================================================================
#  Source card factory
# =============================================================================


def make_source_card(src: PMSource):
    card = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
    card.add_css_class("pm-card")
    card.add_css_class("pm-selected")
    card.set_hexpand(True)

    # Text
    text_col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4, hexpand=True)
    text_col.set_valign(Gtk.Align.CENTER)

    title_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
    title_lbl = Gtk.Label(label=src.label, xalign=0)
    title_lbl.add_css_class("heading")
    title_row.append(title_lbl)

    pill = Gtk.Label(label="checking…")
    pill.add_css_class("pill")
    pill.add_css_class("pill-checking")
    title_row.append(pill)
    text_col.append(title_row)

    sub_lbl = Gtk.Label(label=src.subtitle, xalign=0)
    sub_lbl.add_css_class("caption")
    sub_lbl.set_opacity(0.4)
    text_col.append(sub_lbl)
    card.append(text_col)

    # Count badge
    count_box = Gtk.Box(halign=Gtk.Align.CENTER, valign=Gtk.Align.CENTER)
    count_box.add_css_class("count-badge")
    if src.is_aur:
        count_box.add_css_class("badge-aur")
    count_box.set_visible(False)
    count_lbl = Gtk.Label(label="0")
    count_lbl.add_css_class("count-badge-text")
    count_box.append(count_lbl)
    card.append(count_box)

    # Checkbutton
    check = Gtk.CheckButton()
    check.set_valign(Gtk.Align.CENTER)
    check.set_active(True)
    card.append(check)

    return card, pill, count_box, count_lbl, check


def refresh_pill(pill, count_box, count_lbl, count, is_aur=False):
    for cls in ("pill-checking", "pill-ready", "pill-updates",
                "pill-aur-updates", "pill-missing"):
        pill.remove_css_class(cls)

    if count is None:
        pill.set_label("unavailable")
        pill.add_css_class("pill-missing")
        count_box.set_visible(False)
    elif count == 0:
        pill.set_label("up to date")
        pill.add_css_class("pill-ready")
        count_box.set_visible(False)
    else:
        pill.set_label(f"{count} update{'s' if count != 1 else ''}")
        pill.add_css_class("pill-aur-updates" if is_aur else "pill-updates")
        count_lbl.set_label(str(count))
        count_box.set_visible(True)


# =============================================================================
#  Stats bar factory
# =============================================================================


def make_stats_bar():
    bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
    bar.add_css_class("stats-bar")
    bar.set_hexpand(True)

    def stat_col(label_text, extra=""):
        col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4, hexpand=True)
        col.set_halign(Gtk.Align.CENTER)
        num = Gtk.Label(label="—")
        num.add_css_class("stat-number")
        if extra:
            num.add_css_class(extra)
        lbl = Gtk.Label(label=label_text)
        lbl.add_css_class("stat-label")
        col.append(num)
        col.append(lbl)
        return col, num

    col_total, total_num = stat_col("TOTAL")
    sep1 = Gtk.Separator(orientation=Gtk.Orientation.VERTICAL)
    col_pac, pac_num = stat_col("PACMAN")
    sep2 = Gtk.Separator(orientation=Gtk.Orientation.VERTICAL)
    col_aur, aur_num = stat_col("AUR", "stat-aur")

    for w in (col_total, sep1, col_pac, sep2, col_aur):
        bar.append(w)

    return bar, total_num, pac_num, aur_num


# =============================================================================
#  Main window
# =============================================================================


class UpdaterWindow(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(
            application=app,
            title="System Update",
            default_width=700,
            default_height=620,
        )
        self.sources = detect_sources()
        # key -> (card, pill, count_box, count_lbl, check)
        self.widgets = {}
        self.running = False
        self.proc = None
        self._results = {}      # key -> int|None
        self._progress_id = None

        self._build_ui()
        GLib.idle_add(self.start_check)

    # ─────────────────────────────────────────────────────────────────────

    def _build_ui(self):
        tv = Adw.ToolbarView()
        self.set_content(tv)

        # Header
        hb = Adw.HeaderBar()
        hb.set_title_widget(Adw.WindowTitle(
            title="System Update", subtitle=self._hostname()))

        self.refresh_btn = Gtk.Button()
        self.refresh_btn.set_icon_name("view-refresh-symbolic")
        self.refresh_btn.set_tooltip_text("Re-check for updates")
        self.refresh_btn.add_css_class("refresh-btn")
        self.refresh_btn.connect("clicked", lambda _: self.start_check())
        hb.pack_start(self.refresh_btn)
        tv.add_top_bar(hb)

        self.toast_overlay = Adw.ToastOverlay()
        tv.set_content(self.toast_overlay)

        scroller = Gtk.ScrolledWindow()
        scroller.set_vexpand(True)
        self.toast_overlay.set_child(scroller)

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        root.set_margin_top(20)
        root.set_margin_bottom(20)
        root.set_margin_start(24)
        root.set_margin_end(24)
        scroller.set_child(root)

        # Hero
        hero = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        ht = Gtk.Label(label="Keep your system fresh", xalign=0)
        ht.add_css_class("hero-title")
        hs = Gtk.Label(
            label="Review updates across every package source, then apply them securely.",
            xalign=0, wrap=True)
        hs.add_css_class("hero-subtitle")
        hero.append(ht)
        hero.append(hs)
        root.append(hero)

        # Stats
        self.stats_bar, self.total_num, self.pac_num, self.aur_num = make_stats_bar()
        root.append(self.stats_bar)

        # Sources label
        src_lbl = Gtk.Label(label="Update sources", xalign=0)
        src_lbl.add_css_class("section-label")
        src_lbl.set_margin_top(4)
        root.append(src_lbl)

        # Cards
        cards_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        if not self.sources:
            no_pm = Gtk.Label(label="⚠ No supported package manager found.", xalign=0)
            no_pm.add_css_class("hero-subtitle")
            cards_box.append(no_pm)
        else:
            for src in self.sources:
                card, pill, count_box, count_lbl, check = make_source_card(src)
                self.widgets[src.key] = (card, pill, count_box, count_lbl, check)
                check.connect("toggled", self._on_check_toggled, card)
                cards_box.append(card)
        root.append(cards_box)

        # Action row
        actions = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        actions.set_margin_top(4)

        self.update_btn = Gtk.Button(label="Update selected")
        self.update_btn.add_css_class("update-btn")
        self.update_btn.connect("clicked", self.on_update_clicked)
        actions.append(self.update_btn)

        self.skip_btn = Gtk.Button(label="Skip for now")
        self.skip_btn.add_css_class("ghost-btn")
        self.skip_btn.connect("clicked", lambda _: self.close())
        actions.append(self.skip_btn)

        self.pulse = PulseDots()
        self.pulse.set_visible(False)
        self.pulse.set_margin_start(8)
        actions.append(self.pulse)
        root.append(actions)

        # Progress bar
        self.progress = Gtk.ProgressBar()
        self.progress.set_pulse_step(0.035)
        self.progress.set_visible(False)
        root.append(self.progress)

        # Status banner
        self.status_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.status_box.set_visible(False)
        self.status_lbl = Gtk.Label(label="", xalign=0, wrap=True, hexpand=True)
        self.status_box.append(self.status_lbl)
        root.append(self.status_box)

        # Output section
        out_lbl = Gtk.Label(label="Live output", xalign=0)
        out_lbl.add_css_class("section-label")
        root.append(out_lbl)

        term_outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        term_outer.add_css_class("terminal-frame")
        term_outer.set_size_request(-1, 280)

        # macOS-style topbar
        topbar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=7)
        topbar.add_css_class("terminal-topbar")
        for cls in ("terminal-dot-red", "terminal-dot-amber", "terminal-dot-green"):
            dot = Gtk.Box()
            dot.add_css_class(cls)
            dot.set_size_request(12, 12)
            topbar.append(dot)
        topbar.append(Gtk.Box(hexpand=True))
        term_lbl = Gtk.Label(label="output")
        term_lbl.add_css_class("terminal-label")
        topbar.append(term_lbl)
        topbar.append(Gtk.Box(hexpand=True))
        term_outer.append(topbar)

        if HAVE_VTE:
            self.terminal = Vte.Terminal()
            self.terminal.set_color_background(_rgba("#080a0f"))
            self.terminal.set_color_foreground(_rgba("#e2e8f0"))
            self.terminal.set_scroll_on_output(True)
            self.terminal.set_hexpand(True)
            self.terminal.set_vexpand(True)
            self.terminal.set_margin_top(4)
            self.terminal.set_margin_bottom(8)
            self.terminal.set_margin_start(8)
            self.terminal.set_margin_end(8)
            term_outer.append(self.terminal)
        else:
            sv = Gtk.ScrolledWindow()
            sv.set_hexpand(True)
            sv.set_vexpand(True)
            sv.set_margin_top(4)
            sv.set_margin_bottom(8)
            sv.set_margin_start(8)
            sv.set_margin_end(8)
            self.text_view = Gtk.TextView()
            self.text_view.set_editable(False)
            self.text_view.set_monospace(True)
            self.text_view.set_hexpand(True)
            self.text_view.set_vexpand(True)
            sv.set_child(self.text_view)
            term_outer.append(sv)

        root.append(term_outer)
        self.connect("close-request", self._on_close)

    # ─────────────────────────────────────────────────────────────────────
    #  Helpers
    # ─────────────────────────────────────────────────────────────────────

    def _hostname(self):
        try:
            import socket
            return socket.gethostname()
        except Exception:
            return ""

    def _on_check_toggled(self, check, card):
        if check.get_active():
            card.add_css_class("pm-selected")
        else:
            card.remove_css_class("pm-selected")

    def append_output(self, text):
        if HAVE_VTE:
            self.terminal.feed(text.replace("\n", "\r\n").encode())
        else:
            buf = self.text_view.get_buffer()
            buf.insert(buf.get_end_iter(), text)

    def clear_output(self):
        if HAVE_VTE:
            self.terminal.reset(True, True)
        else:
            self.text_view.get_buffer().set_text("")

    def _toast(self, msg, timeout=3):
        self.toast_overlay.add_toast(Adw.Toast(title=msg, timeout=timeout))

    def _update_stats(self):
        pac = self._results.get("pacman")
        aur = self._results.get("aur")

        def fmt(v):
            return str(v) if v is not None else "—"

        total = None
        if pac is not None or aur is not None:
            total = (pac or 0) + (aur or 0)

        self.total_num.set_label(fmt(total))
        self.pac_num.set_label(fmt(pac))
        self.aur_num.set_label(fmt(aur))

        self.total_num.remove_css_class("stat-zero")
        if total == 0:
            self.total_num.add_css_class("stat-zero")

    # ─────────────────────────────────────────────────────────────────────
    #  Update checking
    # ─────────────────────────────────────────────────────────────────────

    def start_check(self):
        self._results.clear()
        self.total_num.set_label("—")
        self.pac_num.set_label("—")
        self.aur_num.set_label("—")
        self.status_box.set_visible(False)
        self.refresh_btn.set_sensitive(False)

        for src in self.sources:
            if src.key not in self.widgets:
                continue
            _, pill, count_box, _, _ = self.widgets[src.key]
            for cls in ("pill-checking","pill-ready","pill-updates",
                        "pill-aur-updates","pill-missing"):
                pill.remove_css_class(cls)
            pill.set_label("checking…")
            pill.add_css_class("pill-checking")
            count_box.set_visible(False)

        for src in self.sources:
            t = threading.Thread(target=self._check_worker, args=(src,), daemon=True)
            t.start()
        return False

    def _check_worker(self, src: PMSource):
        count = None
        if src.check_cmd:
            try:
                r = subprocess.run(
                    src.check_cmd,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=60,
                )
                txt = r.stdout.strip()
                if txt.isdigit():
                    count = int(txt)
            except Exception:
                count = None
        GLib.idle_add(self._check_done, src, count)

    def _check_done(self, src: PMSource, count):
        self._results[src.key] = count
        if src.key in self.widgets:
            _, pill, count_box, count_lbl, _ = self.widgets[src.key]
            refresh_pill(pill, count_box, count_lbl, count, is_aur=src.is_aur)
        self._update_stats()

        if len(self._results) == len(self.sources):
            self.refresh_btn.set_sensitive(True)
            total = sum(v for v in self._results.values() if v is not None)
            if total > 0:
                self._toast(f"🔔 {total} update{'s' if total != 1 else ''} available", 4)
            else:
                self._toast("✓ Everything is up to date", 3)
        return False

    # ─────────────────────────────────────────────────────────────────────
    #  Running updates
    # ─────────────────────────────────────────────────────────────────────

    def on_update_clicked(self, _btn):
        if self.running:
            return
        selected = [
            src for src in self.sources
            if src.key in self.widgets
            and self.widgets[src.key][4].get_active()
            and src.update_cmd
        ]
        if not selected:
            self._toast("Nothing selected to update", 2)
            return

        needs_sudo = any(s.needs_sudo for s in selected)
        if needs_sudo:
            # Show password dialog; actual launch happens in the response handler
            dlg = PasswordDialog(self)
            dlg.connect("response", self._on_auth_response, selected)
            dlg.present(self)
        else:
            self._launch_update(selected, password=None)

    def _on_auth_response(self, dlg, response, selected):
        password = dlg.get_password() if response == "ok" else None
        dlg.close()
        if response != "ok" or not password:
            self._toast("Update cancelled.", 2)
            return
        self._launch_update(selected, password=password)

    def _launch_update(self, selected, password):
        self.running = True
        self.update_btn.set_sensitive(False)
        self.skip_btn.set_sensitive(False)
        self.refresh_btn.set_sensitive(False)
        self.status_box.set_visible(False)
        self.clear_output()

        self.pulse.start()
        self.progress.set_visible(True)
        self._progress_id = GLib.timeout_add(80, self._pulse_progress)

        labels = ", ".join(s.label for s in selected)
        self.append_output(f"\033[1;36m → Starting update: {labels}\033[0m\n\n")
        if any(s.needs_sudo for s in selected):
            self.append_output("\033[0;90m  (sudo -S — credentials sent via stdin)\033[0m\n\n")

        script = build_update_script(selected, password)
        t = threading.Thread(
            target=self._run_worker, args=(script, password), daemon=True
        )
        t.start()

    def _pulse_progress(self):
        if self.running:
            self.progress.pulse()
            return True
        return False

    def _run_worker(self, script, password: str | None):
        try:
            self.proc = subprocess.Popen(
                ["bash", "-lc", script],
                stdin=subprocess.PIPE if password else None,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )
            # Write password immediately so sudo -S can authenticate.
            # Close stdin right after so the pipe doesn't block downstream reads.
            if password and self.proc.stdin:
                try:
                    self.proc.stdin.write(password + "\n")
                    self.proc.stdin.flush()
                    self.proc.stdin.close()
                except BrokenPipeError:
                    pass

            for line in iter(self.proc.stdout.readline, ""):
                GLib.idle_add(self.append_output, line)
            self.proc.wait()
            code = self.proc.returncode
        except Exception as e:
            code = -1
            GLib.idle_add(self.append_output, f"\n\033[1;31merror: {e}\033[0m\n")
        GLib.idle_add(self._run_done, code)

    def _run_done(self, code):
        self.running = False

        if self._progress_id:
            GLib.source_remove(self._progress_id)
            self._progress_id = None

        self.pulse.stop()
        self.progress.set_fraction(1.0 if code == 0 else 0.0)
        GLib.timeout_add(1400, lambda: self.progress.set_visible(False) or False)

        self.update_btn.set_sensitive(True)
        self.skip_btn.set_sensitive(True)
        self.refresh_btn.set_sensitive(True)

        for cls in ("banner-ok", "banner-warn"):
            self.status_box.remove_css_class(cls)

        if code == 0:
            self.status_lbl.set_label("✓  Update complete — your system is now up to date.")
            self.status_box.add_css_class("banner-ok")
            self._toast("🎉 Update complete!", 4)
        else:
            self.status_lbl.set_label(
                f"⚠  Update ended with exit code {code}. Check the output above.")
            self.status_box.add_css_class("banner-warn")
            self._toast(f"Update ended with code {code}", 5)

        self.status_box.set_visible(True)
        self.append_output(
            f"\n\033[1;{'32' if code == 0 else '33'}m ✓ Done (exit {code})\033[0m\n")

        GLib.timeout_add(600, self.start_check)
        return False

    def _on_close(self, _win):
        if self.running and self.proc:
            try:
                self.proc.terminate()
            except Exception:
                pass
        return False


# =============================================================================
#  Helpers / App
# =============================================================================


def _rgba(hex_color):
    from gi.repository import Gdk
    rgba = Gdk.RGBA()
    rgba.parse(hex_color)
    return rgba


class UpdaterApp(Adw.Application):
    def __init__(self):
        super().__init__(
            application_id="dev.shellninja.pkgupdate",
            flags=Gio.ApplicationFlags.FLAGS_NONE,
        )
        self.connect("activate", self.on_activate)

    def on_activate(self, app):
        from gi.repository import Gdk

        provider = Gtk.CssProvider()
        provider.load_from_string(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )
        win = UpdaterWindow(app)
        win.present()


def main():
    import sys
    app = UpdaterApp()
    sys.exit(app.run(sys.argv))


if __name__ == "__main__":
    main()

    