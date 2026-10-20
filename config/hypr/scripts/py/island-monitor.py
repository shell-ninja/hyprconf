#!/usr/bin/env python3
import os
import time
import json
import glob
import subprocess
import re

CACHE_FILE = "/tmp/island_monitor_cache.json"
GPU_NAME_CACHE = "/tmp/island_gpu_name.txt"

def get_gpu_info(cpu_temp):
    info = {
        "name": "GPU",
        "load": 0,
        "temp": cpu_temp,
        "mem": "",
        "type": "none"
    }

    # Cached GPU name to avoid running lspci on every single poll
    cached_name = None
    if os.path.exists(GPU_NAME_CACHE):
        try:
            with open(GPU_NAME_CACHE, "r") as f:
                cached_name = f.read().strip()
        except Exception:
            pass

    # 1. Check NVIDIA via nvidia-smi
    try:
        res = subprocess.run(
            ["nvidia-smi", "--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu", "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=0.4
        )
        if res.returncode == 0 and res.stdout.strip():
            parts = [p.strip() for p in res.stdout.strip().split(",")]
            if len(parts) >= 5:
                info["name"] = parts[0]
                info["load"] = int(parts[1])
                info["mem"] = f"{int(parts[2])/1024:.1f}/{int(parts[3])/1024:.1f} GB"
                info["temp"] = int(parts[4])
                info["type"] = "nvidia"
                return info
    except Exception:
        pass

    # 2. Check AMD GPU via sysfs
    amd_cards = glob.glob("/sys/class/drm/card*/device/gpu_busy_percent")
    if amd_cards:
        try:
            with open(amd_cards[0], "r") as f:
                info["load"] = int(f.read().strip())
                info["type"] = "amd"
            card_dev = os.path.dirname(amd_cards[0])
            for tp in glob.glob(os.path.join(card_dev, "hwmon/hwmon*/temp1_input")):
                info["temp"] = round(int(open(tp).read().strip()) / 1000.0)
                break
            v_u = glob.glob(os.path.join(card_dev, "mem_info_vram_used"))
            v_t = glob.glob(os.path.join(card_dev, "mem_info_vram_total"))
            if v_u and v_t:
                u = int(open(v_u[0]).read().strip()) / (1024**3)
                t = int(open(v_t[0]).read().strip()) / (1024**3)
                info["mem"] = f"{u:.1f}/{t:.1f} GB"
        except Exception:
            pass

    # 3. Check Intel iGPU via sysfs
    intel_gt_acts = glob.glob("/sys/class/drm/card*/gt_act_freq_mhz")
    if intel_gt_acts:
        try:
            card_dir = os.path.dirname(intel_gt_acts[0])
            act = int(open(os.path.join(card_dir, "gt_act_freq_mhz")).read().strip())
            min_f = int(open(os.path.join(card_dir, "gt_min_freq_mhz")).read().strip())
            max_f = int(open(os.path.join(card_dir, "gt_max_freq_mhz")).read().strip())
            if max_f > min_f:
                load = round(((act - min_f) / (max_f - min_f)) * 100)
            else:
                load = 0
            info["load"] = max(0, min(100, load))
            info["mem"] = f"{act} MHz"
            info["temp"] = cpu_temp # iGPU resides on package die
            info["type"] = "intel"
        except Exception:
            pass

    # Resolve Clean GPU Name
    if cached_name and len(cached_name) > 0:
        info["name"] = cached_name
    else:
        try:
            lspci = subprocess.run(["lspci"], capture_output=True, text=True, timeout=0.6)
            for line in lspci.stdout.splitlines():
                if any(k in line for k in ["VGA compatible controller:", "3D controller:", "Display controller:"]):
                    m = re.search(r"\[([^\]]+)\]", line)
                    if m:
                        bname = m.group(1).strip()
                        if "Intel" in line and not bname.startswith("Intel"):
                            info["name"] = f"Intel {bname}"
                        elif "AMD" in line and not bname.startswith("AMD"):
                            info["name"] = f"AMD {bname}"
                        elif "NVIDIA" in line and not bname.startswith("NVIDIA"):
                            info["name"] = f"NVIDIA {bname}"
                        else:
                            info["name"] = bname
                    else:
                        parts = line.split("controller:")
                        if len(parts) > 1:
                            info["name"] = parts[1].split("(")[0].strip()
                    break
            with open(GPU_NAME_CACHE, "w") as f:
                f.write(info["name"])
        except Exception:
            pass

    if info["name"] == "GPU" and info["type"] == "intel":
        info["name"] = "Intel HD Graphics"

    return info

def read_raw():
    # 1. CPU
    cpu_cores = {}
    try:
        with open("/proc/stat", "r") as f:
            for line in f:
                if line.startswith("cpu"):
                    parts = line.split()
                    name = parts[0]
                    vals = [float(x) for x in parts[1:]]
                    idle = vals[3] + (vals[4] if len(vals) > 4 else 0.0)
                    total = sum(vals)
                    cpu_cores[name] = (total, idle)
    except Exception:
        pass

    # 2. Network I/O
    rx, tx = 0, 0
    try:
        with open("/proc/net/dev", "r") as f:
            for line in f:
                if ":" in line:
                    iface, data = line.split(":", 1)
                    if iface.strip() == "lo":
                        continue
                    fields = data.split()
                    rx += int(fields[0])
                    tx += int(fields[8])
    except Exception:
        pass

    # 3. Memory
    mem = {}
    try:
        with open("/proc/meminfo", "r") as f:
            for line in f:
                p = line.split(":")
                if len(p) == 2:
                    mem[p[0].strip()] = int(p[1].split()[0])
    except Exception:
        pass

    # 4. Temperature
    temp = 48
    found = False
    for p in glob.glob("/sys/class/hwmon/hwmon*/temp*_input"):
        try:
            val = int(open(p).read().strip())
            if 20000 < val < 110000:
                temp = round(val / 1000.0)
                found = True
                break
        except Exception:
            pass

    if not found:
        for p in glob.glob("/sys/class/thermal/thermal_zone*/temp"):
            try:
                val = int(open(p).read().strip())
                if 20000 < val < 110000:
                    temp = round(val / 1000.0)
                    break
            except Exception:
                pass

    return {
        "time": time.time(),
        "cpu": cpu_cores,
        "net": (rx, tx),
        "mem": mem,
        "temp": temp
    }

def main():
    raw_now = read_raw()
    raw_prev = None
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                raw_prev = json.load(f)
        except Exception:
            raw_prev = None

    if not raw_prev or (raw_now["time"] - raw_prev["time"]) > 5.0 or (raw_now["time"] - raw_prev["time"]) < 0.2:
        time.sleep(0.12)
        raw_prev = raw_now
        raw_now = read_raw()

    dt = raw_now["time"] - raw_prev["time"]
    if dt <= 0:
        dt = 1.0

    # CPU Calculations
    cores_pct = []
    total_cpu_pct = 0.0
    core_idx = 0
    while True:
        cname = f"cpu{core_idx}"
        if cname in raw_now["cpu"] and cname in raw_prev["cpu"]:
            t1, i1 = raw_prev["cpu"][cname]
            t2, i2 = raw_now["cpu"][cname]
            d_tot = t2 - t1
            d_idl = i2 - i1
            pct = max(0.0, min(100.0, ((d_tot - d_idl) / d_tot) * 100)) if d_tot > 0 else 0.0
            cores_pct.append(round(pct))
            core_idx += 1
        else:
            break

    if "cpu" in raw_now["cpu"] and "cpu" in raw_prev["cpu"]:
        t1, i1 = raw_prev["cpu"]["cpu"]
        t2, i2 = raw_now["cpu"]["cpu"]
        d_tot = t2 - t1
        d_idl = i2 - i1
        total_cpu_pct = max(0.0, min(100.0, ((d_tot - d_idl) / d_tot) * 100)) if d_tot > 0 else 0.0

    # Network Calculations
    n_rx_dt = max(0, raw_now["net"][0] - raw_prev["net"][0]) / dt
    n_tx_dt = max(0, raw_now["net"][1] - raw_prev["net"][1]) / dt

    def fmt_speed(bps):
        if bps >= 1024 * 1024:
            return f"{bps / (1024 * 1024):.1f} MB/s"
        elif bps >= 1024:
            return f"{bps / 1024:.0f} KB/s"
        else:
            return f"{bps:.0f} B/s"

    # Memory Calculations
    tot_k = raw_now["mem"].get("MemTotal", 1)
    avl_k = raw_now["mem"].get("MemAvailable", 0)
    usd_k = max(0, tot_k - avl_k)
    tot_g = tot_k / (1024 * 1024)
    usd_g = usd_k / (1024 * 1024)
    ram_pct = round((usd_k / tot_k) * 100) if tot_k else 0

    # GPU Calculations
    gpu_info = get_gpu_info(raw_now["temp"])

    # Cache current reading for next query
    try:
        with open(CACHE_FILE, "w") as f:
            json.dump(raw_now, f)
    except Exception:
        pass

    output = {
        "cpu_pct": round(total_cpu_pct),
        "cpu_cores": cores_pct,
        "cpu_temp": raw_now["temp"],
        "gpu_name": gpu_info["name"],
        "gpu_load": gpu_info["load"],
        "gpu_temp": gpu_info["temp"],
        "gpu_mem": gpu_info["mem"],
        "gpu_type": gpu_info["type"],
        "ram_used_gb": round(usd_g, 1),
        "ram_total_gb": round(tot_g, 1),
        "ram_pct": ram_pct,
        "ram_str": f"{usd_g:.1f} GB / {tot_g:.1f} GB ({ram_pct}%)",
        "net_down_str": fmt_speed(n_rx_dt),
        "net_up_str": fmt_speed(n_tx_dt),
        "net_down_kb": round(n_rx_dt / 1024.0, 1),
        "net_up_kb": round(n_tx_dt / 1024.0, 1)
    }

    print(json.dumps(output))

if __name__ == "__main__":
    main()
