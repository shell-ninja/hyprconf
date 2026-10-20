#!/usr/bin/env python3
import subprocess
import sys
import time

last_sink_state = None
last_source_state = None
last_time_sink = 0.0
last_time_source = 0.0

def get_sink():
    try:
        out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], text=True).strip()
        parts = out.split()
        vol = float(parts[1]) if len(parts) > 1 else 0.5
        muted = 1 if "[MUTED]" in out else 0
        return f"{vol:.3f}:{muted}"
    except Exception:
        return None

def get_source():
    try:
        out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"], text=True).strip()
        parts = out.split()
        vol = float(parts[1]) if len(parts) > 1 else 0.5
        muted = 1 if "[MUTED]" in out else 0
        return f"{vol:.3f}:{muted}"
    except Exception:
        return None

def emit_sink(force=False):
    global last_sink_state, last_time_sink
    now = time.time()
    if not force and (now - last_time_sink < 0.04):
        return
    last_time_sink = now
    state = get_sink()
    if state and (force or state != last_sink_state):
        last_sink_state = state
        sys.stdout.write(f"sink:{state}\n")
        sys.stdout.flush()

def emit_source(force=False):
    global last_source_state, last_time_source
    now = time.time()
    if not force and (now - last_time_source < 0.04):
        return
    last_time_source = now
    state = get_source()
    if state and (force or state != last_source_state):
        last_source_state = state
        sys.stdout.write(f"source:{state}\n")
        sys.stdout.flush()

if __name__ == "__main__":
    emit_sink(force=True)
    emit_source(force=True)
    try:
        proc = subprocess.Popen(["stdbuf", "-oL", "pactl", "subscribe"], stdout=subprocess.PIPE, text=True)
        for line in proc.stdout:
            # ONLY respond to sink or source change events!
            # NEVER client/server/card/new/remove to avoid CPU busy-loop.
            if "change" in line:
                if "sink" in line:
                    emit_sink()
                elif "source" in line:
                    emit_source()
    except Exception:
        pass
