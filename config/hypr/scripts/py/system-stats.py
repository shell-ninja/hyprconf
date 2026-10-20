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

    # 3. CPU Load (Instantaneous utilization via /proc/stat delta)
    cpu_pct = 0
    try:
        import time
        cache_file = "/tmp/.sys_stats_cpu_cache"
        now = time.time()
        with open("/proc/stat", "r") as f:
            fields = [float(x) for x in f.readline().split()[1:8]]
            curr_idle = fields[3] + fields[4]
            curr_total = sum(fields)

        calculated = False
        if os.path.exists(cache_file):
            try:
                with open(cache_file, "r") as cf:
                    prev_t, prev_i, prev_tot = [float(x) for x in cf.read().split()]
                dt = now - prev_t
                if 0.1 <= dt <= 8.0:
                    d_idle = curr_idle - prev_i
                    d_total = curr_total - prev_tot
                    if d_total > 0:
                        cpu_pct = int(round(max(0.0, min(100.0, (1.0 - (d_idle / d_total)) * 100.0))))
                        calculated = True
            except Exception:
                pass

        if not calculated:
            time.sleep(0.05)
            with open("/proc/stat", "r") as f:
                fields2 = [float(x) for x in f.readline().split()[1:8]]
                idle2 = fields2[3] + fields2[4]
                tot2 = sum(fields2)
            d_i = idle2 - curr_idle
            d_t = tot2 - curr_total
            if d_t > 0:
                cpu_pct = int(round(max(0.0, min(100.0, (1.0 - (d_i / d_t)) * 100.0))))

        try:
            with open(cache_file, "w") as cf:
                cf.write(f"{now} {curr_idle} {curr_total}")
        except Exception:
            pass
    except Exception:
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

    # 5. GPU Utilization
    gpu_pct = 0
    try:
        # NVIDIA
        import subprocess
        out = subprocess.check_output(['nvidia-smi', '--query-gpu=utilization.gpu', '--format=csv,noheader,nounits'], stderr=subprocess.DEVNULL)
        gpu_pct = int(out.decode().strip().split()[0])
    except Exception:
        # AMD
        import glob
        found_amd = False
        for p in glob.glob('/sys/class/drm/card*/device/gpu_busy_percent'):
            try:
                gpu_pct = int(open(p).read().strip())
                found_amd = True
                break
            except Exception:
                pass
        # Intel
        if not found_amd:
            for card in glob.glob('/sys/class/drm/card*'):
                act = os.path.join(card, 'gt_act_freq_mhz')
                min_f = os.path.join(card, 'gt_min_freq_mhz')
                max_f = os.path.join(card, 'gt_max_freq_mhz')
                if os.path.exists(act) and os.path.exists(max_f):
                    try:
                        a = float(open(act).read().strip())
                        mx = float(open(max_f).read().strip())
                        mn = float(open(min_f).read().strip()) if os.path.exists(min_f) else 300.0
                        if mx > mn:
                            gpu_pct = int(round(max(0.0, min(100.0, ((a - mn) / (mx - mn)) * 100.0))))
                            break
                    except Exception:
                        pass

    # 6. Battery (Optional for laptops)
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
        "gpu_pct": gpu_pct,
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
