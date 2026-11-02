#!/usr/bin/env python3
"""
audio-devices.py — Fast Pipewire / Wireplumber audio device query and switcher
Parses wpctl status to enumerate sinks (output) and sources (input) with active states.
"""

import re
import sys
import json
import subprocess

def get_devices():
    try:
        res = subprocess.run(["wpctl", "status"], capture_output=True, text=True, timeout=2)
        lines = res.stdout.split("\n")
    except Exception as e:
        return {"sinks": [], "sources": [], "error": str(e)}

    sinks = []
    sources = []
    current_section = None

    for line in lines:
        stripped = line.strip()
        # Track Audio sections
        if "Sinks:" in stripped:
            current_section = "sinks"
            continue
        elif "Sources:" in stripped:
            current_section = "sources"
            continue
        elif "Filters:" in stripped or "Streams:" in stripped or "Video" in stripped:
            current_section = None
            continue

        if current_section in ("sinks", "sources"):
            # Match line format: [*]   55. Built-in Audio Analog Stereo        [vol: 0.70]
            m = re.search(r'([*]?)\s*(\d+)\.\s+([^[.]+?)(?:\s+\[vol:\s*([\d.]+))?(?:\s*\[.*\])?$', stripped)
            if m:
                is_default = bool(m.group(1))
                dev_id = int(m.group(2))
                dev_name = m.group(3).strip()
                vol_str = m.group(4)
                vol = float(vol_str) if vol_str else 1.0

                item = {
                    "id": dev_id,
                    "name": dev_name,
                    "is_default": is_default,
                    "volume": vol
                }
                if current_section == "sinks":
                    sinks.append(item)
                else:
                    sources.append(item)

    return {"sinks": sinks, "sources": sources}

def set_default(dev_id):
    try:
        subprocess.run(["wpctl", "set-default", str(dev_id)], check=True, timeout=2)
        return True
    except Exception as e:
        print(f"Error setting default device {dev_id}: {e}", file=sys.stderr)
        return False

def main():
    if len(sys.argv) > 2 and sys.argv[1] in ("--set-sink", "--set-source", "--set"):
        dev_id = sys.argv[2]
        success = set_default(dev_id)
        sys.exit(0 if success else 1)

    data = get_devices()
    print(json.dumps(data, indent=2))

if __name__ == "__main__":
    main()
