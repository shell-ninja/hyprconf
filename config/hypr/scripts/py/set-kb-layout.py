#!/usr/bin/env python3
"""
set-kb-layout.py — Get, set, and list Hyprland keyboard layouts.

Usage:
    python3 set-kb-layout.py --get
    python3 set-kb-layout.py --set <code>
    python3 set-kb-layout.py --list
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

SETTINGS_FILE = Path(os.path.expanduser("~/.hyprconf/hypr/configs/settings.lua"))

POPULAR_CODES = [
    "us", "gb", "de", "fr", "es", "it", "pt", "br",
    "ru", "tr", "pl", "se", "no", "dk", "fi", "jp",
    "kr", "ara", "bd", "in", "nl", "cz", "hu", "ro",
    "ua", "latam", "ca", "ch"
]

FALLBACK_NAMES = {
    "us": "English (US)",
    "gb": "English (UK)",
    "de": "German",
    "fr": "French",
    "es": "Spanish",
    "it": "Italian",
    "pt": "Portuguese",
    "br": "Portuguese (Brazil)",
    "ru": "Russian",
    "tr": "Turkish",
    "pl": "Polish",
    "se": "Swedish",
    "no": "Norwegian",
    "dk": "Danish",
    "fi": "Finnish",
    "jp": "Japanese",
    "kr": "Korean",
    "cn": "Chinese",
    "ara": "Arabic",
    "bd": "Bangla",
    "in": "Indian",
    "nl": "Dutch",
    "cz": "Czech",
    "hu": "Hungarian",
    "ro": "Romanian",
    "ua": "Ukrainian",
    "latam": "Latin American",
    "ca": "French (Canada)",
    "ch": "Swiss",
    "be": "Belgian",
    "at": "German (Austria)",
    "gr": "Greek",
    "il": "Hebrew",
    "th": "Thai",
    "vn": "Vietnamese"
}


def load_xkb_layout_names():
    names = dict(FALLBACK_NAMES)
    candidates = [
        Path("/usr/share/X11/xkb/rules/base.lst"),
        Path("/usr/share/X11/xkb/rules/evdev.lst")
    ]
    for p in candidates:
        if p.is_file():
            try:
                in_layout = False
                with open(p, encoding="utf-8", errors="replace") as f:
                    for line in f:
                        line = line.strip()
                        if line == "! layout":
                            in_layout = True
                            continue
                        elif line.startswith("!") and in_layout:
                            break
                        if in_layout and line:
                            parts = line.split(maxsplit=1)
                            if len(parts) == 2:
                                names[parts[0]] = parts[1]
                break
            except Exception:
                continue
    return names


def get_current_layout():
    if SETTINGS_FILE.is_file():
        try:
            m = re.search(r'kb_layout\s*=\s*"([^"]*)"', SETTINGS_FILE.read_text())
            if m and m.group(1).strip():
                return m.group(1).strip()
        except Exception:
            pass

    try:
        res = subprocess.run(
            ["hyprctl", "getoption", "input:kb_layout"],
            capture_output=True,
            text=True,
            timeout=2
        )
        m = re.search(r"str:\s*([^\s\n]+)", res.stdout)
        if m and m.group(1).strip():
            return m.group(1).strip()
    except Exception:
        pass

    return "us"


def set_layout(layout_code: str):
    code = layout_code.strip()
    if not code:
        return False, "Empty layout code"

    # Validate layout string (letters, numbers, comma, hyphen, underscore, parentheses)
    if not re.match(r"^[a-zA-Z0-9_\-,\(\)\+]+$", code):
        return False, f"Invalid layout string format: '{code}'"

    # 1. Update settings.lua
    if SETTINGS_FILE.is_file():
        try:
            content = SETTINGS_FILE.read_text()
            if re.search(r"kb_layout\s*=", content):
                new_content = re.sub(
                    r'(kb_layout\s*=\s*")[^"]*(")',
                    rf'\g<1>{code}\g<2>',
                    content
                )
            else:
                new_content = re.sub(
                    r"(input\s*=\s*\{)",
                    rf'\1\n        kb_layout  = "{code}",',
                    content
                )
            SETTINGS_FILE.write_text(new_content)
        except Exception as e:
            return False, f"Failed writing to {SETTINGS_FILE}: {e}"
    else:
        return False, f"Settings file not found: {SETTINGS_FILE}"

    # 2. Live apply via hyprctl eval
    try:
        subprocess.run(
            ["hyprctl", "eval", f'hl.config({{ input = {{ kb_layout = "{code}" }} }})'],
            capture_output=True,
            text=True,
            timeout=2
        )
    except Exception:
        pass

    # 3. Reload config
    try:
        subprocess.run(
            ["hyprctl", "reload", "config-only"],
            capture_output=True,
            text=True,
            timeout=2
        )
    except Exception:
        pass

    return True, code


def main():
    names = load_xkb_layout_names()

    if len(sys.argv) < 2 or sys.argv[1] in ("--get", "-g"):
        curr = get_current_layout()
        print(json.dumps({
            "status": "ok",
            "layout": curr,
            "name": names.get(curr, curr.upper())
        }))
        return

    action = sys.argv[1]

    if action in ("--set", "-s"):
        if len(sys.argv) < 3:
            print(json.dumps({"status": "error", "message": "Missing layout code argument"}))
            sys.exit(1)
        code = sys.argv[2]
        ok, res = set_layout(code)
        if ok:
            print(json.dumps({
                "status": "ok",
                "layout": res,
                "name": names.get(res, res.upper())
            }))
        else:
            print(json.dumps({"status": "error", "message": res}))
            sys.exit(1)
        return

    if action in ("--list", "-l"):
        popular_set = set(POPULAR_CODES)
        popular_list = []
        for code in POPULAR_CODES:
            popular_list.append({
                "code": code,
                "name": names.get(code, code.upper()),
                "popular": True
            })

        other_list = []
        for code, name in sorted(names.items(), key=lambda x: x[1].lower()):
            if code not in popular_set:
                other_list.append({
                    "code": code,
                    "name": name,
                    "popular": False
                })

        # Popular layouts first, followed by all other system layouts alphabetically
        all_list = popular_list + other_list

        print(json.dumps({
            "status": "ok",
            "current": get_current_layout(),
            "popular": popular_list,
            "all": all_list
        }))
        return

    print(json.dumps({"status": "error", "message": f"Unknown option: {action}"}))
    sys.exit(1)


if __name__ == "__main__":
    main()
