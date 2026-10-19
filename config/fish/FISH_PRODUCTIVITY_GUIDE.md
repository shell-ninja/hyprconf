# ⚡ Mastering Fish Shell: The Deep Dive Productivity Guide

> A comprehensive, example-based guide to built-in Fish Shell features that maximize workflow efficiency, clean scripting, and terminal productivity — completely independent of external plugins or frameworks.

---

## 📑 Table of Contents

1. [The Fish Philosophy & Core Paradigm](#1-the-fish-philosophy--core-paradigm)
2. [Hidden Default Keybindings & Superpowers](#2-hidden-default-keybindings--superpowers)
3. [Zero-Click & Fast Directory Navigation](#3-zero-click--fast-directory-navigation)
4. [Autosuggestions & Pager Mastery](#4-autosuggestions--pager-mastery)
5. [Wildcards & Expansions Beyond POSIX](#5-wildcards--expansions-beyond-posix)
6. [Universal Variables & Scope Architecture](#6-universal-variables--scope-architecture)
7. [Abbreviations: The Productive Alternative to Aliases](#7-abbreviations-the-productive-alternative-to-aliases)
8. [The `string` Builtin Masterclass (Zero-Fork Text Processing)](#8-the-string-builtin-masterclass-zero-fork-text-processing)
9. [The `math` Builtin Masterclass](#9-the-math-builtin-masterclass)
10. [Functions, Autoloading & Modern CLI with `argparse`](#10-functions-autoloading--modern-cli-with-argparse)
11. [Event-Driven Shell: Hooks & Reactive Handlers](#11-event-driven-shell-hooks--reactive-handlers)
12. [Job Control, Background Tasks & Process Management](#12-job-control-background-tasks--process-management)
13. [Fish vs. Bash/Zsh: Gotchas & Rosetta Stone](#13-fish-vs-bashzsh-gotchas--rosetta-stone)
14. [Top 20 Daily Muscle Memory Shortcuts](#14-top-20-daily-muscle-memory-shortcuts)

---

## 1. The Fish Philosophy & Core Paradigm

Fish (*Friendly Interactive Shell*) is intentionally **not** 100% POSIX compliant. This design decision fixes decades of shell design mistakes:

- **No word splitting by default:** Variables containing spaces remain single tokens unless explicitly split. In Bash, `rm $file` deletes multiple files if `$file="my document.txt"`. In Fish, `rm $file` safely deletes `"my document.txt"`.
- **Everything is a list (Array):** All variables in Fish are lists of strings. A variable containing one item is simply a list of length 1.
- **Consistent Syntax:** No awkward `fi`, `esac`, or differing bracket rules `[[ vs [` — every block opens with a keyword (`if`, `for`, `switch`, `while`, `function`) and closes with `end`.
- **Zero Configuration Necessary:** Syntax highlighting, contextual completions, and autosuggestions work out of the box with zero plugins.

---

## 2. Hidden Default Keybindings & Superpowers

Fish includes powerful default shortcuts that many users never discover:

### Contextual Information Shortcuts

| Keybinding | Action | Why It's Productive |
|---|---|---|
| `Alt + h` (or `F1`) | **Instant Man Page** | Opens the manual for the command currently typed in your prompt. |
| `Alt + w` | **Explain Command** | Runs `type` or `which` on the word under cursor — tells you if it's a builtin, function, alias, or executable with path. |
| `Alt + l` | **List Directory Contents** | Runs `ls` on the directory path currently under the cursor without clearing your prompt line. |
| `Alt + p` | **Append Pager** | Automatically appends `| less` or pager to your current command line. |
| `Alt + .` | **Previous Argument History** | Repeatedly pressing this cycles through the last argument of your previous commands (equivalent to `!$` in bash). |
| `Alt + ↑` | **CD to Parent Directory** | Navigates to the parent directory (`cd ..`) immediately. |
| `Alt + ←` | **Go Back in Directory History** | Runs `prevd` (moves to previous directory in stack). |
| `Alt + →` | **Go Forward in Directory History** | Runs `nextd` (moves to next directory in stack). |
| `Ctrl + X` / `Ctrl + E` | **Edit in $EDITOR** | Opens your full active command line in Neovim/Vim, allowing multi-line complex editing, then executes it upon save & exit. |

#### Example in Action: `Alt + h`
```fish
# Type:
tar -x
# Press Alt+h -> Instantly opens the `man tar` page right at your fingertips!
```

---

## 3. Zero-Click & Fast Directory Navigation

### Implicit `cd` (Direct Directory Execution)
In Fish, you don't even have to type `cd`:
```fish
# Just type the directory path directly:
/var/log
# Shell is now in /var/log!

~/.config/fish
# Shell is now in ~/.config/fish!

..
# Shell is now in the parent directory!

../../
# Shell is now two levels up!
```

### `cdh` — Interactive Directory History
Fish tracks every directory you visit during your session. Type `cdh` to open an interactive, numbered picker:
```fish
cdh
```
Output:
```text
Directory history:
 1)  ~/projects/web-app
 2)  ~/.config/fish
 3)  /etc/nginx
 4)  ~/Downloads
Select directory by number or letter: 3
```
Type `3` and press `Enter` to jump straight to `/etc/nginx`.

### Directory Stack (`pushd`, `popd`, `dirh`)
```fish
# Push directories onto the stack:
pushd /var/log/nginx
pushd ~/my-project

# View the stack:
dirh

# Pop back to the previous directory:
popd
```

---

## 4. Autosuggestions & Pager Mastery

Fish's autosuggestions inspect your history and current filesystem in real time.

### Partial vs. Full Acceptance
- `Right Arrow` (`→`) or `End`: Accept the **entire** suggested command.
- `Alt + →` or `Alt + f`: Accept only the **next word** of the suggestion. This allows you to cherry-pick parts of long commands from history!
- `Ctrl + f`: In insert/emacs mode, accepts character-by-character.

### Real-Time Completion Filtering
When you press `Tab`, Fish opens the completion pager. **Do not just press Tab repeatedly — start typing!**
Fish filters the list of hundreds of flags or files live as you type characters:
```fish
git clone --<Tab>
# Type: 'rec'
# Fish immediately filters candidate flags down to: --recursive, --recurse-submodules
```

### Refreshing System Completions
Fish can parse all installed man pages on your system and create contextual completions for newly installed CLI tools:
```fish
fish_update_completions
```

---

## 5. Wildcards & Expansions Beyond POSIX

### 1. Recursive Globbing (`**`)
Find or act on files at any depth without needing `find`:
```fish
# List all markdown files in any subdirectory:
ls **.md

# Delete all temporary or node_modules directories:
rm -rf **/node_modules

# Search inside all Python files recursively:
grep "def main" **.py
```

### 2. Cartesian Product Expansion
Fish expands sets cleanly without commas requiring escaping:
```fish
# Create a complex project tree in one command:
mkdir -p project/{src,tests,docs}/{assets,code}

# Batch rename or backup:
cp app.js{,.bak}   # Expands to: cp app.js app.js.bak
```

### 3. Numerical & Character Range Expansions
```fish
# Numeric ranges:
echo {1..5}
# Output: 1 2 3 4 5

# Zero-padded ranges:
echo {01..10}
# Output: 01 02 03 04 05 06 07 08 09 10

# Alphabetical ranges:
echo {a..e}
# Output: a b c d e
```

### 4. Direct Command Substitution Indexing & Slicing
In Fish, you can index the result of a command substitution directly using `[index]`:
```fish
# Get only the first 3 files from ls:
echo (ls)[1..3]

# Get the last item from a list:
echo (ls)[-1]

# Slice from 2nd item to end:
echo (ls)[2..-1]
```

### 5. Combining Variables as Cartesian Products
```fish
set -l prefixes a b
set -l suffixes 1 2
echo $prefixes$suffixes
# Output: a1 a2 b1 b2
```

---

## 6. Universal Variables & Scope Architecture

Fish has four variable scopes. Understanding them eliminates the need for messy `.bashrc` exports.

| Scope | Command | Lifespan | Stored in |
|---|---|---|---|
| **Local** | `set -l var val` | Current block/loop | Memory |
| **Function** | `set -f var val` | Current function execution | Memory |
| **Global** | `set -g var val` | Current shell session | Memory |
| **Universal**| `set -U var val` | **Permanent across all shells & reboots** | `~/.config/fish/fish_variables` |

### Why Universal Variables (`set -U`) are Game-Changing
1. **Set once, available everywhere:** Run `set -U EDITOR nvim` in any terminal tab. **All** other running terminals and future sessions instantly see it. No need to reload or re-source config files!
2. **Instant Sync:** When one shell changes a universal variable, all other open fish instances update immediately via IPC.

### Proper PATH Management with `fish_add_path`
Never manually string-concatenate `$PATH` again. Fish includes `fish_add_path` which automatically:
- Checks if the path exists.
- Deduplicates (prevents identical paths added repeatedly).
- Preserves universal configuration.

```fish
# Prepend to PATH universally:
fish_add_path ~/.cargo/bin

# Append to PATH:
fish_add_path --append /opt/cuda/bin

# Check current PATH entries:
echo $PATH
```

---

## 7. Abbreviations: The Productive Alternative to Aliases

Aliases hide what is actually executed and mess up command history. Fish **Abbreviations (`abbr`)** replace aliases by expanding in place when you press `Space` or `Enter`.

### Why `abbr` is Superior
1. **History Quality:** Your shell history records `git commit -m "feat"` instead of cryptic `gcm "feat"`.
2. **Review Before Execution:** You see the full command with flags before pressing Enter.

### 1. Basic Abbreviations
```fish
abbr -a gco "git checkout"
abbr -a gcb "git checkout -b"
abbr -a gl "git pull --rebase"
```

### 2. Cursor Positioning with `%`
Place `%` where you want your cursor to land after expansion:
```fish
# Cursor jumps right between the quotation marks:
abbr -a gcm 'git commit -m "%"'

# Type: gcm<Space>
# Expands to: git commit -m "|" (cursor ready to type message)
```

### 3. POSIX History Expansions (`!!` and `!$`) in Fish
Fish intentionally doesn't have bash's error-prone `!` history expansion. Instead, you can make them explicit abbreviations:
```fish
# Expand !! to last command:
abbr -a !! --position anywhere --function last_history_item

# In fish, you can define:
function last_history_item
    echo $history[1]
end
```
Now typing `sudo !!<Space>` expands to `sudo <your-previous-command>` instantly!

---

## 8. The `string` Builtin Masterclass (Zero-Fork Text Processing)

External utilities like `sed`, `awk`, `cut`, and `tr` spawn new processes. The Fish `string` builtin executes in-process in microseconds.

### Common `string` Operations

#### 1. Matching & Regex
```fish
# Check if string matches regex:
if string match -qr '^[0-9]+$' "$input"
    echo "Is a number"
end

# Extract regex capture groups:
string match -r 'user=(.*)&id=(.*)' 'user=ninja&id=42'
# Output:
# user=ninja&id=42
# ninja
# 42
```

#### 2. Splitting & Joining
```fish
# Split string into a list by delimiter:
set -l parts (string split ":" "root:x:0:0:root:/root:/bin/bash")
echo $parts[1]   # root
echo $parts[-1]  # /bin/bash

# Join a list into a single string:
string join ", " "apple" "banana" "cherry"
# Output: apple, banana, cherry
```

#### 3. Replacing Text
```fish
# Simple replacement:
string replace "world" "fish" "hello world"
# Output: hello fish

# Regex replacement:
string replace -r '\.ya?ml$' '.json' "config.yaml"
# Output: config.json
```

#### 4. Trimming & Case Conversion
```fish
# Trim whitespace:
string trim "   hello world   "

# Upper / Lower:
string upper "fish"  # FISH
string lower "FISH"  # fish

# String length:
string length "antigravity"  # 11

# Slicing:
string sub -s 1 -l 4 "antigravity"  # anti
```

---

## 9. The `math` Builtin Masterclass

Fish includes a native calculation engine — no `expr` or `bc` required:

```fish
# Basic arithmetic:
math "10 + 5 * 2"       # 20

# Floating point operations:
math "10 / 3"           # 3.333333

# Scale control (decimal places):
math --scale=2 "10 / 3" # 3.33
math --scale=0 "10 / 3" # 3 (integer division)

# Scientific functions:
math "sqrt(144)"        # 12
math "2^8"              # 256
math "sin(pi / 2)"      # 1

# Hex and binary conversions:
math "0xFF"             # 255
math --base=16 "255"    # 0xff
math --base=2 "15"      # 0b1111
```

---

## 10. Functions, Autoloading & Modern CLI with `argparse`

### 1. The Autoloading System (Instant Startup)
Instead of putting 5,000 lines of functions into a single file, Fish autoloads functions on demand:
- Put a function called `my_tool` in `~/.config/fish/functions/my_tool.fish`.
- Fish **only reads and compiles it when you actually run `my_tool`**.
- This keeps shell startup speed under 15ms regardless of how many functions you have!

### 2. Writing Professional CLI Tools with `argparse`
`argparse` is a built-in flag parser with built-in validation:

```fish
function backup_dir -d "Backup a directory to a destination"
    # Define flags:
    # -h/help: boolean flag
    # -v/verbose: boolean flag
    # -d/dest=: takes a required value
    argparse 'h/help' 'v/verbose' 'd/dest=' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: backup_dir [-v|--verbose] [-d|--dest=PATH] <DIR>"
        return 0
    end

    set -l target $argv[1]
    test -z "$target"; and begin; echo "Error: Missing directory"; return 1; end

    set -l destination "/tmp/backups"
    if set -q _flag_dest
        set destination $_flag_dest
    end

    if set -q _flag_verbose
        echo "Backing up $target to $destination..."
    end

    mkdir -p "$destination"
    tar -czf "$destination/"(basename $target)-(date +%Y%m%d).tar.gz "$target"
end
```

---

## 11. Event-Driven Shell: Hooks & Reactive Handlers

Fish functions can react to system events automatically:

### 1. Trigger on Directory Change (`--on-variable PWD`)
Automatically list files, activate virtual environments, or check git status when navigating:
```fish
function auto_venv --on-variable PWD -d "Auto-activate Python virtualenv"
    status is-interactive; or return

    if test -f .venv/bin/activate.fish
        source .venv/bin/activate.fish
    else if test -n "$VIRTUAL_ENV" -a ! -d (dirname "$VIRTUAL_ENV")
        deactivate
    end
end
```

### 2. Trigger on Background Job Completion (`--on-job-exit`)
```fish
function notify_done --on-job-exit %last
    notify-send "Task Finished" "Your background process has completed."
end
```

### 3. Trigger at Shell Exit (`--on-event fish_exit`)
```fish
function cleanup_temp --on-event fish_exit
    rm -rf /tmp/my_session_* 2>/dev/null
end
```

---

## 12. Job Control, Background Tasks & Process Management

Fish handles background tasks and PID tracking cleanly:

```fish
# Run a process in background:
sleep 60 &

# Built-in process variables:
echo "Last background PID: $last_pid"
echo "Current Fish PID:    $fish_pid"

# View active jobs:
jobs

# Bring background job to foreground:
fg %1

# Send a running job to background:
# Press Ctrl+Z, then run:
bg %1

# Disown a background process (keeps running after closing terminal):
disown %1
```

---

## 13. Fish vs. Bash/Zsh: Gotchas & Rosetta Stone

| Task | Bash / Zsh | Fish Shell |
|---|---|---|
| **Command Substitution** | `$(date)` or `` `date` `` | `(date)` |
| **Exit Status** | `$?` | `$status` |
| **Pipeline Exit Codes**| `${PIPESTATUS[@]}` | `$pipestatus` |
| **Array Slicing** | `${arr[@]:1:3}` (0-indexed) | `$arr[2..4]` (1-indexed) |
| **Looping** | `for i in 1 2 3; do echo $i; done` | `for i in 1 2 3; echo $i; end` |
| **Checking Variable** | `if [ -z "$var" ]; then` | `if test -z "$var"` |
| **Short-circuit AND** | `cmd1 && cmd2` | `cmd1; and cmd2` (or `cmd1 && cmd2` in Fish 3.0+) |
| **Short-circuit OR**  | `cmd1 \|\| cmd2` | `cmd1; or cmd2` (or `cmd1 \|\| cmd2` in Fish 3.0+) |
| **Subshells** | `(cd /tmp && ls)` | `fish -c "cd /tmp; and ls"` |
| **Export Environment**| `export VAR="val"` | `set -gx VAR "val"` |

---

## 14. Top 20 Daily Muscle Memory Shortcuts

| Shortcut | Context | Effect |
|---|---|---|
| `Alt + h` | Anywhere | Open `man` page for current command |
| `Alt + w` | Under cursor | Explain what the command/alias/binary is |
| `Alt + l` | Under cursor | Run `ls` on folder under cursor |
| `Alt + .` | Prompt | Insert last argument of previous command |
| `Alt + ↑` | Prompt | Jump to parent directory (`cd ..`) |
| `Alt + ←` | Prompt | Jump to previous directory (`prevd`) |
| `Alt + →` | Prompt | Jump to next directory (`nextd`) |
| `cdh` | Command | Interactive recent directories picker |
| `Right Arrow` | Autosuggest | Accept entire suggestion |
| `Alt + →` | Autosuggest | Accept next word of suggestion |
| `Tab` + typing | Completion | Live-filter completion candidates |
| `Ctrl + X` | Commandline | Edit entire command in Neovim/Vim |
| `fish_add_path`| Terminal | Add directory to `$PATH` cleanly |
| `abbr -a` | Terminal | Create instant-expanding abbreviation |
| `string match`| Scripting | Fast in-process regex pattern matching |
| `math` | Scripting/CLI | Native calculator engine |
| `funcsave` | Terminal | Save interactive function permanently |
| `fish_update_completions` | Maintenance | Parse system man pages into completions |
| `fish_config` | Terminal | Launch web UI for colors and settings |
| `type <cmd>` | Terminal | Show exact code or path of any command |

---

*Authored for the deep-dive mastery of Fish Shell.*
