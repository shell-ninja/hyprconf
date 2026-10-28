#!/usr/bin/env python3
"""
pkg-check.py — Fast parallel package-update checker for Quickshell updater.
Checks Pacman (checkupdates), AUR (paru/yay), and Flatpak concurrently.
Emits structured JSON to stdout.
"""

from __future__ import annotations

import concurrent.futures
import json
import os
import shutil
import subprocess
import sys


def parse_pkg_line(line: str) -> dict | None:
    parts = line.strip().split()
    if len(parts) >= 4 and parts[2] == "->":
        return {
            "name": parts[0],
            "old": parts[1],
            "new": parts[3],
        }
    elif len(parts) >= 3:
        return {
            "name": parts[0],
            "old": parts[1],
            "new": parts[2],
        }
    elif len(parts) == 1:
        return {
            "name": parts[0],
            "old": "",
            "new": "latest",
        }
    return None


def check_pacman() -> dict:
    if not shutil.which("checkupdates"):
        return {
            "available": False,
            "installed": bool(shutil.which("pacman")),
            "count": 0,
            "packages": [],
        }

    try:
        proc = subprocess.run(
            ["checkupdates"],
            capture_output=True,
            text=True,
            timeout=20,
        )
        pkgs = []
        for line in proc.stdout.strip().splitlines():
            item = parse_pkg_line(line)
            if item:
                pkgs.append(item)
        return {
            "available": True,
            "installed": True,
            "count": len(pkgs),
            "packages": pkgs,
        }
    except Exception as e:
        return {
            "available": False,
            "installed": True,
            "count": 0,
            "packages": [],
            "error": str(e),
        }


def check_aur() -> dict:
    helper = None
    if shutil.which("paru"):
        helper = "paru"
    elif shutil.which("yay"):
        helper = "yay"

    if not helper:
        return {
            "available": False,
            "installed": False,
            "helper": "",
            "count": 0,
            "packages": [],
        }

    try:
        proc = subprocess.run(
            [helper, "-Qua"],
            capture_output=True,
            text=True,
            timeout=25,
        )
        pkgs = []
        for line in proc.stdout.strip().splitlines():
            item = parse_pkg_line(line)
            if item:
                pkgs.append(item)
        return {
            "available": True,
            "installed": True,
            "helper": helper,
            "count": len(pkgs),
            "packages": pkgs,
        }
    except Exception as e:
        return {
            "available": False,
            "installed": True,
            "helper": helper,
            "count": 0,
            "packages": [],
            "error": str(e),
        }


def check_flatpak() -> dict:
    if not shutil.which("flatpak"):
        return {
            "available": False,
            "installed": False,
            "count": 0,
            "packages": [],
        }

    try:
        proc = subprocess.run(
            ["flatpak", "remote-ls", "--updates"],
            capture_output=True,
            text=True,
            timeout=20,
        )
        pkgs = []
        for line in proc.stdout.strip().splitlines():
            parts = line.split()
            if parts:
                pkgs.append({
                    "name": parts[0],
                    "old": "",
                    "new": parts[1] if len(parts) > 1 else "latest",
                })
        return {
            "available": True,
            "installed": True,
            "count": len(pkgs),
            "packages": pkgs,
        }
    except Exception as e:
        return {
            "available": False,
            "installed": True,
            "count": 0,
            "packages": [],
            "error": str(e),
        }


def get_os_info() -> dict:
    info = {"name": "Linux", "id": "linux"}
    if os.path.exists("/etc/os-release"):
        try:
            with open("/etc/os-release", encoding="utf-8") as f:
                for line in f:
                    if line.startswith("PRETTY_NAME="):
                        info["name"] = line.split("=", 1)[1].strip().strip('"')
                    elif line.startswith("ID="):
                        info["id"] = line.split("=", 1)[1].strip().strip('"')
        except Exception:
            pass
    return info


def main():
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        f_pac = executor.submit(check_pacman)
        f_aur = executor.submit(check_aur)
        f_flat = executor.submit(check_flatpak)

        pacman_res = f_pac.result()
        aur_res = f_aur.result()
        flatpak_res = f_flat.result()

    total = pacman_res["count"] + aur_res["count"] + flatpak_res["count"]
    data = {
        "os": get_os_info(),
        "total": total,
        "pacman": pacman_res,
        "aur": aur_res,
        "flatpak": flatpak_res,
    }
    print(json.dumps(data))


if __name__ == "__main__":
    main()
