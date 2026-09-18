# 🐟 Fish Shell — Deep Productivity Guide

> Fish version **4.x** | Everything outside this custom setup — pure, default fish power.
> Focus: **deep understanding + real, runnable examples**.

---

## Table of Contents

1. [Autosuggestions — How They Really Work](#1-autosuggestions--how-they-really-work)
2. [Tab Completion — Under the Hood](#2-tab-completion--under-the-hood)
3. [History — The Full Power](#3-history--the-full-power)
4. [Variables — Scopes, Types & Tricks](#4-variables--scopes-types--tricks)
5. [String Builtin — The Swiss Army Knife](#5-string-builtin--the-swiss-army-knife)
6. [Wildcards & Globbing](#6-wildcards--globbing)
7. [Brace Expansion](#7-brace-expansion)
8. [Pipes, Redirects & Process Substitution](#8-pipes-redirects--process-substitution)
9. [Functions — Deep Dive](#9-functions--deep-dive)
10. [Abbreviations — Smarter Than Aliases](#10-abbreviations--smarter-than-aliases)
11. [Event System — React to Shell Events](#11-event-system--react-to-shell-events)
12. [Completions — Write Your Own](#12-completions--write-your-own)
13. [Prompts — fish_prompt & fish_right_prompt](#13-prompts--fish_prompt--fish_right_prompt)
14. [Key Bindings — bind Mastery](#14-key-bindings--bind-mastery)
15. [Conditionals & Test Expressions](#15-conditionals--test-expressions)
16. [Loops & Iteration Patterns](#16-loops--iteration-patterns)
17. [Error Handling & Exit Codes](#17-error-handling--exit-codes)
18. [Math & Arithmetic](#18-math--arithmetic)
19. [Background Jobs & Job Control](#19-background-jobs--job-control)
20. [Universal Variables — Persistent Config](#20-universal-variables--persistent-config)
21. [fish_config — Web UI](#21-fish_config--web-ui)
22. [Useful One-Liners & Patterns](#22-useful-one-liners--patterns)
23. [Debugging Fish Scripts](#23-debugging-fish-scripts)
24. [Performance & Startup Speed](#24-performance--startup-speed)

---

## 1. Autosuggestions — How They Really Work

Fish shows **greyed-out suggestions** to the right of your cursor as you type.
They come from two sources, checked in order:

1. **Command history** — most recently used matching command
2. **Completions** — if no history match found

### Accepting Suggestions

```fish
# You type: gi
# Fish shows: git commit -m "fix bug"  (greyed out)

→           # Accept the ENTIRE suggestion (Right arrow)
End         # Same as →
Ctrl+F      # Accept ONE character at a time
Alt+→       # Accept ONE word at a time
Alt+F       # Same as Alt+→
```

### Rejecting / Ignoring

```fish
# Just keep typing — the suggestion disappears naturally
# Or press any navigation key to dismiss
↓           # Dismiss and go to next history entry
Ctrl+C      # Cancel entire line
```

### How to Make Suggestions Better

The more you use fish, the smarter the suggestions.
Run commands you use often — fish remembers them.

```fish
# Check what's in history right now
history | head -20

# Fish suggestions weight recent commands higher
# So a command you ran today beats one from last month
```

---

## 2. Tab Completion — Under the Hood

Fish auto-generates completions by **parsing man pages** on first use.
No plugin needed. Press `Tab` once to complete, twice (or `Tab` again) to see a menu.

```fish
# Single match → completes immediately
git che<Tab>          # → git checkout

# Multiple matches → interactive menu appears
git <Tab>             # shows: add, commit, push, status, ...

# Inside the menu:
Tab / →               # move right
Shift+Tab / ←         # move left
↑ / ↓                 # move up/down
Enter                 # select
Escape                # dismiss menu
```

### Fish Understands Context

```fish
# Completes only files, not directories
cat <Tab>             # shows files

# Completes only directories
cd <Tab>              # shows directories

# Completes flags
git commit -<Tab>     # shows: --message, --amend, --no-verify ...

# Completes values for specific flags
git checkout -b <Tab> # suggests existing branches

# Completes based on argument position
ssh <Tab>             # shows known hosts from ~/.ssh/known_hosts
```

### Force Completion Regeneration

```fish
# If completions are stale or wrong:
fish_update_completions   # rebuilds from man pages
```

### Custom Completion File

Write your own completions for any command:

```fish
# File: ~/.config/fish/completions/deploy.fish

# Tell fish: 'deploy' takes subcommands, no filenames
complete -c deploy -f

# Subcommands
complete -c deploy -n "__fish_use_subcommand" -a "start"   -d "Start deploy"
complete -c deploy -n "__fish_use_subcommand" -a "stop"    -d "Stop deploy"
complete -c deploy -n "__fish_use_subcommand" -a "status"  -d "Check status"

# Flag only valid after 'start'
complete -c deploy \
    -n "__fish_seen_subcommand_from start" \
    -l env -r \
    -d "Target environment"

# -f = no filename completion
# -c = command name
# -n = condition (only show when this is true)
# -a = arguments/completions
# -d = description shown in menu
# -l = long flag (--env)
# -s = short flag (-e)
# -r = requires argument
```

---

## 3. History — The Full Power

Fish keeps a **per-session and merged global history** in `~/.local/share/fish/fish_history`.

### Navigation

```fish
↑ / ↓               # walk through history one by one
Ctrl+P / Ctrl+N     # same (in default emacs mode)

# Type a prefix, then press ↑ to search by prefix:
git ↑               # finds last command starting with "git"
ssh ↑               # finds last ssh command
```

### Interactive Search

```fish
Ctrl+R              # open history search prompt
# Type to filter, ↑↓ to navigate, Enter to run, Esc to cancel
```

### History Commands

```fish
# List all history (newest first)
history

# Search for a pattern
history search "docker"
history search --prefix "git"     # only prefix matches
history search --contains "push"  # substring match

# Delete specific entry
history delete "rm -rf /"         # exact match

# Delete all entries matching pattern
history delete --prefix "cd /tmp"

# Delete everything
history clear

# Merge history from all fish sessions (usually auto-done)
builtin history merge

# Show history with timestamps
history --show-time

# Limit output
history | head -30
history | tail -30
history | grep "nvim"
```

### Prevent a Command from Being Saved

```fish
# Prefix with a space — fish WON'T save it to history
 secret_token=abc123 curl https://api.example.com
# ↑ note the leading space
```

### History Across Multiple Terminals

Fish uses `--show-time` and session IDs to merge histories:

```fish
# After running commands in another terminal:
builtin history merge    # pull in entries from other sessions
```

---

## 4. Variables — Scopes, Types & Tricks

### The Four Scopes

```fish
# LOCAL — only inside the current function/block
function demo
    set -l x 10       # dies when function returns
    echo $x           # 10
end
echo $x               # empty — gone!

# GLOBAL — entire fish session
set -g counter 0
set -g counter (math $counter + 1)

# UNIVERSAL — persisted to disk, shared across ALL fish sessions
set -U theme "dark"
# Survives terminal restarts, reboots!
# Stored in: ~/.config/fish/fish_variables

# EXPORTED — available to child processes (subshells, external commands)
set -gx EDITOR nvim
set -lx TEMP_VAR "only for this scope but exported"
```

### Lists (Arrays)

Fish variables are **always lists**. A single value is just a list of 1.

```fish
# Create a list
set fruits apple banana cherry

# Access by index (1-based!)
echo $fruits[1]        # apple
echo $fruits[2]        # banana
echo $fruits[-1]       # cherry (last)
echo $fruits[-2]       # banana (second from last)

# Slice
echo $fruits[1..2]     # apple banana
echo $fruits[2..-1]    # banana cherry

# Iterate
for f in $fruits
    echo $f
end

# Count
count $fruits           # 3

# Append to list
set -a fruits mango
echo $fruits            # apple banana cherry mango

# Prepend
set -p fruits grape
echo $fruits            # grape apple banana cherry mango

# Delete element at index
set -e fruits[2]        # removes banana

# Check if list contains a value
if contains "apple" $fruits
    echo "found"
end

# String join list
string join ", " $fruits   # grape, apple, cherry, mango
```

### Variable Operations

```fish
# Check if set
set -q myvar; and echo "set"
set -q myvar; or echo "not set"

# Check if set AND non-empty
if set -q myvar; and test -n "$myvar"
    echo "set and non-empty"
end

# Default value pattern
set -q CONFIG_DIR; or set CONFIG_DIR "$HOME/.config"

# Unset / erase
set -e myvar              # erase
set -e myvar[2]           # erase index 2 from list

# Show all variables
set                       # all
set -g                    # only globals
set -U                    # only universals
set -x                    # only exported

# Variable in string
set name "World"
echo "Hello, $name!"         # Hello, World!
echo "Hello, {$name}!"       # Hello, World!  (explicit boundary)
echo "Count: $(count $fruits)"  # NO! use:
echo "Count: "(count $fruits)  # Count: 4
```

---

## 5. String Builtin — The Swiss Army Knife

`string` replaces grep, sed, awk, tr for most common text tasks.

### match — Test & Capture

```fish
# Glob match (returns 0=true, 1=false)
string match -q "*.fish" "config.fish"   # true
string match -q "*.fish" "config.py"     # false

# Regex match
string match -qr "^\d+" "123abc"         # true — starts with digits

# Capture groups
set result (string match -r "(\w+)@(\w+)" "user@host")
echo $result          # user@host  user  host
# $result[1] = full match, [2] = group 1, [3] = group 2

# Case-insensitive
string match -qi "HELLO" "hello"         # true

# Match against multiple strings at once
string match -q "error" $log_lines       # true if ANY line matches
```

### replace — Substitute Text

```fish
# Basic replace (first occurrence)
string replace "foo" "bar" "foo and foo"     # bar and foo

# Replace ALL occurrences
string replace -a "foo" "bar" "foo and foo"  # bar and bar

# Regex replace
string replace -r "(\d+)" "[$1]" "abc123def"  # abc[123]def

# Regex replace with capture group
string replace -r "^(\w+):(.+)" '$2: $1' "name:John"  # John: name

# In-place on a variable
set text "hello world"
set text (string replace "world" "fish" $text)
echo $text    # hello fish
```

### split & join

```fish
# Split on delimiter
string split "," "a,b,c,d"      # a  b  c  d (each on own line)
set parts (string split "," "a,b,c")
echo $parts[2]   # b

# Split on first occurrence only
string split -m 1 "=" "KEY=value=with=equals"   # KEY  value=with=equals

# Split on regex
string split -r "\s+" "hello   world"   # hello  world

# Join list with delimiter
string join ":" $PATH_PARTS          # part1:part2:part3
string join "\n" $lines              # one per line
string join ", " a b c               # a, b, c
```

### trim

```fish
string trim "  hello world  "         # hello world
string trim --left "  hello  "        # hello  
string trim --right "  hello  "       #   hello
string trim --chars "xy" "xyHELLOyx"  # HELLO  (trim specific chars)
```

### sub — Substring

```fish
# string sub -s START -l LENGTH
string sub -s 2 "hello"         # ello  (from index 2 to end)
string sub -s 2 -l 3 "hello"   # ell   (3 chars starting at 2)
string sub -l 3 "hello"        # hel   (first 3 chars)
string sub -s -3 "hello"       # llo   (last 3 chars, negative index)
```

### Other String Operations

```fish
# Length
string length "hello"           # 5
string length -q ""             # quiet, returns 1 if empty

# Upper / lower case
string upper "hello World"      # HELLO WORLD
string lower "Hello WORLD"      # hello world

# Repeat
string repeat -n 5 "-"          # -----
string repeat -n 3 "ab"         # ababab

# Pad
string pad -w 10 "hi"           #         hi  (right-padded by default, actually left-pad)
string pad -r -w 10 "hi"        # hi          (right-pad)
string pad -w 10 -c "0" "42"    # 0000000042  (zero-pad)

# Escape / unescape
string escape "hello world"     # hello\ world
string escape --style=url "a b" # a%20b
string unescape "hello\ world"  # hello world

# Collect (combine multiple outputs into one variable)
set lines (cat file.txt | string collect)  # entire content as one string
```

---

## 6. Wildcards & Globbing

Fish has **powerful, safe globbing** — globs that match nothing throw an error (no silent empty expansion).

```fish
# Basic wildcards
echo *.fish           # all .fish files
echo src/**/*.py      # all .py files recursively (** = recursive)
echo file?.txt        # file1.txt, filea.txt, etc.

# Hidden files (dotfiles)
echo .*               # only hidden files
echo {.,}*.fish       # hidden and non-hidden .fish files

# Brace alternatives with globs
echo *.{jpg,png,gif}  # all image files

# Case-insensitive glob (fish 4+)
echo (ls | string match -i "*.Fish")

# Negate / exclude (use pipe + grep instead)
ls *.txt | grep -v "temp"

# Glob in variable assignment
set fish_files *.fish
echo $fish_files      # lists all .fish files

# Recursive glob
set all_configs **/*.toml   # all .toml files in all subdirs

# When no match: fish throws error
echo *.nonexistent    # error: No matches for wildcard

# Suppress error — use test first
set files (ls 2>/dev/null | grep "\.xyz$"); or set files
```

---

## 7. Brace Expansion

```fish
# Generate multiple values
echo {a,b,c}             # a b c
echo file{1,2,3}.txt     # file1.txt file2.txt file3.txt
echo {start,end}_hook    # start_hook end_hook

# Nested
echo {a,b}{1,2}          # a1 a2 b1 b2

# Ranges (fish 4+)
echo {1..5}              # 1 2 3 4 5
echo {a..e}              # a b c d e
echo {01..05}            # 01 02 03 04 05 (zero-padded)

# With prefix/suffix
echo chapter{1..3}.md   # chapter1.md chapter2.md chapter3.md

# Practical: create multiple files
touch notes_{monday,tuesday,wednesday}.md

# Practical: mkdir multiple dirs
mkdir -p src/{components,hooks,utils,pages}

# Practical: backup files
cp config.fish{,.bak}    # cp config.fish config.fish.bak
```

---

## 8. Pipes, Redirects & Process Substitution

### Pipes

```fish
# Basic pipe
ls -la | grep ".fish"

# Chain multiple pipes
cat /etc/passwd | grep "shell-ninja" | cut -d: -f7

# Pipe stderr too
command 2>&1 | grep "error"

# Pipe with while loop
cat file.txt | while read -l line
    echo "Line: $line"
end
```

### Redirects

```fish
# Stdout to file (overwrite)
echo "hello" > output.txt

# Stdout to file (append)
echo "world" >> output.txt

# Stderr to file
command 2> errors.txt

# Both stdout and stderr to file
command > all.txt 2>&1
# Or in fish (shorthand):
command &> all.txt

# Stderr to stdout (merge)
command 2>&1

# Discard output
command > /dev/null
command 2> /dev/null
command &> /dev/null

# Here string (send string as stdin)
grep "foo" <<< "foo bar baz"

# Read from file as stdin
command < input.txt
```

### Process Substitution

Fish uses `(command)` syntax, not `<()` like bash:

```fish
# Use output of command as a list of arguments
diff (sort file1.txt | psub) (sort file2.txt | psub)
#    ↑ psub creates a temp file from the pipe output

# Practical: compare two command outputs
diff (ls dir1 | psub) (ls dir2 | psub)

# Use in loops
for file in (find . -name "*.log" -newer reference.txt)
    echo "New log: $file"
end

# Parallel execution with psub
paste (command1 | psub) (command2 | psub)
```

### AND / OR Chains

```fish
# Run second only if first succeeds
make && ./run
make; and ./run          # fish style

# Run second only if first fails
make || echo "Build failed"
make; or echo "Build failed"  # fish style

# Chain
git add .; and git commit -m "msg"; and git push

# Begin/end for grouped commands
begin
    cd /tmp
    ls
    cd -
end | grep "cache"
```

---

## 9. Functions — Deep Dive

### The Basics

```fish
function greet
    echo "Hello, $argv[1]!"
end

greet World    # Hello, World!
```

### Flags & Options Parsing with argparse

`argparse` is a fish built-in — no manual argument parsing needed:

```fish
function deploy
    # Define flags:
    # h/help  → boolean flag
    # e/env=  → requires value
    # p/port= → requires value, with default
    argparse \
        'h/help' \
        'e/env=' \
        'p/port=!_validate_int --min 1 --max 65535' \
        -- $argv

    # If -h or --help was passed:
    if set -q _flag_help
        echo "Usage: deploy [-e staging|prod] [-p PORT]"
        return 0
    end

    # Access flag values (fish prefixes with _flag_)
    set -q _flag_env;  or set _flag_env "staging"
    set -q _flag_port; or set _flag_port 8080

    echo "Deploying to: $_flag_env on port $_flag_port"
    echo "Remaining args: $argv"
end

# Usage:
deploy -e prod -p 3000 myapp   # Deploying to: prod on port 3000
deploy --env=prod myapp
deploy -h
```

### Functions with Descriptions

```fish
function mkcd -d "Create a directory and cd into it"
    mkdir -p $argv[1]
    cd $argv[1]
end
```

### Wrapping External Commands

```fish
# Wrap a command to add default flags
function ls
    command ls --color=auto -F $argv
    # 'command' forces the real ls, avoiding recursion
end

# Wrap sudo to auto-elevate when permission denied
function sudo
    if count $argv > /dev/null
        command sudo $argv
    else
        command sudo $history[1]
    end
end
```

### Recursive Functions

```fish
function factorial
    if test $argv[1] -le 1
        echo 1
        return
    end
    set -l prev (factorial (math $argv[1] - 1))
    math $argv[1] \* $prev
end

factorial 5    # 120
```

### Saving & Autoloading Functions

```fish
# Save a function to be available in all sessions
funcsave myfunction
# Creates: ~/.config/fish/functions/myfunction.fish

# Fish autoloads any .fish file in functions/ directory
# So you can also manually create:
# ~/.config/fish/functions/myfunction.fish

# List all defined functions
functions

# Show source of a function
functions myfunction

# Delete a function from current session
functions -e myfunction

# Delete a saved function permanently
rm ~/.config/fish/functions/myfunction.fish
```

### Scoped / Anonymous Functions

```fish
# Define function, use it, then clean up
function __temp_helper
    echo $argv[1] | string upper
end
__temp_helper "hello"   # HELLO
functions -e __temp_helper  # remove it
```

---

## 10. Abbreviations — Smarter Than Aliases

Abbreviations **expand visibly** in the command line as you type — you see exactly what runs, and can edit before executing. Aliases run invisibly.

```fish
# Add abbreviation
abbr -a gco "git checkout"
abbr -a gcm "git commit -m"
abbr -a gst "git status"
abbr -a gd  "git diff"
abbr -a gp  "git push"
abbr -a gl  "git log --oneline"

# How it works:
# Type: gco<Space>
# Fish instantly expands to: git checkout
# You can still edit: git checkout -b new-branch

# List all abbreviations
abbr

# Remove
abbr -e gco

# Abbreviations are UNIVERSAL (persistent across sessions)
# Stored in fish_variables, no need for funcsave
```

### Abbreviations vs Aliases — When to Use Which

| | Abbreviations | Aliases |
|---|---|---|
| Visible expansion | ✅ Yes | ❌ No |
| Editable before run | ✅ Yes | ❌ No |
| Simple text substitution | ✅ Ideal | ✅ OK |
| Complex logic | ❌ No | ✅ Use function |
| Best for | Short git, apt cmds | Complex overrides |

---

## 11. Event System — React to Shell Events

Fish fires **events** at key points. Hook into them with `--on-event`:

### Built-in Events

```fish
# Fish starts (interactive session)
function on_fish_start --on-event fish_prompt
    # runs before EVERY prompt — use sparingly
end

# Fish exits
function on_exit --on-event fish_exit
    echo "Bye! Sessions ended at "(date)
    # log session end, cleanup temp files, etc.
end

# fish_preexec — runs BEFORE a command executes
function log_commands --on-event fish_preexec
    echo (date "+%H:%M:%S") $argv >> ~/.command_log
end

# fish_postexec — runs AFTER a command completes
function on_cmd_done --on-event fish_postexec
    # $argv[1] = command string
    # $argv[2] = exit code
    if test $argv[2] -ne 0
        echo "Command FAILED (exit $argv[2]): $argv[1]"
    end
end
```

### Variable Change Events

```fish
# Fires whenever $PWD changes (i.e., on every cd)
function on_directory_change --on-variable PWD
    status is-interactive; or return
    # Auto-show directory contents:
    ls
end

# Fires when $EDITOR changes
function on_editor_change --on-variable EDITOR
    echo "Editor switched to: $EDITOR"
end
```

### Custom Events (Fire Your Own)

```fish
# Define a listener
function on_build_done --on-event build_complete
    echo "Build finished! Status: $argv[1]"
    # Could send a notification, play sound, etc.
end

# Fire the event from anywhere
function build
    make $argv
    set -l result $status
    emit build_complete $result   # ← fires the event
    return $result
end
```

### Job Events

```fish
# Fires when a background job completes
function notify_job_done --on-job-exit %self
    echo "Background job finished"
end
```

---

## 12. Completions — Write Your Own

### Completion Function Conditions

Fish provides helper functions to use in `-n` (condition):

```fish
# __fish_use_subcommand       → no subcommand given yet
# __fish_seen_subcommand_from → specific subcommand was given
# __fish_is_first_arg         → completing the first argument
# __fish_complete_path        → complete paths
# __fish_complete_directories → complete only directories
```

### Full Example: Custom CLI Tool Completions

```fish
# ~/.config/fish/completions/myapp.fish

# Disable file completion by default for this command
complete -c myapp -f

# Subcommands (shown when no subcommand given)
complete -c myapp -n "__fish_use_subcommand" \
    -a "run"    -d "Run the application"
complete -c myapp -n "__fish_use_subcommand" \
    -a "build"  -d "Build the project"
complete -c myapp -n "__fish_use_subcommand" \
    -a "config" -d "Manage configuration"

# Global flags (available everywhere)
complete -c myapp -l help    -s h -d "Show help"
complete -c myapp -l verbose -s v -d "Verbose output"

# Flags specific to 'run'
complete -c myapp -n "__fish_seen_subcommand_from run" \
    -l port -s p -r -d "Port number"
complete -c myapp -n "__fish_seen_subcommand_from run" \
    -l env  -s e -r -d "Environment" \
    -a "dev staging prod"    # ← fixed value completions

# Flags specific to 'build'
complete -c myapp -n "__fish_seen_subcommand_from build" \
    -l output -s o -r -d "Output directory"
complete -c myapp -n "__fish_seen_subcommand_from build" \
    -l target -r -d "Build target" \
    -a "(myapp targets 2>/dev/null)"  # ← dynamic completions!
```

### Dynamic Completions at Runtime

```fish
# Complete with current git branches
complete -c git-deploy -a "(git branch --format='%(refname:short)' 2>/dev/null)"

# Complete running process names
complete -c mykill -a "(ps -eo comm= | sort -u)"

# Complete files with specific extension, with description
complete -c myapp -a "(
    for f in *.conf
        echo $f\t(head -1 $f)   # filename TAB first line as description
    end
)"
```

---

## 13. Prompts — fish_prompt & fish_right_prompt

### Build Your Own Prompt from Scratch

```fish
# ~/.config/fish/functions/fish_prompt.fish

function fish_prompt
    # Colors using set_color
    set_color --bold cyan
    echo -n (whoami)

    set_color normal
    echo -n "@"

    set_color --bold blue
    echo -n (hostname -s)

    set_color normal
    echo -n ":"

    # Shorten path: replace $HOME with ~
    set_color --bold green
    echo -n (string replace -r "^$HOME" "~" $PWD)

    # Git branch if inside a repo
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1
        set_color normal
        echo -n " on "
        set_color --bold magenta
        echo -n " "(git branch --show-current 2>/dev/null)
    end

    # Show exit code of last command if non-zero
    if test $status -ne 0
        set_color --bold red
        echo -n " [$status]"
    end

    set_color normal
    echo -n " ❯ "
end
```

### Right Prompt

```fish
# ~/.config/fish/functions/fish_right_prompt.fish

function fish_right_prompt
    # Show current time on the right
    set_color --dim white
    echo -n (date "+%H:%M:%S")
    set_color normal
end
```

### set_color Reference

```fish
set_color red              # named colors: red, green, blue, yellow, magenta, cyan, white
set_color FF5555           # hex color
set_color --bold red       # bold
set_color --italic cyan    # italic
set_color --dim white      # dimmed
set_color --underline      # underline
set_color --reverse        # reversed fg/bg
set_color normal           # reset ALL attributes
set_color brred            # bright red (brblue, brgreen, etc.)

# Check if terminal supports colors
if set_color --print-colors > /dev/null 2>&1
    echo "Colors supported"
end
```

---

## 14. Key Bindings — bind Mastery

```fish
# Show all current bindings
bind

# Show bindings for a specific mode
bind -M insert
bind -M default

# Bind a key to a fish function
bind \cb "commandline -f beginning-of-line"

# Bind to a shell command
bind \cg "git status; commandline -f repaint"

# Bind to a fish function (defined elsewhere)
function __my_action
    commandline "ls -la"
    commandline -f execute
end
bind \co __my_action

# Common escape sequences:
# \c + letter = Ctrl+letter  (e.g., \cl = Ctrl+L)
# \e + letter = Alt+letter   (e.g., \ef = Alt+F)
# \cH = Ctrl+H (same as Backspace on many terms)
# \e[A = Up arrow
# \e[B = Down arrow
# \e[C = Right arrow
# \e[D = Left arrow

# Bind in specific mode only (-M insert, -M default, -M visual)
bind -M insert \cf forward-char

# Erase a binding
bind -e \cb

# Useful commandline -f functions:
# beginning-of-line, end-of-line
# forward-char, backward-char
# forward-word, backward-word
# kill-line, backward-kill-line
# kill-word, backward-kill-word
# yank (paste), yank-pop
# undo, redo
# accept-autosuggestion
# complete (trigger completion)
# execute
# repaint
# up-or-search, down-or-search
```

---

## 15. Conditionals & Test Expressions

### test / [ ] — Full Reference

```fish
# File tests
test -e path          # exists (any type)
test -f path          # regular file
test -d path          # directory
test -l path          # symlink
test -r path          # readable
test -w path          # writable
test -x path          # executable
test -s path          # non-empty file
test file1 -nt file2  # file1 newer than file2
test file1 -ot file2  # file1 older than file2

# String tests
test -z "$str"        # empty string
test -n "$str"        # non-empty string
test "$a" = "$b"      # equal
test "$a" != "$b"     # not equal

# Numeric tests
test $a -eq $b        # equal
test $a -ne $b        # not equal
test $a -lt $b        # less than
test $a -le $b        # less than or equal
test $a -gt $b        # greater than
test $a -ge $b        # greater than or equal

# Combining
test -f file -a -r file   # AND
test -f file -o -d file   # OR
not test -f file           # NOT

# In if statements
if test -f ~/.config/fish/config.fish
    echo "config exists"
end
```

### command -v — Check if Command Exists

```fish
# Check if command is available
if command -v nvim > /dev/null 2>&1
    echo "nvim is installed"
end

# One-liner
command -v git > /dev/null; and echo "git found"

# Set variable based on available tool
if command -v bat > /dev/null 2>&1
    set -gx PAGER bat
else
    set -gx PAGER less
end
```

---

## 16. Loops & Iteration Patterns

### for — Over Lists

```fish
# Over explicit list
for fruit in apple banana cherry
    echo "Fruit: $fruit"
end

# Over files
for file in *.md
    echo "Markdown: $file"
end

# Over a range
for i in (seq 1 10)
    echo "Number $i"
end

# Reverse range
for i in (seq 10 -1 1)
    echo "Countdown: $i"
end

# Over command output
for pid in (pgrep firefox)
    echo "Firefox PID: $pid"
end

# Over lines in a file
for line in (cat /etc/hosts)
    echo $line
end
# Better for preserving whitespace:
while read -l line
    echo $line
end < /etc/hosts

# Skip with continue
for f in *.txt
    test -s $f; or continue   # skip empty files
    echo "Processing: $f"
end

# Break early
for i in (seq 1 100)
    if test $i -eq 5
        break
    end
    echo $i
end
```

### while — Condition-Based

```fish
# Basic while
set i 0
while test $i -lt 5
    set i (math $i + 1)
    echo $i
end

# Read lines from command
command | while read -l line
    echo "Got: $line"
end

# Infinite loop with break
while true
    read -P "Enter command (q to quit): " cmd
    if test "$cmd" = "q"
        break
    end
    eval $cmd
end

# Retry until success (with max attempts)
set attempts 0
while not ping -c1 google.com > /dev/null 2>&1
    set attempts (math $attempts + 1)
    if test $attempts -ge 5
        echo "Failed after 5 attempts"
        break
    end
    echo "Attempt $attempts failed, retrying..."
    sleep 2
end
```

---

## 17. Error Handling & Exit Codes

```fish
# $status holds exit code of the last command
ls /nonexistent
echo $status    # 2

# Check immediately after
if test $status -ne 0
    echo "Command failed!"
end

# But beware — $status is overwritten by test itself:
ls /nonexistent
set -l exit_code $status   # save it immediately!
if test $exit_code -ne 0
    echo "Failed with code: $exit_code"
end

# Return from a function with a code
function divide
    if test $argv[2] -eq 0
        echo "Error: division by zero" >&2
        return 1
    end
    math $argv[1] / $argv[2]
    return 0
end

divide 10 2; echo "Exit: $status"   # 5 / Exit: 0
divide 10 0; echo "Exit: $status"   # Error... / Exit: 1

# stderr output (errors should go to stderr)
echo "Something went wrong" >&2

# Propagate errors
function risky_operation
    some_command; or return $status   # propagate failure
    another_command
end

# Set exit code from script
function main
    if not do_something
        return 1
    end
    return 0
end
```

---

## 18. Math & Arithmetic

Fish has a `math` builtin (powered by `bc`-style evaluation):

```fish
# Basic
math 2 + 2          # 4
math 10 - 3         # 7
math 5 \* 6         # 30 (escape * or use quotes)
math "5 * 6"        # 30
math 17 / 4         # 4.25
math 17 % 4         # 1 (modulo)
math 2 ^ 10         # 1024 (power)

# Integer mode
math --scale=0 "17/4"    # 4 (truncate)
math --scale=2 "1/3"     # 0.33

# Functions
math "sqrt(144)"          # 12
math "ceil(4.2)"          # 5
math "floor(4.8)"         # 4
math "round(4.5)"         # 5
math "abs(-42)"           # 42
math "log(100)"           # 4.60517...
math "log2(1024)"         # 10
math "sin(pi/2)"          # 1
math "max(3, 7, 2)"       # 7
math "min(3, 7, 2)"       # 2

# With variables
set x 10
set y 3
math $x + $y        # 13
math $x \* $y       # 30
math "$x ^ $y"      # 1000

# Increment pattern
set counter 0
set counter (math $counter + 1)

# Hex / octal
math "0xFF"         # 255
math "0o17"         # 15
math "0b1010"       # 10 (binary)

# Output as hex
math --base=16 255  # ff
math --base=2  10   # 1010
```

---

## 19. Background Jobs & Job Control

```fish
# Run in background
sleep 60 &
echo "PID: $last_pid"   # PID of backgrounded job

# List background jobs
jobs
# Output: Job 1  [running]  sleep 60

# Bring job to foreground
fg              # most recent job
fg %1           # job number 1
fg %sleep       # job matching name

# Send to background (after stopping with Ctrl+Z)
bg              # resume most recent stopped job in background
bg %1           # specific job

# Kill background job
kill %1         # by job number
kill $last_pid  # by PID
kill %sleep     # by name

# Wait for all background jobs to finish
wait

# Wait for a specific job
wait $last_pid

# Disown — detach from terminal (keeps running after logout)
sleep 1000 &
disown          # detach from terminal
disown %1       # specific job
disown $last_pid

# Check if job is still running
jobs | grep -q "sleep"; and echo "still running"

# Run command in background, redirect output
long_task > /tmp/output.log 2>&1 &
echo "Task running as PID $last_pid. See /tmp/output.log"
```

---

## 20. Universal Variables — Persistent Config

Universal variables survive terminal restarts and are **shared across all fish sessions simultaneously**.

```fish
# Set (automatically persisted)
set -U THEME dark
set -U FONT_SIZE 14
set -U MY_PROJECTS ~/code/proj1 ~/code/proj2

# Read — same as any variable
echo $THEME

# They update LIVE in all open terminals
# Set in terminal 1, immediately available in terminal 2

# See all universal variables
set -U

# Unset
set -e -U THEME

# Universal variables are stored in:
# ~/.config/fish/fish_variables

# Use for user preferences that should persist
set -U fish_color_command green    # make valid commands green
set -U fish_color_error red        # errors in red
```

### Fish Color Variables

```fish
# Customize syntax highlighting colors:
set -U fish_color_command        green        # valid commands
set -U fish_color_error          red          # invalid commands
set -U fish_color_param          normal       # arguments
set -U fish_color_quote          yellow       # quoted strings
set -U fish_color_redirection    cyan         # > >> |
set -U fish_color_comment        brblack      # # comments
set -U fish_color_operator       normal       # & etc.
set -U fish_color_escape         magenta      # \n etc.
set -U fish_color_autosuggestion brblack      # greyed suggestion
set -U fish_color_selection      --background=blue   # visual select

# Or just use the web UI:
fish_config
```

---

## 21. fish_config — Web UI

```fish
fish_config
# Opens a browser-based configuration UI at http://localhost:8000

# Lets you:
# - Choose prompt style
# - Preview and set color themes
# - View/edit abbreviations
# - View history
# - View defined functions
```

---

## 22. Useful One-Liners & Patterns

```fish
# ── File & Text ──────────────────────────────────────────────────────────────

# Count files in directory
count (ls)
ls | wc -l

# Find files larger than 100MB
for f in **/*
    test -f $f; and test (stat -c %s $f) -gt 104857600; and echo $f
end

# Rename all .txt to .md
for f in *.txt
    mv $f (string replace ".txt" ".md" $f)
end

# Remove trailing whitespace from all .fish files
for f in *.fish
    sed -i 's/[[:space:]]*$//' $f
end

# ── Network ──────────────────────────────────────────────────────────────────

# My public IP
curl -s ifconfig.me

# Show open ports
ss -tlnp

# Download file, show progress
curl -L --progress-bar -o output.zip "https://example.com/file.zip"

# ── Process ──────────────────────────────────────────────────────────────────

# Kill process by name
kill (pgrep firefox)

# Memory usage by process
ps aux | sort -k 6 -rn | head -10

# ── Fish-specific ─────────────────────────────────────────────────────────────

# Re-run last command
eval $history[1]

# Edit last command in $EDITOR, then run
fc

# Run last command with sudo
sudo $history[1]

# Echo current fish startup time
time fish -c ""

# Find which config file defines a function
grep -r "function greet" ~/.config/fish/

# Reload config without restarting
source ~/.config/fish/config.fish

# ── String tricks ─────────────────────────────────────────────────────────────

# Extract filename without extension
set file "document.pdf"
set name (string replace -r '\.[^.]+$' '' $file)
echo $name    # document

# Extract extension
set ext (string match -r '\.[^.]+$' $file)
echo $ext     # .pdf

# URL-decode a string
string unescape --style=url "hello%20world"   # hello world

# Count words in a string
string split " " "the quick brown fox" | count  # 4

# Repeat a character N times
string repeat -n 40 "─"   # ────────────────────────────────────────
```

---

## 23. Debugging Fish Scripts

```fish
# ── Print Tracing (like bash -x) ─────────────────────────────────────────────

# Enable print-each-command tracing
fish --debug=1 my_script.fish

# Or add to top of script:
set fish_trace 1     # Print every command before running
...code...
set fish_trace 0     # Disable

# Verbose error messages
fish --debug=reader myscript.fish

# ── Check Syntax Without Running ──────────────────────────────────────────────

fish --parse my_script.fish    # parse-only, no execution

# ── Print Intermediate Values ─────────────────────────────────────────────────

function debug_var
    printf "[DEBUG] %s = %s\n" $argv[1] $$argv[1] >&2
end

set myvar "hello"
debug_var myvar   # [DEBUG] myvar = hello

# ── Using status ─────────────────────────────────────────────────────────────

# After every risky command:
some_command
set -l s $status
echo "Exit code: $s" >&2

# ── stderr vs stdout ──────────────────────────────────────────────────────────

# All debug output should go to stderr so it doesn't pollute pipelines:
echo "Debug info" >&2

# ── Type Checking ─────────────────────────────────────────────────────────────

# What is this thing?
type mycommand
# → mycommand is a function
# → mycommand is a builtin
# → mycommand is /usr/bin/mycommand

# Where is it defined?
type -a mycommand    # show all matches (builtin, function, external)
type -P mycommand    # only show PATH match

# ── Profile Slow Startup ──────────────────────────────────────────────────────

# Find what's slowing down config.fish
fish --profile /tmp/fish_profile.log -c ""
cat /tmp/fish_profile.log | sort -rn | head -20
```

---

## 24. Performance & Startup Speed

### Measure Startup

```fish
# Time a single startup
time fish -c ""

# Average over 10 runs
for i in (seq 10); time fish -c ""; end 2>&1 | grep real | awk '{print $2}'
```

### Common Causes of Slow Startup & Fixes

```fish
# ❌ SLOW: running a tool every startup
eval (brew shellenv)           # spawns brew process
eval (starship init fish)      # spawns starship process

# ✅ FAST: cache the output in a file
set -l cache ~/.config/fish/starship_init.fish
if not test -f $cache
    starship init fish --print-full-init > $cache
end
source $cache

# ── Lazy Loading ─────────────────────────────────────────────────────────────

# ❌ SLOW: source everything at startup
source ~/.config/fish/big_functions.fish

# ✅ FAST: autoload — fish will find functions/ dir automatically
# Just put functions in: ~/.config/fish/functions/myfunction.fish
# Fish loads them ON DEMAND, not at startup!

# ── Avoid External Commands in Prompt ─────────────────────────────────────────

# ❌ SLOW: running git in every prompt (calls git every render)
function fish_prompt
    echo (git branch --show-current)  # slow!
end

# ✅ FAST: cache the value, or use fish's built-in __fish_git_prompt
function fish_prompt
    echo (__fish_git_prompt "%s")   # built-in, optimized
end

# ── Universal Variables vs set -gx ────────────────────────────────────────────

# ❌ set -gx in config.fish for things that never change
# → Re-executes every session

# ✅ Use set -U for static config (only writes once, reads instantly)
set -U EDITOR nvim

# ── Command Caching Pattern ───────────────────────────────────────────────────

# Generic cache helper function
function cached_init -d "Cache expensive command output"
    set -l cmd $argv[1]
    set -l cache_file "$HOME/.config/fish/"(string replace -ra '[^a-zA-Z0-9]' '_' $cmd)"_init.fish"

    set -l bin_path (command -v $cmd 2>/dev/null)
    if test -z "$bin_path"
        return 1   # command not found
    end

    if not test -f "$cache_file"; or test "$bin_path" -nt "$cache_file"
        $cmd init fish --print-full-init > "$cache_file" 2>/dev/null
    end

    source "$cache_file"
end

# Use it for any tool that has "init fish" support:
cached_init starship
cached_init zoxide
cached_init direnv
```

---

## 🎓 Learning Path Summary

```
Level 1 — Basics
  ✅ Tab completion & autosuggestions
  ✅ History search (Ctrl+R, ↑ with prefix)
  ✅ Variables: set, $status, $argv
  ✅ Simple functions, funcsave
  ✅ Abbreviations (abbr)

Level 2 — Intermediate
  ✅ string builtin (replace, split, match, sub)
  ✅ Brace expansion & globbing
  ✅ argparse for flag parsing
  ✅ Event handlers (--on-variable, --on-event)
  ✅ Custom completions

Level 3 — Advanced
  ✅ Process substitution with psub
  ✅ Universal variables for persistent config
  ✅ Custom fish_prompt & fish_right_prompt
  ✅ Custom bind for key bindings
  ✅ Performance profiling & caching patterns
  ✅ Debugging with fish_trace & --parse
```

---

*Fish 4.x • shell-ninja's deep reference — September 2026.*
