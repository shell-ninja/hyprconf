# 🐟 Fish Shell — Complete Reference Guide

> **F**riendly **I**nteractive **Sh**ell — a smart, user-friendly command line shell.

---

## Table of Contents

1. [Why Fish?](#-why-fish)
2. [Vim Keybindings (this config)](#-vim-keybindings-this-config)
3. [Autocompletion & Suggestions](#-autocompletion--suggestions)
4. [Syntax Highlighting](#-syntax-highlighting)
5. [Variables](#-variables)
6. [Functions](#-functions)
7. [Aliases](#-aliases)
8. [Control Flow](#-control-flow)
9. [String Manipulation](#-string-manipulation)
10. [Command Substitution & Pipelines](#-command-substitution--pipelines)
11. [History](#-history)
12. [Tab Completion](#-tab-completion)
13. [Prompt (Starship)](#-prompt-starship)
14. [Abbreviations](#-abbreviations)
15. [Path Management](#-path-management)
16. [Environment Variables](#-environment-variables)
17. [Event Handlers](#-event-handlers)
18. [Key Bindings Reference](#-key-bindings-reference)
19. [Useful Built-in Commands](#-useful-built-in-commands)
20. [Config Files in This Setup](#-config-files-in-this-setup)
21. [Custom Functions (This Config)](#-custom-functions-this-config)
22. [Custom Aliases (This Config)](#-custom-aliases-this-config)

---

## 🌟 Why Fish?

| Feature | Fish | Bash | Zsh |
|---|---|---|---|
| Autosuggestions | ✅ Built-in | ❌ Plugin | ⚠️ Plugin |
| Syntax highlighting | ✅ Built-in | ❌ Plugin | ⚠️ Plugin |
| Man-page completions | ✅ Auto-generated | ❌ Manual | ❌ Manual |
| Scripting syntax | Clean & simple | Complex | Complex |
| Web-based config UI | ✅ `fish_config` | ❌ | ❌ |
| POSIX compliant | ❌ (intentional) | ✅ | ✅ |

---

## ⌨️ Vim Keybindings (this config)

This config enables full vi/vim modal editing at the shell prompt via `fish_vi_key_bindings`.

### Mode Indicator (right prompt)

| Indicator | Color | Mode |
|---|---|---|
| `[N]` | 🔴 Red | Normal — navigate & edit |
| `[I]` | 🟢 Green | Insert — type normally |
| `[V]` | 🟣 Magenta | Visual — select text |
| `[R]` | 🟡 Yellow | Replace — overwrite single char |

### Cursor Shapes

| Mode | Cursor Shape |
|---|---|
| Normal | Block |
| Insert | Beam / Line |
| Replace | Underline |
| Visual | Block |

### Entering Modes

| Key | From Mode | Action |
|---|---|---|
| `Esc` | Insert/Visual | → Normal mode |
| `jk` | Insert | → Normal mode (fast exit) |
| `jj` | Insert | → Normal mode (fast exit) |
| `i` | Normal | → Insert (before cursor) |
| `a` | Normal | → Insert (after cursor) |
| `I` | Normal | → Insert (beginning of line) |
| `A` | Normal | → Insert (end of line) |
| `v` | Normal | → Visual mode |
| `r` | Normal | → Replace single char |

### Normal Mode — Navigation

| Key | Action |
|---|---|
| `h` | Move left |
| `l` | Move right |
| `w` | Jump forward one word |
| `b` | Jump backward one word |
| `e` | Jump to end of word |
| `0` | Beginning of line |
| `$` | End of line |
| `H` | Beginning of line (custom) |
| `L` | End of line (custom) |

### Normal Mode — Editing

| Key | Action |
|---|---|
| `x` | Delete character under cursor |
| `dd` | Delete entire line |
| `D` | Delete to end of line |
| `cc` | Change (replace) entire line |
| `C` | Change to end of line |
| `cw` | Change one word |
| `u` | Undo |
| `p` | Paste after cursor |
| `yy` | Yank (copy) line to clipboard |

### Insert Mode — Custom Bindings

| Key | Action |
|---|---|
| `Ctrl+F` | Accept autosuggestion (one char) |
| `Ctrl+P` | History up |
| `Ctrl+N` | History down |
| `Ctrl+U` | Delete to beginning of line |
| `Ctrl+W` | Delete previous word |
| `Ctrl+A` | Jump to beginning of line |
| `Ctrl+E` | Jump to end of line |
| `Ctrl+L` | Clear screen |

---

## 💡 Autocompletion & Suggestions

Fish provides **real-time inline suggestions** shown in grey as you type.

| Key | Action |
|---|---|
| `→` or `End` | Accept entire suggestion |
| `Ctrl+F` | Accept one character |
| `Alt+→` | Accept one word |
| `Tab` | Open completion menu |
| `Shift+Tab` | Navigate backwards |

---

## 🎨 Syntax Highlighting

- 🟢 **Green** — valid command
- 🔴 **Red** — unknown command / error
- 🔵 **Blue** — flags and options (`--help`)
- 🟡 **Yellow** — quoted strings
- ⬜ **Underline** — valid file/directory path

---

## 📦 Variables

```fish
set -l my_var "hello"         # local (function scope)
set -g my_var "hello"         # global (session)
set -U my_var "hello"         # universal (persists across sessions)
set -gx MY_VAR "hello"        # exported to child processes
set -e my_var                 # unset
set -q my_var; and echo "set" # check if set
```

### Special Variables

| Variable | Description |
|---|---|
| `$status` | Exit code of last command |
| `$argv` | Function arguments |
| `$history[1]` | Last command |
| `$PWD` | Current directory |
| `$HOME` | Home directory |
| `$USER` | Current user |

---

## 🔧 Functions

```fish
function mkcd -d "Create and cd into a directory"
    mkdir -p $argv
    cd $argv
end

# Argument handling
echo $argv[1]      # first arg
echo $argv         # all args
echo $argv[-1]     # last arg
echo $argv[2..-1]  # from 2nd to last

funcsave mkcd      # persist to ~/.config/fish/functions/mkcd.fish
functions          # list all
functions mkcd     # show source
functions -e mkcd  # delete
```

---

## 🔗 Aliases

```fish
alias ll='ls -lah'
alias -s ll='ls -lah'   # persistent
alias ll                 # show definition
functions -e ll          # remove
```

---

## 🔀 Control Flow

```fish
# if / else
if test -f file.txt
    echo "exists"
else
    echo "missing"
end

# switch
switch $argv[1]
    case "start"
        echo "Starting"
    case '*'
        echo "Unknown"
end

# for loop
for i in (seq 1 10)
    echo $i
end

# while
while test $count -lt 10
    set count (math $count + 1)
end

# and / or
test -f file; and echo "ok"
test -f file; or echo "missing"
```

---

## 🧵 String Manipulation

```fish
string match -q "*.fish" config.fish       # glob match
string match -qr "^[0-9]+" "123abc"        # regex match
string replace "old" "new" "old text"      # replace
string split "," "a,b,c"                   # split → a b c
string join ", " a b c                     # join → a, b, c
string sub -s 2 -l 3 "abcdef"             # sub-string → bcd
string trim "  hello  "                    # → hello
string upper "hello"                       # → HELLO
string lower "HELLO"                       # → hello
string length "hello"                      # → 5
string repeat -n 3 "ab"                   # → ababab
```

---

## 🔄 Command Substitution & Pipelines

```fish
set files (ls *.fish)                  # command substitution
cat file | grep "foo"                  # pipe
set n (cat file | wc -l)              # nested substitution
sleep 5 &                              # background job
echo "hello" > file.txt               # redirect (overwrite)
echo "world" >> file.txt              # redirect (append)
cmd > /dev/null 2>&1                  # silence all output
```

---

## 📜 History

```fish
history                    # show all
history search "git"       # search
history delete "bad_cmd"   # remove entry
history clear              # clear all
# Ctrl+R → fzf history search (this config)
```

---

## 📝 Abbreviations

Abbreviations expand when you press Space or Enter — great for discoverability.

```fish
abbr -a gco "git checkout"
abbr -a gcm "git commit -m"
abbr                         # list all
abbr -e gco                  # remove
```

---

## 🗂️ Path Management

```fish
fish_add_path ~/.local/bin           # prepend
fish_add_path --append ~/bin         # append
echo $PATH                           # show PATH
```

---

## 🎣 Event Handlers

```fish
# Fires when PWD changes
function on_dir_change --on-variable PWD
    echo "Now in: $PWD"
end

# Fires at exit
function on_exit --on-event fish_exit
    echo "Goodbye!"
end
```

---

## ⌨️ Key Bindings Reference

### Custom Bindings (this config — vi mode)

| Key | Mode | Action |
|---|---|---|
| `jk` | Insert | Escape to normal |
| `jj` | Insert | Escape to normal |
| `Ctrl+L` | Insert/Normal | Clear screen |
| `Ctrl+P` | Insert | History up |
| `Ctrl+N` | Insert | History down |
| `Ctrl+U` | Insert | Delete to line start |
| `Ctrl+W` | Insert | Delete previous word |
| `Ctrl+A` | Insert | Beginning of line |
| `Ctrl+E` | Insert | End of line |
| `Ctrl+F` | Insert | Accept suggestion char |
| `H` | Normal | Beginning of line |
| `L` | Normal | End of line |
| `yy` | Normal | Copy line to clipboard |

---

## 🛠️ Useful Built-in Commands

```fish
math "2 + 2"             # → 4
math --scale=0 "10/3"    # → 3 (integer)
count $argv              # count items
count *.fish             # count files
type ls                  # what is 'ls'?
random 1 100             # random number
time ls                  # time a command
read -P "Name: " name    # read user input
eval "echo hello"        # eval string
source ~/.config/fish/config.fish  # re-source
fish_config              # open web config UI
```

---

## 📁 Config Files in This Setup

| File | Purpose |
|---|---|
| `config.fish` | Main config — vim mode, integrations, env vars |
| `functions.fish` | All custom functions |
| `alias.fish` | Aliases |
| `fzf_init.fish` | FZF integration (cached) |
| `zoxide_init.fish` | Zoxide smart cd (cached) |
| `starship_init.fish` | Starship prompt (cached) |
| `starship/` | Starship TOML themes |
| `fish_variables` | Universal variables store |

---

## 🧩 Custom Functions (This Config)

| Function | Alias | Description |
|---|---|---|
| `y` | `y` | Yazi file manager (cd on exit) |
| `push` | `push` | git add → commit → push |
| `git_info` | `info` | Git branch/status summary |
| `ffstyle` | `ffstyle` | Pick fastfetch style (fzf) |
| `ffimg` | `ffimg` | Pick fastfetch image (fzf+chafa) |
| `change_style` | `style` | Switch Starship theme |
| `ss` | `ss` | Interactive package search |
| `fn_copy_paste` | `cp` | Smart copy with pv + sudo |
| `fn_removal` | `rm` | Safe remove with sudo |
| `fn_resources` | `disk`/`mem` | Show disk/memory stats |
| `fn_check_updates` | `cu` | Check package updates |
| `fn_update` | `update` | Full system update |
| `fn_install` | `in` | Install packages |
| `fn_uninstall` | `un` | Remove packages |
| `fn_compile_cpp` | `cpp` | Compile C++20 with g++ |
| `vite` | `vite` | Create Vite+React project |
| `play` | `play` | Play notification sound |
| `fastfetch` | `ff` | Fastfetch with saved preset |

---

## 🏷️ Custom Aliases (This Config)

### Files & Navigation

| Alias | Description |
|---|---|
| `ls` | Tree listing (eza, level 1) |
| `la` | All files (eza) |
| `ll` | Long listing (eza) |
| `lst` | 2-level tree |
| `tree` | 3-level tree |
| `cat` | Syntax-highlighted (bat) |
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `.` | `cd /` |
| `find` | FZF file picker → nvim |

### Editors

| Alias | Expands to |
|---|---|
| `vi`, `vim` | `nvim` |
| `svi` | `sudo nvim` |
| `nvm` | `nvim .` |

### Git

| Alias | Action |
|---|---|
| `add` | `git add .` |
| `commit` | `git commit -m` |
| `push` | Smart push (function) |
| `pushm` | `git push -u origin main` |
| `pull` | `git pull` |
| `clone` | `git clone` |
| `cloned` | `git clone --depth=1` |
| `branch` | `git branch -M main` |
| `info` | Git status summary |

### System

| Alias | Action |
|---|---|
| `src` | Re-source config |
| `c`, `clr`, `cls` | Clear terminal |
| `q` | Exit shell |
| `sys` | `btop` |
| `mem` | Memory usage |
| `disk` | Disk usage |
| `cu` | Check updates |
| `update` | Full system update |
| `in` | Install package |
| `un` | Uninstall package |
| `exe` | `chmod +x` |
| `nrd` | `npm run dev` |

### Misc

| Alias | Action |
|---|---|
| `ff` | Clear + fastfetch |
| `clock` | Terminal clock |
| `mat` | Matrix rain (cmatrix) |
| `style` | Switch Starship theme |

---

## 💡 Tips & Tricks

```fish
# Re-run last command with sudo
sudo $history[1]

# Benchmark fish startup time
for i in (seq 10); time fish -c ""; end

# Check syntax without running
fish --parse config.fish

# Multiline command
echo "long \
command"

# Set var temporarily for one command
EDITOR=nano git commit

# Open web-based fish config UI
fish_config
```

---

*Generated for shell-ninja's Fish Shell configuration — September 2026.*
