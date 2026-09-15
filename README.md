<a id="top"></a>

<h1 align="center">Minimal Hyprland Configuration</h1>
<h3 align="center">Crafted with precision by</h3>
<h2 align="center">Shell Ninja</h2>

<p align="center">
  <a href="https://hyprland.org/"><img src="https://img.shields.io/badge/Hyprland-0.42+-blue?style=flat-square&logo=hyprland&logoColor=white" alt="Hyprland"></a>
  <a href="https://www.lua.org/"><img src="https://img.shields.io/badge/Config-Lua-000080?style=flat-square&logo=lua&logoColor=white" alt="Lua"></a>
  <a href="https://github.com/noctalia-dev/noctalia"><img src="https://img.shields.io/badge/Shell-Noctalia-purple?style=flat-square" alt="Noctalia Shell"></a>
  <a href="https://archlinux.org/"><img src="https://img.shields.io/badge/Arch_Linux-Ready-1793D1?style=flat-square&logo=archlinux&logoColor=white" alt="Arch Linux"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License"></a>
</p>

<p align="center">
  A clean, modular <b>Lua-based Hyprland</b> desktop environment powered by the <b>Noctalia Desktop Shell</b>, automatic <b>Material You</b> wallpaper color harmonization, dedicated <b>GTK Settings & Wallpaper GUIs</b>, and fluid keyboard-driven workflows.
</p>

> [!NOTE]
> This repository houses the dotfiles and desktop configurations. If you are looking for a completely automated setup that installs all dependencies, audio servers, fonts, and required packages on Arch Linux, head over to the [hyprconf-install](https://github.com/shell-ninja/hyprconf-install) repository and run the installer.

<br>

<div align="center">

<a href="#screenshots"><kbd> <br> Screenshots <br> </kbd></a>&ensp;&ensp;
<a href="#features"><kbd> <br> Features <br> </kbd></a>&ensp;&ensp;
<a href="#config-structure"><kbd> <br> Configuration <br> </kbd></a>&ensp;&ensp;
<a href="#keybinds"><kbd> <br> Keybindings <br> </kbd></a>&ensp;&ensp;
<a href="#update"><kbd> <br> Installation & Update <br> </kbd></a>&ensp;&ensp;
<a href="#contrib"><kbd> <br> Contributing <br> </kbd></a>

</div>

<br>

> [!TIP]
> This setup runs on a rolling-release model with regular refinements. You can update your dotfiles anytime directly from the Hyprconf Settings app: press <kbd>SUPER</kbd> + <kbd>S</kbd>, scroll to **Dotfiles Update** at the bottom, and click **Update Dotfiles**. You can also run the update command in your terminal.

<br>

<div align="right">
  <a href="#top"><kbd> <br> 🡅 Top <br> </kbd></a>
</div>

<a id="screenshots"></a>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=SCREENSHOTS" width="450"/>

> [!NOTE]
> Screenshots are currently being refreshed to reflect the latest Noctalia shell release and UI updates. Previews will be added here soon!

<!-- Screenshot gallery will be updated here -->
<!--
<details open>
<summary><b>Desktop & Theming</b></summary>
<p align="center">
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/theme/1.png?raw=true" alt="Desktop Theme 1" />
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/theme/2.png?raw=true" alt="Desktop Theme 2" /> <br>
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/theme/3.png?raw=true" alt="Desktop Theme 3" />
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/theme/4.png?raw=true" alt="Desktop Theme 4" /> <br>
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/theme/5.png?raw=true" alt="Desktop Theme 5" />
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/theme/6.png?raw=true" alt="Desktop Theme 6" />
</p>
</details>

<details close>
<summary><b>Launchers, Menus & Panels</b></summary>
<p align="center">
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/menu/1.png?raw=true" alt="Launcher 1" />
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/menu/2.png?raw=true" alt="Launcher 2" /> <br>
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/menu/4.png?raw=true" alt="Launcher 3" />
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/menu/3.png?raw=true" alt="Launcher 4" /> <br>
   <img align="center" width="99%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/clipboard.png?raw=true" alt="Clipboard Manager" />
</p>
</details>

<details close>
<summary><b>Power Menu & Session Controls</b></summary>
<p align="center">
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/power/1.png?raw=true" alt="Power Menu 1" />
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/power/2.png?raw=true" alt="Power Menu 2" />
</p>
</details>

<details close>
<summary><b>Wallpaper Management</b></summary>
<p align="center">
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/wallpaper/1.png?raw=true" alt="Wallpaper 1" />
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/wallpaper/2.png?raw=true" alt="Wallpaper 2" />
</p>
</details>

<details close>
<summary><b>Lock Screen & Display Manager (SDDM)</b></summary>
<p align="center">
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/lockscreen/lock-1.png?raw=true" alt="Lockscreen 1" />
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/lockscreen/lock-2.png?raw=true" alt="Lockscreen 2" /> <br>
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/sddm/sddm1.jpg?raw=true" alt="SDDM 1" />
   <img align="center" width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/sddm/sddm2.jpg?raw=true" alt="SDDM 2" />
</p>
</details>
-->

<br>

<div align="right">
  <a href="#top"><kbd> <br> 🡅 Top <br> </kbd></a>
</div>

<a id="features"></a>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=FEATURES" width="450"/>

- **Modular Lua Configuration**: Hyprland configured natively in Lua (`hyprland.lua`), cleanly splitting rules, keybindings, animations, decorations, environment variables, monitor profiles, and autostart services into individual files.
- **Noctalia Desktop Shell**: Modern Wayland desktop shell providing a lightweight status bar, unified control center, quick toggles, notifications, media controls, and session management.
  - **Dynamic Bar Switcher**: Switch on the fly between multiple bar presets (`full-top`, `minimal-bottom`, `bar-left`) with <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>W</kbd>.
  - **Unified Launchers**: Application launcher (<kbd>SUPER</kbd> + <kbd>D</kbd>), dmenu / command runner (<kbd>SUPER</kbd> + <kbd>Space</kbd>), clipboard manager (<kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>C</kbd>), and emoji picker (<kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>D</kbd>).
- **Material You Dynamic Theming**: Automatic color palette extraction from your current wallpaper via Matugen/Pywal (`noctalia-colors.py`), synchronizing accent and background tones across Hyprland window borders, Noctalia Shell, Kitty terminal, GTK, and Qt applications.
- **Custom GTK Control Center & Utilities**:
  - **Hyprland Settings GUI** (`SUPER + S`): Custom GTK/Adwaita dashboard to toggle animations, adjust blur, rounding, border thickness, shadows, layout gaps, and trigger dotfile updates with instant live reload.
  - **Visual Wallpaper Selector** (`SUPER + SHIFT + W`): Interactive thumbnail gallery with live preview, wallpaper switching, and automatic color regeneration.
  - **Keybindings Visualizer** (`SUPER + SHIFT + H`): Searchable cheatsheet popup with fuzzy search to look up and dispatch any shortcut quickly.
  - **System Package Updates GUI** (`CTRL + U`): Quick GTK-based updater interface (`pkgupdate-gui.py`) with background update notifications.
- **Pyprland Plugins & Workflow**:
  - **Dropdown Scratchpad Terminal**: Quick toggleable terminal slide-down via <kbd>SUPER</kbd> + <kbd>A</kbd>.
  - **Minimized Window Workspace**: Stash and toggle background tasks with <kbd>SUPER</kbd> + <kbd>N</kbd> / <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>N</kbd>.
  - **Screen Magnifier**: Smooth viewport zoom controller with <kbd>SUPER</kbd> + <kbd>Z</kbd> / <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>Z</kbd>.
- **Hardware Integration & OSD**: Smooth hardware keybindings with on-screen visual feedback for volume, mic mute, monitor brightness, and media playback.

<br>

<div align="right">
  <a href="#top"><kbd> <br> 🡅 Top <br> </kbd></a>
</div>

<a id="config-structure"></a>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=CONFIGURATION" width="450"/>

All configurations are stored inside `~/.hyprconf` and symlinked into their standard locations under `~/.config`:

```text
~/.hyprconf/
├── hypr/                       # Core Hyprland configuration & scripts
│   ├── hyprland.lua            # Main entry point & module loader
│   ├── noctalia.lua            # Noctalia dynamic color bridge for Hyprland
│   ├── configs/                # Modular Lua configuration files
│   │   ├── animation.lua       # Window animations & custom bezier curves
│   │   ├── decoration.lua      # Blur, rounding, shadows, & window opacity
│   │   ├── environment.lua     # Wayland, NVIDIA, Qt & toolkit environment variables
│   │   ├── exec.lua            # Autostart applications & background daemons
│   │   ├── keybinds.lua        # Main keyboard shortcuts & dispatchers
│   │   ├── monitor.lua         # Display resolution, refresh rate & layout
│   │   ├── settings.lua        # Input gestures, cursor behavior & general settings
│   │   ├── tags.lua            # Window tags & dynamic classification
│   │   └── wrules.lua          # Window rules & layer effects (Noctalia, PiP, dialogs)
│   ├── scripts/                # Helper utilities, GUI dialogs & dispatchers
│   │   ├── settings.py         # GTK4 Hyprland settings & update dashboard
│   │   ├── WallpaperSelect.py  # GTK visual wallpaper thumbnail browser
│   │   ├── Wallpaper.sh        # Wallpaper rotator & pywal trigger
│   │   ├── noctalia-bar.sh     # Noctalia bar preset switcher
│   │   ├── noctalia-colors.py  # Palette extractor & theme generator
│   │   ├── keybinds.sh         # Interactive keybinds viewer
│   │   ├── pkgupdate-gui.py    # Package update manager GUI
│   │   ├── brightness.sh       # Backlight OSD & control script
│   │   └── volumecontrol.sh    # Audio volume, mute & OSD helper
│   └── Wallpaper/              # Wallpaper collection & cache
├── noctalia/                   # Noctalia Shell TOML configuration
│   ├── 00-shell.toml           # Global shell settings & session definitions
│   ├── 10-theme.toml           # Dynamic color tokens & typography
│   ├── 20-bar.toml             # Active status bar layout & widgets
│   ├── 30-launcher.toml        # Application launcher configuration
│   ├── 40-services.toml        # Notification, audio, battery & network daemons
│   ├── 50-lockscreen.toml      # Lock screen styling & clock layout
│   └── bars/                   # Pre-configured bar presets (full-top, minimal-bottom, bar-left)
├── btop/                       # Resource monitor theme & layout
├── fastfetch/                  # Fastfetch system info presets & logos
├── fish/                       # Fish shell functions, aliases, & starship prompts
├── gtk-3.0/, gtk-4.0/          # GTK theme overrides & dynamic CSS
├── kitty/                      # Terminal emulator configuration & theme
├── pypr/                       # Pyprland plugins (scratchpads, zoom, minimized)
├── nvim/                       # Neovim configuration
├── satty/                      # Screenshot annotation tool styling
├── yazi/                       # Terminal file manager configuration & keymaps
└── nwg-look/, qt5ct/, qt6ct/   # GTK & Qt appearance customization
```

<br>

<div align="right">
  <a href="#top"><kbd> <br> 🡅 Top <br> </kbd></a>
</div>

<a id="keybinds"></a>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=KEYBOARD-SHORTCUTS" width="450"/>

> [!IMPORTANT]
> Press <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>H</kbd> at any time to open the fuzzy-searchable **Keybinds Helper**.

### 🚀 Applications & Launchers

| Shortcut | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>Return</kbd> | Open Main Terminal (`Kitty`) |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>Return</kbd> | Open Floating Terminal (`Kitty`) |
| <kbd>SUPER</kbd> + <kbd>D</kbd> | Open **Noctalia App Launcher** |
| <kbd>SUPER</kbd> + <kbd>Space</kbd> | Open **Noctalia Command Runner** (`>`) |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>C</kbd> | Open **Clipboard Manager** |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>D</kbd> | Open **Emoji Picker** |
| <kbd>SUPER</kbd> + <kbd>E</kbd> | Open Graphical File Manager (`Dolphin` / `Thunar`) |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>E</kbd> | Open Terminal File Manager (`Yazi`) |
| <kbd>SUPER</kbd> + <kbd>B</kbd> | Open Default Web Browser |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>B</kbd> | Open Browser in Incognito Mode |
| <kbd>ALT</kbd> + <kbd>B</kbd> | Reset / Select Default Web Browser |
| <kbd>SUPER</kbd> + <kbd>C</kbd> | Open Code Editor (`VS Code` / `VSCodium`) |

---

### 🎛️ Noctalia Shell, Controls & Desktop Settings

| Shortcut | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>S</kbd> | Open **Hyprland Settings GUI** |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>S</kbd> | Toggle **Noctalia Control Center** |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>,</kbd> | Toggle Noctalia Settings Window |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>W</kbd> | Switch **Noctalia Bar Layout** (`full-top`, `minimal-bottom`, `bar-left`) |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>B</kbd> | Toggle Desktop Shell (**Noctalia** ⟷ **Waybar**) |
| <kbd>SUPER</kbd> + <kbd>X</kbd> | Open Session / Power Menu |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>L</kbd> | Lock Screen |
| <kbd>Print</kbd> | Open Screenshot Menu |
| <kbd>SUPER</kbd> + <kbd>F1</kbd> | Toggle Window Animations On/Off |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>R</kbd> | Reload Hyprland Configuration |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>R</kbd> | Restart Desktop Startup Services |
| <kbd>CTRL</kbd> + <kbd>U</kbd> | Open System Package Updates GUI (`pkgupdate-gui.py`) |

---

### 🖼️ Wallpaper & Colorscheme

| Shortcut | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>W</kbd> | Change Wallpaper (Random pick from collection) |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>W</kbd> | Open **Visual Wallpaper Selector GUI** |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>W</kbd> | Open Live Video Wallpaper Picker (`mpvpaper`) |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>P</kbd> | Regenerate Color Scheme from Current Wallpaper |

---

### 🪟 Window & Layout Management

| Shortcut | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>Q</kbd> | Close Focused Window |
| <kbd>SUPER</kbd> + <kbd>V</kbd> | Toggle Floating Mode (Focused Window) |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>V</kbd> | Toggle All Windows to Float on Active Workspace |
| <kbd>SUPER</kbd> + <kbd>F</kbd> | Toggle Fullscreen Mode |
| <kbd>SUPER</kbd> + <kbd>P</kbd> | Toggle Pseudo-Tiling |
| <kbd>SUPER</kbd> + <kbd>G</kbd> | Toggle Window Grouping |
| <kbd>SUPER</kbd> + <kbd>M</kbd> | Adjust Split Ratio (`0.3`) |
| <kbd>SUPER</kbd> + <kbd>Tab</kbd> | Open Window Switcher |
| <kbd>ALT</kbd> + <kbd>Tab</kbd> | Cycle Focus to Next Window |
| <kbd>SUPER</kbd> + <kbd>H</kbd> / <kbd>J</kbd> / <kbd>K</kbd> / <kbd>L</kbd> | Move Focus (Left / Down / Up / Right) |
| <kbd>SUPER</kbd> + <kbd>Arrow Keys</kbd> | Move Focus |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>H</kbd> / <kbd>J</kbd> / <kbd>K</kbd> / <kbd>L</kbd> | Move Window Position (Vim keys) |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>H</kbd> / <kbd>J</kbd> / <kbd>K</kbd> / <kbd>L</kbd> | Resize Window (Vim keys) |
| <kbd>SUPER</kbd> + <kbd>Arrow Keys</kbd> | Resize Window |
| <kbd>SUPER</kbd> + <kbd>Left Mouse Drag</kbd> | Move Window Interactively |
| <kbd>SUPER</kbd> + <kbd>Right Mouse Drag</kbd> | Resize Window Interactively |
| <kbd>SUPER</kbd> + <kbd>1..0</kbd> | Switch to Workspace 1–10 |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>1..0</kbd> | Move Active Window to Workspace 1–10 |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>1..0</kbd> | Move Active Window to Workspace Silently |
| <kbd>SUPER</kbd> + <kbd>Mouse Scroll</kbd> | Cycle Workspaces |

---

### 🧩 Pyprland Plugins & Scratchpads

| Shortcut | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>A</kbd> | Toggle Dropdown Scratchpad Terminal |
| <kbd>SUPER</kbd> + <kbd>N</kbd> | Toggle Minimized Window Workspace |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>N</kbd> | Toggle Special Minimized Workspace |
| <kbd>SUPER</kbd> + <kbd>Z</kbd> | Reset Screen Magnifier / Zoom |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>Z</kbd> | Zoom In Viewport (`+0.5`) |

---

### 🔊 Audio, Brightness & Media Controls

| Shortcut | Action |
| :--- | :--- |
| <kbd>F9</kbd> / <kbd>XF86AudioMute</kbd> | Toggle Audio Output Mute |
| <kbd>F10</kbd> / <kbd>XF86AudioLowerVolume</kbd> | Decrease Volume |
| <kbd>F11</kbd> / <kbd>XF86AudioRaiseVolume</kbd> | Increase Volume |
| <kbd>XF86AudioMicMute</kbd> | Toggle Microphone Mute |
| <kbd>XF86AudioPlay</kbd> / <kbd>Pause</kbd> | Play / Pause Media |
| <kbd>XF86AudioNext</kbd> | Next Track |
| <kbd>XF86AudioPrev</kbd> | Previous Track |
| <kbd>F4</kbd> / <kbd>XF86MonBrightnessUp</kbd> | Increase Screen Brightness |
| <kbd>F3</kbd> / <kbd>XF86MonBrightnessDown</kbd> | Decrease Screen Brightness |

<br>

<div align="right">
  <a href="#top"><kbd> <br> 🡅 Top <br> </kbd></a>
</div>

<a id="update"></a>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=INSTALLATION%20&%20UPDATE" width="450"/>

### Fresh Installation

For a fully automated installation (including all package dependencies, fonts, and configurations), use the one-liner installation command. Before that, make sure to install **curl**:

```bash
bash <(curl -s https://raw.githubusercontent.com/shell-ninja/hyprconf-install/main/direct_run.sh)
```

---

### Updating Dotfiles

Keeping your installation up-to-date with new improvements is straightforward:

1. Press <kbd>SUPER</kbd> + <kbd>S</kbd> to open the **Hyprland Settings** app.
2. Scroll to the bottom and select the **Dotfiles Update** tab.
3. Click the **Update Dotfiles** button.


The script automatically backs up your existing configuration, pulls the latest updates, updates configuration symlinks, and offers to reboot your session cleanly.

> [!NOTE]
> To check and apply standard Arch Linux system package updates, press <kbd>CTRL</kbd> + <kbd>U</kbd> at any time to open the **Package Updates GUI**.

<br>

<div align="right">
  <a href="#top"><kbd> <br> 🡅 Top <br> </kbd></a>
</div>

<a id="contrib"></a>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=CONTRIBUTING" width="450"/>

Contributions, bug reports, and suggestions are always welcome! If you have ideas for new features or refinements:

1. **Fork the repository** (make sure to uncheck *Copy the main branch only* if working on other branches).
2. **Clone your fork**:
   ```bash
   git clone --depth=1 --branch=noct https://github.com/your-username/hyprconf.git
   cd hyprconf
   ```
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Commit your changes** using clean conventional commit messages:
   ```bash
   git commit -m "feat: describe your change"
   ```
5. **Push to your fork** and open a Pull Request against the `noct` branch.

<br>

## Reference & Acknowledgements

- Built on top of the incredible [Hyprland](https://hyprland.org/) Wayland compositor ecosystem.
- Powered by the sleek [Noctalia](https://github.com/noctalia-dev/noctalia) Desktop Shell.
