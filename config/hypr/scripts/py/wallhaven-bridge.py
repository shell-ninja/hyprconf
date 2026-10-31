#!/usr/bin/env python3
"""
wallhaven-bridge.py — High-performance Wallhaven API bridge for Quickshell Dynamic Island.
Handles searching, parallel caching of thumbnails, and downloading/applying wallpapers.
"""

import sys
import os
import json
import argparse
import hashlib
import subprocess
from concurrent.futures import ThreadPoolExecutor
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
    """Download thumbnail and return local file path or original url on failure."""
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
    """Query Wallhaven API, download thumbnails in parallel, and return item list."""
    # Categories: fallback to 110 if all toggles off or empty
    cat_str = str(categories).strip() if categories else "110"
    if cat_str in ("000", ""):
        cat_str = "110"

    # Sorting normalization
    sort_raw = str(sorting or "").strip().lower()
    if sort_raw in ("latest", "new"):
        sort_mode = "date_added"
    elif sort_raw in ("hot", "views", "favorites", "random", "toplist"):
        sort_mode = sort_raw
    else:
        sort_mode = "toplist"

    if query and not sorting:
        sort_mode = "relevance"

    params = {
        "q": query or "",
        "sorting": sort_mode,
        "categories": cat_str,
        "purity": "100",  # Strict SFW
        "page": page or 1
    }

    if sort_mode == "toplist":
        params["topRange"] = "1M"

    # Resolution handling
    if resolution:
        res_clean = str(resolution).strip().lower()
        if res_clean not in ("all", "all res", ""):
            if "21:9" in res_clean or "ultrawide" in res_clean:
                params["ratios"] = "21x9"
            elif "4k" in res_clean:
                params["atleast"] = "3840x2160"
            elif "1440p" in res_clean:
                params["atleast"] = "2560x1440"
            elif "1080p" in res_clean:
                params["atleast"] = "1920x1080"
            elif "x" in res_clean:
                params["resolutions"] = resolution.strip()

    headers = {"User-Agent": USER_AGENT}
    try:
        r = requests.get(f"{WALLHAVEN_API_BASE}/search", headers=headers, params=params, timeout=12)
        if r.status_code != 200:
            sys.stderr.write(f"Wallhaven API returned status code {r.status_code}\n")
            return []
        data = r.json().get("data", [])
        if not data:
            return []

        raw_items = []
        for x in data:
            if str(x.get("purity", "")).lower() != "sfw":
                continue
            item_id = str(x.get("id", ""))
            full_url = x.get("path", "")
            thumbs = x.get("thumbs", {})
            thumb_url = thumbs.get("large") or thumbs.get("small") or thumbs.get("original") or full_url
            raw_items.append({
                "id": item_id,
                "title": f"wallhaven-{item_id}",
                "path": full_url,
                "url": full_url,
                "thumb": thumb_url
            })

        # Download thumbnails concurrently with ThreadPoolExecutor
        def fetch_item_thumb(item):
            local_thumb = download_thumb(item["thumb"], item["id"])
            source_uri = ("file://" + local_thumb) if local_thumb.startswith("/") else local_thumb
            item["source"] = source_uri
            return item

        with ThreadPoolExecutor(max_workers=8) as executor:
            items = list(executor.map(fetch_item_thumb, raw_items))

        return items
    except Exception as e:
        sys.stderr.write(f"Search error: {e}\n")
        return []


def download_and_apply(url, variant=""):
    """Download Wallhaven wallpaper and set it via Wallpaper.sh."""
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
                subprocess.run(
                    ["notify-send", "-a", "Hyprconf", "Wallhaven", f"Downloading {filename}..."],
                    check=False
                )
                r = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=30)
                if r.status_code == 200 and len(r.content) > 10000:
                    with open(local_path, "wb") as f:
                        f.write(r.content)
                else:
                    subprocess.run(
                        ["notify-send", "-a", "Hyprconf", "Wallhaven Error", f"Download failed (HTTP {r.status_code})"],
                        check=False
                    )
                    return False
            except Exception as e:
                sys.stderr.write(f"Download error: {e}\n")
                subprocess.run(
                    ["notify-send", "-a", "Hyprconf", "Wallhaven Error", f"Download error: {e}"],
                    check=False
                )
                return False

    # Apply through Wallpaper.sh
    script_path = os.path.expanduser("~/.hyprconf/hypr/scripts/sh/Wallpaper.sh")
    cmd = ["bash", script_path]
    if variant:
        cmd.extend(["--variant", variant])
    cmd.append(local_path)
    subprocess.run(cmd)

    subprocess.run(
        ["notify-send", "-a", "Hyprconf", "Wallpaper Set", f"Applied: {os.path.basename(local_path)}"],
        check=False
    )
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
    p_apply.add_argument("--variant", default="")

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
        ok = download_and_apply(args.url, variant=args.variant)
        sys.exit(0 if ok else 1)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
