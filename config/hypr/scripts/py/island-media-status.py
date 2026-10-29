#!/usr/bin/env python3
"""
island-media-status.py — Accurate screen recording and microphone capture detector
for Quickshell Dynamic Island. Returns JSON state.
Prevents false positives when OBS or recording apps are open but not actively recording.
"""

import sys
import os
import subprocess
import json
from pathlib import Path

HOME = Path(os.environ.get("HOME", str(Path.home())))
MOCK_REC_FILES = [
    HOME / ".hyprconf" / "hypr" / ".cache" / "mock_recording.json",
    HOME / ".local" / "share" / "hyprconf" / ".cache" / "mock_recording.json"
]
MOCK_MIC_FILES = [
    HOME / ".hyprconf" / "hypr" / ".cache" / "mock_mic.json",
    HOME / ".local" / "share" / "hyprconf" / ".cache" / "mock_mic.json"
]

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
    """
    Checks if process <pid> has an open file descriptor pointing to a video file
    opened in write or read/write mode.
    """
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
                # Verify that it is opened for writing via /proc/<pid>/fdinfo/<fd>
                fdinfo_path = f"/proc/{pid}/fdinfo/{fd}"
                if os.path.exists(fdinfo_path):
                    try:
                        with open(fdinfo_path, "r") as f:
                            for line in f:
                                if line.startswith("flags:"):
                                    flags_val = int(line.split()[1], 8)
                                    # 0 = O_RDONLY, 1 = O_WRONLY, 2 = O_RDWR
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
    """
    Checks if an OBS process is actively writing an output video file or streaming to RTMP.
    """
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

def is_screen_recording():
    # 1. Mock file check
    for fpath in MOCK_REC_FILES:
        if fpath.exists():
            try:
                with open(fpath, "r", encoding="utf-8") as f:
                    d = json.load(f)
                    if "recording" in d:
                        return bool(d["recording"])
            except Exception:
                pass

    # 2. Dedicated CLI tools that ONLY run while actively recording
    for proc in ["wf-recorder", "wl-screenrec"]:
        if get_pids(proc):
            return True

    # Check ffmpeg recording display
    try:
        r = subprocess.run(["pgrep", "-f", "ffmpeg.*(kmsgrab|wayland|pipewire|x11grab)"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if r.returncode == 0:
            return True
    except Exception:
        pass

    # 3. OBS Studio: ONLY active if writing video or streaming (NOT merely opened!)
    for pid in get_pids("obs") + get_pids("obs-studio"):
        if is_obs_recording_or_streaming(pid):
            return True

    # 4. Other GUI recorders (check if writing a video file)
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

def is_mic_captured():
    # 1. Mock file check
    for fpath in MOCK_MIC_FILES:
        if fpath.exists():
            try:
                with open(fpath, "r", encoding="utf-8") as f:
                    d = json.load(f)
                    if "mic_captured" in d:
                        return bool(d["mic_captured"])
            except Exception:
                pass

    # 2. Check active mic applications
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

def get_media_status():
    rec = is_screen_recording()
    mic = is_mic_captured()
    return {
        "recording": rec,
        "mic_captured": mic
    }

if __name__ == "__main__":
    status = get_media_status()
    sys.stdout.write(json.dumps(status) + "\n")
    sys.stdout.flush()
