#!/usr/bin/env python3
"""
pkg-check.py — Fast parallel package-update checker for Quickshell updater.
Supports multi-distro native package managers (Pacman, APT, DNF, Zypper),
AUR helpers (paru, yay), and Flatpak concurrently.
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


def detect_native_manager() -> tuple[str, str, str]:
    """Returns (manager_type, display_name, description)"""
    os_info = get_os_info()
    os_id = os_info.get("id", "").lower()

    if os_id in ("arch", "endeavouros", "manjaro", "garuda", "cachyos", "artix") or shutil.which("pacman"):
        return ("pacman", "Pacman", "Official Arch Linux repositories")
    elif os_id in ("debian", "ubuntu", "pop", "linuxmint", "elementary", "zorin", "kali") or shutil.which("apt-get"):
        return ("apt", "APT", "Official Debian/Ubuntu repositories")
    elif os_id in ("fedora", "rhel", "centos", "almalinux", "rocky") or shutil.which("dnf5") or shutil.which("dnf"):
        return ("dnf", "DNF", "Official Fedora/RHEL repositories")
    elif os_id in ("opensuse", "opensuse-tumbleweed", "opensuse-leap", "sles") or shutil.which("zypper"):
        return ("zypper", "Zypper", "Official openSUSE repositories")
    elif shutil.which("pacman"):
        return ("pacman", "Pacman", "Official Arch Linux repositories")
    elif shutil.which("apt-get"):
        return ("apt", "APT", "Official Debian/Ubuntu repositories")
    elif shutil.which("dnf5") or shutil.which("dnf"):
        return ("dnf", "DNF", "Official Fedora/RHEL repositories")
    elif shutil.which("zypper"):
        return ("zypper", "Zypper", "Official openSUSE repositories")
    return ("unknown", "Package Manager", "System repositories")


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


def check_apt() -> dict:
    if not shutil.which("apt-get"):
        return {
            "available": False,
            "installed": False,
            "count": 0,
            "packages": [],
        }

    try:
        proc = subprocess.run(
            ["apt-get", "-s", "-o", "Debug::NoLocking=true", "upgrade"],
            capture_output=True,
            text=True,
            timeout=25,
        )
        pkgs = []
        for line in proc.stdout.splitlines():
            if line.startswith("Inst "):
                parts = line.split()
                if len(parts) >= 2:
                    name = parts[1]
                    old = ""
                    new = ""
                    if len(parts) >= 3 and parts[2].startswith("["):
                        old = parts[2].strip("[]")
                    for p in parts[2:]:
                        if p.startswith("(") and not new:
                            new = p.strip("()")
                    pkgs.append({
                        "name": name,
                        "old": old,
                        "new": new or "latest",
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


def check_dnf() -> dict:
    dnf_bin = shutil.which("dnf5") or shutil.which("dnf")
    if not dnf_bin:
        return {
            "available": False,
            "installed": False,
            "count": 0,
            "packages": [],
        }

    try:
        proc = subprocess.run(
            [dnf_bin, "check-update", "-q"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        # dnf check-update returns code 100 when updates exist, 0 when clean
        pkgs = []
        for line in proc.stdout.splitlines():
            parts = line.strip().split()
            if len(parts) >= 3 and "." in parts[0]:
                pkgs.append({
                    "name": parts[0],
                    "old": "",
                    "new": parts[1],
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


def check_zypper() -> dict:
    if not shutil.which("zypper"):
        return {
            "available": False,
            "installed": False,
            "count": 0,
            "packages": [],
        }

    try:
        proc = subprocess.run(
            ["zypper", "--non-interactive", "list-updates"],
            capture_output=True,
            text=True,
            timeout=25,
        )
        pkgs = []
        for line in proc.stdout.splitlines():
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 6 and parts[0] == "v":
                pkgs.append({
                    "name": parts[2],
                    "old": parts[3],
                    "new": parts[4],
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


def main():
    mgr_type, mgr_name, mgr_desc = detect_native_manager()

    tasks = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        if mgr_type == "pacman":
            tasks["native"] = executor.submit(check_pacman)
            tasks["aur"] = executor.submit(check_aur)
        elif mgr_type == "apt":
            tasks["native"] = executor.submit(check_apt)
        elif mgr_type == "dnf":
            tasks["native"] = executor.submit(check_dnf)
        elif mgr_type == "zypper":
            tasks["native"] = executor.submit(check_zypper)
        else:
            tasks["native"] = executor.submit(lambda: {"available": False, "installed": False, "count": 0, "packages": []})

        tasks["flatpak"] = executor.submit(check_flatpak)

        native_res = tasks["native"].result()
        aur_res = tasks["aur"].result() if "aur" in tasks else {
            "available": False,
            "installed": False,
            "helper": "",
            "count": 0,
            "packages": [],
        }
        flatpak_res = tasks["flatpak"].result()

    total = native_res["count"] + aur_res["count"] + flatpak_res["count"]
    data = {
        "os": get_os_info(),
        "total": total,
        "nativeType": mgr_type,
        "nativeName": mgr_name,
        "nativeDesc": mgr_desc,
        "native": native_res,
        "pacman": native_res if mgr_type == "pacman" else {"available": False, "installed": False, "count": 0, "packages": []},
        "aur": aur_res,
        "flatpak": flatpak_res,
    }
    print(json.dumps(data))


if __name__ == "__main__":
    main()
