#!/usr/bin/env python3
"""
hyprconf-plugin.py — Hyprconf Plugin Manager CLI & Backend Engine
Discovers, downloads, installs, and manages plugins from github.com/shell-ninja/hyprconf-plugins.
Powers both the CLI tool (hyprconf-plugin) and Quickshell Settings Studio UI.
"""

import sys
import os
import json
import shutil
import tarfile
import urllib.request
import urllib.error
import argparse
import subprocess
from pathlib import Path
from datetime import datetime

HOME = Path(os.environ.get("HOME", str(Path.home())))
LOCAL_HYPRCONF = HOME / ".local" / "share" / "hyprconf"
PLUGINS_DIR = LOCAL_HYPRCONF / "plugins"
CACHE_DIR = LOCAL_HYPRCONF / ".cache"
INSTALLED_JSON = PLUGINS_DIR / "installed.json"
INDEX_CACHE = CACHE_DIR / "plugins_index.json"

DEV_REGISTRY_PATH = Path("/main/Code/shell-ninja/hyprconf-plugins")
REMOTE_INDEX_URL = "https://raw.githubusercontent.com/shell-ninja/hyprconf-plugins/main/index.json"
REMOTE_TARBALL_URL = "https://api.github.com/repos/shell-ninja/hyprconf-plugins/tarball/main"


def load_installed() -> dict:
    """Load installed plugins state."""
    if not INSTALLED_JSON.exists():
        return {}
    try:
        with open(INSTALLED_JSON, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def save_installed(installed: dict):
    """Save installed plugins state."""
    PLUGINS_DIR.mkdir(parents=True, exist_ok=True)
    with open(INSTALLED_JSON, "w", encoding="utf-8") as f:
        json.dump(installed, f, indent=2)


def fetch_registry(force_refresh=False) -> dict:
    """Fetch central plugin registry from local dev repo or GitHub."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    # 1. If dev registry exists locally, prioritize it
    local_index = DEV_REGISTRY_PATH / "index.json"
    if local_index.exists():
        try:
            with open(local_index, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass

    # 2. Check cached registry if not expired (< 1 hour)
    if not force_refresh and INDEX_CACHE.exists():
        try:
            mtime = INDEX_CACHE.stat().st_mtime
            if (datetime.now().timestamp() - mtime) < 3600:
                with open(INDEX_CACHE, "r", encoding="utf-8") as f:
                    return json.load(f)
        except Exception:
            pass

    # 3. Fetch from remote GitHub
    try:
        req = urllib.request.Request(
            REMOTE_INDEX_URL,
            headers={"User-Agent": "Hyprconf-Plugin-Manager/1.0.3"}
        )
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode("utf-8"))
            with open(INDEX_CACHE, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
            return data
    except Exception as e:
        # Fallback to expired cache if network failed
        if INDEX_CACHE.exists():
            try:
                with open(INDEX_CACHE, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                pass
        return {"plugins": []}


def download_and_extract_plugin(plugin_meta: dict, target_dir: Path) -> bool:
    """Download a plugin folder from GitHub or copy from local dev repo."""
    plugin_id = plugin_meta["id"]
    rel_path = plugin_meta.get("path", plugin_id)

    # 1. Local Dev Copy (instant)
    local_source = DEV_REGISTRY_PATH / rel_path
    if local_source.exists() and local_source.is_dir():
        if target_dir.exists():
            shutil.rmtree(target_dir)
        shutil.copytree(local_source, target_dir)
        return True

    # 2. Remote GitHub Tarball Extraction
    temp_tar = CACHE_DIR / f"{plugin_id}.tar.gz"
    try:
        req = urllib.request.Request(
            REMOTE_TARBALL_URL,
            headers={"User-Agent": "Hyprconf-Plugin-Manager/1.0.3"}
        )
        with urllib.request.urlopen(req, timeout=15) as response, open(temp_tar, "wb") as out_f:
            shutil.copyfileobj(response, out_f)

        target_dir.mkdir(parents=True, exist_ok=True)
        # Extract only matching subfolder
        with tarfile.open(temp_tar, "r:gz") as tar:
            members = tar.getmembers()
            prefix = None
            for m in members:
                parts = Path(m.name).parts
                # Tarball structure: <repo-hash>/<path>/...
                if len(parts) >= 2 and parts[1] == rel_path:
                    prefix = f"{parts[0]}/{rel_path}"
                    break

            if not prefix:
                print(f"[Error] Plugin path '{rel_path}' not found in remote archive.", file=sys.stderr)
                return False

            for m in members:
                if m.name.startswith(prefix):
                    rel = os.path.relpath(m.name, prefix)
                    if rel == ".":
                        continue
                    dest = target_dir / rel
                    if m.isdir():
                        dest.mkdir(parents=True, exist_ok=True)
                    else:
                        dest.parent.mkdir(parents=True, exist_ok=True)
                        with tar.extractfile(m) as src, open(dest, "wb") as dst:
                            shutil.copyfileobj(src, dst)
                        dest.chmod(m.mode)

        temp_tar.unlink(missing_ok=True)
        return True
    except Exception as e:
        print(f"[Error] Failed downloading plugin: {e}", file=sys.stderr)
        temp_tar.unlink(missing_ok=True)
        return False


def install_plugin(plugin_id: str) -> bool:
    """Install a plugin by ID from registry."""
    registry = fetch_registry()
    plugins = {p["id"]: p for p in registry.get("plugins", [])}
    if plugin_id not in plugins:
        print(f"[Error] Unknown plugin '{plugin_id}'. Run 'hyprconf-plugin list' to browse available plugins.", file=sys.stderr)
        return False

    meta = plugins[plugin_id]
    target_dir = PLUGINS_DIR / plugin_id

    print(f"==> Installing {meta['name']} ({plugin_id})...")
    ok = download_and_extract_plugin(meta, target_dir)
    if not ok:
        return False

    # Run install script if available
    install_sh = target_dir / "install.sh"
    if install_sh.exists():
        install_sh.chmod(0o755)
        print("==> Running post-install hook...")
        subprocess.run(["bash", str(install_sh)], cwd=str(target_dir))

    # Update installed.json
    installed = load_installed()
    installed[plugin_id] = {
        "enabled": True,
        "version": meta.get("version", "1.0.0"),
        "installed_at": datetime.now().isoformat(),
        "source": "official"
    }
    save_installed(installed)

    # Trigger color sync if theme plugin
    hypr_colors = HOME / ".hyprconf/hypr/scripts/py/hypr-colors.py"
    if hypr_colors.exists():
        subprocess.run([sys.executable, str(hypr_colors)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    print(f"[OK] Plugin '{plugin_id}' installed and enabled successfully!")
    return True


def install_plugin_from_path(src_path_str: str) -> bool:
    """Install a plugin by dragging and dropping a directory or archive."""
    src_path = Path(src_path_str).expanduser().resolve()
    if not src_path.exists():
        print(f"[Error] Path does not exist: {src_path}", file=sys.stderr)
        return False

    extracted_temp = None
    plugin_dir = src_path

    # If an archive was dropped, extract to temporary location
    if src_path.is_file() and (src_path.name.endswith(".tar.gz") or src_path.suffix in (".tar", ".tgz")):
        import tempfile
        extracted_temp = Path(tempfile.mkdtemp(prefix="hyprconf_drop_"))
        try:
            with tarfile.open(src_path, "r:*") as tar:
                tar.extractall(path=extracted_temp)
            # Find subfolder with plugin.json
            found = False
            for root_dir, _, files in os.walk(extracted_temp):
                if "plugin.json" in files:
                    plugin_dir = Path(root_dir)
                    found = True
                    break
            if not found:
                print(f"[Error] No plugin.json found inside archive.", file=sys.stderr)
                if extracted_temp:
                    shutil.rmtree(extracted_temp, ignore_errors=True)
                return False
        except Exception as e:
            print(f"[Error] Failed extracting archive: {e}", file=sys.stderr)
            if extracted_temp:
                shutil.rmtree(extracted_temp, ignore_errors=True)
            return False

    manifest = plugin_dir / "plugin.json"
    if not manifest.exists():
        print(f"[Error] No plugin.json found in {src_path}", file=sys.stderr)
        if extracted_temp:
            shutil.rmtree(extracted_temp, ignore_errors=True)
        return False

    try:
        with open(manifest, "r", encoding="utf-8") as f:
            meta = json.load(f)
    except Exception as e:
        print(f"[Error] Invalid plugin.json: {e}", file=sys.stderr)
        if extracted_temp:
            shutil.rmtree(extracted_temp, ignore_errors=True)
        return False

    plugin_id = meta.get("id")
    if not plugin_id:
        print("[Error] plugin.json is missing required 'id' field.", file=sys.stderr)
        if extracted_temp:
            shutil.rmtree(extracted_temp, ignore_errors=True)
        return False

    target_dir = PLUGINS_DIR / plugin_id
    if target_dir.exists():
        shutil.rmtree(target_dir)

    shutil.copytree(plugin_dir, target_dir)

    install_sh = target_dir / "install.sh"
    if install_sh.exists():
        install_sh.chmod(0o755)
        subprocess.run(["bash", str(install_sh)], cwd=str(target_dir))

    installed = load_installed()
    installed[plugin_id] = {
        "enabled": True,
        "version": meta.get("version", "1.0.0"),
        "installed_at": datetime.now().isoformat(),
        "source": "local-drop"
    }
    save_installed(installed)

    if extracted_temp:
        shutil.rmtree(extracted_temp, ignore_errors=True)

    print(f"[OK] Plugin '{plugin_id}' installed from drop target!")
    return True


def cleanup_editor_themes():
    """Strip all Hyprconf theme customizations and restore default editor settings."""
    editor_paths = [
        HOME / ".config" / "Antigravity IDE" / "User" / "settings.json",
        HOME / ".config" / "VSCodium" / "User" / "settings.json",
        HOME / ".config" / "Code" / "User" / "settings.json",
        HOME / ".config" / "Code - OSS" / "User" / "settings.json",
        HOME / ".config" / "Cursor" / "User" / "settings.json"
    ]
    for sp in editor_paths:
        if sp.exists():
            try:
                with open(sp, "r", encoding="utf-8") as f:
                    cfg = json.load(f)
                modified = False
                for k in ("workbench.colorCustomizations", "editor.tokenColorCustomizations",
                          "hyprconf.theme.synced", "hyprconf.theme.timestamp", "hyprconf.theme.version"):
                    if k in cfg:
                        cfg.pop(k, None)
                        modified = True
                if modified:
                    with open(sp, "w", encoding="utf-8") as f:
                        json.dump(cfg, f, indent=4)
                        f.flush()
                        os.fsync(f.fileno())
            except Exception:
                pass


def uninstall_plugin(plugin_id: str) -> bool:
    """Uninstall a plugin by ID and revert its changes."""
    target_dir = PLUGINS_DIR / plugin_id
    installed = load_installed()

    print(f"==> Uninstalling {plugin_id}...")

    # Run plugin uninstall hook if available
    uninstall_sh = target_dir / "uninstall.sh"
    if uninstall_sh.exists():
        uninstall_sh.chmod(0o755)
        try:
            subprocess.run(["bash", str(uninstall_sh)], cwd=str(target_dir), timeout=10)
        except Exception:
            pass

    # Ensure editor theme overrides are fully reverted
    if plugin_id == "code-theme-sync" or (target_dir / "bin" / "sync-theme.py").exists():
        cleanup_editor_themes()

    if target_dir.exists():
        shutil.rmtree(target_dir, ignore_errors=True)

    # Clean legacy development paths if any
    legacy_dir = HOME / ".hyprconf" / "plugins" / plugin_id
    if legacy_dir.exists():
        shutil.rmtree(legacy_dir, ignore_errors=True)

    if plugin_id in installed:
        del installed[plugin_id]
        save_installed(installed)

    print(f"[OK] Plugin '{plugin_id}' uninstalled and state reverted.")
    return True


def enable_plugin(plugin_id: str) -> bool:
    """Enable an installed plugin."""
    installed = load_installed()
    target_dir = PLUGINS_DIR / plugin_id
    if not target_dir.exists():
        print(f"[Error] Plugin '{plugin_id}' is not installed.", file=sys.stderr)
        return False

    installed[plugin_id] = installed.get(plugin_id, {})
    installed[plugin_id]["enabled"] = True
    save_installed(installed)

    # Run install or enable script
    install_sh = target_dir / "install.sh"
    if install_sh.exists():
        subprocess.run(["bash", str(install_sh)], cwd=str(target_dir))

    # Trigger color sync if theme plugin
    hypr_colors = HOME / ".hyprconf/hypr/scripts/py/hypr-colors.py"
    if hypr_colors.exists():
        subprocess.run([sys.executable, str(hypr_colors)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    print(f"[OK] Plugin '{plugin_id}' enabled.")
    return True


def disable_plugin(plugin_id: str) -> bool:
    """Disable an installed plugin without deleting files."""
    installed = load_installed()
    target_dir = PLUGINS_DIR / plugin_id
    if not target_dir.exists():
        print(f"[Error] Plugin '{plugin_id}' is not installed.", file=sys.stderr)
        return False

    installed[plugin_id] = installed.get(plugin_id, {})
    installed[plugin_id]["enabled"] = False
    save_installed(installed)

    uninstall_sh = target_dir / "uninstall.sh"
    if uninstall_sh.exists():
        subprocess.run(["bash", str(uninstall_sh)], cwd=str(target_dir))

    if plugin_id == "code-theme-sync":
        cleanup_editor_themes()

    print(f"[OK] Plugin '{plugin_id}' disabled and state reverted.")
    return True


def list_plugins():
    """Display list of available and installed plugins."""
    registry = fetch_registry()
    installed = load_installed()
    plugins = registry.get("plugins", [])

    print("\n📦 Hyprconf Plugins Catalog")
    print("=" * 65)

    if not plugins:
        print("No plugins found in registry.")
        return

    for p in plugins:
        pid = p["id"]
        is_inst = pid in installed or (PLUGINS_DIR / pid).exists()
        is_en = installed.get(pid, {}).get("enabled", True) if is_inst else False

        status_str = "🟢 Enabled" if (is_inst and is_en) else ("🟡 Disabled" if is_inst else "⚪ Available")
        print(f"\n• {p['name']} ({pid})  [{status_str}]")
        print(f"  Category: {p.get('category', 'General')} | Version: {p.get('version', '1.0.0')} | Author: {p.get('author', 'Unknown')}")
        print(f"  {p.get('description', '')}")

    print("\n" + "=" * 65)
    print("Install:   hyprconf-plugin install <id>")
    print("Toggle:    hyprconf-plugin enable|disable <id>")
    print("Remove:    hyprconf-plugin remove <id>\n")


def output_json_status():
    """Return JSON formatted status for Quickshell UI."""
    registry = fetch_registry()
    installed = load_installed()
    output = {
        "installed": [],
        "available": []
    }

    def enrich_plugin(p, is_inst, is_en):
        pid = p.get("id", "")
        item = dict(p)
        item["installed"] = is_inst
        item["enabled"] = is_en

        manifest = None
        for cand in [PLUGINS_DIR / pid / "plugin.json", DEV_REGISTRY_PATH / pid / "plugin.json"]:
            if cand.exists():
                try:
                    with open(cand, "r", encoding="utf-8") as f:
                        manifest = json.load(f)
                        break
                except Exception:
                    pass

        if manifest:
            for k, v in manifest.items():
                if k not in item or not item[k]:
                    item[k] = v

        if "features" not in item:
            if pid == "code-theme-sync":
                item["features"] = [
                    "Zero-Restart Live Injection: Injects color tokens directly into running editor sessions.",
                    "Obsidian Glass Surfaces: Replaces default chrome with deep obsidian glass and subtle accent rims.",
                    "Wallpaper Harmony: Automatically synchronizes editor background, sidebar & syntax with active wallpaper.",
                    "Terminal ANSI Synchronization: Matches integrated editor terminal colors with Kitty terminal.",
                    "Safe & Non-Destructive: Automatic backup and instant restore on uninstallation."
                ]
                item["targets"] = ["Antigravity IDE", "VSCodium", "VS Code", "Code - OSS", "Cursor"]
                item["tagline"] = "Live theme & obsidian palette synchronization for VS Code, VSCodium & Antigravity IDE"
            else:
                item["features"] = ["Native Quickshell integration", "Obsidian glass styling", "Automatic updates"]
                item["targets"] = ["Hyprconf Desktop"]
                item["tagline"] = item.get("description", "")

        # Dynamic icon resolution from plugin directory
        icon_field = item.get("icon", "")
        icon_url = ""
        if icon_field:
            if icon_field.startswith("http://") or icon_field.startswith("https://") or icon_field.startswith("file://"):
                icon_url = icon_field
            else:
                cand_inst = PLUGINS_DIR / pid / icon_field
                if cand_inst.exists():
                    icon_url = f"file://{cand_inst.resolve()}"
                else:
                    cand_dev = DEV_REGISTRY_PATH / pid / icon_field
                    if cand_dev.exists():
                        icon_url = f"file://{cand_dev.resolve()}"
                    else:
                        icon_url = f"https://raw.githubusercontent.com/shell-ninja/hyprconf-plugins/main/{pid}/{icon_field}"

        item["icon_url"] = icon_url

        return item

    known_pids = set()
    for p in registry.get("plugins", []):
        pid = p["id"]
        known_pids.add(pid)
        is_inst = pid in installed or (PLUGINS_DIR / pid).exists()
        is_en = installed.get(pid, {}).get("enabled", True) if is_inst else False

        item = enrich_plugin(p, is_inst, is_en)
        if is_inst:
            output["installed"].append(item)
        else:
            output["available"].append(item)

    for pid, info in installed.items():
        if pid not in known_pids:
            item = enrich_plugin(info, True, info.get("enabled", True))
            output["installed"].append(item)

    print(json.dumps(output, indent=2))


def set_plugin_config(plugin_id: str, key: str, value_str: str) -> bool:
    target_dir = PLUGINS_DIR / plugin_id
    if not target_dir.exists():
        print(f"[Error] Plugin '{plugin_id}' is not installed.", file=sys.stderr)
        return False
    cfg_file = target_dir / "config.json"
    cfg = {}
    if cfg_file.exists():
        try:
            with open(cfg_file, "r", encoding="utf-8") as f:
                cfg = json.load(f)
        except Exception:
            pass

    val = value_str
    if value_str.lower() == "true":
        val = True
    elif value_str.lower() == "false":
        val = False
    elif value_str.isdigit():
        val = int(value_str)

    cfg[key] = val
    with open(cfg_file, "w", encoding="utf-8") as f:
        json.dump(cfg, f, indent=2)
    print(f"[OK] Updated '{key}' = {val} for plugin '{plugin_id}'")
    return True


def main():
    parser = argparse.ArgumentParser(description="Hyprconf Plugin Manager")
    sub = parser.add_subparsers(dest="command")

    sub.add_parser("list", help="List available and installed plugins")
    sub.add_parser("json", help="Dump JSON status for Quickshell UI")

    ins_p = sub.add_parser("install", help="Install a plugin")
    ins_p.add_argument("plugin_id", help="Plugin identifier")

    insp_p = sub.add_parser("install-path", help="Install a plugin from folder or archive path")
    insp_p.add_argument("path", help="Path to plugin folder or archive")

    rem_p = sub.add_parser("remove", aliases=["uninstall"], help="Uninstall a plugin")
    rem_p.add_argument("plugin_id", help="Plugin identifier")

    en_p = sub.add_parser("enable", help="Enable a plugin")
    en_p.add_argument("plugin_id", help="Plugin identifier")

    dis_p = sub.add_parser("disable", help="Disable a plugin")
    dis_p.add_argument("plugin_id", help="Plugin identifier")

    cfg_p = sub.add_parser("set-config", help="Set plugin configuration key")
    cfg_p.add_argument("plugin_id", help="Plugin identifier")
    cfg_p.add_argument("key", help="Configuration key")
    cfg_p.add_argument("value", help="Configuration value")

    args = parser.parse_args()

    if args.command == "list" or not args.command:
        list_plugins()
    elif args.command == "json":
        output_json_status()
    elif args.command == "install":
        install_plugin(args.plugin_id)
    elif args.command == "install-path":
        install_plugin_from_path(args.path)
    elif args.command in ("remove", "uninstall"):
        uninstall_plugin(args.plugin_id)
    elif args.command == "enable":
        enable_plugin(args.plugin_id)
    elif args.command == "disable":
        disable_plugin(args.plugin_id)
    elif args.command == "set-config":
        set_plugin_config(args.plugin_id, args.key, args.value)


if __name__ == "__main__":
    main()
