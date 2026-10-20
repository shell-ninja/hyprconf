#!/usr/bin/env python3
"""
wallhaven-bridge.py — Lightweight Wallhaven API bridge for Quickshell Dynamic Island.
Handles searching, caching thumbnails, and downloading wallpapers.
"""

import sys
import os
import json
import argparse
import hashlib
import time
import subprocess
import requests

USER_AGENT = "QuickshellWallpaperPanel/1.0"
WALLHAVEN_API_BASE = "https://wallhaven.cc/api/v1"
CACHE_DIR = os.path.expanduser("~/.hyprconf/hypr/.cache")
THUMB_CACHE_DIR = os.path.expanduser("~/.cache/quickshell-wallpaper-panel/thumbnails")
STREAM_CACHE_DIR = os.path.join(CACHE_DIR, "stream")
WALLPAPER_SAVE_DIR = os.path.expanduser("~/.hyprconf/hypr/Wallpaper/wallhaven")

os.makedirs(THUMB_CACHE_DIR, exist_ok=True)
os.makedirs(STREAM_CACHE_DIR, exist_ok=True)
os.makedirs(WALLPAPER_SAVE_DIR, exist_ok=True)


def download_thumb(url, item_id):
    if not url:
        return ""
    digest = hashlib.sha1(url.encode()).hexdigest()[:10]
    local_path = os.path.join(THUMB_CACHE_DIR, f"wh_{item_id}_{digest}.jpg")
    if os.path.exists(local_path) and os.path.getsize(local_path) > 1000:
        return local_path

    try:
        r = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=8)
        if r.status_code == 200 and len(r.content) > 1000:
            with open(local_path, "wb") as f:
                f.write(r.content)
            return local_path
    except Exception:
        pass
    return url


def search_wallhaven(query="", sorting="toplist", categories="110", resolution="all", page=1):
    params = {
        "q": query or "",
        "sorting": sorting if not query else "relevance",
        "categories": categories or "110",
        "purity": "100",  # Strict SFW
        "page": page or 1
    }

    if resolution and resolution != "All Res" and resolution != "all":
        res_map = {
            "1080p": "1920x1080",
            "1440p": "2560x1440",
            "4k": "3840x2160"
        }
        target_res = res_map.get(resolution.lower(), resolution)
        params["resolutions"] = target_res

    headers = {"User-Agent": USER_AGENT}
    try:
        r = requests.get(f"{WALLHAVEN_API_BASE}/search", headers=headers, params=params, timeout=10)
        if r.status_code != 200:
            return []
        data = r.json().get("data", [])
        items = []
        for x in data:
            if str(x.get("purity", "")).lower() != "sfw":
                continue
            item_id = str(x.get("id", ""))
            full_url = x.get("path", "")
            thumbs = x.get("thumbs", {})
            thumb_url = thumbs.get("large") or thumbs.get("small") or thumbs.get("original") or full_url

            # Download or cache thumbnail
            local_thumb = download_thumb(thumb_url, item_id)
            source_uri = ("file://" + local_thumb) if local_thumb.startswith("/") else local_thumb

            items.append({
                "id": item_id,
                "title": f"wallhaven-{item_id}",
                "path": full_url,
                "url": full_url,
                "thumb": thumb_url,
                "source": source_uri
            })
        return items
    except Exception as e:
        sys.stderr.write(f"Search error: {e}\n")
        return []


def download_and_apply(url):
    if not url:
        return False
    if url.startswith("file://"):
        local_path = url[7:]
    elif url.startswith("/"):
        local_path = url
    else:
        # Download full wallpaper
        filename = os.path.basename(url.split("?")[0])
        local_path = os.path.join(WALLPAPER_SAVE_DIR, filename)
        if not (os.path.exists(local_path) and os.path.getsize(local_path) > 10000):
            try:
                r = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=25)
                if r.status_code == 200:
                    with open(local_path, "wb") as f:
                        f.write(r.content)
                else:
                    return False
            except Exception as e:
                sys.stderr.write(f"Download error: {e}\n")
                return False

    # Apply through Wallpaper.sh
    script_path = os.path.expanduser("~/.hyprconf/hypr/scripts/sh/Wallpaper.sh")
    subprocess.run(["bash", script_path, local_path])
    print(f"SUCCESS: {local_path}")
    return True


def main():
    parser = argparse.ArgumentParser(description="Wallhaven Quickshell Bridge")
    sub = parser.add_subparsers(dest="action")

    # Search
    p_search = sub.add_parser("search")
    p_search.add_argument("--query", default="")
    p_search.add_argument("--sorting", default="toplist")
    p_search.add_argument("--categories", default="110")
    p_search.add_argument("--resolution", default="all")
    p_search.add_argument("--page", type=int, default=1)

    # Apply
    p_apply = sub.add_parser("apply")
    p_apply.add_argument("--url", required=True)

    args = parser.parse_args()

    if args.action == "search":
        results = search_wallhaven(
            query=args.query,
            sorting=args.sorting,
            categories=args.categories,
            resolution=args.resolution,
            page=args.page
        )
        print(json.dumps(results))
    elif args.action == "apply":
        ok = download_and_apply(args.url)
        sys.exit(0 if ok else 1)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
