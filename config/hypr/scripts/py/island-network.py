#!/usr/bin/env python3
"""
island-network.py — Network & Wi-Fi state bridge for Quickshell Dynamic Island.
Provides JSON status, available Wi-Fi networks scanning, connection handler,
and terminal nmtui launcher.
"""

import sys
import os
import subprocess
import json
import re
from pathlib import Path

HOME = Path(os.environ.get("HOME", str(Path.home())))
MOCK_FILE = HOME / ".hyprconf" / "hypr" / ".cache" / "mock_wifi.json"

def run_cmd(args, timeout=10):
    try:
        res = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except Exception as e:
        return 1, "", str(e)

def get_status():
    if MOCK_FILE.exists():
        try:
            with open(MOCK_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                if "status" in data:
                    return data["status"]
        except Exception:
            pass

    _, wifi_out, _ = run_cmd(["nmcli", "-t", "-f", "WIFI", "g"])
    wifi_enabled = wifi_out.lower() == "enabled"

    code, dev_out, _ = run_cmd(["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION,DEVICE", "device"])
    
    conn_type = "none"
    conn_name = "Disconnected"
    is_connected = False
    signal = 0

    if code == 0 and dev_out:
        lines = dev_out.splitlines()
        # Look for connected devices
        for line in lines:
            parts = line.split(":")
            if len(parts) >= 3 and parts[1] == "connected":
                dtype = parts[0].lower()
                dconn = parts[2]
                if dtype == "ethernet":
                    conn_type = "ethernet"
                    conn_name = dconn or "Ethernet"
                    is_connected = True
                    signal = 100
                    break
                elif dtype == "wifi":
                    conn_type = "wifi"
                    conn_name = dconn or "Wi-Fi"
                    is_connected = True
                    # Wifi found connected, we can keep checking if ethernet is also there,
                    # but if ethernet was before it, ethernet took precedence.

    # If connected to Wi-Fi, get accurate active signal and SSID
    if conn_type == "wifi" and is_connected:
        code_act, act_out, _ = run_cmd(["nmcli", "-t", "-f", "ACTIVE,SIGNAL,SSID", "device", "wifi"])
        if code_act == 0 and act_out:
            for aline in act_out.splitlines():
                if aline.startswith("yes:"):
                    aparts = aline.split(":")
                    if len(aparts) >= 2 and aparts[1].isdigit():
                        signal = int(aparts[1])
                    if len(aparts) >= 3:
                        assid = ":".join(aparts[2:]).strip()
                        if assid and assid != "--":
                            conn_name = assid
                    break

        if signal == 0 or conn_name == "Wi-Fi":
            _, wlist_out, _ = run_cmd(["nmcli", "-t", "-f", "IN-USE,SIGNAL,SSID", "device", "wifi", "list"])
            if wlist_out:
                for wline in wlist_out.splitlines():
                    if wline.startswith("*:"):
                        wparts = wline.split(":")
                        if len(wparts) >= 2 and wparts[1].isdigit():
                            signal = int(wparts[1])
                        if len(wparts) >= 3:
                            found_ssid = ":".join(wparts[2:]).strip()
                            if found_ssid and found_ssid != "--":
                                conn_name = found_ssid
                        break

    return {
        "connected": is_connected,
        "type": conn_type,
        "name": conn_name,
        "signal": signal,
        "wifi_enabled": wifi_enabled
    }

def get_saved_connections():
    code, out, _ = run_cmd(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"])
    saved = set()
    if code == 0 and out:
        for line in out.splitlines():
            parts = line.split(":")
            if len(parts) >= 2 and ("wireless" in parts[1] or "wifi" in parts[1]):
                saved.add(parts[0])
    return saved

def get_wifi_list():
    if MOCK_FILE.exists():
        try:
            with open(MOCK_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                if "networks" in data:
                    return {
                        "wifi_enabled": data.get("wifi_enabled", True),
                        "networks": data["networks"]
                    }
        except Exception:
            pass

    _, wifi_out, _ = run_cmd(["nmcli", "-t", "-f", "WIFI", "g"])
    wifi_enabled = wifi_out.lower() == "enabled"

    if not wifi_enabled:
        return {
            "wifi_enabled": False,
            "networks": []
        }

    saved_conns = get_saved_connections()

    # Query Wi-Fi list (auto rescan)
    code, out, err = run_cmd(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY,BARS", "device", "wifi", "list"])
    
    networks_map = {}
    if code == 0 and out:
        for line in out.splitlines():
            # Format: IN-USE:SSID:SIGNAL:SECURITY:BARS
            # Note: SSID may contain colons, but nmcli escape is usually \:
            # Using regex or partition for safe split
            parts = line.split(":")
            if len(parts) < 4:
                continue
            
            in_use = (parts[0] == "*")
            # In case SSID had escaped colons or was blank
            ssid = parts[1]
            if not ssid or ssid == "--":
                continue
            
            signal_str = parts[2]
            try:
                signal = int(signal_str)
            except ValueError:
                signal = 0
                
            security = parts[3] if len(parts) > 3 else ""
            is_secured = bool(security and security != "--" and security.lower() != "none")

            is_saved = ssid in saved_conns

            # Keep strongest signal if duplicate SSID
            if ssid not in networks_map or signal > networks_map[ssid]["signal"] or in_use:
                networks_map[ssid] = {
                    "ssid": ssid,
                    "signal": signal,
                    "security": security if is_secured else "Open",
                    "is_secured": is_secured,
                    "is_connected": in_use,
                    "is_saved": is_saved
                }

    # Sort networks: Connected first, then Saved, then by Signal strength descending
    networks = list(networks_map.values())
    networks.sort(key=lambda n: (
        not n["is_connected"],
        not n["is_saved"],
        -n["signal"]
    ))

    return {
        "wifi_enabled": True,
        "networks": networks
    }

def connect_wifi(ssid, password=""):
    if not ssid:
        return {"success": False, "message": "SSID cannot be empty"}

    saved_conns = get_saved_connections()

    # If already saved and no password was passed, try activating saved connection profile
    if ssid in saved_conns and not password:
        code, out, err = run_cmd(["nmcli", "connection", "up", "id", ssid], timeout=25)
        if code == 0:
            return {"success": True, "message": f"Connected to {ssid}"}
        # If activation failed, fall through to dev wifi connect

    cmd = ["nmcli", "device", "wifi", "connect", ssid]
    if password:
        cmd.extend(["password", password])

    code, out, err = run_cmd(cmd, timeout=30)
    if code == 0:
        return {"success": True, "message": f"Successfully connected to {ssid}"}
    else:
        err_msg = err or out or "Connection failed"
        # Clean up common nmcli error messages
        err_msg = re.sub(r"^Error:\s*", "", err_msg)
        return {"success": False, "message": err_msg}

def disconnect_wifi(ssid=""):
    if ssid:
        code, out, err = run_cmd(["nmcli", "connection", "down", "id", ssid])
        return {"success": code == 0, "message": out or err}
    else:
        # Disconnect any wifi interface
        code, out, err = run_cmd(["bash", "-c", "nmcli -t -f DEVICE,TYPE dev | awk -F: '$2==\"wifi\" {print $1}' | xargs -r -n1 nmcli dev disconnect"])
        return {"success": code == 0, "message": out or err}

def toggle_wifi():
    _, wifi_out, _ = run_cmd(["nmcli", "-t", "-f", "WIFI", "g"])
    is_on = wifi_out.lower() == "enabled"
    new_state = "off" if is_on else "on"
    run_cmd(["nmcli", "radio", "wifi", new_state])
    return {"wifi_enabled": not is_on}

def open_nmtui():
    try:
        # Launch nmtui in floating Kitty window
        subprocess.Popen(["kitty", "--title", "floating", "-e", "nmtui"])
        return {"success": True, "message": "nmtui launched"}
    except Exception as e:
        return {"success": False, "message": str(e)}

def main():
    if len(sys.argv) < 2:
        print(json.dumps(get_status()))
        return

    action = sys.argv[1].lower()

    if action in ("status", "get"):
        print(json.dumps(get_status()))
    elif action in ("list", "wifi-list", "scan"):
        print(json.dumps(get_wifi_list()))
    elif action == "connect":
        ssid = sys.argv[2] if len(sys.argv) > 2 else ""
        password = sys.argv[3] if len(sys.argv) > 3 else ""
        print(json.dumps(connect_wifi(ssid, password)))
    elif action == "disconnect":
        ssid = sys.argv[2] if len(sys.argv) > 2 else ""
        print(json.dumps(disconnect_wifi(ssid)))
    elif action in ("toggle", "toggle-wifi"):
        print(json.dumps(toggle_wifi()))
    elif action in ("nmtui", "open-nmtui"):
        print(json.dumps(open_nmtui()))
    else:
        print(json.dumps({"error": f"Unknown action: {action}"}))

if __name__ == "__main__":
    main()
