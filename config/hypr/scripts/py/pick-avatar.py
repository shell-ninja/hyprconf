#!/usr/bin/env python3
"""
pick-avatar.py - Open xdg-desktop-portal FileChooser to select and apply an avatar image.
Crops the image to a center-square, resizes it with high quality, and installs it to ~/.hyprconf/hypr/.cache/.face.
"""

import os
import sys
import json
import uuid
import urllib.parse
from pathlib import Path
from PIL import Image

HOME = Path(os.environ.get("HOME", "/home/shell-ninja"))
CACHE_DIR = HOME / ".hyprconf" / "hypr" / ".cache"
FACE_DEST = CACHE_DIR / ".face"
BACKUP_FACE = CACHE_DIR / ".face.bkp"
LOCKSCREEN_JSON = HOME / ".hyprconf" / "quickshell" / "lockscreen.json"

def process_avatar(src_path: str, dst_path: Path):
    """Crop image to center square, convert to RGBA PNG, and save."""
    with Image.open(src_path) as im:
        im = im.convert("RGBA")
        w, h = im.size
        min_dim = min(w, h)
        left = (w - min_dim) // 2
        top = (h - min_dim) // 2
        right = left + min_dim
        bottom = top + min_dim
        im = im.crop((left, top, right, bottom))
        
        # Save at crisp high resolution (512x512)
        target_size = 512
        im = im.resize((target_size, target_size), Image.Resampling.LANCZOS)
        
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        im.save(dst_path, "PNG")
        
    # Also update ~/.face
    home_face = HOME / ".face"
    try:
        if home_face.is_symlink() or home_face.exists():
            home_face.unlink(missing_ok=True)
        home_face.symlink_to(dst_path)
    except Exception:
        pass

def reset_avatar():
    """Restore backup avatar if available."""
    if BACKUP_FACE.exists():
        import shutil
        shutil.copy2(BACKUP_FACE, FACE_DEST)
    
    # Remove custom_path in lockscreen.json
    if LOCKSCREEN_JSON.exists():
        try:
            with open(LOCKSCREEN_JSON, "r", encoding="utf-8") as f:
                cfg = json.load(f)
            if "avatar" in cfg and "custom_path" in cfg["avatar"]:
                del cfg["avatar"]["custom_path"]
            with open(LOCKSCREEN_JSON, "w", encoding="utf-8") as f:
                json.dump(cfg, f, indent=2)
        except Exception:
            pass

    print(json.dumps({"status": "reset", "cache_path": str(FACE_DEST)}), flush=True)

def open_portal_file_chooser():
    """Trigger xdg-desktop-portal FileChooser via D-Bus."""
    import dbus
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import GLib

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    loop = GLib.MainLoop()

    result = {"status": "cancelled"}

    def on_response(response, results):
        nonlocal result
        try:
            if response == 0 and "uris" in results:
                uris = results["uris"]
                if uris:
                    raw_uri = str(uris[0])
                    parsed_path = urllib.parse.unquote(
                        urllib.parse.urlparse(raw_uri).path if raw_uri.startswith("file://") else raw_uri
                    )
                    
                    if os.path.isfile(parsed_path):
                        # Backup original avatar if no backup exists yet
                        if FACE_DEST.exists() and not BACKUP_FACE.exists():
                            import shutil
                            shutil.copy2(FACE_DEST, BACKUP_FACE)

                        process_avatar(parsed_path, FACE_DEST)

                        # Update lockscreen.json custom_path
                        if LOCKSCREEN_JSON.exists():
                            try:
                                with open(LOCKSCREEN_JSON, "r", encoding="utf-8") as f:
                                    cfg = json.load(f)
                                if "avatar" not in cfg:
                                    cfg["avatar"] = {}
                                cfg["avatar"]["custom_path"] = str(FACE_DEST)
                                with open(LOCKSCREEN_JSON, "w", encoding="utf-8") as f:
                                    json.dump(cfg, f, indent=2)
                            except Exception as e:
                                sys.stderr.write(f"Warning: could not update lockscreen.json: {e}\n")

                        result = {
                            "status": "success",
                            "src_path": parsed_path,
                            "cache_path": str(FACE_DEST)
                        }
        except Exception as e:
            result = {"status": "error", "message": str(e)}
        finally:
            loop.quit()

    try:
        portal = bus.get_object("org.freedesktop.portal.Desktop", "/org/freedesktop/portal/desktop")
        chooser = dbus.Interface(portal, "org.freedesktop.portal.FileChooser")

        token = f"avatar_pick_{uuid.uuid4().hex[:8]}"
        options = {
            "handle_token": dbus.String(token),
            "multiple": dbus.Boolean(False),
            "filters": dbus.Array([
                dbus.Struct((
                    dbus.String("Image Files (*.png, *.jpg, *.jpeg, *.webp)"),
                    dbus.Array([
                        dbus.Struct((dbus.UInt32(0), dbus.String("*.png"))),
                        dbus.Struct((dbus.UInt32(0), dbus.String("*.jpg"))),
                        dbus.Struct((dbus.UInt32(0), dbus.String("*.jpeg"))),
                        dbus.Struct((dbus.UInt32(0), dbus.String("*.webp"))),
                    ], signature="(us)")
                ), signature="(sa(us))")
            ], signature="(sa(us))")
        }

        request_path = chooser.OpenFile("", "Select Avatar / Profile Picture", options)
        bus.add_signal_receiver(
            on_response,
            dbus_interface="org.freedesktop.portal.Request",
            signal_name="Response",
            path=request_path
        )

        loop.run()

    except Exception as e:
        result = {"status": "error", "message": str(e)}

    print(json.dumps(result), flush=True)

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--reset":
        reset_avatar()
    else:
        open_portal_file_chooser()
