# ~/.config/fish/functions.fish

#==============================================================================
# ███████╗██╗  ██╗███████╗██╗     ██╗     
# ██╔════╝██║  ██║██╔════╝██║     ██║     
# ███████╗███████║█████╗  ██║     ██║     
# ╚════██║██╔══██║██╔══╝  ██║     ██║     
# ███████║██║  ██║███████╗███████╗███████╗
# ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
#                                         
# ███╗   ██╗██╗███╗   ██╗     ██╗ █████╗  
# ████╗  ██║██║████╗  ██║     ██║██╔══██╗ 
# ██╔██╗ ██║██║██╔██╗ ██║     ██║███████║ 
# ██║╚██╗██║██║██║╚██╗██║██   ██║██╔══██║ 
# ██║ ╚████║██║██║ ╚████║╚█████╔╝██║  ██║ 
# ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═╝                                                       
#==============================================================================

# ----------------- Shell Ninja Color Palette (Cyber-Purple & Neon Cyan)
set -g red      (printf "\e[1;38;2;247;118;142m")   # Crimson error
set -g green    (printf "\e[1;38;2;166;227;161m")   # Soft emerald
set -g yellow   (printf "\e[1;38;2;224;175;104m")   # Warm gold
set -g blue     (printf "\e[1;38;2;122;162;247m")   # Soft azure
set -g magenta  (printf "\e[1;38;2;232;121;249m")   # Vibrant violet-magenta
set -g cyan     (printf "\e[1;38;2;125;207;255m")   # Neon glacier cyan
set -g purple   (printf "\e[1;38;2;189;147;249m")   # Electric neon purple (primary accent)
set -g lavender (printf "\e[1;38;2;203;166;247m")   # Soft lavender (secondary accent)
set -g slate    (printf "\e[38;2;98;114;164m")      # Tokyo Night slate
set -g muted    (printf "\e[38;2;108;112;134m")     # Dim grey
set -g white    (printf "\e[1;37m")
set -g bold     (printf "\e[1m")
set -g dim      (printf "\e[2m")
set -g end      (printf "\e[0m")

# message function
function msg -a actn
    set -l text (string join " " $argv[2..-1])

    switch "$actn"
        case act
            printf "%s→%s %s\n" "$cyan" "$end" "$text"
        case ask
            printf "%s?%s %s\n" "$purple" "$end" "$text"
        case dn ok
            printf "%s✓%s %s\n" "$green" "$end" "$text"
        case att
            printf "%s<>%s %s\n" "$lavender" "$end" "$text"
        case nt info
            printf "%sℹ%s %s\n" "$blue" "$end" "$text"
        case skp skip
            printf "%s·[]%s %s\n" "$muted" "$end" "$text"
        case err error
            printf "%s✗%s %s\n" "$red" "$end" "$text"
        case warn warning
            printf "%s⚠%s %s\n" "$yellow" "$end" "$text"
        case cncl cancel
            printf "%s><%s %s\n" "$red" "$end" "$text"
        case '*'
            printf "%s\n" "$text"
    end
end


# --- internal helper: ensure root/sudo privileges using gum if installed ---
function _ensure_sudo
    if test (id -u) -eq 0
        return 0
    end
    if sudo -n true 2>/dev/null
        return 0
    end

    if command -v gum >/dev/null 2>&1
        set -l max_attempts 3
        set -l attempt 1
        while test $attempt -le $max_attempts
            set -l pwd (gum input --password --placeholder "Enter root/sudo password" --prompt (printf "$purple Password: $end"))
            if test $status -ne 0 -o -z "$pwd"
                msg cncl "Authentication aborted."
                return 1
            end
            if echo "$pwd" | sudo -S -v 2>/dev/null
                return 0
            else
                msg err (printf "Incorrect password. Try again (%d/%d)." $attempt $max_attempts)
            end
            set attempt (math $attempt + 1)
        end
        msg err "Authentication failed."
        return 1
    else
        sudo -v
        return $status
    end
end

# --- internal helper: sync dirty pages to disk with a progress bar ---
function _sync_progress -a need_sudo
    set -l dirty_init (awk '/Dirty:/ {print $2}' /proc/meminfo 2>/dev/null; or echo 0)
    test -z "$dirty_init"; and set dirty_init 0

    # Start sync in background
    if test "$need_sudo" = "1"
        sudo sync &
    else
        sync &
    end
    set -l sync_pid $last_pid

    set -l width 35
    if test $dirty_init -lt 2048
        if command -v gum >/dev/null 2>&1
            gum spin --spinner dot --title "Syncing dirty pages to disk..." -- wait $sync_pid
        else
            wait $sync_pid 2>/dev/null
        end
        msg dn "Sync complete."
        return 0
    end

    msg act "Flushing dirty pages to disk..."
    while kill -0 $sync_pid 2>/dev/null
        set -l dirty_curr (awk '/Dirty:/ {print $2}' /proc/meminfo 2>/dev/null; or echo 0)
        test -z "$dirty_curr"; and set dirty_curr 0
        set -l flushed (math "$dirty_init - $dirty_curr")
        test $flushed -lt 0; and set flushed 0

        set -l pct (math -s0 "min(100, max(0, ($flushed * 100) / $dirty_init))" 2>/dev/null; or echo 0)
        set -l filled (math -s0 "min($width, max(0, ($pct * $width) / 100))" 2>/dev/null; or echo 0)
        set -l empty (math "$width - $filled")

        set -l bar_filled (string repeat -n $filled "█")
        set -l bar_empty (string repeat -n $empty "░")
        set -l mb_flushed (math -s1 "$flushed / 1024")
        set -l mb_total (math -s1 "$dirty_init / 1024")
        printf "\r  [%s%s%s%s%s%s] %s%3d%%%s (%sM / %sM)" "$cyan" "$bar_filled" "$end" "$muted" "$bar_empty" "$end" "$yellow" $pct "$end" $mb_flushed $mb_total
        sleep 0.15
    end
    wait $sync_pid 2>/dev/null

    set -l bar_full (string repeat -n $width "█")
    set -l mb_total (math -s1 "$dirty_init / 1024")
    printf "\r  [%s%s%s] %s100%%%s (%sM / %sM)\n" "$cyan" "$bar_full" "$end" "$yellow" "$end" $mb_total $mb_total
    msg dn "Sync complete."
end

# --- copy-paste with automatic sudo elevation, file/dir mode detection, and ISO sync ---
function fn_copy_paste
    if contains -- --help $argv; or contains -- -h $argv; or contains -- --version $argv
        command cp $argv
        return $status
    end

    set -l opts
    set -l targets
    set -l after_double_dash 0

    for arg in $argv
        if test $after_double_dash -eq 1
            set -a targets "$arg"
        else if test "$arg" = "--"
            set after_double_dash 1
        else if string match -q -- "-*" "$arg"
            set -a opts "$arg"
        else
            set -a targets "$arg"
        end
    end

    if test (count $targets) -lt 2
        command cp $argv
        return $status
    end

    set -l sources $targets[1..-2]
    set -l destination $targets[-1]

    # Normalize trailing slash for checks if needed, but preserve knowledge of trailing slash
    set -l has_trailing_slash 0
    if string match -q '*/' -- "$destination"
        set has_trailing_slash 1
    end
    set -l dest_clean (string trim --right --chars=/ -- "$destination")

    # Detect if any source is a directory
    set -l has_directory 0
    for src in $sources
        if test -d "$src"
            set has_directory 1
            break
        end
    end

    # Detect if any source is an ISO file and destination is a directory
    set -l has_iso 0
    for src in $sources
        if test -f "$src"; and string match -qi "*.iso" -- "$src"
            set has_iso 1
            break
        end
    end

    set -l is_dest_dir 0
    if test -d "$dest_clean"; or test $has_trailing_slash -eq 1; or test (count $sources) -gt 1
        set is_dest_dir 1
    end

    # Check whether root access (sudo) is needed
    set -l need_sudo 0
    if test (id -u) -ne 0
        # 1. Check sources readability / searchability
        for src in $sources
            if not test -r "$src"
                set need_sudo 1
                break
            end
            if test -d "$src"; and not test -x "$src"
                set need_sudo 1
                break
            end
            set -l owner (stat -c '%u' "$src" 2>/dev/null; or echo 1)
            if test "$owner" -eq 0 -a ! -r "$src"
                set need_sudo 1
                break
            end
        end

        # 2. Check destination writability
        if test $need_sudo -eq 0
            if test -e "$dest_clean"
                if test -d "$dest_clean"
                    if not test -w "$dest_clean"; or not test -x "$dest_clean"
                        set need_sudo 1
                    else
                        # Check if any existing target file inside dest_clean is not writable
                        for src in $sources
                            set -l target_file "$dest_clean/"(basename -- "$src")
                            if test -e "$target_file" -a ! -w "$target_file"
                                set need_sudo 1
                                break
                            end
                        end
                    end
                else
                    if not test -w "$dest_clean"
                        set need_sudo 1
                    end
                end
            else
                # Destination does not exist yet; find nearest existing parent directory
                set -l check_dir (dirname -- "$dest_clean")
                while not test -d "$check_dir" -a "$check_dir" != "/"
                    set check_dir (dirname -- "$check_dir")
                end
                if not test -w "$check_dir"; or not test -x "$check_dir"
                    set need_sudo 1
                end
            end
        end
    end

    # If root access is needed, ensure sudo authentication via gum / fallback
    if test $need_sudo -eq 1
        if not _ensure_sudo
            return 1
        end
    end

    # If destination had trailing slash and doesn't exist, create it
    if test $has_trailing_slash -eq 1 -a ! -d "$dest_clean"
        if test $need_sudo -eq 1
            sudo mkdir -p "$destination"
        else
            command mkdir -p "$destination"
        end
    end

    # Prepare command arguments: add -r if any source is a directory
    set -l final_args
    if test $has_directory -eq 1
        # Add -r if not already present in options
        if not contains -- -r $opts; and not contains -- -R $opts; and not contains -- -a $opts
            set final_args -r $opts $targets
        else
            set final_args $opts $targets
        end
    else
        # Only files: run cp only
        set final_args $opts $targets
    end

    # Execute copy (using sudo if root access needed)
    if test $need_sudo -eq 1
        sudo cp $final_args
    else
        command cp $final_args
    end
    set -l cp_status $status

    # If copying was successful and an ISO was copied to a directory, offer sync
    if test $cp_status -eq 0 -a $has_iso -eq 1 -a $is_dest_dir -eq 1
        set -l do_sync 0
        if command -v gum >/dev/null 2>&1
            if gum confirm (printf "  %s?%s ISO file copied. Do you want to sync changes to disk?" "$purple" "$end")
                set do_sync 1
            end
        else
            read -P (printf "  %s?%s ISO file copied. Do you want to sync changes to disk? [y/N]: " "$purple" "$end") -l ans
            if string match -qi "y" "$ans"; or string match -qi "yes" "$ans"
                set do_sync 1
            end
        end

        if test $do_sync -eq 1
            _sync_progress $need_sudo
        end
    end

    return $cp_status
end

# --- remove files and directories safely with confirmation warning and root detection ---
function fn_removal
    if test (count $argv) -eq 0
        msg err "Usage: rm <file|dir> ..."
        return 1
    end

    if contains -- --help $argv; or contains -- -h $argv; or contains -- --version $argv
        command rm $argv
        return $status
    end

    set -l opts
    set -l items
    set -l after_double_dash 0

    for arg in $argv
        if test $after_double_dash -eq 1
            set -a items "$arg"
        else if test "$arg" = "--"
            set after_double_dash 1
        else if string match -q -- "-*" "$arg"
            set -a opts "$arg"
        else
            set -a items "$arg"
        end
    end

    if test (count $items) -eq 0
        command rm $opts
        return $status
    end

    # Provide confirmation warning before proceeding
    echo
    msg warn "You are about to permanently delete the following:"
    for item in $items
        if test -d "$item" -a ! -L "$item"
            printf "$purple [ DIR ] $end  $item\n"
        else if test -L "$item"
            printf "$cyan [ LINK ] $end  $item\n"
        else if test -e "$item"
            printf "$greed [ FILE ] $end  $item\n"
        else
            printf "$muted [ UNKNOWN ] $end  $item\n"
        end
    end

    set -l confirmed 0
    if command -v gum >/dev/null 2>&1
    echo
        if gum confirm --default=false (printf "%s?%s Are you sure you want to delete these item(s)?" "$purple" "$end")
            set confirmed 1
        end
    else
    echo
        read -P (printf "%s?%s Are you sure you want to delete these item(s)? [Y/N]: " "$purple" "$end") -l ans
        if string match -qi "y" "$ans"; or string match -qi "yes" "$ans"
            set confirmed 1
        end
    end

    if test $confirmed -ne 1
        msg cncl "Deletion aborted."
        return 0
    end

    # Check if any item requires root access
    set -l any_need_sudo 0
    if test (id -u) -ne 0
        for item in $items
            set -l parent (dirname -- "$item")
            if not test -w "$parent"; or not test -x "$parent"
                set any_need_sudo 1
                break
            end
            if test -e "$item" -o -L "$item"
                set -l owner (stat -c '%u' "$item" 2>/dev/null; or echo 1)
                if test "$owner" -eq 0 -a ! -w "$item"
                    set any_need_sudo 1
                    break
                end
            end
            if test -d "$item" -a ! -L "$item"
                if not test -w "$item"; or not test -r "$item"; or not test -x "$item"
                    set any_need_sudo 1
                    break
                end
            end
        end
    end

    if test $any_need_sudo -eq 1
        if not _ensure_sudo
            return 1
        end
    end

    for item in $items
        # Determine whether this item requires sudo
        set -l item_need_sudo 0
        if test (id -u) -ne 0
            set -l parent (dirname -- "$item")
            if not test -w "$parent"; or not test -x "$parent"
                set item_need_sudo 1
            else if test -e "$item" -o -L "$item"
                set -l owner (stat -c '%u' "$item" 2>/dev/null; or echo 1)
                if test "$owner" -eq 0 -a ! -w "$item"
                    set item_need_sudo 1
                end
            end
            if test -d "$item" -a ! -L "$item"
                if not test -w "$item"; or not test -r "$item"; or not test -x "$item"
                    set item_need_sudo 1
                end
            end
        end

        if test $item_need_sudo -eq 1
            if test -d "$item" -a ! -L "$item"
                msg act "Removing directory: $item"
                sudo rm -rf $opts "$item"
            else if test -e "$item" -o -L "$item"
                msg act "Removing file: $item"
                sudo rm $opts "$item"
            else
                msg err "$item does not exist"
            end
        else
            if test -d "$item" -a ! -L "$item"
                msg act "Removing directory: $item"
                command rm -rf $opts "$item"
            else if test -e "$item" -o -L "$item"
                msg act "Removing file: $item"
                command rm $opts "$item"
            else
                msg err "$item does not exist"
            end
        end
    end
end

# disk and memory resources
function fn_resources
    switch "$argv[1]"
        case disk __disk
            df -h / | awk 'NR==2 {printf "Total: %s\nUsed: %s\nFree: %s\n", $2, $3, $4}'
        case memory __memory
            free -h | awk '/^Mem:/ {printf "Total: %s\nUsed: %s\nFree: %s\n", $2, $3, $7}'
        case '*'
            printf "Usage: fn_resources <disk|memory>\n"
            return 1
    end
end

# internal: detect package manager
function _detect_pkg_manager
    if set -q PKG_MANAGER
        return
    end

    if command -v pacman >/dev/null 2>&1
        set -gx PKG_MANAGER "pacman"
        set -l aur (command -v yay 2>/dev/null; or command -v paru 2>/dev/null)
        set -gx AUR_HELPER "$aur"
    else if command -v dnf >/dev/null 2>&1
        set -gx PKG_MANAGER "dnf"
    else if command -v zypper >/dev/null 2>&1
        set -gx PKG_MANAGER "zypper"
    else if command -v apt-get >/dev/null 2>&1
        set -gx PKG_MANAGER "apt"
    else
        set -gx PKG_MANAGER "unknown"
    end
end

# check updates
function fn_check_updates
    _detect_pkg_manager
    switch "$PKG_MANAGER"
        case pacman
            set -l ofc 0
            if command -v checkupdates >/dev/null 2>&1
                set ofc (checkupdates 2>/dev/null | wc -l)
            else
                set ofc (pacman -Qu 2>/dev/null | wc -l)
            end
            set -l aur 0
            if test -n "$AUR_HELPER"
                set aur ($AUR_HELPER -Qua 2>/dev/null | wc -l)
            end
            set -l upd (math $ofc + $aur)
            msg att (printf "You have %s%d%s updates available (Main: %d, AUR: %d)" "$green" $upd "$end" $ofc $aur)
        case dnf
            set -l upd (dnf check-update -q 2>/dev/null | grep -cv '^$')
            msg att (printf "You have %s%d%s updates available" "$green" $upd "$end")
        case zypper
            set -l upd (zypper lu --best-effort 2>/dev/null | grep -c 'v  |')
            msg att (printf "You have %s%d%s updates available" "$green" $upd "$end")
        case apt
            set -l upd (apt list --upgradable 2>/dev/null | grep -c '\[upgradable from')
            msg att (printf "You have %s%d%s updates available" "$green" $upd "$end")
        case '*'
            msg err "Unsupported package manager"
            return 1
    end
end

# package updates
function fn_update
    _detect_pkg_manager
    switch "$PKG_MANAGER"
        case pacman
            if test -n "$AUR_HELPER"
                $AUR_HELPER -Syyu --noconfirm
            else
                sudo pacman -Syyu --noconfirm
            end
        case dnf
            sudo dnf upgrade -y
        case zypper
            sudo zypper ref; and sudo zypper up -y
        case apt
            sudo apt update; and sudo apt upgrade -y
        case '*'
            msg err "Unsupported package manager"
            return 1
    end
end

# package install
function fn_install
    if test (count $argv) -eq 0
        msg err "Usage: fn_install <package...>"
        return 1
    end
    _detect_pkg_manager
    switch "$PKG_MANAGER"
        case pacman
            if test -n "$AUR_HELPER"
                $AUR_HELPER -S --noconfirm $argv
            else
                sudo pacman -S --noconfirm $argv
            end
        case dnf
            sudo dnf install -y $argv
        case zypper
            sudo zypper in -y $argv
        case apt
            sudo apt install -y $argv
        case '*'
            msg err "Unsupported package manager"
            return 1
    end
end

# package uninstall
function fn_uninstall
    if test (count $argv) -eq 0
        msg err "Usage: fn_uninstall <package...>"
        return 1
    end
    _detect_pkg_manager
    switch "$PKG_MANAGER"
        case pacman
            if test -n "$AUR_HELPER"
                $AUR_HELPER -Rns --noconfirm $argv
            else
                sudo pacman -Rns --noconfirm $argv
            end
        case dnf
            sudo dnf remove -y $argv
        case zypper
            sudo zypper rm -y $argv
        case apt
            sudo apt remove -y $argv
        case '*'
            msg err "Unsupported package manager"
            return 1
    end
end

# git info
function git_info
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        return 0
    end

    set -l branch_name (git branch --show-current 2>/dev/null)
    if test -z "$branch_name"
        set branch_name (git rev-parse --short HEAD 2>/dev/null)
    end

    if test -n "$branch_name"
        set -l untracked_count 0
        set -l unstaged_count 0
        set -l staged_count 0

        for line in (git status --porcelain 2>/dev/null)
            test -z "$line"; and continue
            set -l x (string sub -s 1 -l 1 "$line")
            set -l y (string sub -s 2 -l 1 "$line")
            if test "$x" = "?" -a "$y" = "?"
                set untracked_count (math $untracked_count + 1)
            else
                if test "$x" != " " -a "$x" != "?"
                    set staged_count (math $staged_count + 1)
                end
                if test "$y" != " " -a "$y" != "?"
                    set unstaged_count (math $unstaged_count + 1)
                end
            end
        end

        printf "on \e[1;34m\e[1;32m %s\e[1;0m " "$branch_name"

        test $untracked_count -gt 0; and printf "\e[1;31m?%d \e[3;0m" $untracked_count
        test $staged_count -gt 0; and printf "\e[1;32m%d \e[3;0m" $staged_count
        test $unstaged_count -gt 0; and printf "\e[1;33m!%d \e[3;0m" $unstaged_count

        if test $untracked_count -eq 0 -a $staged_count -eq 0 -a $unstaged_count -eq 0
            printf "\e[1;32m✓ \e[3;0m"
        end
        printf "\n"
    end
end

# git push shortcut
function push
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        msg err "Not inside a Git repository."
        return 1
    end

    set -l branch_name (git branch --show-current 2>/dev/null)
    if test -z "$branch_name"
        msg err "Detached HEAD or unknown branch. Please push manually."
        return 1
    end

    set -l untracked_count 0
    set -l unstaged_count 0
    set -l staged_count 0

    for line in (git status --porcelain 2>/dev/null)
        test -z "$line"; and continue
        set -l x (string sub -s 1 -l 1 "$line")
        set -l y (string sub -s 2 -l 1 "$line")
        if test "$x" = "?" -a "$y" = "?"
            set untracked_count (math $untracked_count + 1)
        else
            if test "$x" != " " -a "$x" != "?"
                set staged_count (math $staged_count + 1)
            end
            if test "$y" != " " -a "$y" != "?"
                set unstaged_count (math $unstaged_count + 1)
            end
        end
    end

    test $untracked_count -gt 0; and msg nt "$untracked_count untracked files"
    test $unstaged_count -gt 0; and msg nt "$unstaged_count uncommitted changes"
    test $staged_count -gt 0; and msg nt "$staged_count staged changes"

    if test $untracked_count -eq 0 -a $unstaged_count -eq 0 -a $staged_count -eq 0
        msg dn "Nothing to push."
        return 0
    end

    msg ask "$branch_name branch — Write the commit message:"

    set -l msg_text ""
    if command -v gum >/dev/null 2>&1
        set msg_text (gum input --placeholder "Write your commit message")
    else
        read -P "=> " msg_text
    end

    if test -z "$msg_text"
        msg err "Aborting due to empty commit message."
        return 1
    end

    git add .
    if not git commit -m "$msg_text"
        msg err "Commit failed."
        return 1
    end

    git push origin "$branch_name"
    set -l pstatus $status

    if test $pstatus -eq 0
        set -l sound "$HOME/.config/fish/fah.mp3"
        if test -f "$sound"
            if command -v pw-play >/dev/null 2>&1; pw-play "$sound" >/dev/null 2>&1 &
            else if command -v paplay >/dev/null 2>&1; paplay "$sound" >/dev/null 2>&1 &
            else if command -v aplay >/dev/null 2>&1; aplay "$sound" >/dev/null 2>&1 &
            else if command -v ffplay >/dev/null 2>&1; ffplay -nodisp -autoexit "$sound" >/dev/null 2>&1 &
            end
        end
        msg dn "Pushed successfully!"
    else
        msg err "Push failed. Please check for errors."
    end
end

# yazi wrapper
function y
    set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if test -f "$tmp"
        set -l cwd (cat -- "$tmp")
        if test -n "$cwd" -a "$cwd" != "$PWD"
            builtin cd -- "$cwd"
        end
        command rm -f -- "$tmp"
    end
end

# fastfetch wrapper
function fastfetch
    set -l preset_dir "$HOME/.local/share/fastfetch/presets"
    if test (count $argv) -eq 0 -a -n "$ffconfig" -a -d "$preset_dir"
        if test -f "$preset_dir/$ffconfig.jsonc"
            command fastfetch --config "$preset_dir/$ffconfig.jsonc"
        else
            command fastfetch --config "$ffconfig"
        end
    else
        command fastfetch $argv
    end
end

# fastfetch style switcher (uses fzf when available, falls back to numbered menu)
# Persists selection via fish universal variable (set -U ffconfig)
function ffstyle
    set -l preferredDir "$HOME/.local/share/fastfetch/presets"
    if not test -d "$preferredDir"
        printf "Preset directory not found: %s\n" "$preferredDir"
        return 1
    end

    set -l presets
    for preset in "$preferredDir"/*.jsonc
        test -f "$preset"; or continue
        set -a presets (basename "$preset" .jsonc)
    end

    if test (count $presets) -eq 0
        printf "No presets found in %s\n" "$preferredDir"
        return 1
    end

    set -l selected ""

    if command -v fzf > /dev/null 2>&1
        set selected (printf '%s\n' $presets | fzf \
            --height=40% \
            --layout=reverse \
            --border \
            --prompt="Style > " \
            --header="↑↓ Browse • Enter Select • Esc Cancel")
        if test -z "$selected"
            printf "Selection cancelled.\n"
            return 0
        end
    else
        printf -- "-> Choose Fastfetch style you want\n"
        for i in (seq (count $presets))
            printf "%d. %s\n" $i "$presets[$i]"
        end

        set -l stl
        read -P "Select: " stl
        if not string match -qr '^[0-9]+$' "$stl"; or test $stl -lt 1 -o $stl -gt (count $presets)
            printf "Invalid selection.\n"
            return 1
        end
        set selected "$presets[$stl]"
    end

    printf "Setting %s as fastfetch style...\n" "$selected"

    # Erase any shadowing global variable so universal variable is active
    set -e -g ffconfig
    # Persist across sessions via universal variable (unexported)
    set -U ffconfig "$selected"

    # Keep ~/.config/fastfetch/config.jsonc in sync
    mkdir -p "$HOME/.config/fastfetch"
    ln -sf "$preferredDir/$selected.jsonc" "$HOME/.config/fastfetch/config.jsonc"

    # Display immediately with the chosen preset path
    command fastfetch --config "$preferredDir/$selected.jsonc"
end

# fastfetch image switcher (uses fzf+chafa for live preview when available)
function ffimg
    set -l preferredDir "$HOME/.local/share/fastfetch/images"
    if not test -d "$preferredDir"
        printf "Image directory not found: %s\n" "$preferredDir"
        return 1
    end

    set -l config "$HOME/.local/share/fastfetch/presets/minimal.jsonc"
    if not test -f "$config"
        printf "Config file not found: %s\n" "$config"
        return 1
    end

    # Erase any shadowing global variable to ensure current universal ffconfig is checked
    set -e -g ffconfig

    # Only makes sense when the minimal preset is active
    if test "$ffconfig" != minimal
        printf "minimal style is not selected (current: %s).\n" "$ffconfig"
        printf "Run 'ffstyle' and select 'minimal' first.\n"
        return 0
    end

    set -l images
    for img in "$preferredDir"/*
        test -f "$img"; or continue
        set -a images (basename "$img")
    end

    if test (count $images) -eq 0
        printf "No images found in %s\n" "$preferredDir"
        return 1
    end

    set -l selected ""

    # Use fzf + chafa for interactive live preview if both are available
    if command -v fzf > /dev/null 2>&1; and command -v chafa > /dev/null 2>&1
        set selected (printf '%s\n' $images | fzf \
            --height=80% \
            --layout=reverse \
            --border \
            --prompt="Image > " \
            --header="↑↓ Browse • Enter Select • Esc Cancel" \
            --preview="chafa --clear --format=symbols --size=45x20 --animate=off --polite on -- \"$preferredDir\"/{}" \
            --preview-window='right:55%:wrap')
        if test -z "$selected"
            printf "Selection cancelled.\n"
            return 0
        end
    else
        # Hint about missing tools
        if not command -v fzf > /dev/null 2>&1
            printf "fzf not found — install it for live image preview (sudo pacman -S fzf)\n"
        end
        if not command -v chafa > /dev/null 2>&1
            printf "chafa not found — install it for live image preview (sudo pacman -S chafa)\n"
        end

        printf "-> Choose Fastfetch image you want:\n"
        for i in (seq (count $images))
            printf "%d. %s\n" $i "$images[$i]"
        end

        set -l stl
        read -P "Select (1-"(count $images)"): " stl
        if not string match -qr '^[0-9]+$' "$stl"; or test $stl -lt 1 -o $stl -gt (count $images)
            printf "Invalid selection.\n"
            return 1
        end
        set selected "$images[$stl]"
    end

    printf "\nSetting %s as Fastfetch image...\n" "$selected"

    if grep -qE 'fastfetch/images/[^"]+' "$config"
        sed -i -E "s|(fastfetch/images/)[^\"/]+|\1$selected|" "$config"
    else
        printf "Could not find an image path in %s\n" "$config"
        return 1
    end

    printf "Fastfetch image updated successfully.\n"
    printf "Image : %s\n" "$selected"
    printf "Config: %s\n" "$config"
    printf "\n"
    command fastfetch --config "$config"
end

# software search
function ss
    if command -v pacman > /dev/null 2>&1
        set -l aur (command -v yay 2>/dev/null; or command -v paru 2>/dev/null)
        if test -n "$aur"
            set -l fzf_query_flag
            if test (count $argv) -gt 0
                set fzf_query_flag --query="$argv[1]"
            end
            $aur -Slq | fzf --multi $fzf_query_flag --preview "$aur -Sii {1}" --preview-window=down:75% | xargs -ro $aur -S --noconfirm
        else
            printf "No AUR helper found. Install yay or paru for interactive search.\n"
            return 1
        end
    else
        if test (count $argv) -eq 0
            printf "Usage: ss <package_name>\n"
            return 1
        end
        if command -v apt > /dev/null 2>&1
            apt search "$argv[1]"
        else if command -v dnf > /dev/null 2>&1
            dnf search "$argv[1]"
        else if command -v zypper > /dev/null 2>&1
            zypper search "$argv[1]"
        else
            printf "!! Unsupported package manager.\n"
            return 1
        end
    end
end

# change starship prompt style
function change_style
    set -l starship_dir "$HOME/.hyprconf/starship"
    if not test -d "$starship_dir"
        set starship_dir "$HOME/.config/starship"
    end

    if not test -d "$starship_dir"
        printf "Starship directory not found: %s\n" "$starship_dir"
        return 1
    end

    set -l styles
    for file in "$starship_dir"/*.toml
        test -f "$file"; or continue
        set -a styles (basename "$file" .toml)
    end

    if test (count $styles) -eq 0
        printf "No starship styles found in %s\n" "$starship_dir"
        return 1
    end

    function __print_starship_box_header
        printf "\e[1;36m╭────────────────────────────────────────╮\e[0m\n"
        printf "\e[1;36m│ \e[1;37m        Choose a Starship Style        \e[1;36m│\e[0m\n"
        printf "\e[1;36m├────────────────────────────────────────┤\e[0m\n"
    end

    function __print_starship_box_footer
        printf "\e[1;36m╰────────────────────────────────────────╯\e[0m\n"
    end

    __print_starship_box_header
    for i in (seq (count $styles))
        printf "\e[1;36m│\e[0m \e[1;33m%2d.\e[0m \e[1;32m%-34s\e[0m \e[1;36m│\e[0m\n" $i "$styles[$i]"
    end
    __print_starship_box_footer

    echo
    printf "\e[1;35m❯\e[0m \e[1;37mChoose a number (1-%d):\e[0m " (count $styles)
    read -l stl

    functions -e __print_starship_box_header __print_starship_box_footer

    if string match -qr '^[0-9]+$' "$stl"; and test $stl -ge 1 -a $stl -le (count $styles)
        set -l selected "$styles[$stl]"
        set -l prompt_file "$starship_dir/$selected.toml"

        echo
        printf "  \e[1;34m[*]\e[0m Setting prompt to: \e[1;32m%s\e[0m\n" "$selected"

        # Copy selected preset to active ~/.config/starship.toml
        cp "$prompt_file" "$HOME/.config/starship.toml"

        # Re-apply Noctalia palette if available
        set -l noctalia_apply "/usr/share/noctalia/assets/templates/starship/apply.sh"
        if test -x "$noctalia_apply"
            "$noctalia_apply" 2>/dev/null
        end

        # Set in current environment immediately
        set -gx STARSHIP_CONFIG "$HOME/.config/starship.toml"

        # Invalidate cached init script to pick up changes
        rm -f "$HOME/.config/fish/starship_init.fish"

        printf "  \e[1;34m[*]\e[0m Applying changes immediately...\n"
        sleep 1; and clear
        exec fish
    else
        echo
        printf "\e[1;31m  [!] Invalid choice. Exiting.\e[0m\n"
        return 1
    end
end

# Auto-cd with case-insensitive matching and multi-match selection
function fish_command_not_found
    set -l cmd $argv[1]

    # 1. Exact directory match
    if test -d "$cmd"
        cd "$cmd"
        return 0
    end

    # 2. Case-insensitive directory lookup
    set -l parent_dir (dirname -- "$cmd")
    set -l base_name (basename -- "$cmd")

    if test -d "$parent_dir"
        set -l lower_base (string lower -- "$base_name")
        set -l matches

        for entry in "$parent_dir"/*
            set -l entry_name (basename -- "$entry")
            if test (string lower -- "$entry_name") = "$lower_base" -a -d "$entry"
                set -a matches "$entry"
            end
        end

        # Single match found: auto cd
        if test (count $matches) -eq 1
            cd "$matches[1]"
            return 0
        # Multiple matches (e.g. downloads, Downloads, DOWNLOADS): ask user
        else if test (count $matches) -gt 1
            printf "\e[1;33mMultiple matches found for '%s':\e[0m\n" "$cmd"
            if command -v fzf >/dev/null 2>&1
                set -l choice (printf "%s\n" $matches | fzf --prompt="Select Directory > " --height=40% --layout=reverse --border)
                if test -n "$choice"
                    cd "$choice"
                    return 0
                end
            else
                for i in (seq (count $matches))
                    printf "  \e[1;36m%d.\e[0m %s\n" $i "$matches[$i]"
                end
                read -l -P "Select number (1-"(count $matches)"): " choice
                if string match -qr '^[0-9]+$' "$choice"; and test $choice -ge 1 -a $choice -le (count $matches)
                    cd "$matches[$choice]"
                    return 0
                end
            end
            return 1
        end
    end

    # Fallback for standard unknown commands
    printf "fish: Unknown command: '%s'\n" "$cmd"
    return 127
end

# Auto-ls (2-level tree view) on directory change (skips HOME)
function __auto_tree_on_cd --on-variable PWD
    status is-interactive; or return
    
    # Do not auto-ls when navigating to HOME
    test "$PWD" = "$HOME"; and return

    if command -v eza >/dev/null 2>&1
        eza -T --level=1 --color=always --icons=always --group-directories-first \
            --ignore-glob="node_modules|.git|.venv|target|vendor|.cache|.next|dist|build"
    else
        ls
    end
end