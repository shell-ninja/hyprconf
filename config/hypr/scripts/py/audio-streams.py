#!/usr/bin/env python3
"""
audio-streams.py — Real-Time Per-Application Audio Stream Matrix for Hyprconf
Parses PulseAudio / PipeWire sink-inputs to list running audio applications,
their volume levels, mute states, and provides instant control commands.
"""

import sys
import re
import json
import subprocess

def get_streams():
    try:
        res = subprocess.run(["pactl", "list", "sink-inputs"], capture_output=True, text=True, timeout=2)
        raw = res.stdout
    except Exception as e:
        return {"streams": [], "error": str(e)}

    blocks = raw.split("Sink Input #")
    streams = []

    for b in blocks:
        if not b.strip():
            continue
        lines = b.split("\n")
        idx_str = lines[0].strip()
        if not idx_str.isdigit():
            continue
        stream_id = int(idx_str)

        app_name = ""
        media_name = ""
        binary_name = ""
        icon_name = ""
        corked = False
        muted = False
        volume = 1.0

        for line in lines:
            line = line.strip()
            if line.startswith("Corked:"):
                corked = (line.split(":", 1)[1].strip().lower() == "yes")
            elif line.startswith("Mute:"):
                muted = (line.split(":", 1)[1].strip().lower() == "yes")
            elif line.startswith("Volume:"):
                m = re.search(r'(\d+)%', line)
                if m:
                    volume = int(m.group(1)) / 100.0
            elif "application.name =" in line:
                app_name = line.split("=", 1)[1].strip().strip('"')
            elif "application.process.binary =" in line:
                binary_name = line.split("=", 1)[1].strip().strip('"')
            elif "application.icon_name =" in line:
                icon_name = line.split("=", 1)[1].strip().strip('"')
            elif "media.name =" in line and not media_name:
                media_name = line.split("=", 1)[1].strip().strip('"')

        # Clean display title
        display_name = app_name or binary_name or media_name or f"Stream {stream_id}"
        
        # Clean known loopback labels if user has microphone loopbacks
        if "loopback" in display_name.lower():
            if not app_name and not binary_name:
                display_name = "System Audio"

        streams.append({
            "id": stream_id,
            "name": display_name,
            "app": binary_name.lower() or app_name.lower(),
            "media": media_name,
            "icon": icon_name or binary_name.lower(),
            "corked": corked,
            "muted": muted,
            "volume": round(volume, 2)
        })

    return {"streams": streams}

def set_volume(stream_id, percent):
    try:
        percent = max(0, min(150, int(percent)))
        subprocess.run(["pactl", "set-sink-input-volume", str(stream_id), f"{percent}%"], check=True, timeout=2)
        return True
    except Exception as e:
        print(f"Error setting volume for stream {stream_id}: {e}", file=sys.stderr)
        return False

def toggle_mute(stream_id):
    try:
        subprocess.run(["pactl", "set-sink-input-mute", str(stream_id), "toggle"], check=True, timeout=2)
        return True
    except Exception as e:
        print(f"Error toggling mute for stream {stream_id}: {e}", file=sys.stderr)
        return False

def main():
    if len(sys.argv) >= 3 and sys.argv[1] == "--set-vol":
        stream_id = sys.argv[2]
        vol = sys.argv[3] if len(sys.argv) > 3 else "100"
        success = set_volume(stream_id, vol)
        sys.exit(0 if success else 1)

    if len(sys.argv) >= 3 and sys.argv[1] == "--toggle-mute":
        stream_id = sys.argv[2]
        success = toggle_mute(stream_id)
        sys.exit(0 if success else 1)

    print(json.dumps(get_streams(), indent=2))

if __name__ == "__main__":
    main()
