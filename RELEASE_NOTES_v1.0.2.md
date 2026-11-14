# Hyprconf v1.0.2 — Release Notes

> **Codename**: *Obsidian Horizon*  
> **Tag**: `v1.0.2` (Quickshell Qt6 Desktop Environment)  
> **Compositor Target**: Hyprland (Wayland)  

---

## Highlights & Executive Summary

Hyprconf **v1.0.2** brings the largest architectural and visual evolution since the transition to pure Quickshell. This milestone introduces a native **GLSL shader-driven wallpaper transition pipeline**, an **interactive Welcome App personalization studio**, a **Cursor Quick Paste** clipboard popup, a unified **tri-state Desktop System Modes supervisor**, **multi-category unit conversion in Spotlight Omnibar**, and deep physics and GPU optimizations across all obsidian glass layer surfaces.

---

## 1. Native GLSL Shader Wallpaper Transitions (`wallfx`)

A bespoke GPU-accelerated wallpaper transition engine built directly on Quickshell layer surfaces (`WlrLayer.Bottom`, `exclusiveZone = -1`) running beneath all bars, docks, and windows:

- **Two Distinct Shader Modes**:
  - **`perfil` (Silhouette Outline & Bloom)**: Designed for subject/character wallpapers. Uses an ONNX deep-learning model (`silueta.onnx`) with signed distance fields to trace the subject's silhouette from top to bottom with ink-line bloom colonies before seamlessly expanding outward.
  - **`contagio` (Cellular Contagion)**: Designed for landscape, abstract, and architecture wallpapers. Uses 2D value-noise maps to produce organic burning ember colonies that spread across the canvas in the active theme's accent color.
- **Universal Shell Compatibility**:
  - Works seamlessly whether running **Dynamic Island** (`qs -c island`) or **Full Top Bar** (`qs -c bar`).
  - Native Quickshell IPC routing automatically dispatches `play` commands to whichever top interface daemon is currently active.
- **Zero Shockwave / Distortion Hand-off**:
  - Strict subpixel anti-aliasing via `smoothstep` to eliminate pixel-staircase artifacts.
  - Locked camera UVs throughout the entire timeline ($t = 0.0 \to 1.0$), ensuring a zero-flicker, 1:1 pixel hand-off to `awww` (`--transition-type none`).
- **Wallhaven API Bridge**:
  - High-performance Wallhaven wallpaper browser integrated directly into Dynamic Island's wallpaper studio with relevance sorting, Ctrl+L search focus shortcut, and background thumbnail pre-warming.

---

## 2. Interactive Welcome App & Personalization Studio

The Welcome onboarding modal has been revamped into a dynamic desktop configuration studio:

- **Top Interface Switcher**:
  - 1-click live switching between **Prism Blade**, **Orbital**, **Minimal Rail**, and **Full Top Bar**.
  - Detached daemon swapping terminates opposing Wayland surfaces cleanly, commits state atomically to `bar.json` and `island.json` with synchronous disk flushing (`os.fsync`), and restarts the new shell in under 200ms.
- **App Launcher Switcher**:
  - Instant toggle between **Style 2: Panoramic Grid** and **Style 1: Slanted Split Quad**.
- **Live Weather Location Setup**:
  - Inline City and Country input fields with instant save and live Open-Meteo forecast fetch.
- **Keyboard Layout Selector**:
  - Instant layout switching via `localectl list-x11-keymap-layouts` and XKB discovery with state persistence to `welcome-app.json` and Hyprland config.
- **Interactive Shortcuts Matrix**:
  - Searchable keybindings list with 1-click execution to test shortcuts directly.
- **Unattended `setup.sh`**:
  - Interactive prompts for bar style, launcher style, and weather location have been removed from `setup.sh` and relocated into the Welcome App, allowing zero-friction, unattended script installations.

---

## 3. Cursor Quick Paste (`Super + V`)

A lightweight, cursor-anchored clipboard popup that renders directly at pointer coordinates:

- Displays the **12 most recent clipboard history entries** formatted in obsidian glass cards with syntax tags (URLs, code snippets, plain text).
- **1-Click Auto-Paste**: Automatically restores compositor focus to the previous active window and dispatches `Ctrl + V` (or `Ctrl + Shift + V` for terminals) via native Hyprland Lua dispatchers (`hl.dsp.focus` & `hl.dsp.send_shortcut`).
- Dedicated shortcut: `Super + Shift + V` toggles floating Kitty terminal with clipboard history.

---

## 4. Tri-State Desktop System Modes (`system-mode.sh`)

Quickly adapt the desktop's performance, display pipeline, and distraction level via OSD, Top Bar, or Dynamic Island toggles (`Super + Alt + M`):

| Mode | Opacity | Blur & Wobble | Direct Scanout Tearing | Caffeine & DND | Power Profile |
|---|---|---|---|---|---|
| **Normal (Mode 0)** | Theme Alpha | Enabled | Disabled (`allow_tearing = false`) | Inactive | User Config |
| **Game (Mode 1)** | 100% Solid | Disabled | Enabled (`allow_tearing = true`) | Caffeine ON | Performance |
| **Class (Mode 2)** | 100% Solid | Disabled | Disabled (presentation-safe) | DND & Caffeine ON | Balanced |

---

## 5. Spotlight Omnibar Enhancements (`Super + Space`)

The Raycast-style command center embedded in Dynamic Island and application launchers now features:

- **Multi-Category Unit Converter**: Seamless natural language unit conversions across **11 categories**:
  - Length, Mass/Weight, Temperature, Area, Volume, Speed, Digital Storage, Time, Pressure, Energy, and Power (e.g. `10 cm to in`, `25 c to f`, `50 kg in lbs`, `1024 mb in gb`).
- **Live Currency Converter**: Daily foreign exchange rates across 26 world currencies (`100 USD to EUR`).
- **Inline Math Calculator**: Instant evaluation of arithmetic expressions (`(48 * 12) / 4`).
- **Emoji Search & Copy**: Search emojis by semantic keywords with direct clipboard copy and auto-paste.
- **AI Agent Terminal Integration**: Prefix `>` or `ai ` launches prompt directly in Kitty.

---

## 6. Visual Polish, Physics & Component Refinements

- **Obsidian Glass Tokens**: Unified dark obsidian glass tokens (`#0a0a0c`, `#111116`, `#181820`) paired with subtle glass rims (`Theme.alpha(Theme.accent, 0.20)`), removing all flat opaque panels.
- **Physical Spring Tuning**: Dynamic Island notch expansions, dock slide-outs, and window animations use calibrated `SpringAnimation` physics with damping curves.
- **Top Bar Centered Power Menu**: Redesigned power menu modal that animates out from the center with fluid bubble expansion physics.
- **Live Workspace App Previews**: Top bar workspace pills feature live running application icons and 1-click focus dispatchers.
- **Zero Generic Emojis**: Replaced generic emoji glyphs across the desktop with inline vector SVGs.
- **Multi-Line Monospace Notifications**: Notification banners now render full multi-line monospace blocks without clipping or truncation.
- **GPU Bottleneck Fixes**: Optimized CPU and GPU load on Intel UHD Graphics by eliminating redundant canvas redraws and idle polling.

---

## 7. Upgrade Guide for Existing Users

If upgrading from an earlier version (e.g., `v1.0.1` or `v1.0.0`):

1. **Pull the latest changes**:
   ```bash
   git pull origin main
   ```
2. **Run the updater or setup script**:
   ```bash
   bash ~/.hyprconf/setup.sh
   ```
3. **Update Keybindings**:
   Hyprconf preserves `~/.local/share/hyprconf/keybinds.lua` across git pulls. Copy new shortcuts from `~/.hyprconf/hypr/configs/keybinds-updated.lua` into your local `keybinds.lua`:
   - `Super + V`: Cursor Quick Paste Tooltip
   - `Super + Shift + V`: Floating Kitty Terminal
   - `Super + Alt + M`: Cycle Desktop Modes (Normal / Game / Class)
   - `Super + Ctrl + B`: Toggle Top Bar / Dynamic Island

---

**Full Commit History**: [v1.0.1...v1.0.2](https://github.com/shell-ninja/hyprconf/compare/v1.0.1...v1.0.2)
