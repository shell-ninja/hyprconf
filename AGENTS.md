# Hyprconf — AI Agent & Developer Guidelines

> [!IMPORTANT]
> This document is the authoritative architecture, design, and development manual for AI agents and human contributors working on **Hyprconf**. Read this thoroughly before planning, editing, or introducing changes to this repository.

---

## 1. Project Philosophy & Core Principles

Hyprconf is a minimalist, obsidian-themed **Hyprland** desktop environment built natively with **Quickshell** (Qt6 / QML).

### Key Architectural Tenets
1. **100% Pure Quickshell & Wayland**: Noctalia has been completely removed. All desktop shell components (Dynamic Island, Dock, Launcher, Lockscreen, Settings, Desktop Widgets) are native Qt6 QML layer surfaces managed via Quickshell IPC.
2. **Obsidian Glass Aesthetics**: Deep, refined obsidian surfaces (`#0a0a0c`, `#111116`, `#181820`) paired with subtle glass rims (`Theme.alpha(Theme.accent, 0.20)`), gentle backdrop blur, and vibrant wallpaper-derived accents.
3. **Zero Generic Emojis / No AI Vibe**: Never use generic emoji glyphs (e.g. 🌧️, ⚡, ⚙️) or garish placeholder graphics. All iconography must use inline vector SVGs or clean QML Canvas shapes.
4. **Fluid Spring Physics**: Windows, morphing notch expansions, and hover animations use physical spring simulations (`SpringAnimation`, `damping`, `epsilon`) rather than stiff linear transitions.
5. **Multi-User State Isolation**: Core dotfiles in `~/.hyprconf` remain pristine and immutable across git pulls; all mutable user choices (pinned dock apps, lockscreen layout, island style, wallpaper cache) are segregated into `~/.local/share/hyprconf/`.

---

## 2. Repository vs Live System Layout

Hyprconf uses a dual-layer hierarchy to separate version-controlled configuration from active user runtime state:

```
Repository Root
├── config/                     # Canonical configuration tree installed to ~/.hyprconf/
│   ├── hypr/                   # Hyprland configurations, Lua modules, scripts
│   │   ├── configs/            # Modular Lua scripts (keybinds, windowrules, exec, env)
│   │   ├── scripts/            # Python (py/) and Shell (sh/) IPC scripts
│   │   └── Wallpaper/          # Shipped desktop wallpaper assets
│   ├── quickshell/             # Quickshell desktop environment modules
│   │   ├── Theme.qml           # Central theme singleton (monitors colors.json)
│   │   ├── colors.json         # Active wallpaper palette tokens
│   │   ├── dock/               # Application Dock daemon
│   │   ├── island/             # 3-Page Dynamic Island notch
│   │   ├── launcher/           # Custom application launchers
│   │   ├── lockscreen/         # Morphing PAM lockscreen
│   │   ├── settings/           # Unified Quickshell Settings Studio
│   │   └── widgets/            # Desktop widgets
│   ├── kitty/                  # Terminal configuration
│   └── nvim/                   # Neovim configuration
├── extras/                     # System integration (desktop files, fonts, sessions)
├── local/                      # Default user templates (installed to ~/.local/share/)
│   └── share/
│       ├── fastfetch/          # Fastfetch presets and ascii art
│       └── hyprconf/           # Default template JSON configs
├── setup.sh                    # Interactive installer & system deployment script
├── update.sh                   # Self-healing repository updater
├── .version                    # Semantic version tag (e.g., v1.0.1)
└── README.md                   # User documentation
```

### Active Deployment Mapping
- **Dotfiles Root**: `~/.hyprconf/` (mirrors `config/` from repository).
- **XDG Config Links**: `~/.config/<module>` are symbolic links pointing directly into `~/.hyprconf/<module>` (e.g., `~/.config/hypr -> ~/.hyprconf/hypr`).
- **User State Directory**: `~/.local/share/hyprconf/` holds user-modifiable state:
  - `dock.json`: Pinned applications, visibility mode, dock position, opacity.
  - `island.json`: Dynamic Island notch position, visualizer toggles.
  - `launcher.json`: Active launcher style (Style 1 Quad vs Style 2 Panoramic).
  - `lockscreen.json`: Lockscreen widget canvas layout, weather coordinates.
  - `monitor.lua`: Machine-specific monitor resolutions and scaling.
  - `keybinds.lua`: User custom keybindings.
  - `.cache/`: Active wallpaper symlink (`current_wallpaper.png`), weather cache (`weather.json`), and generated color palettes.
- **Symlink Synchronization**: Subprojects in `~/.hyprconf/quickshell/<subproject>/config.json` point to `~/.local/share/hyprconf/<subproject>.json` so git updates never wipe user customizations.

---

## 3. Dynamic Theming Engine (`Theme.qml` & `hypr-colors.py`)

### Palette Generation Pipeline
1. When wallpaper changes, [`config/hypr/scripts/py/hypr-colors.py`](config/hypr/scripts/py/hypr-colors.py) is invoked with the wallpaper path.
2. It samples colors using Pillow (`PIL.Image`), quantizes into 32 adaptive clusters, and bins into 24 distinct hue intervals (15° increments).
3. Evaluates 7 color harmony variants: `vibrant`, `muted`, `expressive`, `warm`, `cool`, `pastel`, `original`.
4. Atomically generates:
   - `quickshell/colors.json` & `quickshell/Theme.qml`
   - `hypr/theme.lua` (Hyprland active border colors)
   - `kitty/colors-kitty.conf`
   - `btop/themes/theme.theme` & `noctalia.theme`
   - `nvim/lua/matugen.lua` (dispatches `SIGUSR1` to running Neovim instances)
   - GTK3 & GTK4 stylesheets (`gtk-3.0/theme.css`, `gtk-4.0/theme.css`) and signals `xsettingsd` via `SIGHUP`.

### QML Theme Tokens
Every QML component should import the theme singleton and reference standardized tokens:
```qml
import Quickshell
import ".." // or through qmldir Theme 1.0 Theme.qml

Rectangle {
    color: Theme.alpha(Theme.surface, 0.85)
    border.color: Theme.alpha(Theme.accent, 0.35)
    border.width: 1
    radius: 12
}
```
Standard properties on `Theme`:
`primary`, `secondary`, `accent`, `surface`, `background`, `foreground`, `on_primary`, `on_surface`, `muted`, `error`.
Helper: `Theme.alpha(color, opacity)` returns a hex color with modified alpha.

---

## 4. Quickshell Subproject Architecture

Each subproject under `config/quickshell/` runs as an independent Quickshell application or layer shell.

### 1. Application Dock (`quickshell/dock/`)
- **Main Daemon**: [`config/quickshell/dock/shell.qml`](config/quickshell/dock/shell.qml) (`quickshell -p ~/.hyprconf/quickshell/dock`).
- **Surface**: Wayland `PanelWindow` anchored to `Bottom`, `Top`, `Left`, or `Right`.
- **Modes**:
  - `always_on`: Sets `exclusiveZone = dockSize + 12`.
  - `auto_hide`: Off-screen slide; reveals when cursor hits 3px edge trigger input mask.
  - `smart_hide`: Monitors `Hyprland.focusedWorkspace.toplevels.values.length`. Stays visible on empty workspaces; slides off-screen when windows exist.
- **Window Correlation**: Uses `Hyprland.toplevels` and matches window classes against `~/.local/share/hyprconf/.cache/apps.json`.
- **Context Menu**: [`config/quickshell/dock/DockContextMenu.qml`](config/quickshell/dock/DockContextMenu.qml) allows Pinning/Unpinning to `dock.json`.
- **Position Switching**: Changing dock orientation requires layer surface recreation (`LayerSurface.recreate()` or key rebinding) so geometry recalculations apply without restart.

### 2. Dynamic Island (`quickshell/island/`)
- **Main Notch**: [`config/quickshell/island/shell.qml`](config/quickshell/island/shell.qml).
- **3-Page Carousel** ([`config/quickshell/island/DashboardView.qml`](config/quickshell/island/DashboardView.qml)):
  - **Page 1: WeatherPage (`WeatherPage.qml`)**: 7-day forecast & hourly metrics from Open-Meteo via [`config/hypr/scripts/py/weather.py`](config/hypr/scripts/py/weather.py).
  - **Page 2: Control Center (`HomePage.qml`)**: Default view on notch expansion. Features dynamic `$USER@$HOSTNAME`, audio volume/sink switchers, brightness, and quick toggles. Has a quick button on the left to switch to Weather.
  - **Page 3: System Status (`StatusPage.qml`)**: Real-time CPU, RAM, GPU, and storage load. Hosts an embedded sub-page ([`config/quickshell/island/NetworkDetailPage.qml`](config/quickshell/island/NetworkDetailPage.qml)) for live per-process socket/traffic monitoring.
- **Fullscreen Guard**: Listens to Hyprland fullscreen state and auto-unmaps to prevent obstructing games or media.

### 3. Application Launcher (`quickshell/launcher/`)
- **Style 1**: Slanted Split Quad with category chips and category-filtered grids.
- **Style 2**: Panoramic Grid with instant keyword search and keyboard navigation.
- **Search Focus**: `focusInput()` must explicitly invoke `searchInput.forceActiveFocus()` and `searchInput.selectAll()`. Ensure no container steals keyboard focus.

### 4. Settings Studio (`quickshell/settings/`)
- **Entrypoint**: [`config/quickshell/settings/shell.qml`](config/quickshell/settings/shell.qml) (`qs-settings.sh`).
- **Sections**:
  - `DockSection.qml`: Dock positioning, visibility mode, physics sliders, pinned apps manager.
  - `IslandSection.qml`: Dynamic Island options and notch layout.
  - `LockscreenSection.qml`: Interactive drag & drop canvas positioning.
  - `ThemeSection.qml`: Wallpaper selector and Noctalia palette switcher.
- **Components**: Reusable UI widgets exported in `quickshell/settings/qmldir` (`ModernSlider.qml`, `CapsuleSwitch.qml`, `IconCard.qml`).

---

### 5. Package Updater (`quickshell/updater/`)
- **Main App**: [`config/quickshell/updater/shell.qml`](config/quickshell/updater/shell.qml) (`qs-updater.sh`).
- **Surface**: Centered floating XDG toplevel window (`FloatingWindow`) styled with obsidian glass.
- **Source Inspection**: Concurrently queries official Pacman (`checkupdates`), AUR (`paru -Qua` / `yay -Qua`), and Flatpak through [`config/hypr/scripts/py/pkg-check.py`](config/hypr/scripts/py/pkg-check.py).
- **Update Execution & Polkit Integration**: Runs [`config/hypr/scripts/sh/pkg-apply.sh`](config/hypr/scripts/sh/pkg-apply.sh) using `pkexec`, triggering Quickshell Dynamic Island's native Polkit agent (`quickshell/island/PolkitView.qml`) when password authentication is required. Live terminal output is streamed directly into the bottom log preview container.

---

## 5. Scripts and Daemons

All helper scripts reside under `config/hypr/scripts/`:

| Script | Purpose |
|---|---|
| `sh/qs-dock.sh` | Dock supervisor (`--start`, `--stop`, `--restart`, `--toggle`) |
| `sh/qs-island.sh` | Island supervisor and dynamic user resolver |
| `sh/qs-reload.sh` | Clean reload supervisor: restarts Island, Dock, and Widgets in sequence |
| `sh/qs-settings.sh` | Launches Quickshell Settings Studio modal |
| `sh/qs-updater.sh` | Launches native Quickshell Package Updater modal |
| `sh/pkg-apply.sh` | Streaming package upgrade runner using Polkit pkexec elevation |
| `py/pkg-check.py` | Fast parallel package updates scanner (Pacman, AUR, Flatpak) |
| `py/hypr-colors.py` | Extracts wallpaper color scheme and broadcasts tokens to all tools |
| `py/weather.py` | Open-Meteo weather background worker and JSON cache updater |
| `sh/caffeine-manager.sh` | Toggles Hypridle inhibition for uninterrupted display |
| `sh/hyprsunset-manager.sh`| 3-stage blue light night filter manager (Off / Always On / Scheduled) |

---

## 6. Guidelines for AI Agents Making Changes

When tasked with implementing features, fixing bugs, or refactoring in this repository, follow these mandatory rules:

### A. Editing QML Components
1. **Maintain Component Exports in `qmldir`**: If creating a new QML component intended for use across files, declare it in that directory's `qmldir` (e.g. `WeatherPage 1.0 WeatherPage.qml`).
2. **Synchronize Generator Templates**: Remember that `hypr-colors.py` recreates `qmldir` dynamically across subprojects (`SUBPROJECT_QMLDIRS`). Always check and update `hypr-colors.py` templates whenever adding a new type to `qmldir`.
3. **Prevent Binding Loops**: Always supply `implicitWidth` and `implicitHeight` on custom components. Never bind a parent's size directly to a child that anchors to the parent.
4. **Clean Input Masks**: On floating panels and layer shells with auto-hide, ensure non-visible parts do not steal pointer clicks. Use dynamic input masks (`MaskRegion`) or collapse dimensions to 3px.

### B. Modifying `setup.sh` and Installation Scripts
1. **Never Clobber Existing User Files**: Use non-clobbering copies or presence checks:
   - Wallpapers: Iterate over backup and only copy wallpapers that do not already exist in the target directory.
   - User configs: Never overwrite existing files in `~/.local/share/hyprconf/`.
2. **Prevent Broken Symlink Traps**:
   - Remember that `[[ ! -e "$path" ]]` returns `true` if `$path` is a broken symlink!
   - Always verify: `if [[ ! -e "$path" && ! -L "$path" ]]` or cleanly `rm -f "$path"` if broken before writing.
3. **Avoid Conflicting Directory Errors**:
   - When copying directories, ensure target exists and use `/.`:
     `mkdir -p "$dest" && cp -a "$src/." "$dest/"`
   - Never run `cp -a dir dest/` if `dest/dir` might already exist, as it will nest `dest/dir/dir`.

### C. Workspace Synchronization
1. The development repository is the root of the Hyprconf codebase.
2. The live running desktop reads from `~/.hyprconf`.
3. When testing or finalizing changes:
   - Verify code within the repository (`config/`).
   - Copy modified files into `~/.hyprconf/` so live desktop updates reflect the work immediately.
   - Stage changes in git on the active branch (e.g., `qs-v1.0.1`).
