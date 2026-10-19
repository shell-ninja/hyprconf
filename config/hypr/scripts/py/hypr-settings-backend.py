#!/usr/bin/env python3
"""
hypr-settings-backend.py — CLI/JSON backend bridge for Quickshell Settings.
Leverages the robust parser and applicator mechanisms from settings.py.
"""

import sys
import os
import json
import getpass
import subprocess
import shutil
from pathlib import Path

# Add hypr/scripts to sys.path to import settings.py directly
SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))

try:
    import settings
except ImportError as e:
    print(json.dumps({"error": f"Failed to import settings.py: {e}"}))
    sys.exit(1)


def get_all_settings():
    monitors_data = settings.parse_monitors()
    monitors_with_options = []
    for m in monitors_data:
        out_name = m.get("output", "")
        res_list, hz_map = settings.get_resolution_options(out_name)
        # Format resolutions as list of strings "1920x1080"
        formatted_res = [f"{w}x{h}" for w, h in res_list]
        formatted_hz = {}
        for (w, h), rates in hz_map.items():
            formatted_hz[f"{w}x{h}"] = [settings.fmt_hz(r) for r in rates]
        
        m_copy = dict(m)
        m_copy["available_resolutions"] = formatted_res
        m_copy["available_refresh"] = formatted_hz
        monitors_with_options.append(m_copy)

    # Keybinds list
    keybinds_list = []
    for kb in settings.iter_keybind_statements():
        raw_combo = kb.get("combo", "").strip().strip('"\'')
        display_combo = raw_combo.replace('.. "', '+ ').replace('.. \'', '+ ').replace('"', '').replace("'", '').replace("mainMod", "SUPER").strip()
        import re
        display_combo = re.sub(r"\+\s*\+", "+", display_combo).strip()
        if display_combo.startswith(","):
            display_combo = display_combo.lstrip(", ")
        display_combo = display_combo.strip()
        
        raw_action = kb.get("action", "").strip()
        display_action = raw_action
        if display_action.startswith("hl.dsp."):
            display_action = display_action[7:]
        
        keybinds_list.append({
            "combo": display_combo or "(bind)",
            "action": display_action,
            "raw": kb.get("raw", ""),
        })

    # Files status
    files_status = [
        {"name": "Appearance (configs.lua)", "path": str(settings.CONFIGS_LUA), "exists": settings.CONFIGS_LUA.is_file()},
        {"name": "Decoration (decoration.lua)", "path": str(settings.DECORATION_LUA), "exists": settings.DECORATION_LUA.is_file()},
        {"name": "Display (monitor.lua)", "path": str(settings.MONITOR_LUA), "exists": settings.MONITOR_LUA.is_file()},
        {"name": "Animations (animation.lua)", "path": str(settings.ANIMATION_LUA), "exists": settings.ANIMATION_LUA.is_file()},
        {"name": "Input (settings.lua)", "path": str(settings.SETTINGS_LUA), "exists": settings.SETTINGS_LUA.is_file()},
    ]

    # Avatar paths
    user = getpass.getuser()
    sddm_face = settings.SDDM_FACES_DIR / f"{user}.face.icon"
    local_face = Path.home() / ".face"
    cache_face = Path.home() / ".hyprconf" / "hypr" / ".cache" / ".face"

    current_sddm_theme = get_current_sddm_theme()
    silent_sddm_available = Path("/usr/share/sddm/themes/SilentSDDM").is_dir()
    is_silent_sddm = (current_sddm_theme.strip().lower() == "silentsddm")

    data = {
        "appearance": settings.read_appearance(),
        "input": settings.read_input(),
        "monitors": monitors_with_options,
        "animations": settings.parse_animations(),
        "curves": settings.parse_curves(),
        "anim_global": settings.parse_anim_global_enabled(),
        "env_vars": settings.parse_env_vars(),
        "keybinds": keybinds_list,
        "files": files_status,
        "sddm": {
            "current_theme": current_sddm_theme,
            "is_silent_sddm": is_silent_sddm,
            "silent_sddm_available": silent_sddm_available,
        },
        "avatar": {
            "username": user,
            "sddm_face_path": str(sddm_face),
            "sddm_face_exists": sddm_face.is_file(),
            "sddm_face_backup_exists": (settings.SDDM_FACES_DIR / f"{user}.face.icon.bkp").is_file(),
            "local_face_path": str(local_face),
            "local_face_exists": local_face.is_file(),
            "cache_face_path": str(cache_face),
            "cache_face_exists": cache_face.is_file(),
        }
    }
    return data


def get_current_sddm_theme():
    candidate_paths = [
        Path("/etc/sddm.conf.d/theme.conf.user"),
        Path("/etc/sddm.conf.d/theme.conf"),
        Path("/etc/sddm.conf"),
    ]
    theme_name = ""
    for p in candidate_paths:
        if p.is_file():
            try:
                content = p.read_text(errors="replace")
                in_theme_sec = False
                for line in content.splitlines():
                    stripped = line.strip()
                    if stripped.startswith("[") and stripped.endswith("]"):
                        in_theme_sec = (stripped.lower() == "[theme]")
                    elif in_theme_sec and stripped.startswith("Current="):
                        val = stripped.split("=", 1)[1].strip()
                        if val:
                            theme_name = val
                            break
            except Exception:
                pass
            if theme_name:
                break
    return theme_name or "default"


def launch_terminal(cmd_args, title="Hyprconf", wait=True):
    """
    Launch an interactive command inside kitty (or fallback terminal) with LD_PRELOAD
    stripped from the environment to prevent dynamic linker errors with libhypr_gtkblur.
    If wait is True, blocks until the terminal window is closed so Quickshell's Process
    handler receives the exit notification and refreshes UI state.
    """
    clean_env = os.environ.copy()
    clean_env.pop("LD_PRELOAD", None)
    
    kitty_bin = shutil.which("kitty")
    if kitty_bin:
        full_cmd = [kitty_bin]
        if title:
            full_cmd.extend(["--title", title])
        full_cmd.extend(cmd_args)
    else:
        for term in ["alacritty", "foot", "xterm", "gnome-terminal"]:
            term_bin = shutil.which(term)
            if term_bin:
                full_cmd = [term_bin, "-e"] + cmd_args
                break
        else:
            full_cmd = cmd_args

    proc = subprocess.Popen(
        full_cmd,
        env=clean_env,
        start_new_session=True,
    )
    if wait:
        proc.wait()
    return proc


def set_sddm_theme(theme_name="SilentSDDM"):
    target_dir = Path("/usr/share/sddm/themes") / theme_name
    if not target_dir.is_dir():
        return {"status": "error", "message": f"Theme '{theme_name}' not found in /usr/share/sddm/themes/"}
    
    cache_dir = settings.CACHE_HOME / "hypr-settings"
    cache_dir.mkdir(parents=True, exist_ok=True)
    helper_path = cache_dir / "priv-set-sddm-theme.sh"
    
    script_content = (
        "#!/usr/bin/env bash\n"
        "set -e\n"
        f"echo '==> Switching SDDM Theme to {theme_name} (requires sudo)...'\n"
        "sudo mkdir -p /etc/sddm.conf.d\n"
        f"sudo tee /etc/sddm.conf.d/theme.conf >/dev/null << 'EOF'\n"
        "[Theme]\n"
        f"Current={theme_name}\n"
        "\n"
        "[General]\n"
        "InputMethod=\n"
        "EOF\n"
        f"sudo tee /etc/sddm.conf.d/theme.conf.user >/dev/null << 'EOF'\n"
        "[Theme]\n"
        f"Current={theme_name}\n"
        "\n"
        "[General]\n"
        "InputMethod=\n"
        "EOF\n"
        "echo\n"
        f"echo '==> SDDM Theme successfully switched to {theme_name}!'\n"
        "echo 'Press Enter to close.'\n"
        "read -r\n"
    )
    helper_path.write_text(script_content)
    helper_path.chmod(0o755)
    
    launch_terminal(["bash", str(helper_path)], title="Set SDDM Theme", wait=True)
    return {"status": "ok", "message": f"Terminal launched to set SDDM theme to {theme_name}."}


def install_sddm_avatar():
    import shlex
    user = getpass.getuser()
    cache_face = Path.home() / ".hyprconf" / "hypr" / ".cache" / ".face"
    if not cache_face.is_file():
        return {"status": "error", "message": "No local avatar found. Choose an avatar first."}
    
    script_text = settings.build_avatar_apply_script(user, str(cache_face))
    cache_dir = settings.CACHE_HOME / "hypr-settings"
    cache_dir.mkdir(parents=True, exist_ok=True)
    script_path = cache_dir / "priv-helper.sh"
    wrapper_path = cache_dir / "priv-helper-sddm.sh"
    
    script_path.write_text(script_text)
    script_path.chmod(0o755)
    
    wrapper_path.write_text(
        "#!/usr/bin/env bash\n"
        "set -e\n"
        f"echo '==> Installing SDDM Login Avatar for {user} (requires sudo)...'\n"
        f"sudo bash {shlex.quote(str(script_path))}\n"
        "echo\n"
        "echo '==> SDDM Avatar successfully installed!'\n"
        "echo 'Press Enter to close.'\n"
        "read -r\n"
    )
    wrapper_path.chmod(0o755)
    
    launch_terminal(["bash", str(wrapper_path)], title="Set SDDM Avatar", wait=True)
    return {"status": "ok", "message": "Terminal launched to install SDDM avatar."}


def restore_sddm_avatar():
    import shlex
    user = getpass.getuser()
    backup_icon = settings.SDDM_FACES_DIR / f"{user}.face.icon.bkp"
    face_icon = settings.SDDM_FACES_DIR / f"{user}.face.icon"
    if not backup_icon.is_file():
        return {"status": "error", "message": "No SDDM avatar backup found."}
    
    cache_dir = settings.CACHE_HOME / "hypr-settings"
    cache_dir.mkdir(parents=True, exist_ok=True)
    wrapper_path = cache_dir / "priv-restore-sddm.sh"
    q = shlex.quote
    wrapper_path.write_text(
        "#!/usr/bin/env bash\n"
        "set -e\n"
        f"echo '==> Restoring previous SDDM Login Avatar backup for {user}...'\n"
        f"sudo cp -f {q(str(backup_icon))} {q(str(face_icon))}\n"
        "echo\n"
        "echo '==> SDDM Avatar backup restored successfully!'\n"
        "echo 'Press Enter to close.'\n"
        "read -r\n"
    )
    wrapper_path.chmod(0o755)
    
    launch_terminal(["bash", str(wrapper_path)], title="Restore SDDM Avatar", wait=True)
    return {"status": "ok", "message": "Terminal launched to restore SDDM avatar."}


def apply_settings(pending_dict):
    result = settings.ApplyResult()
    settings.apply_all(pending_dict, result)
    errors = sum(1 for status, _ in result.lines if status == "err")
    return {
        "status": "ok" if errors == 0 else "error",
        "errors": errors,
        "messages": [f"[{status.upper()}] {msg}" for status, msg in result.lines],
    }


def main():
    if len(sys.argv) < 2 or sys.argv[1] == "get":
        data = get_all_settings()
        print(json.dumps(data, indent=2))
        sys.exit(0)

    cmd = sys.argv[1]
    if cmd == "apply":
        # Read JSON pending from stdin or argument
        if len(sys.argv) > 2:
            raw_json = sys.argv[2]
        else:
            raw_json = sys.stdin.read()
        
        try:
            pending = json.loads(raw_json)
        except Exception as e:
            print(json.dumps({"status": "error", "errors": 1, "messages": [f"Invalid JSON: {e}"]}))
            sys.exit(1)
            
        res = apply_settings(pending)
        print(json.dumps(res, indent=2))
        sys.exit(0 if res["status"] == "ok" else 1)

    elif cmd == "install-sddm-avatar":
        res = install_sddm_avatar()
        print(json.dumps(res))
        sys.exit(0)

    elif cmd == "restore-sddm-avatar":
        res = restore_sddm_avatar()
        print(json.dumps(res))
        sys.exit(0)

    elif cmd == "set-sddm-theme":
        theme = sys.argv[2] if len(sys.argv) > 2 else "SilentSDDM"
        res = set_sddm_theme(theme)
        print(json.dumps(res))
        sys.exit(0)


    else:
        print(json.dumps({"error": f"Unknown command: {cmd}"}))
        sys.exit(1)


if __name__ == "__main__":
    main()
