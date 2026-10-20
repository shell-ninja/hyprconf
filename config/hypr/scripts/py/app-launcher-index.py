#!/usr/bin/env python3
"""
app-launcher-index.py — Fast Desktop Entry Indexer with Icon Resolution
Scans XDG application directories, resolves desktop entries, locates vector SVG
icons from the active icon theme, and outputs cached JSON for Quickshell Launcher.
"""

import os
import sys
import glob
import re
import time
import json
import configparser
from pathlib import Path

HOME = Path(os.getenv("HOME", str(Path.home())))
CACHE_DIR = HOME / ".hyprconf" / "hypr" / ".cache"
CACHE_FILE = CACHE_DIR / "apps.json"

APP_DIRS = [
    HOME / ".local" / "share" / "applications",
    Path("/usr/local/share/applications"),
    Path("/usr/share/applications"),
]


def resolve_icon(icon_name, theme=None):
    if not icon_name:
        return ""
    if os.path.isabs(icon_name) and os.path.exists(icon_name):
        return f"file://{icon_name}"

    if theme is not None:
        base = os.path.splitext(icon_name)[0]
        info = theme.lookup_icon(base, 48, 0)
        if info:
            return f"file://{info.get_filename()}"
        info = theme.lookup_icon(icon_name, 48, 0)
        if info:
            return f"file://{info.get_filename()}"

    return ""


def build_app_index():
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk

    theme = Gtk.IconTheme.get_default()

    apps = []
    seen = set()

    for app_dir in APP_DIRS:
        if not app_dir.is_dir():
            continue

        for entry_path in sorted(app_dir.glob("*.desktop")):
            app_id = entry_path.name
            if app_id in seen:
                continue

            cp = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                cp.read(str(entry_path), encoding="utf-8")
                if not cp.has_section("Desktop Entry"):
                    continue

                sec = cp["Desktop Entry"]
                if sec.getboolean("NoDisplay", fallback=False):
                    continue
                if sec.get("Type", "Application") != "Application":
                    continue

                name = sec.get("Name", "").strip()
                exec_cmd = sec.get("Exec", "").strip()
                if not name or not exec_cmd:
                    continue

                # Strip field codes like %u, %U, %f, %F, %i, %c, %k
                clean_exec = re.sub(r"%[a-zA-Z]", "", exec_cmd).strip()

                is_term = sec.getboolean("Terminal", fallback=False)
                if is_term:
                    clean_exec = f"kitty -e {clean_exec}"

                icon_name = sec.get("Icon", "").strip()
                icon_path = resolve_icon(icon_name, theme)
                comment = sec.get("Comment", "").strip()
                generic_name = sec.get("GenericName", "").strip()
                categories = [c.strip() for c in sec.get("Categories", "").split(";") if c.strip()]

                seen.add(app_id)
                apps.append({
                    "id": app_id,
                    "name": name,
                    "generic_name": generic_name,
                    "comment": comment or generic_name,
                    "exec": clean_exec,
                    "icon": icon_name,
                    "icon_path": icon_path,
                    "categories": categories,
                    "search_key": f"{name} {generic_name} {comment} {clean_exec} {' '.join(categories)}".lower()
                })
            except Exception:
                pass

    # Sort alphabetically by name
    apps.sort(key=lambda x: x["name"].lower())

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(apps, f, indent=2)

    return apps


def main():
    force_refresh = "--refresh" in sys.argv

    if not force_refresh and CACHE_FILE.exists():
        # Check cache age (regenerate if older than 1 hour)
        age = time.time() - CACHE_FILE.stat().st_mtime
        if age < 3600:
            try:
                with open(CACHE_FILE, "r", encoding="utf-8") as f:
                    content = f.read()
                    if content.strip():
                        print(content)
                        return
            except Exception:
                pass

    apps = build_app_index()
    print(json.dumps(apps, indent=2))


if __name__ == "__main__":
    main()
