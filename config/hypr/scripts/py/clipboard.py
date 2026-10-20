#!/usr/bin/env python3
"""
clipboard.py — Clipboard Management Helper for Quickshell Dynamic Island
Uses `cliphist`, `wl-paste`, and `wl-copy` to list, decode, copy, delete, and manage clipboard history.
"""

import sys
import os
import json
import re
import subprocess
import shutil

def is_daemon_running():
    try:
        out = subprocess.check_output(["pgrep", "-f", "cliphist store"], text=True)
        return len(out.strip()) > 0
    except Exception:
        return False

def ensure_daemon():
    if not is_daemon_running():
        if shutil.which("wl-paste") and shutil.which("cliphist"):
            try:
                subprocess.Popen(
                    ["wl-paste", "--watch", "cliphist", "store"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    start_new_session=True
                )
                subprocess.Popen(
                    ["wl-paste", "--type", "image", "--watch", "cliphist", "store"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    start_new_session=True
                )
            except Exception as e:
                pass

def classify_text(text):
    t = text.strip()
    if re.match(r'^(https?://|www\.)[^\s]+$', t):
        return "url"
    if re.match(r'^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$', t):
        return "color"
    code_indicators = ["def ", "class ", "import ", "const ", "let ", "function ", "#!/", "echo ", "sudo ", "{", "}", "=>", "return "]
    for ind in code_indicators:
        if ind in t:
            return "code"
    return "text"

def get_clip_list():
    ensure_daemon()
    if not shutil.which("cliphist"):
        return []

    try:
        proc = subprocess.run(["cliphist", "list"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
        lines = proc.stdout.splitlines()
        items = []
        for line in lines:
            line_str = line.strip()
            if not line_str:
                continue
            parts = line.split("\t", 1)
            item_id = parts[0].strip()
            preview = parts[1].strip() if len(parts) > 1 else ""
            if not preview and not item_id:
                continue
            
            c_type = classify_text(preview)
            items.append({
                "id": item_id,
                "raw": line,
                "preview": preview,
                "type": c_type,
                "length": len(preview)
            })
        return items
    except Exception as e:
        return []

def copy_entry(raw_line):
    if not shutil.which("cliphist") or not shutil.which("wl-copy"):
        return False
    try:
        decode_proc = subprocess.run(
            ["cliphist", "decode"],
            input=raw_line,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False
        )
        if decode_proc.returncode == 0:
            content = decode_proc.stdout
            subprocess.run(["wl-copy"], input=content, text=True, check=False)
            return True
        else:
            # Fallback: copy line after tab directly
            parts = raw_line.split("\t", 1)
            txt = parts[1] if len(parts) > 1 else raw_line
            subprocess.run(["wl-copy"], input=txt, text=True, check=False)
            return True
    except Exception as e:
        return False

def delete_entry(raw_line):
    if not shutil.which("cliphist"):
        return False
    try:
        subprocess.run(["cliphist", "delete"], input=raw_line, text=True, check=False)
        return True
    except Exception:
        return False

def wipe_history():
    if not shutil.which("cliphist"):
        return False
    try:
        subprocess.run(["cliphist", "wipe"], check=False)
        return True
    except Exception:
        return False

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "--list":
        items = get_clip_list()
        print(json.dumps(items))
        return

    cmd = sys.argv[1]
    if cmd == "--copy" and len(sys.argv) >= 3:
        raw = sys.argv[2]
        res = copy_entry(raw)
        print("ok" if res else "error")
    elif cmd == "--delete" and len(sys.argv) >= 3:
        raw = sys.argv[2]
        res = delete_entry(raw)
        print("ok" if res else "error")
    elif cmd == "--wipe":
        res = wipe_history()
        print("ok" if res else "error")
    elif cmd == "--daemon":
        ensure_daemon()
        print("daemon checked")
    else:
        print(json.dumps(get_clip_list()))

if __name__ == "__main__":
    main()
