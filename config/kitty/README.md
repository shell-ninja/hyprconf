# 🐱 Kitty Terminal Configuration

A productivity-focused, keyboard-driven Kitty terminal configuration crafted for **Hyprland / Arch Linux**. Featuring smart window splits in current directories, tmux-like instant window zooming, styled powerline tabs, deep mouse-less screen hints, and smooth visual animations synced with Noctalia theming.

---

## 📑 Table of Contents

- [Overview & Architecture](#overview--architecture)
- [Installation & File Structure](#installation--file-structure)
- [Key Features](#key-features)
- [Keybindings & Practical Examples](#keybindings--practical-examples)
  - [1. Windows: Creation & Splits](#1-windows-creation--splits)
  - [2. Windows: Navigation & Selection](#2-windows-navigation--selection)
  - [3. Windows: Movement, Swapping & Resizing](#3-windows-movement-swapping--resizing)
  - [4. Windows: Zoom & Layout Switching](#4-windows-zoom--layout-switching)
  - [5. Tabs: Creation, Renaming & Closing](#5-tabs-creation-renaming--closing)
  - [6. Tabs: Navigation & Jumping](#6-tabs-navigation--jumping)
  - [7. Scrollback & History Search](#7-scrollback--history-search)
  - [8. Kitten Hints (Mouse-Free Workflow)](#8-kitten-hints-mouse-free-workflow)
  - [9. Clipboard & Font Scaling](#9-clipboard--font-scaling)
  - [10. Config Reloading & Debugging](#10-config-reloading--debugging)
- [Quick Reference Cheat Sheet](#quick-reference-cheat-sheet)

---

## 🔍 Overview & Architecture

- **Modifier Key**: `kitty_mod` is configured to `Ctrl + Shift`.
- **Typography**: Uses `Caskaydia Cove Nerd Font` at `14.0pt` with automatic bold/italic pairing.
- **Visuals**: Modern cursor trail (`cursor_trail 1`), 90% opacity (`background_opacity 0.9`) with dynamic opacity support, and 2px borders styled to match the Noctalia theme palette.
- **Directory Persistence**: All newly spawned windows, splits, and tabs inherit the current working directory (`--cwd=current`) of the active window.

---

## 📁 Installation & File Structure

```text
~/.hyprconf/kitty/
├── kitty.conf            # Main terminal configuration & bindings
├── colors-kitty.conf     # Auto-generated color palette (noctalia-colors.sh)
├── colors-matugen.conf   # Matugen-synced palette
├── themes/
│   └── noctalia.conf     # Active Noctalia theme (included at bottom of kitty.conf)
└── README.md             # This documentation
```

The config is symlinked to the standard XDG path:
```bash
~/.config/kitty -> ~/.hyprconf/kitty
```

### Live Reloading
Whenever you modify `kitty.conf` or switch wallpapers via Noctalia, the config can be reloaded instantly without closing your terminal:
- Press <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>F5</kbd> inside Kitty.
- Or run: `killall -SIGUSR1 kitty`

---

## ⚡ Key Features

1. **Working Directory Inheritance (`--cwd=current`)**: No more `cd`-ing again when you split a window or open a tab to run tests or git commands.
2. **Tmux-like Window Zoom (`stack` layout)**: Instantly maximize any window to full terminal size with one keybind (<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Z</kbd>), and restore your split layout when done.
3. **Slanted Powerline Tab Bar**: Minimalist, high-contrast tab bar styled at the top that only appears when 2 or more tabs are open.
4. **Kitten Hints Superpowers**: Keyboard-driven text, path, hash, and URL picker. Extract text directly into your shell prompt without reaching for the mouse.
5. **10,000 Lines Scrollback**: Ample buffer with built-in pager search support (<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>).

---

## ⌨️ Keybindings & Practical Examples

> **Note**: `kitty_mod` = <kbd>Ctrl</kbd> + <kbd>Shift</kbd>.

### 1. Windows: Creation & Splits

All split actions open the shell in the **same directory** as the active window.

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Enter</kbd> | New window (following layout) | `launch --cwd=current` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>\</kbd> or <kbd>\|</kbd> | **Vertical split** | `launch --location=vsplit --cwd=current` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>-</kbd> or <kbd>_</kbd> | **Horizontal split** | `launch --location=hsplit --cwd=current` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>W</kbd> | Close active window | `close_window` |

#### 💡 Real-World Example:
> You are in `~/projects/my-app` editing code in Neovim. Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>\</kbd> to pop open a vertical split right beside your editor in `~/projects/my-app` to run `npm run dev` or `cargo test`.

---

### 2. Windows: Navigation & Selection

Quickly jump between split windows without using the mouse.

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Left</kbd> | Focus window to the left | `neighboring_window left` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Right</kbd> | Focus window to the right | `neighboring_window right` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Up</kbd> | Focus window above | `neighboring_window up` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Down</kbd> | Focus window below | `neighboring_window down` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>[</kbd> | Previous window in order | `previous_window` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>]</kbd> | Next window in order | `next_window` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>H</kbd> | Jump directly to 1st window | `first_window` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>L</kbd> | Jump directly to 2nd window | `second_window` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>J</kbd> | Jump directly to 3rd window | `third_window` |

#### 💡 Real-World Example:
> You have 3 splits open. While typing in the rightmost window, simply tap <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>H</kbd> to immediately jump back to your primary window #1 without stepping through intermediate panes.

---

### 3. Windows: Movement, Swapping & Resizing

Rearrange your pane positions or tweak their proportions on the fly.

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Shift</kbd>+<kbd>Left</kbd> | Move / swap window left | `move_window left` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Shift</kbd>+<kbd>Right</kbd> | Move / swap window right | `move_window right` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Shift</kbd>+<kbd>Up</kbd> | Move / swap window up | `move_window up` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Shift</kbd>+<kbd>Down</kbd> | Move / swap window down | `move_window down` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd> | Interactive resize mode | `start_resizing_window` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>Left</kbd> | Shrink window width (-2) | `resize_window narrower 2` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>Right</kbd> | Expand window width (+2) | `resize_window wider 2` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>Up</kbd> | Expand window height (+2) | `resize_window taller 2` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>Down</kbd> | Shrink window height (-2) | `resize_window shorter 2` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>Home</kbd> | Reset window proportions | `resize_window reset` |

#### 💡 Real-World Example:
> You need your log window slightly wider to avoid line wraps. Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>Right</kbd> a couple of times to expand it by 2 units per stroke.

---

### 4. Windows: Zoom & Layout Switching

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Z</kbd> | **Toggle Zoom (Stack Layout)** | `toggle_layout stack` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Space</kbd> | Cycle layouts | `next_layout` |

#### 💡 Real-World Example:
> You have 4 splits running. A compiler error spits out a long backtrace in one pane. Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Z</kbd> to zoom that pane into full-screen. Once you inspect the error, press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Z</kbd> again to return seamlessly to your 4-pane grid.

---

### 5. Tabs: Creation, Renaming & Closing

Tabs help isolate different projects or long-running processes into distinct workspaces.

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>T</kbd> | New tab in current directory | `launch --type=tab --cwd=current` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Q</kbd> | Close active tab | `close_tab` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>T</kbd> | **Rename tab title** | `set_tab_title` |

#### 💡 Real-World Example:
> You are working on the backend. Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>T</kbd> to open a second tab for the frontend. Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>T</kbd>, type `Frontend`, and press Enter. The tab bar now clearly labels it `2: Frontend`.

---

### 6. Tabs: Navigation & Jumping

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Tab</kbd> / <kbd>PageDown</kbd> | Switch to next tab | `next_tab` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Shift</kbd>+<kbd>Tab</kbd> / <kbd>PageUp</kbd> | Switch to previous tab | `previous_tab` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>1</kbd> ... <kbd>9</kbd> | **Direct jump to tab 1–9** | `goto_tab 1` ... `goto_tab 9` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>.</kbd> | Reorder tab forward | `move_tab_forward` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>,</kbd> | Reorder tab backward | `move_tab_backward` |

#### 💡 Real-World Example:
> You have 5 tabs open. You are currently on tab 5 and need to check the database logs on tab 2: simply hit <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>2</kbd> to switch directly.

---

### 7. Scrollback & History Search

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Up</kbd> / <kbd>Down</kbd> | Scroll line by line | `scroll_line_up` / `down` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>PageUp</kbd> / <kbd>PageDown</kbd> | Scroll full page | `scroll_page_up` / `down` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Home</kbd> / <kbd>End</kbd> | Jump to top / bottom of scrollback | `scroll_home` / `end` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd> | **Open scrollback in pager** | `show_scrollback` |

#### 💡 Real-World Example:
> An extensive test suite just finished, producing 8,000 lines of output. Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd> to open the entire scrollback in `less`. Type `/FAIL` and press Enter to search through all failures using standard pager search commands.

---

### 8. Kitten Hints (Mouse-Free Workflow)

The built-in Kitty Hints Kitten analyzes text on your screen and overlays letter tags so you can pick elements using only your keyboard.

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd> | **Open URL in browser** | `open_url_with_hints` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> then <kbd>F</kbd> | **Insert file path into prompt** | `hints --type path --program -` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> then <kbd>L</kbd> | **Insert entire line into prompt** | `hints --type line --program -` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> then <kbd>W</kbd> | **Insert word into prompt** | `hints --type word --program -` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> then <kbd>H</kbd> | **Insert Git commit hash** | `hints --type hash --program -` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> then <kbd>N</kbd> | **Open file at line number in editor** | `hints --type linenum` |

#### 💡 Real-World Examples:
1. **Open a GitHub Pull Request URL**:
   Someone posts a link in your IRC/log output. Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd>, hit the highlighted hint letter (e.g. `a`), and your default browser opens the link immediately.
2. **Git Commit Inspection**:
   Run `git log --oneline`. You see a commit you want to view. Type `git show ` at your prompt, press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> then <kbd>H</kbd>. Kitty highlights all commit hashes on screen with letters. Press the letter, and the hash is inserted directly after `git show `!
3. **Insert File Path from `git status` or `ls`**:
   Type `nvim `, press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> then <kbd>F</kbd>, pick the file shown on your screen, and it is automatically pasted into your command.
4. **Jump Directly to Compiler Error Line**:
   A compiler outputs `src/main.rs:42:15: error: ...`. Press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> then <kbd>N</kbd>, select the hint letter, and Kitty will open `src/main.rs` directly at line 42 in your editor.

---

### 9. Clipboard & Font Scaling

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>C</kbd> | Copy selected text to clipboard | `copy_to_clipboard` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>V</kbd> | Paste from system clipboard | `paste_from_clipboard` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>=</kbd> or <kbd>+</kbd> | Increase font size (+1.0) | `change_font_size all +1.0` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>-</kbd> *(when not in split context)* | Decrease font size (-1.0) | `change_font_size all -1.0` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Backspace</kbd> | Reset font size to default (14.0) | `change_font_size all 0` |

---

### 10. Config Reloading & Debugging

| Keybinding | Action | Command |
| :--- | :--- | :--- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F5</kbd> | **Hot-reload config file** | `load_config_file` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F6</kbd> | Debug active Kitty configuration | `debug_config` |

---

## 🚀 Quick Reference Cheat Sheet

| Task | Shortcut |
| :--- | :--- |
| **New Window in CWD** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Enter</kbd> |
| **Vertical Split in CWD** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>\</kbd> |
| **Horizontal Split in CWD** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>-</kbd> |
| **Close Window** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>W</kbd> |
| **Toggle Window Zoom** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Z</kbd> |
| **Move Focus to Split** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Arrows</kbd> or <kbd>[</kbd> / <kbd>]</kbd> |
| **Jump to Window 1, 2, 3** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>H</kbd> / <kbd>L</kbd> / <kbd>J</kbd> |
| **Resize Splits** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>Arrows</kbd> |
| **New Tab in CWD** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>T</kbd> |
| **Close Tab** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Q</kbd> |
| **Rename Tab** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>T</kbd> |
| **Jump to Tab 1–9** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>1</kbd> ... <kbd>9</kbd> |
| **Search Scrollback** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd> |
| **Open URL without Mouse** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd> |
| **Insert Path / Hash into Prompt** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> then <kbd>F</kbd> (path) or <kbd>H</kbd> (hash) |
| **Hot Reload Config** | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F5</kbd> |
