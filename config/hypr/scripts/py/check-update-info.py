#!/usr/bin/env python3
"""
check-update-info.py — Fast, rate-limit immune update and changelog discovery for Hyprconf.
Outputs structured JSON consumed by Settings Studio (UpdateSection.qml) and CLI tools.
"""

import urllib.request
import json
import subprocess
import re
import sys
import os
from pathlib import Path

HOME = Path.home()
REPO_URL = "https://github.com/shell-ninja/hyprconf"
RAW_BASE = "https://raw.githubusercontent.com/shell-ninja/hyprconf/main"

def get_local_version() -> str:
    candidates = [
        HOME / ".hyprconf" / ".version",
        HOME / ".local" / "share" / "hyprconf" / ".version",
        Path("/main/Code/shell-ninja/hyprconf-qs/.version")
    ]
    for c in candidates:
        if c.is_file():
            try:
                v = c.read_text(encoding="utf-8").strip()
                if v:
                    return v
            except Exception:
                pass
    return "v1.0.2"

def parse_semver(v: str) -> tuple:
    if not v:
        return ()
    v = v.lstrip("vV").strip()
    parts = re.split(r"[-+.]", v)
    nums = []
    for p in parts:
        try:
            nums.append(int(p))
        except ValueError:
            nums.append(0)
    return tuple(nums)

def fetch_remote_info(local_ver: str) -> dict:
    remote_ver = None
    release_name = ""
    release_body = ""
    published_at = ""

    # 1. Attempt raw .version from GitHub main branch (Instant & immune to 60 req/hr rate limits)
    try:
        req = urllib.request.Request(
            f"{RAW_BASE}/.version",
            headers={"User-Agent": "hyprconf-updater"}
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            txt = resp.read().decode("utf-8").strip()
            if txt and txt.startswith("v"):
                remote_ver = txt
    except Exception:
        pass

    # 2. Check git ls-remote tags (Git protocol over HTTPS, also rate-limit immune)
    try:
        res = subprocess.run(
            ["git", "ls-remote", "--tags", "--refs", f"{REPO_URL}.git"],
            capture_output=True, text=True, timeout=6
        )
        if res.returncode == 0 and res.stdout.strip():
            found = []
            for line in res.stdout.strip().splitlines():
                m = re.search(r"refs/tags/(v?[0-9].*)", line)
                if m:
                    found.append(m.group(1))
            if found:
                found.sort(key=parse_semver)
                if not remote_ver or parse_semver(found[-1]) > parse_semver(remote_ver):
                    remote_ver = found[-1]
    except Exception:
        pass

    # 3. Optional: Attempt GitHub Releases API for release date & body if under rate limit
    try:
        req = urllib.request.Request(
            "https://api.github.com/repos/shell-ninja/hyprconf/releases/latest",
            headers={"User-Agent": "hyprconf-updater", "Accept": "application/vnd.github.v3+json"}
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            if isinstance(data, dict):
                tag = data.get("tag_name")
                if tag and (not remote_ver or parse_semver(tag) >= parse_semver(remote_ver)):
                    remote_ver = tag
                release_name = data.get("name", "")
                release_body = data.get("body", "")
                published_at = data.get("published_at", "")
    except Exception:
        pass

    # 4. Fetch release highlights from whatsnew.json (remote raw fallback to local)
    features = []
    title = f"What's New in {remote_ver or local_ver}"
    subtitle = "Performance enhancements, updated obsidian aesthetics, and system refinements."
    keybinds_notice = ""

    try:
        req = urllib.request.Request(
            f"{RAW_BASE}/config/quickshell/welcome/whatsnew.json",
            headers={"User-Agent": "hyprconf-updater"}
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            d = json.loads(resp.read().decode("utf-8"))
            versions = d.get("versions", [])
            if versions:
                v0 = versions[0]
                title = v0.get("title", title)
                subtitle = v0.get("subtitle", subtitle)
                features = v0.get("features", [])
                keybinds_notice = v0.get("keybindsNotice", "")
    except Exception:
        pass

    if not features:
        local_whatsnew = HOME / ".hyprconf" / "quickshell" / "welcome" / "whatsnew.json"
        if not local_whatsnew.is_file():
            local_whatsnew = Path("/main/Code/shell-ninja/hyprconf-qs/config/quickshell/welcome/whatsnew.json")
        if local_whatsnew.is_file():
            try:
                d = json.loads(local_whatsnew.read_text(encoding="utf-8"))
                versions = d.get("versions", [])
                if versions:
                    v0 = versions[0]
                    title = v0.get("title", title)
                    subtitle = v0.get("subtitle", subtitle)
                    features = v0.get("features", [])
                    keybinds_notice = v0.get("keybindsNotice", "")
            except Exception:
                pass

    final_remote = remote_ver or local_ver
    has_update = parse_semver(final_remote) > parse_semver(local_ver)

    return {
        "status": "ok" if remote_ver else "fallback",
        "local": local_ver,
        "remote": final_remote,
        "has_update": bool(has_update),
        "release_name": release_name or final_remote,
        "published_at": published_at,
        "title": title,
        "subtitle": subtitle,
        "keybinds_notice": keybinds_notice,
        "features": features
    }

def main():
    local_ver = get_local_version()
    if len(sys.argv) > 1 and sys.argv[1] == "--local-only":
        print(json.dumps({"local": local_ver}))
        return

    info = fetch_remote_info(local_ver)
    print(json.dumps(info, indent=2))

if __name__ == "__main__":
    main()
