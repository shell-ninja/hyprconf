#!/usr/bin/env python3
"""
noctalia-colors.py — Sync Noctalia Theme & Propagate to Hyprland, Kitty & Dolphin
Triggers Noctalia template generation (when explicitly changing wallpaper),
syncs the Qt6 color scheme so Dolphin picks up the new palette,
and reloads Hyprland and Kitty configurations.
"""

import os
import re
import sys
import fcntl
import shutil
import subprocess
from pathlib import Path

HOME = os.getenv("HOME", str(Path.home()))
CACHE_DIR = Path(HOME) / ".hyprconf/hypr/.cache"
CURRENT_WALLPAPER = CACHE_DIR / "current_wallpaper.png"
LOCK_FILE = Path("/tmp/noctalia_colors_sync.lock")


def sync_qt6ct_colors():
    """Copy the noctalia qt6ct color scheme to the live config directory
    so Dolphin and other Qt6 apps always use the current palette."""
    src = Path(HOME) / ".hyprconf/qt6ct/colors/noctalia.conf"
    dst_dir = Path(HOME) / ".config/qt6ct/colors"
    dst = dst_dir / "noctalia.conf"
    try:
        dst_dir.mkdir(parents=True, exist_ok=True)
        if src.exists():
            shutil.copy2(src, dst)
            print(f"Qt6ct color scheme synced: {dst}")
    except Exception as e:
        print(f"Warning: Qt6ct color sync failed: {e}", file=sys.stderr)

    # Also fix the color_scheme_path in case it ever has the wrong username
    qt6ct_conf = Path(HOME) / ".config/qt6ct/qt6ct.conf"
    correct_path = str(dst)
    if qt6ct_conf.exists():
        try:
            text = qt6ct_conf.read_text()
            text = re.sub(
                r"^color_scheme_path=.*$",
                f"color_scheme_path={correct_path}",
                text,
                flags=re.MULTILINE,
            )
            qt6ct_conf.write_text(text)
        except Exception as e:
            print(f"Warning: qt6ct.conf path fix failed: {e}", file=sys.stderr)


def notify_kde_reload():
    """Signal running Qt/KDE apps (e.g. Dolphin) to reload their color palette via DBus."""
    try:
        subprocess.run(
            [
                "dbus-send", "--session", "--type=signal",
                "/KGlobalSettings", "org.kde.KGlobalSettings.notifyChange",
                "int32:3", "int32:0",
            ],
            capture_output=True, timeout=3,
        )
    except Exception:
        pass


def sync_noctalia_theme(wallpaper_path=None, explicit_change=False):
    # Only set wallpaper and trigger template generation if explicitly requested
    # (e.g. via command-line argument or WallpaperSelect).
    # When called as a hook (colors_changed), Noctalia has ALREADY changed colors
    # and applied templates — calling wallpaper-set or templates-apply here would
    # cause an infinite recursion loop!
    if explicit_change and wallpaper_path and os.path.exists(wallpaper_path):
        try:
            subprocess.run(
                ["noctalia", "msg", "wallpaper-set", wallpaper_path],
                capture_output=True,
                text=True,
                timeout=5,
            )
        except Exception as e:
            print(f"Warning: Noctalia wallpaper-set failed: {e}", file=sys.stderr)

        try:
            subprocess.run(
                ["noctalia", "msg", "templates-apply"],
                capture_output=True,
                text=True,
                timeout=5,
            )
        except Exception as e:
            print(f"Warning: Noctalia templates-apply failed: {e}", file=sys.stderr)

    # Sync qt6ct color scheme so Dolphin picks up the new palette
    sync_qt6ct_colors()

    # Reload Hyprland configuration to update border colors
    subprocess.run(["hyprctl", "reload", "config-only"], capture_output=True)

    # Send SIGUSR1 to reload running Kitty instances
    subprocess.run("killall -SIGUSR1 kitty 2>/dev/null || true", shell=True)

    # Notify KDE/Qt apps (Dolphin, etc.) to reload their color palette via DBus
    notify_kde_reload()

    print("Noctalia colors applied and desktop reloaded.")


def main():
    # Use non-blocking flock to avoid overlapping / recursive executions
    lock_fd = os.open(str(LOCK_FILE), os.O_CREAT | os.O_RDWR)
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        # Another instance is already syncing colors, skip
        sys.exit(0)

    try:
        explicit_change = False
        wall = None
        if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
            wall = sys.argv[1]
            explicit_change = True

        sync_noctalia_theme(wall, explicit_change=explicit_change)
    finally:
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_UN)
            os.close(lock_fd)
        except Exception:
            pass


if __name__ == "__main__":
    main()
