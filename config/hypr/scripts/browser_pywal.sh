#!/bin/bash
# browser_pywal.sh — Generate and apply pywal colors to Chromium-based browsers.
# Supports: Google Chrome, Chromium, Brave, Vivaldi
#
# Architecture (two extensions):
#   1. Pywal Theme    — pure theme extension (manifest.json with colors, no JS)
#   2. Pywal Watcher  — monitors for color changes via localhost HTTP server,
#                       then disables/re-enables the theme extension to force
#                       a live re-apply. Colors update within ~3 seconds.
#
# A lightweight localhost HTTP server (port 38471) serves a trigger file.
# The watcher's service worker polls this endpoint. When the timestamp changes,
# it toggles the theme extension off→on, which forces the browser to re-read
# the manifest.json from disk and apply the updated colors — all while the
# browser stays open.

colors_file="$HOME/.cache/wal/colors.json"
cache_dir="$HOME/.hyprconf/hypr/.cache"
current_wallpaper="$cache_dir/current_wallpaper.png"
theme_dir="$HOME/.cache/wal/pywal-browser-theme"
watcher_dir="$HOME/.cache/wal/pywal-browser-watcher"
server_port=38471
server_pidfile="$HOME/.cache/wal/.pywal-server.pid"

# ── Guard ─────────────────────────────────────────────────────────────────────
[[ ! -f "$colors_file" ]] && echo "pywal colors not found!" && exit 1

# ── 1. Parse colors from pywal ────────────────────────────────────────────────
read -r \
    background foreground cursor \
    color0  color1  color2  color3  color4  color5  color6  color7 \
    color8  color9  color10 color11 color12 color13 color14 color15 \
    < <(jq -r '[
        .special.background, .special.foreground, .special.cursor,
        .colors.color0,  .colors.color1,  .colors.color2,  .colors.color3,
        .colors.color4,  .colors.color5,  .colors.color6,  .colors.color7,
        .colors.color8,  .colors.color9,  .colors.color10, .colors.color11,
        .colors.color12, .colors.color13, .colors.color14, .colors.color15
    ] | @tsv' "$colors_file")

# ── 2. Helper: hex → RGB ─────────────────────────────────────────────────────
hex_to_rgb() {
    local hex="${1#\#}"
    printf "%d, %d, %d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# ── 3. Derive theme palette ──────────────────────────────────────────────────
rgb_bg=$(hex_to_rgb "$background")
rgb_fg=$(hex_to_rgb "$foreground")
rgb_accent=$(hex_to_rgb "$color4")
rgb_accent2=$(hex_to_rgb "$color6")
rgb_tab_bg=$(hex_to_rgb "$color8")
rgb_frame_inactive=$(hex_to_rgb "$color0")

# Slightly lighter toolbar (3:1 blend of color0 toward color8)
_c0="${color0#\#}"; _c8="${color8#\#}"
_tr=$(( (0x${_c0:0:2} * 3 + 0x${_c8:0:2}) / 4 ))
_tg=$(( (0x${_c0:2:2} * 3 + 0x${_c8:2:2}) / 4 ))
_tb=$(( (0x${_c0:4:2} * 3 + 0x${_c8:4:2}) / 4 ))
rgb_toolbar_blend="$_tr, $_tg, $_tb"

# ── 4. Generate THEME extension ──────────────────────────────────────────────
# Pure theme — no JS, no service worker. Just colors.
mkdir -p "$theme_dir/images"

if [[ -f "$current_wallpaper" ]]; then
    cp -f "$current_wallpaper" "$theme_dir/images/theme_ntp_background.png"
    ntp_images='"theme_ntp_background": "images/theme_ntp_background.png"'
else
    ntp_images=""
fi

images_block=""
if [[ -n "$ntp_images" ]]; then
    images_block="
    \"images\": {
      $ntp_images
    },"
fi

cat > "$theme_dir/manifest.json" <<MANIFEST
{
  "manifest_version": 3,
  "name": "Pywal Theme",
  "version": "1.0",
  "description": "Pywal wallpaper colors applied to browser chrome",
  "theme": {$images_block
    "colors": {
      "frame":                  [$rgb_bg],
      "frame_inactive":         [$rgb_frame_inactive],
      "frame_incognito":        [$rgb_bg],
      "frame_incognito_inactive": [$rgb_frame_inactive],
      "toolbar":                [$rgb_toolbar_blend],
      "toolbar_text":           [$rgb_fg],
      "toolbar_button_icon":    [$rgb_fg],
      "tab_text":               [$rgb_fg],
      "tab_background_text":    [$rgb_tab_bg],
      "bookmark_text":          [$rgb_fg],
      "ntp_background":         [$rgb_bg],
      "ntp_text":               [$rgb_fg],
      "ntp_link":               [$rgb_accent],
      "ntp_header":             [$rgb_accent2],
      "omnibox_background":     [$rgb_bg],
      "omnibox_text":           [$rgb_fg],
      "button_background":      [$rgb_bg]
    },
    "tints": {
      "buttons":                [0.0, 0.0, 0.7],
      "background_tab":         [-1.0, -1.0, 0.6]
    },
    "properties": {
      "ntp_background_alignment": "bottom",
      "ntp_background_repeat": "no-repeat"
    }
  }
}
MANIFEST

# ── 5. Write the trigger file (in the WATCHER dir for HTTP serving) ──────────
mkdir -p "$watcher_dir"
echo "$(date +%s%N)" > "$watcher_dir/.trigger"

# ── 6. Generate WATCHER extension ────────────────────────────────────────────
# Separate extension with `management` permission.
# Polls the HTTP trigger, then disables/re-enables the theme extension
# to force the browser to re-read the theme manifest from disk.

cat > "$watcher_dir/manifest.json" <<MANIFEST
{
  "manifest_version": 3,
  "name": "Pywal Watcher",
  "version": "1.0",
  "description": "Watches for pywal color changes and live-reloads the theme",
  "permissions": ["management", "alarms"],
  "host_permissions": ["http://localhost:${server_port}/*"],
  "background": {
    "service_worker": "watcher.js"
  }
}
MANIFEST

cat > "$watcher_dir/watcher.js" <<WORKER
// Pywal Watcher — polls for color changes, then toggles the theme extension
// off→on to force the browser to re-read its manifest.json with new colors.

const TRIGGER_URL = "http://localhost:${server_port}/.trigger";
const THEME_NAME  = "Pywal Theme";
let lastTrigger   = "";

// Find the theme extension by name
async function findTheme() {
  const all = await chrome.management.getAll();
  return all.find(e => e.name === THEME_NAME);
}

// Disable then re-enable the theme to force a live re-apply
async function reloadTheme() {
  const theme = await findTheme();
  if (!theme) {
    console.warn("[Pywal] Theme extension not found");
    return;
  }
  try {
    await chrome.management.setEnabled(theme.id, false);
    // Brief pause so Chrome fully removes the old theme
    await new Promise(r => setTimeout(r, 300));
    await chrome.management.setEnabled(theme.id, true);
    console.log("[Pywal] Theme reloaded with new colors");
  } catch (err) {
    console.error("[Pywal] Failed to reload theme:", err);
  }
}

// Poll the trigger file via HTTP (not extension cache)
async function checkForUpdate() {
  try {
    const resp = await fetch(TRIGGER_URL, { cache: "no-store" });
    if (!resp.ok) return;
    const trigger = (await resp.text()).trim();

    if (lastTrigger === "") {
      // First check — just store the value, don't reload
      lastTrigger = trigger;
      return;
    }

    if (trigger !== lastTrigger) {
      console.log("[Pywal] Color change detected — reloading theme…");
      lastTrigger = trigger;
      await reloadTheme();
    }
  } catch (err) {
    // Server not running yet — retry later
  }
}

// Reliable polling via chrome.alarms (~3 seconds)
chrome.alarms.create("pywal-check", { periodInMinutes: 0.05 });
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === "pywal-check") checkForUpdate();
});

chrome.runtime.onStartup.addListener(() => checkForUpdate());
chrome.runtime.onInstalled.addListener(() => checkForUpdate());
checkForUpdate();
WORKER

# ── 7. Start the local HTTP trigger server ────────────────────────────────────
start_trigger_server() {
    if [[ -f "$server_pidfile" ]]; then
        local old_pid
        old_pid=$(cat "$server_pidfile" 2>/dev/null)
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            return 0  # already running
        fi
        rm -f "$server_pidfile"
    fi

    if ss -tlnp 2>/dev/null | grep -q ":${server_port} "; then
        return 0  # port already in use
    fi

    python3 -c "
import http.server, socketserver, os, sys

os.chdir('$watcher_dir')

class CORSHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()
    def log_message(self, *a): pass

try:
    with socketserver.TCPServer(('127.0.0.1', $server_port), CORSHandler) as s:
        s.serve_forever()
except OSError:
    sys.exit(0)
" &>/dev/null &
    local pid=$!
    disown $pid
    echo "$pid" > "$server_pidfile"
}

start_trigger_server

echo "✓ Pywal Theme:   $theme_dir"
echo "✓ Pywal Watcher: $watcher_dir"

# ── 8. Detect installed browsers ──────────────────────────────────────────────
declare -A browser_configs=(
    ["google-chrome-stable"]="$HOME/.config/google-chrome"
    ["chromium"]="$HOME/.config/chromium"
    ["brave"]="$HOME/.config/BraveSoftware/Brave-Browser"
    ["vivaldi"]="$HOME/.config/vivaldi"
)

applied=0
for browser_cmd in "${!browser_configs[@]}"; do
    if command -v "$browser_cmd" &>/dev/null; then
        config_dir="${browser_configs[$browser_cmd]}"
        if [[ -d "$config_dir" ]]; then
            echo "  → Found: $browser_cmd"
            ((applied++))
        fi
    fi
done

[[ $applied -eq 0 ]] && echo "⚠ No Chromium-based browsers detected."
