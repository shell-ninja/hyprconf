#!/usr/bin/env python3
"""
pick-wallpaper-dir.py — Select and persist active wallpaper directory or choose video wallpaper.
Provides CLI retrieval/setting, native folder chooser dialog, and video file chooser.
Persists selection to ~/.hyprconf/hypr/.cache/wallpaper_config.json.
"""

import os
import sys
import json
import subprocess
from pathlib import Path

HOME = Path(os.environ.get("HOME", str(Path.home())))
CACHE_DIR = HOME / ".hyprconf" / "hypr" / ".cache"
CONFIG_FILE = CACHE_DIR / "wallpaper_config.json"
DEFAULT_WALLPAPER_DIR = str(HOME / ".hyprconf" / "hypr" / "Wallpaper")
DEFAULT_LIVE_DIR = str(HOME / ".hyprconf" / "hypr" / "Wallpaper" / "Live")
DEFAULT_WALLHAVEN_DIR = str(HOME / ".hyprconf" / "hypr" / "Wallpaper" / "wallhaven")


def get_current_dir() -> str:
    """Return the saved wallpaper directory or default fallback."""
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                d = data.get("wallpaper_dir")
                if d and os.path.isdir(d):
                    return os.path.abspath(os.path.expanduser(d))
        except Exception:
            pass
    return DEFAULT_WALLPAPER_DIR


def get_live_dir() -> str:
    """Return the saved live wallpaper directory or default fallback."""
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                d = data.get("live_dir")
                if d and os.path.isdir(d):
                    return os.path.abspath(os.path.expanduser(d))
        except Exception:
            pass
    if os.path.isdir(DEFAULT_LIVE_DIR):
        return DEFAULT_LIVE_DIR
    fallback = str(HOME / ".hyprconf" / "hypr" / "LiveWallpaper")
    if os.path.isdir(fallback):
        return fallback
    videos = str(HOME / "Videos")
    if os.path.isdir(videos):
        return videos
    return DEFAULT_LIVE_DIR


def save_dir(new_dir: str):
    """Save the chosen wallpaper directory into config file."""
    norm_path = os.path.abspath(os.path.expanduser(new_dir))
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cfg = {}
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                cfg = json.load(f)
        except Exception:
            cfg = {}
    cfg["wallpaper_dir"] = norm_path
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(cfg, f, indent=2)


def save_live_dir(new_dir: str):
    """Save the chosen live wallpaper directory into config file."""
    norm_path = os.path.abspath(os.path.expanduser(new_dir))
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cfg = {}
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                cfg = json.load(f)
        except Exception:
            cfg = {}
    cfg["live_dir"] = norm_path
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(cfg, f, indent=2)


def choose_dir(is_live: bool = False):
    """Open native folder chooser dialog and return chosen path."""
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk

    initial_dir = get_live_dir() if is_live else get_current_dir()
    if not os.path.isdir(initial_dir):
        initial_dir = str(HOME)

    title = "Select Live Wallpaper Directory" if is_live else "Select Wallpaper Directory"
    native = Gtk.FileChooserNative.new(
        title,
        None,
        Gtk.FileChooserAction.SELECT_FOLDER,
        "_Select Folder",
        "_Cancel"
    )
    native.set_current_folder(initial_dir)

    res = native.run()
    if res == Gtk.ResponseType.ACCEPT:
        chosen = native.get_filename()
        native.destroy()
        if chosen and os.path.isdir(chosen):
            if is_live:
                save_live_dir(chosen)
            else:
                save_dir(chosen)
            print(json.dumps({
                "status": "success",
                "path": os.path.abspath(chosen),
                "type": "live" if is_live else "wallpaper"
            }), flush=True)
            return

    native.destroy()
    print(json.dumps({"status": "cancelled"}), flush=True)


def choose_video():
    """Open video wallpaper file chooser dialog and apply with mpvpaper via Wallpaper.sh."""
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk

    initial_dir = get_live_dir()
    if not os.path.isdir(initial_dir):
        initial_dir = str(HOME / "Videos")
    if not os.path.isdir(initial_dir):
        initial_dir = get_current_dir()

    native = Gtk.FileChooserNative.new(
        "Select Live / Video Wallpaper (mpvpaper)",
        None,
        Gtk.FileChooserAction.OPEN,
        "_Set as Live Wallpaper",
        "_Cancel"
    )
    native.set_current_folder(initial_dir)

    # Video & GIF filter
    filter_video = Gtk.FileFilter()
    filter_video.set_name("Live / Video Wallpapers (*.mp4, *.webm, *.mkv, *.gif)")
    for ext in ["*.mp4", "*.webm", "*.mkv", "*.mov", "*.avi", "*.flv", "*.gif"]:
        filter_video.add_pattern(ext)
        filter_video.add_pattern(ext.upper())
    native.add_filter(filter_video)

    # All files filter
    filter_all = Gtk.FileFilter()
    filter_all.set_name("All Files")
    filter_all.add_pattern("*")
    native.add_filter(filter_all)

    res = native.run()
    if res == Gtk.ResponseType.ACCEPT:
        chosen = native.get_filename()
        native.destroy()
        if chosen and os.path.isfile(chosen):
            script_path = str(HOME / ".hyprconf" / "hypr" / "scripts" / "sh" / "Wallpaper.sh")
            subprocess.run(["bash", script_path, "--live", chosen])
            # Also save its parent directory as live_dir
            parent_dir = str(Path(chosen).parent)
            save_live_dir(parent_dir)
            print(json.dumps({
                "status": "success",
                "file": chosen,
                "path": parent_dir,
                "is_video": True
            }), flush=True)
            return

    native.destroy()
    print(json.dumps({"status": "cancelled"}), flush=True)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--get":
        print(get_current_dir(), flush=True)
    elif len(sys.argv) > 1 and sys.argv[1] == "--get-live":
        print(get_live_dir(), flush=True)
    elif len(sys.argv) > 1 and sys.argv[1] in ("--config", "--get-config"):
        cfg = {
            "wallpaper_dir": get_current_dir(),
            "live_dir": get_live_dir(),
            "color_variant": "vibrant"
        }
        if CONFIG_FILE.exists():
            try:
                with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    cfg["mode"] = data.get("mode", "static")
                    cfg["live_wallpaper"] = data.get("live_wallpaper", "")
                    if data.get("color_variant"):
                        cfg["color_variant"] = data.get("color_variant")
            except Exception:
                pass
        print(json.dumps(cfg), flush=True)
    elif len(sys.argv) > 2 and sys.argv[1] == "--set-variant":
        new_v = sys.argv[2].strip().lower()
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        cfg_data = {}
        if CONFIG_FILE.exists():
            try:
                with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                    cfg_data = json.load(f)
            except Exception:
                cfg_data = {}
        cfg_data["color_variant"] = new_v
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(cfg_data, f, indent=2)
        print(json.dumps({"status": "success", "color_variant": new_v}), flush=True)
    elif len(sys.argv) > 2 and sys.argv[1] == "--set":
        new_d = os.path.abspath(os.path.expanduser(sys.argv[2]))
        if os.path.isdir(new_d):
            save_dir(new_d)
            print(json.dumps({"status": "success", "path": new_d}), flush=True)
        else:
            print(json.dumps({"status": "error", "message": f"Directory not found: {new_d}"}), flush=True)
    elif len(sys.argv) > 2 and sys.argv[1] == "--set-live":
        new_d = os.path.abspath(os.path.expanduser(sys.argv[2]))
        if os.path.isdir(new_d):
            save_live_dir(new_d)
            print(json.dumps({"status": "success", "path": new_d}), flush=True)
        else:
            print(json.dumps({"status": "error", "message": f"Directory not found: {new_d}"}), flush=True)
    elif len(sys.argv) > 1 and sys.argv[1] in ("--pick-live-dir", "--pick-live-folder"):
        choose_dir(is_live=True)
    elif len(sys.argv) > 1 and sys.argv[1] in ("--pick-dir", "--pick-folder"):
        choose_dir(is_live=False)
    elif len(sys.argv) > 1 and sys.argv[1] in ("--pick-video", "--pick-file"):
        choose_video()
    else:
        choose_dir(is_live=False)
