#!/usr/bin/env python3
"""
list-wallpaper-dirs.py — Scan directories for wallpaper images, video wallpapers, and subdirectories.
Outputs structured JSON for Quickshell in-app directory navigation and video wallpaper selection.
"""

import os
import sys
import json
import hashlib
import argparse
import subprocess
from pathlib import Path

HOME = Path(os.environ.get("HOME", str(Path.home())))
CONFIG_FILE = HOME / ".hyprconf" / "hypr" / ".cache" / "wallpaper_config.json"
DEFAULT_WALLPAPER_DIR = str(HOME / ".hyprconf" / "hypr" / "Wallpaper")
THUMB_CACHE_DIR = HOME / ".cache" / "quickshell-wallpaper-panel" / "thumbnails"

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
VIDEO_EXTENSIONS = {".mp4", ".mkv", ".webm", ".avi", ".mov", ".flv", ".gif"}
ALL_EXTENSIONS = IMAGE_EXTENSIONS | VIDEO_EXTENSIONS

THUMB_CACHE_DIR.mkdir(parents=True, exist_ok=True)


def get_default_dir() -> str:
    """Read saved wallpaper directory from config or fallback to default."""
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


def count_wallpapers(dir_path: str) -> int:
    """Count image files in directory without recursion."""
    count = 0
    try:
        with os.scandir(dir_path) as it:
            for entry in it:
                try:
                    if entry.is_file(follow_symlinks=True):
                        ext = os.path.splitext(entry.name)[1].lower()
                        if ext in IMAGE_EXTENSIONS:
                            count += 1
                except (PermissionError, FileNotFoundError, OSError):
                    continue
    except (PermissionError, FileNotFoundError, OSError):
        pass
    return count


def count_videos(dir_path: str) -> int:
    """Count video and GIF files in directory without recursion."""
    count = 0
    try:
        with os.scandir(dir_path) as it:
            for entry in it:
                try:
                    if entry.is_file(follow_symlinks=True):
                        ext = os.path.splitext(entry.name)[1].lower()
                        if ext in VIDEO_EXTENSIONS:
                            count += 1
                except (PermissionError, FileNotFoundError, OSError):
                    continue
    except (PermissionError, FileNotFoundError, OSError):
        pass
    return count


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
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=4)
        if os.path.exists(thumb_path) and os.path.getsize(thumb_path) > 500:
            return thumb_path
        # Fallback to frame 0
        cmd[2] = "00:00:00"
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3)
        if os.path.exists(thumb_path) and os.path.getsize(thumb_path) > 500:
            return thumb_path
    except Exception:
        pass
    return ""


def get_videos_in_dir(dir_path: str) -> list:
    """Scan and return video wallpapers inside dir_path."""
    videos = []
    try:
        with os.scandir(dir_path) as it:
            for entry in it:
                try:
                    if entry.is_file(follow_symlinks=True):
                        ext = os.path.splitext(entry.name)[1].lower()
                        if ext in VIDEO_EXTENSIONS:
                            st = entry.stat()
                            thumb_path = get_video_thumb(entry.path, st.st_mtime)
                            thumb_uri = ("file://" + thumb_path) if thumb_path else ("file://" + entry.path if ext == ".gif" else "")
                            base_name = os.path.splitext(entry.name)[0]
                            size_mb = round(st.st_size / (1024 * 1024), 1)
                            videos.append({
                                "name": entry.name,
                                "title": base_name,
                                "path": entry.path,
                                "ext": ext.upper().lstrip("."),
                                "size_mb": size_mb,
                                "thumb": thumb_uri,
                                "source": thumb_uri,
                                "is_video": True,
                                "is_gif": (ext == ".gif")
                            })
                except (PermissionError, FileNotFoundError, OSError):
                    continue
    except (PermissionError, FileNotFoundError, OSError):
        pass

    videos.sort(key=lambda x: x["name"].lower())
    return videos


def check_has_subdirs(dir_path: str, include_hidden: bool = False) -> bool:
    """Check if directory contains any child subdirectories."""
    try:
        with os.scandir(dir_path) as it:
            for entry in it:
                try:
                    if entry.is_dir(follow_symlinks=True):
                        if not include_hidden and entry.name.startswith("."):
                            continue
                        return True
                except (PermissionError, FileNotFoundError, OSError):
                    continue
    except (PermissionError, FileNotFoundError, OSError):
        pass
    return False


DEFAULT_LIVE_DIR = str(HOME / ".hyprconf" / "hypr" / "Wallpaper" / "Live")
DEFAULT_WALLHAVEN_DIR = str(HOME / ".hyprconf" / "hypr" / "Wallpaper" / "wallhaven")


def get_bookmarks() -> list:
    """Return common quick-jump bookmark paths."""
    candidates = [
        {"name": "Wallpapers", "path": DEFAULT_WALLPAPER_DIR, "icon": "󰉋"},
        {"name": "Live Walls", "path": DEFAULT_LIVE_DIR, "icon": "󰕧"},
        {"name": "Wallhaven", "path": DEFAULT_WALLHAVEN_DIR, "icon": "★"},
        {"name": "Videos", "path": str(HOME / "Videos"), "icon": "󰕧"},
        {"name": "Pictures", "path": str(HOME / "Pictures"), "icon": "󰉏"},
        {"name": "Downloads", "path": str(HOME / "Downloads"), "icon": "󰇚"},
        {"name": "Home", "path": str(HOME), "icon": "󰋜"}
    ]
    return [b for b in candidates if os.path.isdir(b["path"])]


def list_directory(target_path: str, show_hidden: bool = False) -> dict:
    """Inspect target_path and return directory information and video wallpapers."""
    target = os.path.abspath(os.path.expanduser(target_path))
    if not os.path.exists(target) or not os.path.isdir(target):
        return {
            "status": "error",
            "message": f"Path is not a valid directory: {target_path}",
            "current_path": target,
            "parent_path": str(Path(target).parent) if target != "/" else None,
            "current_wall_count": 0,
            "current_video_count": 0,
            "directories": [],
            "videos": [],
            "bookmarks": get_bookmarks()
        }

    auto_hidden = show_hidden or any(part.startswith(".") for part in Path(target).parts)

    subdirs = []
    try:
        with os.scandir(target) as it:
            for entry in it:
                try:
                    if entry.is_dir(follow_symlinks=True):
                        if not auto_hidden and entry.name.startswith("."):
                            continue
                        p = entry.path
                        subdirs.append({
                            "name": entry.name,
                            "path": p,
                            "wall_count": count_wallpapers(p),
                            "video_count": count_videos(p),
                            "has_sub": check_has_subdirs(p, auto_hidden)
                        })
                except (PermissionError, FileNotFoundError, OSError):
                    continue
    except (PermissionError, OSError) as e:
        return {
            "status": "error",
            "message": f"Permission denied: {str(e)}",
            "current_path": target,
            "parent_path": str(Path(target).parent) if target != "/" else None,
            "current_wall_count": 0,
            "current_video_count": 0,
            "directories": [],
            "videos": [],
            "bookmarks": get_bookmarks()
        }

    subdirs.sort(key=lambda x: x["name"].lower())
    parent = str(Path(target).parent) if target != "/" else None
    videos = get_videos_in_dir(target)

    return {
        "status": "success",
        "current_path": target,
        "parent_path": parent,
        "current_wall_count": count_wallpapers(target),
        "current_video_count": len(videos),
        "directories": subdirs,
        "videos": videos,
        "bookmarks": get_bookmarks()
    }


def main():
    parser = argparse.ArgumentParser(description="List wallpaper directories, image counts, and video wallpapers.")
    parser.add_argument("--path", "-p", type=str, default="", help="Target directory path")
    parser.add_argument("--show-hidden", action="store_true", help="Include hidden directories")
    args = parser.parse_args()

    target = args.path if args.path else get_default_dir()
    result = list_directory(target, show_hidden=args.show_hidden)
    print(json.dumps(result))


if __name__ == "__main__":
    main()
