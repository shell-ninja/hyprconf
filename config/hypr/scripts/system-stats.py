#!/usr/bin/env python3
import json
import os
import shutil
import sys

def get_system_stats():
    # 1. System Uptime
    uptime_str = "0m"
    try:
        with open("/proc/uptime", "r") as f:
            sec = float(f.readline().split()[0])
            hrs = int(sec // 3600)
            mins = int((sec % 3600) // 60)
            uptime_str = f"{hrs}h {mins}m" if hrs > 0 else f"{mins}m"
    except Exception:
        pass

    # 2. RAM Usage
    ram_total = 0
    ram_avail = 0
    try:
        with open("/proc/meminfo", "r") as f:
            for line in f:
                parts = line.split()
                if parts[0] == "MemTotal:":
                    ram_total = int(parts[1]) * 1024
                elif parts[0] == "MemAvailable:":
                    ram_avail = int(parts[1]) * 1024
    except Exception:
        pass
    ram_used = max(0, ram_total - ram_avail)
    ram_pct = int(round((ram_used / ram_total) * 100)) if ram_total else 0

    # 3. CPU Load (1m load average normalized to core count)
    cpu_pct = 0
    try:
        load1, _, _ = os.getloadavg()
        cores = os.cpu_count() or 1
        cpu_pct = min(100, max(0, int(round((load1 / cores) * 100))))
    except Exception:
        pass

    # 4. Usable Disk Space (Root / partition)
    disk_total = 0
    disk_used = 0
    disk_free = 0
    try:
        total_d, used_d, free_d = shutil.disk_usage("/")
        disk_total = total_d
        disk_used = used_d
        disk_free = free_d
    except Exception:
        pass
    disk_free_pct = int(round((disk_free / disk_total) * 100)) if disk_total else 0

    # 5. Battery (Optional for laptops)
    battery_pct = -1
    for bat_path in ["/sys/class/power_supply/BAT0/capacity", "/sys/class/power_supply/BAT1/capacity"]:
        if os.path.exists(bat_path):
            try:
                with open(bat_path, "r") as f:
                    battery_pct = int(f.read().strip())
                break
            except Exception:
                pass

    return {
        "uptime": uptime_str,
        "cpu_pct": cpu_pct,
        "ram_used_bytes": ram_used,
        "ram_total_bytes": ram_total,
        "ram_pct": ram_pct,
        "disk_free_bytes": disk_free,
        "disk_total_bytes": disk_total,
        "disk_free_pct": disk_free_pct,
        "battery_pct": battery_pct
    }

if __name__ == "__main__":
    stats = get_system_stats()
    print(json.dumps(stats))
