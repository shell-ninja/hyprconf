#!/usr/bin/env python3
"""
paste-emoji.py — Copies selected emoji to clipboard, updates recent emojis,
refocuses target window, and dispatches native paste shortcut.
"""
import sys
import os
import json
import time
import shutil
import subprocess

CACHE_DIR = os.path.expanduser("~/.hyprconf/hypr/.cache")
RECENT_FILE = os.path.join(CACHE_DIR, "recent_emojis.json")
TARGET_FILE = os.path.join(CACHE_DIR, "emoji_target.json")

def find_fallback_target():
    try:
        raw = subprocess.check_output(["hyprctl", "clients", "-j"], stderr=subprocess.DEVNULL)
        clients = json.loads(raw)
        valid = [
            c for c in clients
            if c.get("mapped", True) and not c.get("hidden", False)
            and c.get("class", "").lower() not in ["quickshell", "qs", ""]
        ]
        if valid:
            valid.sort(key=lambda x: x.get("focusHistoryID", 999))
            return valid[0].get("address", ""), valid[0].get("class", "").lower()
    except Exception:
        pass
    return "", ""

def main():
    if len(sys.argv) < 2:
        sys.exit(0)
    emoji = sys.argv[1]
    if not emoji:
        sys.exit(0)

    # 1. Copy emoji to Wayland clipboard and primary selection
    try:
        subprocess.run(["wl-copy", "--", emoji], check=False)
        subprocess.run(["wl-copy", "--primary", "--", emoji], check=False)
    except Exception:
        pass

    # Also store into cliphist if running so clipboard history retains it
    if shutil.which("cliphist"):
        try:
            subprocess.run(["cliphist", "store"], input=emoji.encode("utf-8"), check=False)
        except Exception:
            pass

    # 2. Update recent emojis cache
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        recent = []
        if os.path.exists(RECENT_FILE):
            try:
                with open(RECENT_FILE, "r", encoding="utf-8") as f:
                    recent = json.load(f)
            except Exception:
                recent = []
        recent = [x for x in recent if x != emoji]
        recent.insert(0, emoji)
        recent = recent[:40]
        with open(RECENT_FILE, "w", encoding="utf-8") as f:
            json.dump(recent, f, ensure_ascii=False)
    except Exception:
        pass

    # 3. Read target window
    target_addr = ""
    target_class = ""
    if os.path.exists(TARGET_FILE):
        try:
            with open(TARGET_FILE, "r", encoding="utf-8") as f:
                tdata = json.load(f)
                target_addr = tdata.get("address", "")
                target_class = tdata.get("class", "").lower()
        except Exception:
            pass

    # If no valid target address was stored, find the most recently focused client
    if not target_addr:
        target_addr, target_class = find_fallback_target()

    # 4. Close Dynamic Island emoji view & standalone emoji picker
    subprocess.run(["qs", "ipc", "-c", "island", "call", "island", "closeEmoji"], stderr=subprocess.DEVNULL)
    subprocess.run(["pkill", "-f", "qs -c emoji"], stderr=subprocess.DEVNULL)

    # Allow window manager time to unmap the surface
    time.sleep(0.12)

    # 5. Refocus target window using Hyprland Lua dispatcher
    if target_addr:
        addr_arg = target_addr if target_addr.startswith("address:") else f"address:{target_addr}"
        try:
            subprocess.run(
                ["hyprctl", "dispatch", f'hl.dsp.focus({{ window = "{addr_arg}" }})'],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        except Exception:
            pass

    time.sleep(0.08)

    # 6. Dispatch paste shortcut to target window
    is_terminal = any(term in target_class for term in [
        "kitty", "alacritty", "foot", "wezterm", "terminal",
        "ghostty", "rio", "xterm", "urxvt", "gnome-terminal", "konsole"
    ])
    mods = "CTRL,SHIFT" if is_terminal else "CTRL"

    # Use native Hyprland send_shortcut dispatcher
    try:
        subprocess.run(
            ["hyprctl", "dispatch", f'hl.dsp.send_shortcut({{ mods = "{mods}", key = "v" }})'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception:
        pass

    # If wtype is present, provide additional keyboard typing fallback
    if shutil.which("wtype"):
        try:
            if is_terminal:
                subprocess.run(["wtype", "-M", "ctrl", "-M", "shift", "-k", "v", "-m", "shift", "-m", "ctrl"], stderr=subprocess.DEVNULL)
            else:
                subprocess.run(["wtype", "-M", "ctrl", "-k", "v", "-m", "ctrl"], stderr=subprocess.DEVNULL)
        except Exception:
            pass

if __name__ == "__main__":
    main()
