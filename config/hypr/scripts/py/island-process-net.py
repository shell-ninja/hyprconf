#!/usr/bin/env python3
import subprocess
import re
import time
import json
import os

CACHE_FILE = "/tmp/island_proc_net_cache.json"

def get_process_display(pid, raw_name):
    clean_name = raw_name
    icon_type = "network"
    
    # Try reading /proc/<pid>/cmdline
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            raw_cmd = f.read().decode("utf-8", errors="ignore").split("\0")
            full_cmd = " ".join(raw_cmd).lower()
            
            if "brave" in full_cmd:
                clean_name = "Brave Browser"
                icon_type = "browser"
            elif "firefox" in full_cmd:
                clean_name = "Firefox"
                icon_type = "browser"
            elif "chrome" in full_cmd or "chromium" in full_cmd:
                clean_name = "Chromium"
                icon_type = "browser"
            elif "discord" in full_cmd or "vesktop" in full_cmd:
                clean_name = "Discord"
                icon_type = "chat"
            elif "telegram" in full_cmd:
                clean_name = "Telegram"
                icon_type = "chat"
            elif "spotify" in full_cmd:
                clean_name = "Spotify"
                icon_type = "media"
            elif "steam" in full_cmd:
                clean_name = "Steam"
                icon_type = "game"
            elif "antigravity" in full_cmd or "code" in full_cmd or "vscodium" in full_cmd:
                clean_name = "Antigravity IDE"
                icon_type = "code"
            elif "language_server" in full_cmd:
                clean_name = "Language Server"
                icon_type = "code"
            elif "curl" in full_cmd or "wget" in full_cmd:
                clean_name = "Downloader (curl)"
                icon_type = "download"
            elif "pacman" in full_cmd or "yay" in full_cmd or "paru" in full_cmd:
                clean_name = "Package Manager"
                icon_type = "system"
            elif "quickshell" in full_cmd:
                clean_name = "Quickshell"
                icon_type = "system"
            elif "hyprland" in full_cmd:
                clean_name = "Hyprland Session"
                icon_type = "system"
            else:
                # Format raw name nicely
                clean_name = raw_name.replace("-", " ").replace("_", " ").title()
    except Exception:
        clean_name = raw_name.replace("-", " ").replace("_", " ").title()
        
    return clean_name, icon_type

def take_snapshot():
    # Run ss -t -u -p -i -H to query TCP and UDP sockets
    procs = {} # pid: {'raw_name': str, 'recv': int, 'sent': int, 'ext_recv': int, 'ext_sent': int, 'ext_conns': int}
    try:
        res = subprocess.run(["ss", "-t", "-u", "-p", "-i", "-H"], capture_output=True, text=True, timeout=1.0)
        lines = res.stdout.splitlines()
        current_proc = None
        is_external = False
        
        for line in lines:
            if line.startswith("\t") or line.startswith(" "):
                if current_proc:
                    pid, name = current_proc
                    m_sent = re.search(r"bytes_sent:(\d+)", line)
                    m_recv = re.search(r"bytes_received:(\d+)", line)
                    sent = int(m_sent.group(1)) if m_sent else 0
                    recv = int(m_recv.group(1)) if m_recv else 0
                    
                    if pid not in procs:
                        procs[pid] = {"raw_name": name, "recv": 0, "sent": 0, "ext_recv": 0, "ext_sent": 0, "ext_conns": 0}
                    procs[pid]["recv"] += recv
                    procs[pid]["sent"] += sent
                    if is_external:
                        procs[pid]["ext_recv"] += recv
                        procs[pid]["ext_sent"] += sent
                        procs[pid]["ext_conns"] += 1
                current_proc = None
            else:
                parts = line.split()
                if len(parts) >= 5:
                    peer = parts[4]
                    # Ignore loopback 127.0.0.1 and ::1 for external internet calculation
                    is_external = not (peer.startswith("127.") or peer.startswith("[::1]") or peer.startswith("::ffff:127."))
                m = re.search(r'users:\(\(\"([^\"]+)\",pid=(\d+)', line)
                if m:
                    current_proc = (int(m.group(2)), m.group(1))
                else:
                    current_proc = None
    except Exception:
        pass
        
    return {"time": time.time(), "procs": procs}

def fmt_speed(bps):
    if bps >= 1024 * 1024:
        return f"{bps / (1024 * 1024):.1f} MB/s"
    elif bps >= 1024:
        return f"{bps / 1024:.0f} KB/s"
    elif bps > 0:
        return f"{bps:.0f} B/s"
    else:
        return "0 B/s"

def main():
    snap_now = take_snapshot()
    snap_prev = None
    
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                snap_prev = json.load(f)
                # Convert string keys back to int
                snap_prev["procs"] = {int(k): v for k, v in snap_prev.get("procs", {}).items()}
        except Exception:
            snap_prev = None

    if not snap_prev or (snap_now["time"] - snap_prev["time"]) > 4.0 or (snap_now["time"] - snap_prev["time"]) < 0.2:
        time.sleep(0.15)
        snap_prev = snap_now
        snap_now = take_snapshot()

    dt = snap_now["time"] - snap_prev["time"]
    if dt <= 0:
        dt = 1.0

    proc_list = []
    tot_down_bps = 0.0
    tot_up_bps = 0.0

    for pid, d2 in snap_now["procs"].items():
        d1 = snap_prev["procs"].get(pid, d2)
        # Delta bytes
        d_recv = max(0, d2["recv"] - d1.get("recv", 0)) / dt
        d_sent = max(0, d2["sent"] - d1.get("sent", 0)) / dt
        d_ext_recv = max(0, d2.get("ext_recv", 0) - d1.get("ext_recv", 0)) / dt
        d_ext_sent = max(0, d2.get("ext_sent", 0) - d1.get("ext_sent", 0)) / dt
        
        tot_down_bps += d_recv
        tot_up_bps += d_sent

        disp_name, icon_type = get_process_display(pid, d2["raw_name"])
        total_speed = d_recv + d_sent

        proc_list.append({
            "pid": pid,
            "name": disp_name,
            "raw_name": d2["raw_name"],
            "icon": icon_type,
            "down_bps": round(d_recv),
            "up_bps": round(d_sent),
            "total_bps": round(total_speed),
            "down_str": fmt_speed(d_recv),
            "up_str": fmt_speed(d_sent),
            "total_str": fmt_speed(total_speed),
            "ext_conns": d2.get("ext_conns", 0),
            "active": total_speed > 0
        })

    # Sort: active consuming processes first (highest speed), then by total external sockets
    proc_list.sort(key=lambda x: (x["total_bps"], x["down_bps"], x["ext_conns"]), reverse=True)

    # Save cache
    try:
        with open(CACHE_FILE, "w") as f:
            json.dump(snap_now, f)
    except Exception:
        pass

    out = {
        "total_down_str": fmt_speed(tot_down_bps),
        "total_up_str": fmt_speed(tot_up_bps),
        "total_down_bps": round(tot_down_bps),
        "total_up_bps": round(tot_up_bps),
        "active_proc_count": len([p for p in proc_list if p["active"]]),
        "total_proc_count": len(proc_list),
        "processes": proc_list[:25] # top 25 processes
    }

    print(json.dumps(out))

if __name__ == "__main__":
    main()
