#!/usr/bin/env python3
# =============================================================================
#  usb-notifier.py — USB & Pen Drive Insertion/Removal Watchdog
#
#  Listens for USB storage device events (pen drives, external SSDs/HDDs)
#  via udev events in user-space, sends desktop notifications with device
#  details (Vendor, Model, Size, Partitions, Labels), and plays sound effects.
#
#  Sound files checked in ~/.hyprconf/hypr/sounds/:
#    - Connect:    usb-plug.wav, usb-insert.wav, usb-inserted.wav, usb.wav,
#                  device-added.oga (fallback: /usr/share/sounds/freedesktop/...)
#    - Disconnect: usb-unplug.wav, usb-remove.wav, usb-removed.wav,
#                  device-removed.oga (fallback: freedesktop)
#
#  Usage:
#    python3 usb-notifier.py            # Run in daemon mode (default)
#    python3 usb-notifier.py --test     # Fire test connect & disconnect alerts
#    python3 usb-notifier.py --status   # Check if background daemon is active
# =============================================================================

from __future__ import annotations

import argparse
import fcntl
import json
import logging
import os
import re
import shutil
import signal
import subprocess
import sys
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

# Paths
HOME = Path.home()
HYPRCONF_DIR = HOME / ".hyprconf" / "hypr"
SCRIPTS_DIR = HYPRCONF_DIR / "scripts"
SOUNDS_DIR = HYPRCONF_DIR / "sounds"
CACHE_DIR = HOME / ".cache" / "usb-notifier"
LOCK_FILE = CACHE_DIR / "usb-notifier.lock"
LOG_FILE = CACHE_DIR / "usb-notifier.log"

# Debounce delay (seconds) to wait for partitions to enumerate
DEBOUNCE_DELAY = 0.8

# Standard fallback sounds
SYSTEM_SOUND_ADD = Path("/usr/share/sounds/freedesktop/stereo/device-added.oga")
SYSTEM_SOUND_REMOVE = Path("/usr/share/sounds/freedesktop/stereo/device-removed.oga")


# -----------------------------------------------------------------------------
# Sound playback
# -----------------------------------------------------------------------------

def find_sound(kind: str) -> Optional[Path]:
    """Find sound file by priority: custom in ~/.hyprconf/hypr/sounds, then system."""
    if kind == "plug":
        candidates = [
            SOUNDS_DIR / "usb-plug.wav",
            SOUNDS_DIR / "usb-plug.mp3",
            SOUNDS_DIR / "usb-plug.oga",
            SOUNDS_DIR / "usb-insert.wav",
            SOUNDS_DIR / "usb-inserted.wav",
            SOUNDS_DIR / "usb.wav",
            SOUNDS_DIR / "device-added.oga",
            SOUNDS_DIR / "device-added.wav",
            SYSTEM_SOUND_ADD,
            SOUNDS_DIR / "update.wav",
        ]
    else:  # unplug
        candidates = [
            SOUNDS_DIR / "usb-unplug.wav",
            SOUNDS_DIR / "usb-unplug.mp3",
            SOUNDS_DIR / "usb-unplug.oga",
            SOUNDS_DIR / "usb-remove.wav",
            SOUNDS_DIR / "usb-removed.wav",
            SOUNDS_DIR / "device-removed.oga",
            SOUNDS_DIR / "device-removed.wav",
            SYSTEM_SOUND_REMOVE,
        ]

    for p in candidates:
        if p.exists() and p.is_file():
            return p
    return None


def play_sound(kind: str) -> None:
    """Play sound in a background thread to prevent blocking event loop."""
    def _worker():
        sound_path = find_sound(kind)
        if not sound_path:
            return

        players = ["paplay", "pw-play", "canberra-gtk-play", "mpv", "aplay"]
        for player in players:
            bin_path = shutil.which(player)
            if not bin_path:
                continue

            try:
                cmd = [bin_path, str(sound_path)]
                if player == "canberra-gtk-play":
                    cmd = [bin_path, "-f", str(sound_path)]
                elif player == "mpv":
                    cmd = [bin_path, "--no-video", "--really-quiet", str(sound_path)]

                subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
                return
            except Exception as e:
                logging.debug("Sound player %s failed: %s", player, e)

    threading.Thread(target=_worker, daemon=True).start()


# -----------------------------------------------------------------------------
# Desktop Notification
# -----------------------------------------------------------------------------

def notify_user(title: str, message: str, icon: str = "drive-removable-media-usb-pendrive", urgency: str = "normal") -> None:
    """Send notification via notify-send."""
    if not shutil.which("notify-send"):
        logging.warning("notify-send not installed")
        return

    # Check for available icon fallbacks
    cmd = [
        "notify-send",
        "-a", "USB Notifier",
        "-i", icon,
        "-u", urgency,
        title,
        message,
    ]
    try:
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
    except Exception as e:
        logging.error("Failed to run notify-send: %s", e)


# -----------------------------------------------------------------------------
# Device Inspection
# -----------------------------------------------------------------------------

def format_size(bytes_val: int) -> str:
    """Convert bytes to human-readable size."""
    if not bytes_val or bytes_val <= 0:
        return ""
    n = float(bytes_val)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024.0 or unit == "TB":
            return f"{n:.1f} {unit}" if unit in ("GB", "TB") else f"{int(n)} {unit}"
        n /= 1024.0
    return f"{n:.1f} TB"


@dataclass
class USBDevice:
    devnode: str  # e.g. /dev/sdb
    vendor: str = ""
    model: str = ""
    size_str: str = ""
    label: str = ""
    partitions: List[str] = field(default_factory=list)

    def display_name(self) -> str:
        parts = [self.vendor.strip(), self.model.strip()]
        name = " ".join(p for p in parts if p)
        if not name:
            name = "USB Storage Device"
        if self.label:
            name = f"{name} ({self.label})"
        elif self.size_str:
            name = f"{name} ({self.size_str})"
        return name


def get_device_info(disk_node: str) -> Optional[USBDevice]:
    """Query lsblk for structured block device information."""
    if not os.path.exists(disk_node):
        return None

    try:
        res = subprocess.run(
            ["lsblk", "-b", "-J", "-o", "NAME,SIZE,LABEL,FSTYPE,MOUNTPOINTS,MODEL,VENDOR,TYPE", disk_node],
            capture_output=True,
            text=True,
            check=False,
            timeout=3,
        )
        if not res.stdout:
            return None

        data = json.loads(res.stdout)
        devices = data.get("blockdevices", [])
        if not devices:
            return None

        dev = devices[0]
        vendor = (dev.get("vendor") or "").strip()
        model = (dev.get("model") or "").strip()
        size_bytes = dev.get("size") or 0
        size_str = format_size(size_bytes)
        label = (dev.get("label") or "").strip()

        partitions = []
        for child in dev.get("children", []):
            c_name = child.get("name") or ""
            c_label = child.get("label") or ""
            c_fs = child.get("fstype") or ""
            c_size = format_size(child.get("size") or 0)

            part_desc = f"/dev/{c_name}"
            extra = []
            if c_label:
                extra.append(c_label)
            if c_fs:
                extra.append(c_fs)
            if c_size:
                extra.append(c_size)

            if extra:
                part_desc += f" [{', '.join(extra)}]"
            partitions.append(part_desc)

            if not label and c_label:
                label = c_label

        return USBDevice(
            devnode=disk_node,
            vendor=vendor,
            model=model,
            size_str=size_str,
            label=label,
            partitions=partitions,
        )
    except Exception as e:
        logging.debug("Error inspecting device %s: %s", disk_node, e)
        return None


# -----------------------------------------------------------------------------
# Event Processing & Debouncing
# -----------------------------------------------------------------------------

class USBWatcher:
    def __init__(self):
        self.pending_adds: Dict[str, threading.Timer] = {}
        self.known_devices: Dict[str, USBDevice] = {}
        self.lock = threading.Lock()
        self.running = True

    def on_device_added(self, disk_node: str):
        """Called when a USB disk/partition event settles."""
        with self.lock:
            self.pending_adds.pop(disk_node, None)

        info = get_device_info(disk_node)
        if not info:
            # Device might have been removed immediately or couldn't be read
            return

        with self.lock:
            self.known_devices[disk_node] = info

        # Construct notification
        title = "USB Drive Connected"
        name = info.display_name()

        lines = [name]
        if info.partitions:
            if len(info.partitions) == 1:
                lines.append(f"Partition: {info.partitions[0]}")
            else:
                lines.append(f"Partitions:\n" + "\n".join(f" • {p}" for p in info.partitions))
        else:
            lines.append(f"Node: {disk_node}")

        body = "\n".join(lines)
        logging.info("USB inserted: %s (%s)", name, disk_node)

        # Notify and Play Sound
        notify_user(title, body, icon="drive-removable-media-usb-pendrive")
        play_sound("plug")

    def schedule_add(self, disk_node: str):
        """Debounce addition events for disk and partitions."""
        with self.lock:
            if disk_node in self.pending_adds:
                self.pending_adds[disk_node].cancel()

            timer = threading.Timer(DEBOUNCE_DELAY, self.on_device_added, args=[disk_node])
            self.pending_adds[disk_node] = timer
            timer.start()

    def handle_remove(self, disk_node: str):
        """Handle USB device removal."""
        with self.lock:
            if disk_node in self.pending_adds:
                self.pending_adds[disk_node].cancel()
                del self.pending_adds[disk_node]

            info = self.known_devices.pop(disk_node, None)

        if info:
            name = info.display_name()
            body = f"{name} was disconnected."
        else:
            body = f"USB device ({disk_node}) was disconnected."

        logging.info("USB removed: %s", disk_node)
        notify_user("USB Drive Removed", body, icon="drive-removable-media-usb-pendrive")
        play_sound("unplug")

    def run(self):
        """Monitor udevadm events."""
        cmd = ["udevadm", "monitor", "--udev", "-p", "--subsystem-match=block"]
        try:
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                bufsize=1,
            )
        except Exception as e:
            logging.error("Failed to start udevadm monitor: %s", e)
            return

        current_props: Dict[str, str] = {}

        try:
            for line in iter(proc.stdout.readline, ""):
                if not self.running:
                    break

                line = line.strip()
                if not line:
                    if current_props:
                        self._process_event(current_props)
                        current_props = {}
                    continue

                if "=" in line:
                    k, v = line.split("=", 1)
                    current_props[k] = v

            if current_props:
                self._process_event(current_props)

        finally:
            proc.terminate()
            with self.lock:
                for timer in self.pending_adds.values():
                    timer.cancel()
                self.pending_adds.clear()

    def _process_event(self, props: Dict[str, str]):
        action = props.get("ACTION")
        subsystem = props.get("SUBSYSTEM")
        id_bus = props.get("ID_BUS")
        devname = props.get("DEVNAME")
        devtype = props.get("DEVTYPE")
        devpath = props.get("DEVPATH", "")

        if subsystem != "block" or not devname:
            return

        # Check if USB bus (either via ID_BUS or path containing /usb)
        is_usb = (id_bus == "usb") or ("/usb" in devpath)
        if not is_usb:
            return

        # Find parent disk node (e.g. if devname is /dev/sdb1, disk is /dev/sdb)
        disk_node = devname
        m = re.match(r"^(/dev/[a-z]+)\d+$", devname)
        if m:
            disk_node = m.group(1)

        if action == "add":
            self.schedule_add(disk_node)
        elif action == "remove":
            # Only trigger on the parent disk removal or if we have it tracked
            if devtype == "disk" or disk_node in self.known_devices:
                self.handle_remove(disk_node)

    def stop(self):
        self.running = False


# -----------------------------------------------------------------------------
# Daemon Control & Lock
# -----------------------------------------------------------------------------

def acquire_lock():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    fh = open(LOCK_FILE, "w")
    try:
        fcntl.flock(fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        logging.error("Another instance of usb-notifier is already running — exiting.")
        sys.exit(0)
    fh.write(str(os.getpid()))
    fh.flush()
    return fh


def setup_logging():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[
            logging.FileHandler(LOG_FILE),
            logging.StreamHandler(),
        ],
    )


# -----------------------------------------------------------------------------
# CLI Entrypoint
# -----------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="USB & Pen Drive Notifier Daemon")
    parser.add_argument("--test", action="store_true", help="Send test insert & remove notifications with sound")
    parser.add_argument("--status", action="store_true", help="Check daemon running status")
    args = parser.parse_args()

    if args.status:
        if LOCK_FILE.exists():
            try:
                pid = int(LOCK_FILE.read_text().strip())
                os.kill(pid, 0)
                print(f"usb-notifier is RUNNING (PID {pid})")
                return
            except (ValueError, OSError):
                pass
        print("usb-notifier is NOT running")
        return

    if args.test:
        print("Firing test USB insert notification & sound...")
        notify_user(
            "USB Drive Connected",
            "SanDisk Ultra USB 3.0 (32.0 GB)\nPartition: /dev/sdb1 [SANDISK, vfat, 31.9 GB]",
            icon="drive-removable-media-usb-pendrive",
        )
        play_sound("plug")
        time.sleep(2.5)
        print("Firing test USB remove notification & sound...")
        notify_user(
            "USB Drive Removed",
            "SanDisk Ultra USB 3.0 was disconnected.",
            icon="drive-removable-media-usb-pendrive",
        )
        play_sound("unplug")
        print("Test completed.")
        return

    setup_logging()
    lock_fh = acquire_lock()

    watcher = USBWatcher()

    def _sig_handler(signum, _frame):
        logging.info("Received signal %s, terminating watcher...", signum)
        watcher.stop()

    signal.signal(signal.SIGINT, _sig_handler)
    signal.signal(signal.SIGTERM, _sig_handler)

    logging.info("USB Notifier daemon started.")
    try:
        watcher.run()
    finally:
        lock_fh.close()
        try:
            LOCK_FILE.unlink(missing_ok=True)
        except Exception:
            pass
        logging.info("USB Notifier daemon stopped.")


if __name__ == "__main__":
    main()
