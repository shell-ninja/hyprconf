#!/usr/bin/env python3
"""
island-battery.py — Laptop battery state detector for Quickshell Dynamic Island.
Provides JSON battery percentage, charging state, and power supply status.
Supports sysfs (/sys/class/power_supply/BAT*), upower fallback, and cache mocking for desktop testing.
"""

import sys
import os
import glob
import subprocess
import json
from pathlib import Path

HOME = Path(os.environ.get("HOME", str(Path.home())))
MOCK_FILE_1 = HOME / ".hyprconf" / "hypr" / ".cache" / "mock_battery.json"
MOCK_FILE_2 = HOME / ".local" / "share" / "hyprconf" / ".cache" / "mock_battery.json"
MOCK_FILES = [MOCK_FILE_1, MOCK_FILE_2]

def set_mock(has_battery, percent, status, is_charging):
    data = {
        "has_battery": has_battery,
        "percent": max(0, min(100, int(percent))),
        "status": status,
        "is_charging": bool(is_charging)
    }
    for mf in MOCK_FILES:
        try:
            mf.parent.mkdir(parents=True, exist_ok=True)
            with open(mf, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
        except Exception:
            pass
    print(f"Mock battery set: {data['percent']}% ({data['status']})")
    return data

def clear_mock():
    removed = False
    for mf in MOCK_FILES:
        if mf.exists():
            try:
                mf.unlink()
                removed = True
            except Exception:
                pass
    if removed:
        print("Mock battery removed. Live desktop/system mode active.")
    else:
        print("No mock battery active.")

def get_battery_info():
    # 1. Check for mock file for testing/development
    for mf in MOCK_FILES:
        if mf.exists():
            try:
                with open(mf, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if "has_battery" in data:
                        return data
            except Exception:
                pass

    # 2. Check sysfs (/sys/class/power_supply/)
    bat_dirs = glob.glob("/sys/class/power_supply/BAT*")
    if not bat_dirs:
        for ps in glob.glob("/sys/class/power_supply/*"):
            type_file = os.path.join(ps, "type")
            if os.path.exists(type_file):
                try:
                    with open(type_file, "r") as tf:
                        if tf.read().strip().lower() == "battery":
                            bat_dirs.append(ps)
                except Exception:
                    pass

    if bat_dirs:
        bat_dir = bat_dirs[0]
        try:
            cap_file = os.path.join(bat_dir, "capacity")
            stat_file = os.path.join(bat_dir, "status")
            if os.path.exists(cap_file):
                with open(cap_file, "r") as cf:
                    pct = int(cf.read().strip())
                status = "Discharging"
                if os.path.exists(stat_file):
                    with open(stat_file, "r") as sf:
                        status = sf.read().strip()
                is_charging = "charging" in status.lower() and "dis" not in status.lower() and "not" not in status.lower()
                return {
                    "has_battery": True,
                    "percent": max(0, min(100, pct)),
                    "status": status,
                    "is_charging": is_charging
                }
        except Exception:
            pass

    # 3. Check upower CLI fallback
    try:
        env = os.environ.copy()
        if "XDG_RUNTIME_DIR" not in env:
            env["XDG_RUNTIME_DIR"] = f"/run/user/{os.getuid()}"
        out = subprocess.check_output(["upower", "-e"], text=True, stderr=subprocess.DEVNULL, env=env)
        for line in out.splitlines():
            if "battery" in line.lower():
                dev_path = line.strip()
                info = subprocess.check_output(["upower", "-i", dev_path], text=True, stderr=subprocess.DEVNULL, env=env)
                pct = None
                status = "Discharging"
                for l in info.splitlines():
                    if "percentage:" in l:
                        pct = int(float(l.split(":")[1].replace("%", "").strip()))
                    elif "state:" in l:
                        status = l.split(":")[1].strip().capitalize()
                if pct is not None:
                    is_charging = "charging" in status.lower() and "dis" not in status.lower() and "not" not in status.lower()
                    return {
                        "has_battery": True,
                        "percent": max(0, min(100, pct)),
                        "status": status,
                        "is_charging": is_charging
                    }
    except Exception:
        pass

    return {
        "has_battery": False,
        "percent": -1,
        "status": "None",
        "is_charging": False
    }

if __name__ == "__main__":
    args = sys.argv[1:]
    if args:
        cmd = args[0]
        if cmd in ("--mock-charging", "-c"):
            pct = int(args[1]) if len(args) > 1 else 88
            set_mock(True, pct, "Charging", True)
            sys.exit(0)
        elif cmd in ("--mock-discharging", "-d"):
            pct = int(args[1]) if len(args) > 1 else 65
            set_mock(True, pct, "Discharging", False)
            sys.exit(0)
        elif cmd in ("--mock-critical", "-cr"):
            pct = int(args[1]) if len(args) > 1 else 12
            set_mock(True, pct, "Discharging", False)
            sys.exit(0)
        elif cmd in ("--mock-clear", "--clear", "-x", "off"):
            clear_mock()
            sys.exit(0)
        elif cmd in ("--help", "-h"):
            print("Usage: island-battery.py [OPTIONS]")
            print("  (no args)             Print current JSON status")
            print("  --mock-charging [pct] Set mock charging battery (default 88%)")
            print("  --mock-discharging [pct] Set mock discharging battery (default 65%)")
            print("  --mock-critical [pct] Set mock critical battery (default 12%)")
            print("  --mock-clear          Remove mock and return to real detection")
            sys.exit(0)

    result = get_battery_info()
    sys.stdout.write(json.dumps(result) + "\n")
    sys.stdout.flush()
