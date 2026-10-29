#!/usr/bin/env python3
import subprocess
import sys
import time
import os
import json
import threading
from pathlib import Path

HOME = Path(os.environ.get("HOME", str(Path.home())))
MOCK_REC_FILE = HOME / ".hyprconf" / "hypr" / ".cache" / "mock_recording.json"
MOCK_MIC_FILE = HOME / ".hyprconf" / "hypr" / ".cache" / "mock_mic.json"

last_sink_state = None
last_source_state = None
last_rec_state = None
last_mic_state = None

last_time_sink = 0.0
last_time_source = 0.0
last_time_rec = 0.0
last_time_mic = 0.0

def get_env():
    env = os.environ.copy()
    if "XDG_RUNTIME_DIR" not in env:
        env["XDG_RUNTIME_DIR"] = f"/run/user/{os.getuid()}"
    return env

def get_pids(proc_name):
    try:
        out = subprocess.check_output(["pgrep", "-x", proc_name], text=True, stderr=subprocess.DEVNULL)
        return [int(p.strip()) for p in out.splitlines() if p.strip().isdigit()]
    except Exception:
        return []

def is_process_writing_video(pid):
    video_exts = ('.mp4', '.mkv', '.webm', '.flv', '.mov', '.avi', '.ts', '.m4v')
    fd_dir = f"/proc/{pid}/fd"
    if not os.path.exists(fd_dir):
        return False
    try:
        for fd in os.listdir(fd_dir):
            fd_path = os.path.join(fd_dir, fd)
            try:
                target = os.readlink(fd_path)
            except Exception:
                continue
            if target.lower().endswith(video_exts):
                fdinfo_path = f"/proc/{pid}/fdinfo/{fd}"
                if os.path.exists(fdinfo_path):
                    try:
                        with open(fdinfo_path, "r") as f:
                            for line in f:
                                if line.startswith("flags:"):
                                    flags_val = int(line.split()[1], 8)
                                    if (flags_val & 3) in (1, 2):
                                        return True
                    except Exception:
                        return True
                else:
                    return True
    except Exception:
        pass
    return False

def is_obs_recording_or_streaming(pid):
    if is_process_writing_video(pid):
        return True
    try:
        tcp_file = f"/proc/{pid}/net/tcp"
        if os.path.exists(tcp_file):
            with open(tcp_file, "r") as f:
                for line in f:
                    parts = line.strip().split()
                    if len(parts) >= 4:
                        rem_address = parts[2]
                        state = parts[3]
                        if state == "01" and rem_address.endswith(":078F"):
                            return True
    except Exception:
        pass
    return False

def check_screen_recording():
    if MOCK_REC_FILE.exists():
        try:
            with open(MOCK_REC_FILE, "r", encoding="utf-8") as f:
                d = json.load(f)
                if "recording" in d:
                    return bool(d["recording"])
        except Exception:
            pass

    # Dedicated CLI tools that only run when recording
    for proc in ["wf-recorder", "wl-screenrec"]:
        if get_pids(proc):
            return True

    try:
        r = subprocess.run(["pgrep", "-f", "ffmpeg.*(kmsgrab|wayland|pipewire|x11grab)"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if r.returncode == 0:
            return True
    except Exception:
        pass

    # OBS: Only if writing video or streaming
    for pid in get_pids("obs") + get_pids("obs-studio"):
        if is_obs_recording_or_streaming(pid):
            return True

    # Other GUI recorders
    for proc in ["gpu-screen-recorder", "simplescreenrecorder", "vokoscreen", "vokoscreenNG"]:
        for pid in get_pids(proc):
            if is_process_writing_video(pid):
                return True

    return False

def get_active_mic_apps():
    try:
        out = subprocess.check_output(["pactl", "list", "source-outputs"], text=True, stderr=subprocess.DEVNULL, env=get_env(), timeout=0.8)
    except Exception:
        return []

    apps = []
    current_app = None
    is_corked = False
    for line in out.splitlines():
        line_str = line.strip()
        if line_str.startswith("Source Output #"):
            if current_app and not is_corked:
                apps.append(current_app)
            current_app = "unknown"
            is_corked = False
        elif line_str.startswith("Corked:"):
            is_corked = "yes" in line_str.lower()
        elif "application.name =" in line_str:
            current_app = line_str.split("=", 1)[1].strip().strip('"')
        elif "application.process.binary =" in line_str:
            bin_name = line_str.split("=", 1)[1].strip().strip('"')
            if current_app == "unknown" or not current_app:
                current_app = bin_name

    if current_app and not is_corked:
        apps.append(current_app)

    return apps

def check_mic_captured():
    if MOCK_MIC_FILE.exists():
        try:
            with open(MOCK_MIC_FILE, "r", encoding="utf-8") as f:
                d = json.load(f)
                if "mic_captured" in d:
                    return bool(d["mic_captured"])
        except Exception:
            pass

    apps = get_active_mic_apps()
    if not apps:
        return False

    obs_pids = get_pids("obs") + get_pids("obs-studio")
    obs_recording = any(is_obs_recording_or_streaming(pid) for pid in obs_pids)

    real_apps = []
    for app in apps:
        if "obs" in app.lower():
            if obs_recording:
                real_apps.append(app)
        else:
            real_apps.append(app)

    return len(real_apps) > 0

def get_sink():
    try:
        out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], text=True, env=get_env(), stderr=subprocess.DEVNULL).strip()
        parts = out.split()
        vol = float(parts[1]) if len(parts) > 1 else 0.5
        muted = 1 if "[MUTED]" in out else 0
        return f"{vol:.3f}:{muted}"
    except Exception:
        return None

def get_source():
    try:
        out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"], text=True, env=get_env(), stderr=subprocess.DEVNULL).strip()
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

def emit_rec(force=False):
    global last_rec_state, last_time_rec
    now = time.time()
    if not force and (now - last_time_rec < 0.3):
        return
    last_time_rec = now
    is_rec = check_screen_recording()
    val = "1" if is_rec else "0"
    if force or val != last_rec_state:
        last_rec_state = val
        sys.stdout.write(f"rec_active:{val}\n")
        sys.stdout.flush()

def emit_mic_active(force=False):
    global last_mic_state, last_time_mic
    now = time.time()
    if not force and (now - last_time_mic < 0.3):
        return
    last_time_mic = now
    is_mic = check_mic_captured()
    val = "1" if is_mic else "0"
    if force or val != last_mic_state:
        last_mic_state = val
        sys.stdout.write(f"mic_active:{val}\n")
        sys.stdout.flush()

def periodic_checker():
    while True:
        try:
            emit_rec()
            emit_mic_active()
        except Exception:
            pass
        time.sleep(1.2)

import atexit
import ctypes
import signal

# Ensure process terminates immediately if parent dies
try:
    libc = ctypes.CDLL("libc.so.6")
    libc.prctl(1, 15)  # PR_SET_PDEATHSIG = 1, SIGTERM = 15
except Exception:
    pass

proc = None

def cleanup():
    global proc
    if proc:
        try:
            proc.terminate()
            proc.kill()
        except Exception:
            pass

def sig_handler(sig, frame):
    cleanup()
    sys.exit(0)

signal.signal(signal.SIGTERM, sig_handler)
signal.signal(signal.SIGINT, sig_handler)
signal.signal(signal.SIGHUP, sig_handler)
signal.signal(signal.SIGPIPE, sig_handler)
atexit.register(cleanup)

if __name__ == "__main__":
    emit_sink(force=True)
    emit_source(force=True)
    emit_rec(force=True)
    emit_mic_active(force=True)

    checker_thread = threading.Thread(target=periodic_checker, daemon=True)
    checker_thread.start()

    try:
        proc = subprocess.Popen(["stdbuf", "-oL", "pactl", "subscribe"], stdout=subprocess.PIPE, text=True, env=get_env())
        for line in proc.stdout:
            if "change" in line or "new" in line or "remove" in line:
                if "sink" in line:
                    emit_sink()
                elif "source" in line and "source-output" not in line:
                    emit_source()
                elif "source-output" in line:
                    emit_mic_active()
    except Exception:
        while True:
            time.sleep(5)
    finally:
        cleanup()
