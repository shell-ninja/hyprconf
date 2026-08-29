<a id="top"></a>

<h1 align="center">Minimal Hyprland Configuration</h1>
<h3 align="center">Crafted with precision by</h3>
<h2 align="center">Shell Ninja</h2>
<br>

<p align="center">
  A sleek, modern, and highly modular <b>Lua-based Hyprland</b> desktop environment integrated with the <b>Noctalia Desktop Shell</b>, dynamic <b>Pywal</b> / <b>Material You</b> wallpaper color generation, dedicated <b>GTK Settings & Wallpaper GUIs</b>, and seamless workflow utilities.
</p>

> [!NOTE]
> This repository contains dotfiles and desktop configurations. To install all required dependencies, packages, and fonts automatically on Arch Linux, visit the [hyprconf-install](https://github.com/shell-ninja/hyprconf-install) repository and run the installer.

<br>

<div align="center">

<a href="#screenshots"><kbd> <br> Screenshots <br> </kbd></a>&ensp;&ensp;
<a href="#features"><kbd> <br> Features <br> </kbd></a>&ensp;&ensp;
<a href="#config-structure"><kbd> <br> Configuration <br> </kbd></a>&ensp;&ensp;
<a href="#keybinds"><kbd> <br> Shortcuts <br> </kbd></a>&ensp;&ensp;
<a href="#update"><kbd> <br> Update <br> </kbd></a>&ensp;&ensp;
<a href="#contrib"><kbd> <br> Contributing <br> </kbd></a>

</div>

<br>

> [!TIP]
> This is a rolling-release configuration with active improvements and refinements. You can effortlessly update your dotfiles at any time using the keyboard shortcut `CTRL + U` or the update command below.

<br>

<div align="right">
  <a href="#top"><kbd> <br> 🡅 Top <br> </kbd></a>
</div>

<a id="screenshots"></a>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=SCREENSHOTS" width="450"/>

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

<br>

<div align="right">
  <a href="#top"><kbd> <br> 🡅 Top <br> </kbd></a>
</div>

<a id="features"></a>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=FEATURES" width="450"/>

- **Modular Lua Configuration**: Fully structured Hyprland setup written in Lua (`hyprland.lua`), dividing rules, keybindings, animations, decorations, environment, monitors, and startup execution into clean modules.
- **Noctalia Desktop Shell**: Modern Wayland desktop shell providing a status bar, unified control center, quick settings, notifications, session management, and media overlays.
  - **Dynamic Bar Switching**: Switch between multiple bar layouts (`full-top`, `minimal-bottom`, `bar-left`) with `SUPER + CTRL + W`.
  - **Dmenu & Launcher Providers**: Interactive app launcher (`SUPER + Space`), clipboard manager (`SUPER + ALT + C`), emoji picker (`SUPER + SHIFT + D`), SSH connections, calculator, and system commands.
  - **Desktop Shell Switcher**: Toggle instantly between Noctalia and classic Waybar/SwayNC (`SUPER + ALT + B`).
- **Dynamic Theming & Color Generation**: Automatic palette extraction from active wallpapers using Pywal and Material You color generation (`noctalia-colors.sh`), synchronizing colors across Hyprland borders, Noctalia Shell, terminal, and GUI elements.
- **Hyprland Settings Apps**:
  - **GTK Settings GUI** (`settings.py` / `SUPER + S`): Toggle and tweak animations, blur, rounding, borders, shadows, layout modes, and visual preferences with instant live reload.
  - **Interactive TUI Settings** (`settings.sh`): Command-line configuration dashboard for terminal workflows.
- **Visual Wallpaper Selector GUI** (`WallpaperSelect.py` / `SUPER + SHIFT + W`): Interactive GTK-based thumbnail grid with live preview, wallpaper switching, and palette regeneration.
- **Pyprland Plugins & Productivity**:
  - **Dropdown Scratchpad Terminal**: Slide-down scratchpad terminal toggleable via `SUPER + A`.
  - **Minimized Window Tray**: Toggle and manage minimized workspaces via `SUPER + N` / `SUPER + SHIFT + N`.
  - **Screen Magnifier**: Smooth viewport zoom controller (`SUPER + Z` / `SUPER + SHIFT + Z`).
- **Keybinds Visualizer & Dispatcher** (`keybinds.sh` / `SUPER + SHIFT + H`): Interactive fuzzy-searchable cheatsheet and direct action dispatcher.
- **Night Light & Eye Care**: Integrated `hyprsunset` screen temperature controller with smooth adjustments (`nightlight.sh`).
- **Unified Audio, Brightness & Media OSD**: Hardware and media key bindings with on-screen visual feedback and player control.
- **SDDM & Lock Screen Theming**: Customized SDDM login screen themes and user avatar setup (`sddm_avatar.sh`, `sddm_theme.sh`), paired with Noctalia / Hyprlock lock screen integrations.

<br>

<div align="right">
  <a href="#top"><kbd> <br> 🡅 Top <br> </kbd></a>
</div>

<a id="config-structure"></a>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=CONFIGURATION" width="450"/>

All configurations reside in the `~/.hyprconf` directory and are symlinked into `~/.config`:

```
~/.hyprconf/
├── hypr/                       # Hyprland core configuration & scripts
│   ├── hyprland.lua            # Main entry point & module loader
│   ├── noctalia.lua            # Dynamic Noctalia color bridge for Hyprland
│   ├── hypridle.conf           # Idle & auto-lock configuration
│   ├── configs/                # Modular Lua configs
│   │   ├── animation.lua       # Window animations & bezier curves
│   │   ├── decoration.lua      # Blur, rounding, shadow, & opacity settings
│   │   ├── environment.lua     # Environment variables (NVIDIA, Wayland, Qt)
│   │   ├── exec.lua            # Autostart daemons & startup scripts
│   │   ├── keybinds.lua        # Keyboard shortcuts & dispatchers
│   │   ├── monitor.lua         # Display resolution, scaling & layout
│   │   ├── settings.lua        # General Hyprland input, gestures & layout rules
│   │   ├── tags.lua            # Window tagging rules
│   │   └── wrules.lua          # Window rules & layer effects (Noctalia, PiP, dialogs)
│   ├── scripts/                # Helper utilities, GUI apps & dispatchers
│   │   ├── settings.py         # GTK Hyprland settings menu GUI
│   │   ├── WallpaperSelect.py  # GTK visual wallpaper selector
│   │   ├── keybinds.sh         # Interactive keybinds viewer & launcher
│   │   ├── noctalia-bar.sh     # Noctalia bar preset switcher
│   │   ├── noctalia-colors.sh  # Pywal & Material You color generator
│   │   ├── shell.sh            # Desktop shell switcher (Noctalia <-> Waybar)
│   │   ├── brightness.sh       # Backlight control helper
│   │   ├── volumecontrol.sh    # Audio volume & mute helper
│   │   ├── nightlight.sh       # Hyprsunset night light toggle
│   │   └── screenshot.sh       # Screenshot utility (Grimblast / Satty)
│   └── Wallpaper/              # Wallpaper collection & cache
├── noctalia/                   # Noctalia Shell TOML configuration
│   ├── 00-shell.toml           # Global shell settings, launcher & session rules
│   ├── 10-theme.toml           # Dynamic color definitions & typography
│   ├── 20-bar.toml             # Active status bar widget layout
│   ├── 40-services.toml        # Notification, audio, battery & network daemons
│   ├── 50-lockscreen.toml      # Lock screen layout & clock configuration
│   └── bars/                   # Pre-configured bar presets (full-top, minimal-bottom, bar-left)
├── btop/                       # Resource monitor theme & layout
├── fastfetch/                  # Fastfetch system info presets
├── fish/                       # Fish shell functions, aliases & prompt
├── kitty/                      # Terminal emulator styling & keymaps
├── pypr/                       # Pyprland plugins (scratchpads, zoom, minimized)
├── nvim/                       # Neovim text editor configuration
├── satty/                      # Screenshot annotation tool styling
├── yazi/                       # Terminal file manager configuration & keymaps
└── nwg-look/, qt5ct/, qt6ct/   # GTK and Qt visual customization tools
```

<br>

<div align="right">
  <a href="#top"><kbd> <br> 🡅 Top <br> </kbd></a>
</div>

<a id="keybinds"></a>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=KEYBOARD-SHORTCUTS" width="450"/>

> [!IMPORTANT]
> Press <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>H</kbd> at any time to open the interactive **Keybinds Search & Dispatcher**.

### 🚀 Applications & Launchers

| Shortcut | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>Return</kbd> | Open Main Terminal (`Kitty`) |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>Return</kbd> | Open Floating Terminal (`Kitty`) |
| <kbd>SUPER</kbd> + <kbd>Space</kbd> | Open **Noctalia Launcher** |
| <kbd>SUPER</kbd> + <kbd>D</kbd> | Open Application Menu (`Rofi` fallback) |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>C</kbd> | Open **Clipboard Manager** |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>D</kbd> | Open **Emoji Picker** |
| <kbd>SUPER</kbd> + <kbd>E</kbd> | Open File Manager (`Dolphin` / `Thunar`) |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>E</kbd> | Open Terminal File Manager (`Yazi`) |
| <kbd>SUPER</kbd> + <kbd>B</kbd> | Open Default Web Browser |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>B</kbd> | Open Browser in Incognito Mode |
| <kbd>SUPER</kbd> + <kbd>C</kbd> | Open Code Editor (`VS Code` / `VSCodium`) |

---

### 🎛️ Noctalia Shell, Controls & Desktop Settings

| Shortcut | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>S</kbd> | Open **Hyprland Settings GUI** |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>S</kbd> | Toggle **Noctalia Control Center** |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>,</kbd> | Toggle Noctalia Settings Window |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>W</kbd> | Switch **Noctalia Bar Layout** (`full-top`, `minimal-bottom`, `bar-left`) |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>B</kbd> | Switch Desktop Shell (**Noctalia** ⟷ **Waybar / SwayNC**) |
| <kbd>SUPER</kbd> + <kbd>X</kbd> | Open Session / Power Menu |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>L</kbd> | Lock Screen |
| <kbd>Print</kbd> | Take Screenshot via Launcher Palette |
| <kbd>SUPER</kbd> + <kbd>F1</kbd> | Toggle Window Animations On/Off |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>R</kbd> | Reload Hyprland Configuration |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>R</kbd> | Restart Startup Services |
| <kbd>CTRL</kbd> + <kbd>U</kbd> | Run Automated System & Dotfiles Update |

---

### 🖼️ Wallpaper & Colorscheme

| Shortcut | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>W</kbd> | Change Wallpaper (Random from collection) |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>W</kbd> | Open **Visual Wallpaper Selector GUI** |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>P</kbd> | Regenerate Color Scheme from Current Wallpaper |

---

### 🪟 Window & Layout Management

| Shortcut | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>Q</kbd> | Close Active Window |
| <kbd>SUPER</kbd> + <kbd>V</kbd> | Toggle Floating Mode (Active Window) |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>V</kbd> | Toggle All Windows to Float |
| <kbd>SUPER</kbd> + <kbd>F</kbd> | Toggle Fullscreen Mode |
| <kbd>SUPER</kbd> + <kbd>P</kbd> | Toggle Pseudo-Tiling |
| <kbd>SUPER</kbd> + <kbd>G</kbd> | Toggle Window Group |
| <kbd>SUPER</kbd> + <kbd>Tab</kbd> | Open Window Switcher |
| <kbd>ALT</kbd> + <kbd>Tab</kbd> | Cycle Next Window |
| <kbd>SUPER</kbd> + <kbd>H</kbd> / <kbd>J</kbd> / <kbd>K</kbd> / <kbd>L</kbd> | Move Window Focus (Left / Down / Up / Right) |
| <kbd>SUPER</kbd> + <kbd>Arrow Keys</kbd> | Move Window Focus |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>H</kbd> / <kbd>J</kbd> / <kbd>K</kbd> / <kbd>L</kbd> | Move Active Window Position |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>H</kbd> / <kbd>J</kbd> / <kbd>K</kbd> / <kbd>L</kbd> | Resize Active Window (Vim keys) |
| <kbd>SUPER</kbd> + <kbd>LMB Drag</kbd> | Move Window with Mouse |
| <kbd>SUPER</kbd> + <kbd>RMB Drag</kbd> | Resize Window with Mouse |
| <kbd>SUPER</kbd> + <kbd>1..0</kbd> | Switch to Workspace 1–10 |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>1..0</kbd> | Move Active Window to Workspace 1–10 |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>1..0</kbd> | Move Active Window Silently to Workspace |
| <kbd>SUPER</kbd> + <kbd>Mouse Scroll</kbd> | Cycle Workspaces |

---

### 🧩 Pyprland Plugins & Scratchpads

| Shortcut | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>A</kbd> | Toggle Dropdown Scratchpad Terminal |
| <kbd>SUPER</kbd> + <kbd>N</kbd> | Toggle Minimized Window Workspace |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>N</kbd> | Toggle Special Minimized Workspace |
| <kbd>SUPER</kbd> + <kbd>Z</kbd> | Reset Screen Zoom / Magnifier |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>Z</kbd> | Zoom Screen In (`+0.5`) |

---

### 🔊 Audio, Brightness & Media Controls

| Shortcut | Action |
| :--- | :--- |
| <kbd>F9</kbd> / <kbd>XF86AudioMute</kbd> | Toggle Audio Mute |
| <kbd>F10</kbd> / <kbd>XF86AudioLowerVolume</kbd> | Decrease Audio Volume |
| <kbd>F11</kbd> / <kbd>XF86AudioRaiseVolume</kbd> | Increase Audio Volume |
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

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=UPDATE" width="450"/>

To update your installation to the latest commit, simply press <kbd>CTRL</kbd> + <kbd>U</kbd> or run:

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/shell-ninja/hyprconf/main/update.sh)"
```

The script will back up your local configuration, pull the latest changes, update symlinks, and reload your desktop session.

<br>

<div align="right">
  <a href="#top"><kbd> <br> 🡅 Top <br> </kbd></a>
</div>

<a id="contrib"></a>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=CONTRIBUTING" width="450"/>

Contributions, bug reports, and suggestions are welcome!

1. Fork the repository (uncheck *Copy the main branch only* to include all branches).
2. Clone your fork:
   ```bash
   git clone --depth=1 --branch=development https://github.com/your_user_name/hyprconf.git
   ```
3. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. Commit your changes following standard conventional commit conventions:
   ```bash
   git commit -m "feat: Add new feature description"
   ```
5. Push to your branch and open a Pull Request targeting the `development` branch.

## Reference & Acknowledgements

- Inspired by [JaKooLit](https://github.com/JaKooLit)'s Hyprland installation scripts and configurations.
- Built on top of the [Hyprland](https://hyprland.org/) ecosystem and [Noctalia](https://github.com/noctalia-dev/noctalia) Shell.
