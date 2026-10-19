#!/usr/bin/env python3
# =============================================================================
#  pkgupdate-notifier.py — background package-update watchdog
#
#  Runs continuously in the background and periodically checks EVERY
#  package manager it can find on the system (pacman + AUR helper, dnf/dnf5,
#  yum, apt/apt-get, zypper, apk) plus Flatpak, for pending updates. Once the
#  combined total exceeds a threshold, it fires a single desktop
#  notification — styled to match systemupdate.sh's own large-update alert
#  (same nerd-font glyphs, warning-sign title, critical/no-auto-dismiss) —
#  showing:
#
#     1. package counts (broken out per source — e.g. Pacman vs AUR)
#     2. total download size
#     3. total install size
#     4. a reminder to press CTRL + U to open the updater and install them
#
#  Timing behaviour (the tricky part):
#     - While the machine stays on, it checks every INTERVAL hours.
#     - If the machine was OFF when a check was due, it checks immediately
#       the next time this script starts, then resumes the normal cadence.
#   This is done by persisting the timestamp of the last check to a small
#   state file on disk (~/.cache/pkgupdate-notifier/state.json), so the
#   "catch up on boot" behaviour survives reboots without needing systemd
#   timers, cron, or root privileges.
#
#  Companion to: systemupdate.sh (waybar module + CTRL+U updater) and
#  pkgupdate-gui.py (GTK update manager). This script does not perform any
#  updates itself — it only checks and notifies. Run the update itself via
#  systemupdate.sh --update or pkgupdate-gui.py, as before.
#
#  Usage:
#     python3 pkgupdate-notifier.py                  # run forever (daemon mode)
#     python3 pkgupdate-notifier.py --once            # single check, then exit
#     python3 pkgupdate-notifier.py --once --force    # single check, always notify
#     python3 pkgupdate-notifier.py --interval 3      # check every 3h instead of 5h
#     python3 pkgupdate-notifier.py --threshold 10     # notify only above 10 updates
#
#  See PROJECT_SUMMARY.md for full setup instructions (autostart, systemd
#  service, keybindings) and design notes.
# =============================================================================

from __future__ import annotations

import argparse
import fcntl
import json
import logging
import os
import re
import shutil
import signal
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

DEFAULT_INTERVAL_HOURS = 5
DEFAULT_THRESHOLD = 5  # notify only when MORE than this many updates are pending

CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "pkgupdate-notifier"
STATE_FILE = CACHE_DIR / "state.json"
LOCK_FILE = CACHE_DIR / "notifier.lock"
LOG_FILE = CACHE_DIR / "notifier.log"

# Reuse the same icon/sound assets as systemupdate.sh when present, so
# notifications look consistent with the rest of the rice. Falls back to a
# themed icon name if the hypr config isn't there (e.g. on a non-Hyprland box).
HYPR_ICONS = Path.home() / ".config/hypr/icons"
HYPR_SOUNDS = Path.home() / ".config/hypr/sounds"
UPDATE_ICON = HYPR_ICONS / "update.png"
SOUND_UPDATE = HYPR_SOUNDS / "update.wav"
FALLBACK_ICON = "software-update-available"


# -----------------------------------------------------------------------------
# Small helpers
# -----------------------------------------------------------------------------

def which(name: str) -> Optional[str]:
    return shutil.which(name)


def run(cmd: list[str], timeout: int = 90) -> str:
    """Run a command and return stdout text. Never raises — logs and returns
    "" on any failure (missing binary, timeout, non-zero exit, etc.), since a
    single package manager acting up shouldn't take the whole checker down."""
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.stdout or ""
    except Exception as e:  # noqa: BLE001 — deliberately broad, see docstring
        logging.debug("command failed: %s (%s)", cmd, e)
        return ""


_UNIT_MULT = {
    "B": 1,
    "KB": 1000, "K": 1000, "KIB": 1024,
    "MB": 1000 ** 2, "M": 1000 ** 2, "MIB": 1024 ** 2,
    "GB": 1000 ** 3, "G": 1000 ** 3, "GIB": 1024 ** 3,
    "TB": 1000 ** 4, "TIB": 1024 ** 4,
}


def parse_size(text: str) -> int:
    """Convert a human-readable size string ('45.2 MiB', '1,234 kB', '12 M')
    into bytes. Best-effort: unrecognised units are treated as bytes."""
    if not text:
        return 0
    text = text.strip().replace(",", "")
    m = re.match(r"([\d.]+)\s*([A-Za-z]+)", text)
    if not m:
        return 0
    value, unit = m.groups()
    mult = _UNIT_MULT.get(unit.upper(), 1)
    try:
        return int(float(value) * mult)
    except ValueError:
        return 0


def human_size(n: Optional[int]) -> str:
    if n is None:
        return "N/A"
    sign = "-" if n < 0 else ""
    n = float(abs(n))
    for unit in ("B", "KiB", "MiB", "GiB"):
        if n < 1024 or unit == "GiB":
            return f"{sign}{n:.0f} {unit}" if unit == "B" else f"{sign}{n:.1f} {unit}"
        n /= 1024
    return f"{sign}{n:.1f} TiB"


# -----------------------------------------------------------------------------
# Per-package-manager checkers
#
# Each checker returns a SourceResult, or None if that package manager isn't
# installed on this system. `count` mirrors the exact counting formula used
# by systemupdate.sh / pkgupdate-gui.py so the notification never disagrees
# with the waybar module. download_bytes / install_bytes are None when a
# manager genuinely can't report sizes ahead of time (e.g. AUR builds from
# source), which the notification renders as "N/A" rather than a wrong 0.
# -----------------------------------------------------------------------------

@dataclass
class SourceResult:
    key: str
    label: str
    count: int = 0
    download_bytes: Optional[int] = None
    install_bytes: Optional[int] = None


def check_pacman() -> Optional[SourceResult]:
    if not which("pacman") or not which("checkupdates"):
        return None
    out = run(["checkupdates"])
    names = [line.split()[0] for line in out.strip().splitlines() if line.strip()]
    dl = inst = 0
    if names:
        info = run(["pacman", "-Si", *names], timeout=60)
        dl = sum(parse_size(s) for s in re.findall(r"Download Size\s*:\s*(.+)", info))
        inst = sum(parse_size(s) for s in re.findall(r"Installed Size\s*:\s*(.+)", info))
    return SourceResult("pacman", "Pacman", len(names), dl, inst)


def check_aur() -> Optional[SourceResult]:
    aur_bin = which("yay") or which("paru")
    if not aur_bin:
        return None
    out = run([aur_bin, "-Qua"], timeout=120)
    lines = [l for l in out.strip().splitlines() if l.strip()]
    # AUR packages are built from PKGBUILDs locally — there's no published
    # download/install size before the build actually runs.
    return SourceResult("aur", f"AUR ({os.path.basename(aur_bin)})", len(lines), None, None)


def _dnf_style(bin_path: str, label: str) -> SourceResult:
    check_out = run([bin_path, "check-update", "--quiet"])
    count = len([
        l for l in check_out.splitlines()
        if l.strip() and "Last metadata expiration" not in l
    ])
    dl = inst = None
    if count:
        # --assumeno resolves the full transaction (and prints its summary,
        # including sizes) but always answers "no" to the confirmation
        # prompt, so nothing is actually installed.
        sim = run([bin_path, "upgrade", "--assumeno"], timeout=180)
        m_dl = re.search(r"Total download size:\s*(.+)", sim)
        m_inst = re.search(r"Install(?:ed)? size:\s*(.+)", sim)
        dl = parse_size(m_dl.group(1)) if m_dl else None
        inst = parse_size(m_inst.group(1)) if m_inst else None
    return SourceResult(bin_path.split("/")[-1], label, count, dl, inst)


def check_dnf() -> Optional[SourceResult]:
    bin_path = which("dnf5") or which("dnf")
    if not bin_path:
        return None
    return _dnf_style(bin_path, "DNF")


def check_yum() -> Optional[SourceResult]:
    if which("dnf5") or which("dnf"):
        return None  # avoid double-counting on systems that ship both
    bin_path = which("yum")
    if not bin_path:
        return None
    return _dnf_style(bin_path, "YUM")


def check_apt() -> Optional[SourceResult]:
    bin_path = which("apt-get") or which("apt")
    if not bin_path:
        return None
    listed = run([bin_path, "list", "--upgradable"])
    count = len([l for l in listed.splitlines() if "upgradable" in l])
    dl = inst = None
    if count:
        # Simulate mode (-s): resolves and prints the transaction summary
        # without changing anything on disk, no root required.
        sim = run([bin_path, "-s", "upgrade"], timeout=180)
        m_dl = re.search(r"Need to get\s+(.+?)\s+of archives", sim)
        m_used = re.search(r"After this operation,\s*(.+?)\s+of additional disk space will be used", sim)
        m_freed = re.search(r"After this operation,\s*(.+?)\s+disk space will be freed", sim)
        dl = parse_size(m_dl.group(1)) if m_dl else None
        if m_used:
            inst = parse_size(m_used.group(1))
        elif m_freed:
            inst = -parse_size(m_freed.group(1))
    return SourceResult("apt", "APT", count, dl, inst)


def check_zypper() -> Optional[SourceResult]:
    bin_path = which("zypper")
    if not bin_path:
        return None
    listed = run([bin_path, "--non-interactive", "lu", "--best-effort"])
    count = len(re.findall(r"^v\s+\|", listed, re.MULTILINE))
    dl = inst = None
    if count:
        sim = run([bin_path, "--non-interactive", "--no-refresh", "up", "--dry-run"], timeout=180)
        m_dl = re.search(r"Overall download size:\s*([\d.,]+\s*\w+)", sim)
        m_used = re.search(r"additional\s+([\d.,]+\s*\w+)\s+will be used", sim)
        m_freed = re.search(r"([\d.,]+\s*\w+)\s+will be freed", sim)
        dl = parse_size(m_dl.group(1)) if m_dl else None
        if m_used:
            inst = parse_size(m_used.group(1))
        elif m_freed:
            inst = -parse_size(m_freed.group(1))
    return SourceResult("zypper", "Zypper", count, dl, inst)


def check_apk() -> Optional[SourceResult]:
    bin_path = which("apk")
    if not bin_path:
        return None
    out = run([bin_path, "list", "--upgradable"], timeout=60)
    lines = [l for l in out.strip().splitlines() if l.strip()]
    # apk has no simulate/dry-run mode that reports sizes ahead of time.
    return SourceResult("apk", "APK (Alpine)", len(lines), None, None)


def check_flatpak() -> Optional[SourceResult]:
    bin_path = which("flatpak")
    if not bin_path:
        return None
    plain = run([bin_path, "remote-ls", "--updates"], timeout=60)
    count = len([l for l in plain.strip().splitlines() if l.strip()])
    if count == 0:
        return SourceResult("flatpak", "Flatpak", 0, 0, 0)

    dl = inst = 0
    sized_out = run(
        [bin_path, "remote-ls", "--updates", "--columns=download-size,installed-size"],
        timeout=60,
    )
    sized_lines = [l for l in sized_out.strip().splitlines() if l.strip()]
    if len(sized_lines) == count:
        try:
            for line in sized_lines:
                cols = line.split("\t")
                dl += parse_size(cols[0])
                inst += parse_size(cols[1])
        except Exception:
            dl = inst = None
    else:
        # Older flatpak versions don't support --columns=download-size — fall
        # back to "sizes unknown" rather than trusting misaligned columns.
        dl = inst = None
    return SourceResult("flatpak", "Flatpak", count, dl, inst)


CHECKERS = [
    check_pacman,
    check_aur,
    check_dnf,
    check_yum,
    check_apt,
    check_zypper,
    check_apk,
    check_flatpak,
]


def gather_results() -> list[SourceResult]:
    results = []
    for fn in CHECKERS:
        try:
            r = fn()
        except Exception:
            logging.exception("checker %s crashed", fn.__name__)
            r = None
        if r is not None:
            results.append(r)
    return results


# -----------------------------------------------------------------------------
# Notification
#
# Styled to match systemupdate.sh's own large_update_notification rather
# than generic emoji: the same 󱓽 / 󱓾 glyphs it already uses in the waybar
# tooltip (so we know they render on this system), a plain ⚠ for the
# title, no icon at all for sources that don't have a proven glyph (e.g.
# Flatpak), and the same "Press CTRL + U…" call to action.
# -----------------------------------------------------------------------------

# Nerd Font glyphs already used elsewhere in this rice (systemupdate.sh) —
# reused here so nothing new needs to render that hasn't already been
# proven to work on this system.
ICON_OFFICIAL = "\U000F14FD"   # 󱓽 — used for "official repo" counts
ICON_AUR = "\U000F14FE"        # 󱓾 — used for AUR counts
SOURCES_USE_OFFICIAL_ICON = {"pacman", "dnf", "dnf5", "yum", "apt", "zypper", "apk"}


def build_notification(results: list[SourceResult]) -> tuple[str, str, int]:
    active = [r for r in results if r.count > 0]
    total = sum(r.count for r in active)

    dl_total = inst_total = 0
    dl_unknown = inst_unknown = False
    lines = []
    for r in active:
        if r.key in SOURCES_USE_OFFICIAL_ICON:
            prefix = f"{ICON_OFFICIAL} "
        elif r.key == "aur":
            prefix = f"{ICON_AUR} "
        else:
            prefix = "  "  # e.g. Flatpak — no proven glyph, just indent
        lines.append(f"{prefix}{r.label:<14} {r.count}")
        if r.download_bytes is None:
            dl_unknown = True
        else:
            dl_total += r.download_bytes
        if r.install_bytes is None:
            inst_unknown = True
        else:
            inst_total += r.install_bytes

    title = f"\u26A0 {total} Package Update{'s' if total != 1 else ''} Pending"

    dl_str = human_size(dl_total) + (" +" if dl_unknown and dl_total else "")
    inst_str = human_size(inst_total) + (" +" if inst_unknown and inst_total else "")
    if dl_unknown and not dl_total:
        dl_str = "N/A"
    if inst_unknown and not inst_total:
        inst_str = "N/A"

    body_lines = lines + [
        "",
        f"Download: {dl_str}",
        f"Install:  {inst_str}",
    ]
    if dl_unknown or inst_unknown:
        body_lines.append("(+ = some sources don't report size ahead of time, e.g. AUR)")

    body_lines += ["", "Press CTRL + U to open the package updater and update your packages."]

    return title, "\n".join(body_lines), total


def send_notification(title: str, body: str) -> None:
    icon = str(UPDATE_ICON) if UPDATE_ICON.exists() else FALLBACK_ICON
    cmd = [
        "notify-send",
        "--urgency=critical",
        "--expire-time=0",       # stays until dismissed — same as the
                                  # existing >10-updates alert in
                                  # systemupdate.sh, since this is the
                                  # same kind of "go press CTRL+U" reminder
        "--app-name=Package Updates",
        "--icon", icon,
        title,
        body,
    ]
    if which("notify-send"):
        subprocess.run(cmd, check=False)
    else:
        logging.warning("notify-send not found — skipping desktop notification")

    if SOUND_UPDATE.exists() and which("paplay"):
        subprocess.Popen(
            ["paplay", str(SOUND_UPDATE)],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )


# -----------------------------------------------------------------------------
# Check-and-notify cycle
# -----------------------------------------------------------------------------

def run_check(threshold: int, force_notify: bool = False) -> list[SourceResult]:
    logging.info("Running update check…")
    results = gather_results()
    total = sum(r.count for r in results)
    found = ", ".join(f"{r.label}={r.count}" for r in results) or "no package managers found"
    logging.info("Total pending updates: %d (%s)", total, found)

    if force_notify or total > threshold:
        title, body, _ = build_notification(results)
        send_notification(title, body)
        logging.info("Notification sent (%s).", "forced" if force_notify else f"total {total} > threshold {threshold}")
    else:
        logging.info("Below threshold (%d <= %d) — staying quiet.", total, threshold)

    return results


# -----------------------------------------------------------------------------
# State persistence (drives the "catch up on boot" behaviour)
# -----------------------------------------------------------------------------

def load_state() -> dict:
    try:
        return json.loads(STATE_FILE.read_text())
    except Exception:
        return {}


def save_state(state: dict) -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state))


# -----------------------------------------------------------------------------
# Single-instance lock — prevents two copies (e.g. a re-login) from both
# polling package managers at once.
# -----------------------------------------------------------------------------

def acquire_lock():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    fh = open(LOCK_FILE, "w")
    try:
        fcntl.flock(fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        logging.error("Another instance is already running — exiting.")
        sys.exit(1)
    fh.write(str(os.getpid()))
    fh.flush()
    return fh  # caller must keep this open for the life of the process


# -----------------------------------------------------------------------------
# Daemon loop
# -----------------------------------------------------------------------------

_shutdown = False


def _handle_signal(signum, _frame) -> None:
    global _shutdown
    logging.info("Received signal %s — shutting down.", signum)
    _shutdown = True


def sleep_interruptible(seconds: float) -> None:
    end = time.time() + seconds
    while not _shutdown and time.time() < end:
        time.sleep(min(30, max(0.0, end - time.time())))


def daemon_loop(interval_hours: float, threshold: int) -> None:
    interval = interval_hours * 3600
    signal.signal(signal.SIGTERM, _handle_signal)
    signal.signal(signal.SIGINT, _handle_signal)

    logging.info("Notifier started. interval=%sh threshold=%d", interval_hours, threshold)

    while not _shutdown:
        state = load_state()
        last = state.get("last_check")
        now = time.time()
        elapsed = (now - last) if last else None

        if elapsed is None or elapsed >= interval:
            # Either this is the very first run, or a check was due while
            # the machine was off — catch up immediately.
            run_check(threshold)
            save_state({"last_check": time.time()})
            sleep_for = interval
        else:
            sleep_for = interval - elapsed

        if _shutdown:
            break
        logging.info("Next check in %.2f hours", sleep_for / 3600)
        sleep_interruptible(sleep_for)

    logging.info("Notifier stopped.")


# -----------------------------------------------------------------------------
# Entry point
# -----------------------------------------------------------------------------

def setup_logging() -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[
            logging.FileHandler(LOG_FILE),
            logging.StreamHandler(),
        ],
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Background package-update notifier")
    parser.add_argument("--once", action="store_true", help="Run a single check and exit (no loop)")
    parser.add_argument("--force", action="store_true", help="Always send a notification, even below threshold (implies --once)")
    parser.add_argument("--interval", type=float, default=DEFAULT_INTERVAL_HOURS, help=f"Hours between checks (default: {DEFAULT_INTERVAL_HOURS})")
    parser.add_argument("--threshold", type=int, default=DEFAULT_THRESHOLD, help=f"Notify only when MORE than this many updates are pending (default: {DEFAULT_THRESHOLD})")
    args = parser.parse_args()

    setup_logging()
    lock_fh = acquire_lock()
    try:
        if args.once or args.force:
            run_check(args.threshold, force_notify=args.force)
        else:
            daemon_loop(args.interval, args.threshold)
    finally:
        lock_fh.close()


if __name__ == "__main__":
    main()
