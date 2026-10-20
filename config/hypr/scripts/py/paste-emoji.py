#!/usr/bin/env python3
"""
paste-emoji.py — Copies selected emoji to clipboard, updates recent emojis,
refocuses target window, and dispatches native paste shortcut.
"""
import sys
import os
import json
import time
import subprocess

CACHE_DIR = os.path.expanduser("~/.hyprconf/hypr/.cache")
RECENT_FILE = os.path.join(CACHE_DIR, "recent_emojis.json")
TARGET_FILE = os.path.join(CACHE_DIR, "emoji_target.json")

def main():
    if len(sys.argv) < 2:
        sys.exit(0)
    emoji = sys.argv[1]
    if not emoji:
        sys.exit(0)

    # 1. Copy emoji to Wayland clipboard
    try:
        subprocess.run(["wl-copy", emoji], check=True)
    except Exception as e:
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
        # Deduplicate and place at front
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

    # 4. Close Dynamic Island emoji view
    subprocess.run(["qs", "ipc", "-c", "island", "call", "island", "closeEmoji"], stderr=subprocess.DEVNULL)
    subprocess.run(["pkill", "-f", "qs -c emoji"], stderr=subprocess.DEVNULL)

    # Small delay for Hyprland window focus to return to previous window
    time.sleep(0.08)

    # Refocus target window if address is known
    if target_addr:
        try:
            subprocess.run(
                ["hyprctl", "dispatch", f"focuswindow address:{target_addr}"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        except Exception:
            pass

    time.sleep(0.05)

    # 5. Dispatch paste shortcut to target window
    # Check if target is a terminal
    is_terminal = any(term in target_class for term in ["kitty", "alacritty", "foot", "wezterm", "terminal"])
    mod = "ctrl shift" if is_terminal else "ctrl"
    
    # Use Hyprland Lua dispatcher
    lua_cmd = f'hl.dispatch(hl.dsp.send_shortcut({{ mod = "{mod}", key = "v" }}))'
    try:
        subprocess.run(
            ["hyprctl", "repl", lua_cmd],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception:
        pass

if __name__ == "__main__":
    main()
