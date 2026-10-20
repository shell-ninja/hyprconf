#!/usr/bin/env python3
"""
scan-wallpapers.py — Rapidly scan wallpaper directories for images and video wallpapers.
Generates cached thumbnails for video files using ffmpeg and emits structured JSON.
"""

import os
import sys
import json
import hashlib
import argparse
import subprocess
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

HOME = Path(os.environ.get("HOME", str(Path.home())))
CACHE_DIR = HOME / ".hyprconf" / "hypr" / ".cache"
CONFIG_FILE = CACHE_DIR / "wallpaper_config.json"
DEFAULT_WALLPAPER_DIR = str(HOME / ".hyprconf" / "hypr" / "Wallpaper")
DEFAULT_LIVE_DIR = str(HOME / ".hyprconf" / "hypr" / "Wallpaper" / "Live")
DEFAULT_WALLHAVEN_DIR = str(HOME / ".hyprconf" / "hypr" / "Wallpaper" / "wallhaven")
THUMB_CACHE_DIR = HOME / ".cache" / "quickshell-wallpaper-panel" / "thumbnails"

IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
VIDEO_EXTS = {".mp4", ".mkv", ".webm", ".avi", ".mov", ".flv"}
GIF_EXT = {".gif"}
ALL_EXTS = IMAGE_EXTS | VIDEO_EXTS | GIF_EXT

THUMB_CACHE_DIR.mkdir(parents=True, exist_ok=True)


def get_default_dir() -> str:
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


def get_default_live_dir() -> str:
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
    videos_dir = str(HOME / "Videos")
    if os.path.isdir(videos_dir):
        return videos_dir
    return DEFAULT_LIVE_DIR


def get_video_thumb(video_path: str, mtime: float) -> str:
    """Generate or retrieve cached thumbnail for video files."""
    digest = hashlib.sha1(f"{video_path}_{mtime}".encode()).hexdigest()[:14]
    thumb_path = str(THUMB_CACHE_DIR / f"vid_{digest}.jpg")
    if os.path.exists(thumb_path) and os.path.getsize(thumb_path) > 1000:
        return thumb_path

    try:
        cmd = [
            "ffmpeg", "-y", "-ss", "00:00:01",
            "-i", video_path,
            "-frames:v", "1",
            "-vf", "scale=400:230:force_original_aspect_ratio=increase,crop=400:230",
            "-q:v", "3",
            thumb_path
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=6)
        if os.path.exists(thumb_path) and os.path.getsize(thumb_path) > 500:
            return thumb_path
        # Fallback to frame 0
        cmd[2] = "00:00:00"
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=4)
        if os.path.exists(thumb_path) and os.path.getsize(thumb_path) > 500:
            return thumb_path
    except Exception:
        pass
    return ""


def process_entry(entry_tuple):
    filename, fullpath, ext, mtime, size = entry_tuple
    base_name = os.path.splitext(filename)[0]
    is_video = ext in VIDEO_EXTS or ext in GIF_EXT
    size_mb = round(size / (1024 * 1024), 1)

    thumb_uri = "file://" + fullpath
    if ext in VIDEO_EXTS:
        t_path = get_video_thumb(fullpath, mtime)
        if t_path:
            thumb_uri = "file://" + t_path
    elif ext in GIF_EXT:
        t_path = get_video_thumb(fullpath, mtime)
        if t_path:
            thumb_uri = "file://" + t_path

    return {
        "filename": filename,
        "title": base_name,
        "path": fullpath,
        "source": thumb_uri,
        "is_video": is_video,
        "is_gif": (ext in GIF_EXT),
        "ext": ext.upper().lstrip("."),
        "size_mb": size_mb
    }


def scan_directory(target_dir: str, max_depth: int = 1, file_type: str = "all") -> list:
    """Scan target_dir without mixing subdirectories into the same list."""
    target = os.path.abspath(os.path.expanduser(target_dir))
    if not os.path.isdir(target):
        return []

    if file_type in ("wallpaper", "static", "image"):
        allowed_exts = IMAGE_EXTS
    elif file_type in ("live", "video"):
        allowed_exts = VIDEO_EXTS | GIF_EXT
    else:
        allowed_exts = ALL_EXTS

    collected = []
    try:
        if max_depth <= 1:
            with os.scandir(target) as entries:
                for entry in entries:
                    try:
                        if entry.is_file(follow_symlinks=True):
                            ext = os.path.splitext(entry.name)[1].lower()
                            if ext in allowed_exts:
                                st = entry.stat(follow_symlinks=True)
                                collected.append((entry.name, entry.path, ext, st.st_mtime, st.st_size))
                    except (PermissionError, FileNotFoundError, OSError):
                        continue
        else:
            for root, dirs, files in os.walk(target, followlinks=True):
                rel_depth = len(Path(root).relative_to(target).parts)
                if rel_depth >= max_depth:
                    dirs.clear()
                elif os.path.abspath(target) == os.path.abspath(DEFAULT_WALLPAPER_DIR):
                    dirs[:] = [d for d in dirs if d.lower() not in ("live", "wallhaven")]
                for f in files:
                    ext = os.path.splitext(f)[1].lower()
                    if ext in allowed_exts:
                        full = os.path.join(root, f)
                        try:
                            st = os.stat(full)
                            collected.append((f, full, ext, st.st_mtime, st.st_size))
                        except OSError:
                            continue
    except Exception:
        pass

    collected.sort(key=lambda x: x[0].lower())

    results = []
    with ThreadPoolExecutor(max_workers=4) as executor:
        for res in executor.map(process_entry, collected):
            results.append(res)

    return results


def main():
    parser = argparse.ArgumentParser(description="Scan wallpapers and video wallpapers without mixing subdirectories.")
    parser.add_argument("--dir", "-d", default="", help="Target directory")
    parser.add_argument("--type", "-t", default="all", choices=["wallpaper", "static", "live", "video", "all"], help="Filter file type")
    parser.add_argument("--depth", type=int, default=1, help="Max depth (default: 1, strict per-directory)")
    args = parser.parse_args()

    if args.dir:
        target = args.dir
    else:
        if args.type in ("live", "video"):
            target = get_default_live_dir()
        else:
            target = get_default_dir()

    items = scan_directory(target, max_depth=args.depth, file_type=args.type)
    print(json.dumps(items))


if __name__ == "__main__":
    main()
