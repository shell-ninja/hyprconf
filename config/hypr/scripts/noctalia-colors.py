#!/usr/bin/env python3
"""
noctalia-colors.py — Sync Noctalia Theme & Propagate to Hyprland & Kitty
Triggers Noctalia template generation and reloads Hyprland and Kitty configurations.
"""

import os
import sys
import subprocess
from pathlib import Path

HOME = os.getenv("HOME", str(Path.home()))
CACHE_DIR = Path(HOME) / ".hyprconf/hypr/.cache"
CURRENT_WALLPAPER = CACHE_DIR / "current_wallpaper.png"

def get_wallpaper_path():
    if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
        return sys.argv[1]

    try:
        res = subprocess.run(
            ["noctalia", "msg", "wallpaper-get"],
            capture_output=True,
            text=True,
            timeout=2,
        )
        if res.returncode == 0 and res.stdout.strip() and os.path.exists(res.stdout.strip()):
            return res.stdout.strip()
    except Exception:
        pass

    if CURRENT_WALLPAPER.exists():
        try:
            target = CURRENT_WALLPAPER.resolve()
            if target.exists():
                return str(target)
        except Exception:
            pass

    return None

def sync_noctalia_theme(wallpaper_path=None):
    # If wallpaper path is known, set it in Noctalia
    if wallpaper_path and os.path.exists(wallpaper_path):
        try:
            subprocess.run(
                ["noctalia", "msg", "wallpaper-set", wallpaper_path],
                capture_output=True,
                text=True,
                timeout=5,
            )
        except Exception as e:
            print(f"Warning: Noctalia wallpaper-set failed: {e}", file=sys.stderr)

    # Trigger Noctalia template application
    try:
        subprocess.run(
            ["noctalia", "msg", "templates-apply"],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except Exception as e:
        print(f"Warning: Noctalia templates-apply failed: {e}", file=sys.stderr)

    # Reload Hyprland
    subprocess.run(["hyprctl", "reload"], capture_output=True)

    # Send SIGUSR1 to reload running Kitty instances
    subprocess.run("killall -SIGUSR1 kitty 2>/dev/null || true", shell=True)
    print("Noctalia colors applied and desktop reloaded.")

def main():
    wall = get_wallpaper_path()
    sync_noctalia_theme(wall)

if __name__ == "__main__":
    main()
