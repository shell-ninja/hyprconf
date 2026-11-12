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
import shutil
try:
    import psutil
except ImportError:
    psutil = None
import datetime
import subprocess

POWER_ACTION_DELAY_SEC = 1.0

def get_session_metrics():
    try:
        if psutil is None:
            raise ImportError("psutil not available")
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
    width = 40
    title = f"PC SESSION SUMMARY ({action.upper()})"
    pad_title = title.center(width - 2)

    boot_str = metrics["boot_str"]
    now_str = metrics["now_str"]
    dur_str = metrics["duration_str"]
    hours_dec_str = f"{metrics['hours_dec']:.2f} hrs"

    col1_w = 14
    col2_w = width - 3 - col1_w

    box = (
        f"╭{'─' * (width - 2)}╮\n"
        f"│{pad_title}│\n"
        f"├{'─' * col1_w}┬{'─' * col2_w}┤\n"
        f"│ {'Startup Time':<{col1_w - 1}}│ {boot_str:<{col2_w - 1}}│\n"
        f"│ {action:<{col1_w - 1}}│ {now_str:<{col2_w - 1}}│\n"
        f"│ {'Session Time':<{col1_w - 1}}│ {dur_str:<{col2_w - 1}}│\n"
        f"│ {'Total Usage':<{col1_w - 1}}│ {hours_dec_str:<{col2_w - 1}}│\n"
        f"╰{'─' * col1_w}┴{'─' * col2_w}╯"
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
        "reboot": os.path.join(home, ".hyprconf", "hypr", "sounds", "poweroff.mp3"),
        "logout": os.path.join(home, ".hyprconf", "hypr", "sounds", "poweroff.mp3")
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
    title = f"Pc Usage {metrics['now_dt'].strftime('%d-%m-%Y')}"
    body = metrics["duration_str"]
    action_key = action.lower()
    icon = "system-reboot" if action_key == "reboot" else (
        "system-log-out" if action_key == "logout" else "system-shutdown"
    )

    # Send concise desktop notification: "Pc Usage dd-mm-yyyy" / "USAGE_TIME"
    try:
        subprocess.run([
            "notify-send",
            "-a", "Hyprconf Power",
            "-i", icon,
            "-t", "6500",
            title,
            body
        ], timeout=2, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def _dismiss_power_menus():
    """Best-effort dismiss of open power overlays so usage notification shows cleanly."""
    ipc_calls = [
        ["qs", "ipc", "-c", "island", "call", "island", "collapse"],
        ["qs", "ipc", "-c", "bar", "call", "bar", "closePower"],
    ]
    for cmd in ipc_calls:
        if not shutil.which(cmd[0]):
            continue
        try:
            subprocess.run(cmd, timeout=0.4, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            pass

def _run_first_success(commands):
    """Run fallback commands sequentially until one exits with status 0."""
    for cmd in commands:
        exe = shutil.which(cmd[0])
        if not exe:
            continue
        try:
            res = subprocess.run([exe, *cmd[1:]], check=False)
            if res.returncode == 0:
                return True
        except Exception:
            continue
    return False

def _run_logout():
    """Execute Hyprland session logout after notification delay."""
    logout_script = os.path.expanduser("~/.hyprconf/hypr/scripts/sh/qs-logout.sh")
    if os.path.isfile(logout_script):
        res = subprocess.run(["bash", logout_script, "--now"], check=False)
        if res.returncode == 0:
            return True
    user = os.environ.get("USER", "")
    cmds = [
        ["hyprctl", "eval", "hl.dispatch(hl.dsp.exit())"],
        ["hyprctl", "dispatch", "exit"],
    ]
    if user:
        cmds.append(["loginctl", "terminate-user", user])
    return _run_first_success(cmds)

def _execute_power_workflow(metrics, action_label, sound_key, post_delay_fn):
    """Record session, display concise usage toast, wait 1s, then run power action."""
    log_session(metrics, action_label)
    _dismiss_power_menus()
    send_notification(metrics, action_label)
    play_sound(sound_key)
    print(format_box(metrics, action_label))
    time.sleep(POWER_ACTION_DELAY_SEC)
    post_delay_fn()

def main():
    action = "Shutdown"
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower().replace("--", "")
        if "reboot" in arg:
            action = "Reboot"
        elif "logout" in arg:
            action = "Logout"
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
        sound_key = "startup" if action == "Startup" else action.lower()
        play_sound(sound_key)
        return

    if "--show" in sys.argv:
        print(format_box(metrics, action))
        return

    if "--notify-only" in sys.argv:
        log_session(metrics, action)
        send_notification(metrics, action)
        return

    # Full poweroff workflow
    if "--shutdown" in sys.argv or "--poweroff" in sys.argv:
        _execute_power_workflow(
            metrics,
            "Shutdown",
            "shutdown",
            lambda: _run_first_success([
                ["systemctl", "poweroff"],
                ["systemctl", "poweroff", "-i"],
                ["loginctl", "poweroff"],
                ["loginctl", "poweroff", "-i"],
            ]),
        )
        return

    # Full reboot workflow
    if "--reboot" in sys.argv:
        _execute_power_workflow(
            metrics,
            "Reboot",
            "reboot",
            lambda: _run_first_success([
                ["systemctl", "reboot"],
                ["systemctl", "reboot", "-i"],
                ["loginctl", "reboot"],
                ["loginctl", "reboot", "-i"],
            ]),
        )
        return

    # Full logout workflow
    if "--logout" in sys.argv:
        _execute_power_workflow(metrics, "Logout", "logout", _run_logout)
        return

    # Default action: record and display box
    log_session(metrics, action)
    send_notification(metrics, action)
    print(format_box(metrics, action))

if __name__ == "__main__":
    main()
