#!/usr/bin/env python3
"""
uptime-tracker.py — PC Session & Uptime Tracker for Hyprconf
Calculates session startup time, shutdown/reboot time, and usage duration.
Renders an obsidian box summary, logs to ~/.hyprconf/hypr/.cache/.uptime,
dispatches desktop notification, plays shutdown/reboot audio chimes,
and coordinates clean poweroff/reboot execution.
"""

import os
import sys
import time
import json
import psutil
import datetime
import subprocess

def get_session_metrics():
    try:
        boot_ts = psutil.boot_time()
        boot_dt = datetime.datetime.fromtimestamp(boot_ts)
    except Exception:
        # Fallback to uptime -s
        try:
            res = subprocess.run(["uptime", "-s"], capture_output=True, text=True, timeout=2)
            boot_dt = datetime.datetime.strptime(res.stdout.strip(), "%Y-%m-%d %H:%M:%S")
        except Exception:
            boot_dt = datetime.datetime.now()

    now_dt = datetime.datetime.now()
    diff = now_dt - boot_dt
    total_sec = max(0, int(diff.total_seconds()))

    hours = total_sec // 3600
    minutes = (total_sec % 3600) // 60
    seconds = total_sec % 60
    hours_dec = round(total_sec / 3600.0, 2)

    return {
        "boot_dt": boot_dt,
        "now_dt": now_dt,
        "total_sec": total_sec,
        "hours": hours,
        "minutes": minutes,
        "seconds": seconds,
        "hours_dec": hours_dec,
        "boot_str": boot_dt.strftime("%Y-%m-%d %H:%M:%S"),
        "now_str": now_dt.strftime("%Y-%m-%d %H:%M:%S"),
        "duration_str": f"{hours}h {minutes:02d}m {seconds:02d}s"
    }

def format_box(metrics, action="Shutdown"):
    title = f"PC SESSION SUMMARY ({action.upper()})"
    width = 42
    pad_title = title.center(width - 2)

    boot_str = metrics["boot_str"]
    now_str = metrics["now_str"]
    dur_str = metrics["duration_str"]
    hours_dec_str = f"{metrics['hours_dec']:.2f} hrs"

    box = (
        f"╭{'─' * (width - 2)}╮\n"
        f"│{pad_title}│\n"
        f"├{'─' * 16}┬{'─' * (width - 19)}┤\n"
        f"│ Startup Time   │ {boot_str:<{width - 21}} │\n"
        f"│ {action:<14} │ {now_str:<{width - 21}} │\n"
        f"│ Session Time   │ {dur_str:<{width - 21}} │\n"
        f"│ Total Usage    │ {hours_dec_str:<{width - 21}} │\n"
        f"╰{'─' * 16}┴{'─' * (width - 19)}╯"
    )
    return box

def get_cache_paths():
    home = os.path.expanduser("~")
    # Primary cache dirs
    dirs = [
        os.path.join(home, ".hyprconf", "hypr", ".cache"),
        os.path.join(home, ".local", "share", "hyprconf", ".cache"),
        os.path.join(home, ".config", "hypr", ".cache")
    ]
    for d in dirs:
        try:
            os.makedirs(d, exist_ok=True)
        except Exception:
            pass
    return dirs

def log_session(metrics, action="Shutdown"):
    dirs = get_cache_paths()
    boot_dt = metrics["boot_dt"]
    now_dt = metrics["now_dt"]
    usage_dec = f"{metrics['hours_dec']:.2f}"
    box_text = format_box(metrics, action)

    # Format table entry: Date         StartupTime     PowerOfftime     Usage(HOUR)
    table_entry = f"{boot_dt.strftime('%Y-%m-%d'):<12} {boot_dt.strftime('%H:%M:%S'):<15} {now_dt.strftime('%H:%M:%S'):<16} {usage_dec}\n"

    for d in dirs:
        uptime_file = os.path.join(d, ".uptime")
        try:
            if not os.path.exists(uptime_file) or os.path.getsize(uptime_file) == 0:
                with open(uptime_file, "w", encoding="utf-8") as f:
                    f.write(f"{'Date':<12} {'StartupTime':<15} {'PowerOfftime':<16} {'Usage(HOUR)'}\n")
            with open(uptime_file, "a", encoding="utf-8") as f:
                f.write(table_entry)
        except Exception:
            pass

        # Write latest session box and json for fast HUD access
        try:
            with open(os.path.join(d, "latest_session.txt"), "w", encoding="utf-8") as f:
                f.write(box_text + "\n")
            with open(os.path.join(d, "session_summary.json"), "w", encoding="utf-8") as f:
                json.dump({
                    "action": action,
                    "startup": metrics["boot_str"],
                    "end_time": metrics["now_str"],
                    "duration": metrics["duration_str"],
                    "usage_hours": metrics["hours_dec"],
                    "timestamp": time.time()
                }, f, indent=2)
        except Exception:
            pass

def play_sound(sound_type="poweroff"):
    home = os.path.expanduser("~")
    sounds = {
        "startup": os.path.join(home, ".hyprconf", "hypr", "sounds", "system-startup.wav"),
        "shutdown": os.path.join(home, ".hyprconf", "hypr", "sounds", "poweroff.mp3"),
        "reboot": os.path.join(home, ".hyprconf", "hypr", "sounds", "poweroff.mp3")
    }
    sound_path = sounds.get(sound_type, sounds["shutdown"])
    if not os.path.exists(sound_path):
        return

    # Try fast playback tools
    players = [
        ["pw-play", sound_path],
        ["paplay", sound_path],
        ["mpv", "--no-video", "--really-quiet", sound_path]
    ]
    for cmd in players:
        try:
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return
        except Exception:
            continue

def send_notification(metrics, action="Shutdown"):
    box = format_box(metrics, action)
    title = f"System {action.capitalize()}"
    icon = "system-reboot" if action.lower() == "reboot" else "system-shutdown"
    
    # Try notify-send with mono box formatting
    try:
        subprocess.run([
            "notify-send",
            "-a", "Hyprconf Power",
            "-i", icon,
            "-t", "4500",
            title,
            box
        ], timeout=2, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def main():
    action = "Shutdown"
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower().replace("--", "")
        if "reboot" in arg:
            action = "Reboot"
        elif "start" in arg:
            action = "Startup"

    metrics = get_session_metrics()

    if "--json" in sys.argv:
        print(json.dumps({
            "startup": metrics["boot_str"],
            "end": metrics["now_str"],
            "duration": metrics["duration_str"],
            "hours": metrics["hours_dec"]
        }, indent=2))
        return

    if "--sound-only" in sys.argv:
        play_sound("startup" if action == "Startup" else ("reboot" if action == "Reboot" else "shutdown"))
        return

    if "--show" in sys.argv:
        print(format_box(metrics, action))
        return

    # Full poweroff workflow
    if "--shutdown" in sys.argv or "--poweroff" in sys.argv:
        log_session(metrics, "Shutdown")
        send_notification(metrics, "Shutdown")
        play_sound("shutdown")
        print(format_box(metrics, "Shutdown"))
        time.sleep(2.2)
        subprocess.run(["systemctl", "poweroff"])
        return

    # Full reboot workflow
    if "--reboot" in sys.argv:
        log_session(metrics, "Reboot")
        send_notification(metrics, "Reboot")
        play_sound("reboot")
        print(format_box(metrics, "Reboot"))
        time.sleep(2.2)
        subprocess.run(["systemctl", "reboot"])
        return

    # Default action: record and display box
    log_session(metrics, action)
    send_notification(metrics, action)
    print(format_box(metrics, action))

if __name__ == "__main__":
    main()
