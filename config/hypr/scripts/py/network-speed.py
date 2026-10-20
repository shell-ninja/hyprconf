#!/usr/bin/env python3
import time
import sys
import json

def get_net_bytes():
    rx, tx = 0, 0
    try:
        with open("/proc/net/dev", "r") as f:
            for line in f:
                if ":" in line:
                    iface, data = line.split(":", 1)
                    iface = iface.strip()
                    if iface == "lo" or iface.startswith("virbr") or iface.startswith("docker"):
                        continue
                    fields = data.split()
                    rx += int(fields[0])
                    tx += int(fields[8])
    except Exception:
        pass
    return rx, tx

def fmt_speed(bps):
    if bps < 1000:
        return f"{int(bps)}B"
    elif bps < 1000 * 1000:
        v = bps / 1024.0
        return f"{v:.1f}K" if v < 10 else f"{int(v)}K"
    elif bps < 1000 * 1000 * 1000:
        v = bps / (1024.0 * 1024.0)
        return f"{v:.1f}M" if v < 100 else f"{int(v)}M"
    else:
        v = bps / (1024.0 * 1024.0 * 1024.0)
        return f"{v:.1f}G"

def main():
    prev_rx, prev_tx = get_net_bytes()
    prev_time = time.time()
    
    # Print initial 0 values so QML immediately receives valid initial data
    print(json.dumps({"down": "0B", "up": "0B"}), flush=True)

    while True:
        try:
            time.sleep(1.5)
            now_time = time.time()
            rx, tx = get_net_bytes()
            dt = max(0.2, now_time - prev_time)
            rx_speed = max(0.0, rx - prev_rx) / dt
            tx_speed = max(0.0, tx - prev_tx) / dt
            prev_rx, prev_tx, prev_time = rx, tx, now_time

            data = {
                "down": fmt_speed(rx_speed),
                "up": fmt_speed(tx_speed)
            }
            print(json.dumps(data), flush=True)
        except (KeyboardInterrupt, SystemExit):
            break
        except Exception:
            time.sleep(2.0)

if __name__ == "__main__":
    main()
