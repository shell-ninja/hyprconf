#!/usr/bin/env python3
"""Quick Paste backend: cursor capture, text/link history filtering, and 1-click auto-paste."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import clipboard  # noqa: E402

CACHE_DIR = Path.home() / ".local/share/hyprconf/.cache"
STATE_FILE = CACHE_DIR / "quickpaste_state.json"
TARGET_FILE = CACHE_DIR / "quickpaste_target.json"

MAX_ITEMS = 12
BINARY_RE = re.compile(r"^\[\[\s*binary data\b", re.IGNORECASE)

TERMINAL_CLASSES = {
    "kitty",
    "alacritty",
    "foot",
    "footclient",
    "wezterm",
    "org.wezterm.wezterm",
    "ghostty",
    "com.mitchellh.ghostty",
    "konsole",
    "org.kde.konsole",
    "gnome-terminal",
    "org.gnome.Terminal",
    "xfce4-terminal",
    "tilix",
    "terminator",
    "st",
    "st-256color",
    "urxvt",
    "rio",
}


def atomic_write_json(path: Path, payload: dict) -> None:
    """Write JSON atomically so readers never observe partial state."""
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    tmp.replace(path)


def run_cmd_raw(args: list[str], timeout: float = 1.5) -> str:
    """Execute a short command and return stripped stdout, or empty string on error."""
    try:
        res = subprocess.run(
            args,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
        return res.stdout.strip()
    except Exception:
        return ""


def parse_cursor_pos(raw: str) -> tuple[float, float]:
    """Parse `hyprctl cursorpos` output (`X, Y`)."""
    parts = raw.replace(",", " ").split()
    if len(parts) >= 2:
        try:
            return float(parts[0]), float(parts[1])
        except ValueError:
            pass
    return 0.0, 0.0


def monitor_logical_rect(mon: dict) -> tuple[float, float, float, float]:
    """Return `(x, y, logical_w, logical_h)` accounting for scale and rotation."""
    x = float(mon.get("x", 0))
    y = float(mon.get("y", 0))
    scale = float(mon.get("scale", 1.0) or 1.0)
    w = float(mon.get("width", 1920)) / scale
    h = float(mon.get("height", 1080)) / scale
    if int(mon.get("transform", 0)) % 2 == 1:
        w, h = h, w
    return x, y, w, h


def pick_monitor(monitors: list[dict], cx: float, cy: float) -> dict:
    """Select the monitor containing `(cx, cy)`, falling back to the focused monitor."""
    for mon in monitors:
        mx, my, mw, mh = monitor_logical_rect(mon)
        if mx <= cx < mx + mw and my <= cy < my + mh:
            return mon
    for mon in monitors:
        if mon.get("focused"):
            return mon
    return monitors[0] if monitors else {}


def find_fallback_target() -> dict[str, str]:
    """Return the most recently focused non-Quickshell client window."""
    raw = run_cmd_raw(["hyprctl", "clients", "-j"])
    if not raw:
        return {"address": "", "class": ""}
    try:
        clients = json.loads(raw)
    except Exception:
        return {"address": "", "class": ""}

    candidates = [
        c
        for c in clients
        if c.get("address")
        and "quickshell" not in (c.get("class") or "").lower()
        and int(c.get("focusHistoryID", -1)) >= 0
    ]
    if not candidates:
        return {"address": "", "class": ""}
    candidates.sort(key=lambda c: int(c.get("focusHistoryID", 9999)))
    top = candidates[0]
    return {
        "address": str(top.get("address", "")),
        "class": str(top.get("class", "")),
    }


def extract_url_host(text: str) -> str:
    """Extract readable domain/host for URL entries."""
    candidate = text.strip()
    if candidate.lower().startswith("www."):
        candidate = "https://" + candidate
    try:
        parsed = urllib.parse.urlparse(candidate)
        host = parsed.netloc or ""
        if host.lower().startswith("www."):
            host = host[4:]
        return host
    except Exception:
        return ""


def get_text_history(raw_cliphist: str, limit: int = MAX_ITEMS) -> list[dict]:
    """Filter `cliphist list` down to the newest non-binary text and URL entries."""
    items: list[dict] = []
    for line in raw_cliphist.splitlines():
        if not line or "\t" not in line:
            continue
        clip_id, preview = line.split("\t", 1)
        if BINARY_RE.match(preview.strip()):
            continue
        cleaned = preview.strip()
        if not cleaned:
            continue

        kind = clipboard.classify_text(cleaned)
        host = extract_url_host(cleaned) if kind == "url" else ""
        items.append(
            {
                "id": clip_id,
                "raw": line,
                "preview": cleaned,
                "kind": kind,
                "host": host,
            }
        )
        if len(items) >= limit:
            break
    return items


def prepare() -> None:
    """Capture cursor coordinates, monitor bounds, target window, and recent text clips."""
    clipboard.ensure_daemon()

    # Run independent compositor & cliphist queries concurrently for low latency.
    procs = {
        "cursor": subprocess.Popen(
            ["hyprctl", "cursorpos"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
        ),
        "monitors": subprocess.Popen(
            ["hyprctl", "monitors", "-j"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
        ),
        "active": subprocess.Popen(
            ["hyprctl", "activewindow", "-j"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
        ),
        "cliphist": subprocess.Popen(
            ["cliphist", "list"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
        ),
    }

    outputs: dict[str, str] = {}
    for key, proc in procs.items():
        try:
            out, _ = proc.communicate(timeout=1.5)
            outputs[key] = out or ""
        except Exception:
            proc.kill()
            outputs[key] = ""

    cx, cy = parse_cursor_pos(outputs["cursor"])

    try:
        monitors = json.loads(outputs["monitors"]) if outputs["monitors"] else []
    except Exception:
        monitors = []

    mon = pick_monitor(monitors, cx, cy)
    mx, my, mw, mh = monitor_logical_rect(mon) if mon else (0.0, 0.0, 1920.0, 1080.0)
    reserved = mon.get("reserved", [0, 0, 0, 0]) if isinstance(mon.get("reserved"), list) else [0, 0, 0, 0]
    while len(reserved) < 4:
        reserved.append(0)

    target = {"address": "", "class": ""}
    try:
        active = json.loads(outputs["active"]) if outputs["active"] else {}
        cls = str(active.get("class") or "")
        addr = str(active.get("address") or "")
        if addr and "quickshell" not in cls.lower():
            target = {"address": addr, "class": cls}
    except Exception:
        pass

    if not target["address"]:
        target = find_fallback_target()

    items = get_text_history(outputs["cliphist"], MAX_ITEMS)

    atomic_write_json(TARGET_FILE, target)
    atomic_write_json(
        STATE_FILE,
        {
            "timestamp": time.time(),
            "cursorX": cx,
            "cursorY": cy,
            "localX": cx - mx,
            "localY": cy - my,
            "screenName": str(mon.get("name", "")),
            "monWidth": mw,
            "monHeight": mh,
            "reserved": [float(v) for v in reserved[:4]],
            "targetClass": target["class"],
            "items": items,
        },
    )


def load_target() -> dict[str, str]:
    """Read target window metadata saved during --prepare, with fallback lookup."""
    if TARGET_FILE.exists():
        try:
            data = json.loads(TARGET_FILE.read_text(encoding="utf-8"))
            if isinstance(data, dict) and data.get("address"):
                return {
                    "address": str(data.get("address", "")),
                    "class": str(data.get("class", "")),
                }
        except Exception:
            pass
    return find_fallback_target()


def set_wayland_clipboard(data: bytes) -> None:
    """Populate Wayland regular and primary selections without hanging pipes."""
    for args in (["wl-copy"], ["wl-copy", "--primary"]):
        try:
            subprocess.run(
                args,
                input=data,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=1.5,
                check=False,
            )
        except Exception:
            pass


def paste_entry(raw_line: str) -> int:
    """Decode cliphist entry, restore target focus, and inject paste shortcut."""
    try:
        res = subprocess.run(
            ["cliphist", "decode"],
            input=raw_line.encode("utf-8"),
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=2.0,
            check=True,
        )
        decoded = res.stdout
    except Exception:
        return 1

    if not decoded:
        return 1

    set_wayland_clipboard(decoded)

    target = load_target()
    addr = target.get("address", "")
    cls = target.get("class", "").lower()

    # Wait briefly so the overlay unmaps and releases keyboard focus.
    time.sleep(0.06)

    if addr:
        subprocess.run(
            ["hyprctl", "dispatch", f'hl.dsp.focus({{ window = "address:{addr}" }})'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        time.sleep(0.07)

    mods = "CTRL,SHIFT" if cls in TERMINAL_CLASSES else "CTRL"
    subprocess.run(
        ["hyprctl", "dispatch", f'hl.dsp.send_shortcut({{ mods = "{mods}", key = "v" }})'],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Hyprconf Quick Paste helper")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--prepare", action="store_true", help="Snapshot cursor and recent text clips")
    group.add_argument("--paste", metavar="RAW_LINE", help="Decode cliphist entry and paste into target window")
    args = parser.parse_args()

    if args.prepare:
        prepare()
        return 0
    return paste_entry(args.paste)


if __name__ == "__main__":
    raise SystemExit(main())
