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

# --- copy-paste with automatic sudo elevation and file/dir mode detection ---
function fn_copy_paste
    if test (count $argv) -lt 2
        printf "Usage: fn_copy_paste <source...> <destination>\n"
        return 1
    end

    set -l destination $argv[-1]
    # Strip trailing slash to normalise
    set destination (string trim --right --chars=/ -- "$destination")
    set -l items $argv[1..-2]

    # ---- Determine mode: file rename vs directory copy ----
    set -l mode dir
    if test (count $items) -eq 1; and not test -d "$destination"
        set mode file
    end
    # If original argument had trailing slash, force dir mode
    if string match -q '*/' -- $argv[-1]
        set mode dir
    end

    # ---- Decide whether sudo is needed ----
    set -l SUDO ""
    if test (id -u) -ne 0
        if test "$mode" = dir
            if test -d "$destination"
                if not test -w "$destination"; or not test -x "$destination"
                    set SUDO sudo
                end
            else
                set -l parent (dirname "$destination")
                if not test -w "$parent"; or not test -x "$parent"
                    set SUDO sudo
                end
            end
        else
            set -l dest_dir (dirname "$destination")
            if test -e "$destination"
                if not test -w "$destination"
                    set SUDO sudo
                end
            else
                if not test -w "$dest_dir"; or not test -x "$dest_dir"
                    set SUDO sudo
                end
            end
        end
        # Check readability of every source item
        for item in $items
            if not test -r "$item"
                set SUDO sudo
                break
            end
        end
    end

    if test -n "$SUDO"
        sudo -v 2>/dev/null; or true
    end

    # ---- Create destination if needed ----
    if test "$mode" = dir
        if not test -d "$destination"
            if test -n "$SUDO"
                $SUDO mkdir -p "$destination"; or begin
                    printf "!! Failed to create destination directory: %s\n" "$destination"
                    return 1
                end
            else
                mkdir -p "$destination"; or begin
                    printf "!! Failed to create destination directory: %s\n" "$destination"
                    return 1
                end
            end
        end
    else
        set -l dest_dir (dirname "$destination")
        if not test -d "$dest_dir"
            if test -n "$SUDO"
                $SUDO mkdir -p "$dest_dir"; or begin
                    printf "!! Failed to create parent directory: %s\n" "$dest_dir"
                    return 1
                end
            else
                mkdir -p "$dest_dir"; or begin
                    printf "!! Failed to create parent directory: %s\n" "$dest_dir"
                    return 1
                end
            end
        end
    end

    # ---- Copy each item ----
    for item in $items
        set item (string trim --right --chars=/ -- "$item")
        set -l name (basename "$item")

        if test -f "$item"
            if test "$mode" = file
                printf "\n:: Copying file %s → %s\n" "$name" "$destination"
                if string match -q "*.iso" "$name"
                    if test -n "$SUDO"
                        pv "$item" | sudo dd of="$destination" bs=4M status=none
                    else
                        pv "$item" | dd of="$destination" bs=4M status=none
                    end
                    if test $status -eq 0
                        printf "\n:: Syncing to disk (this may take a while)...\n"
                        if test -n "$SUDO"; sudo sync; else; sync; end
                        printf "Sync complete.\n"
                    end
                else
                    if test -n "$SUDO"
                        pv "$item" | sudo tee "$destination" > /dev/null
                    else
                        pv "$item" > "$destination"
                    end
                end
            else
                printf "\n:: Copying file %s → %s\n" "$name" "$destination"
                if string match -q "*.iso" "$name"
                    if test -n "$SUDO"
                        pv "$item" | sudo dd of="$destination/$name" bs=4M status=none
                    else
                        pv "$item" | dd of="$destination/$name" bs=4M status=none
                    end
                    if test $status -eq 0
                        printf "\n:: Syncing to disk (this may take a while)...\n"
                        if test -n "$SUDO"; sudo sync; else; sync; end
                        printf "Sync complete.\n"
                    else
                        printf "!! ISO copy failed.\n"
                    end
                else
                    if test -n "$SUDO"
                        pv "$item" | sudo tee "$destination/$name" > /dev/null
                    else
                        pv "$item" > "$destination/$name"
                    end
                end
            end
        else if test -d "$item"
            set -l parent (dirname "$item")
            printf "\n:: Copying directory %s → %s\n" "$name" "$destination"
            if test -n "$SUDO"
                sudo tar -C "$parent" -cf - "$name" | pv -N "$name" | sudo tar -xf - -C "$destination"
            else
                tar -C "$parent" -cf - "$name" | pv -N "$name" | tar -xf - -C "$destination"
            end
        else
            printf "!! Skipping unknown type: %s\n" "$item"
        end
    end
end

# remove files and directories safely
function fn_removal
    if test (count $argv) -eq 0
        printf "Usage: fn_removal <file|dir> ...\n"
        return 1
    end

    set -l SUDO ""
    if test (id -u) -ne 0
        for item in $argv
            # Skip option flags like -r, -f, -rf, --
            if string match -q -- "-*" "$item"
                continue
            end
            set -l parent (dirname -- "$item")
            if not test -w "$parent"
                set SUDO "sudo"
                break
            end
        end
    end

    if test -n "$SUDO"
        sudo -v 2>/dev/null; or true
    end

    for item in $argv
        if string match -q -- "-*" "$item"
            continue
        end

        if test -f "$item"
            printf ":: Removing file: %s\n" "$item"
            if test -n "$SUDO"
                sudo rm "$item"
            else
                command rm "$item"
            end
        else if test -d "$item"
            printf ":: Removing directory: %s\n" "$item"
            if test -n "$SUDO"
                sudo rm -rf "$item"
            else
                command rm -rf "$item"
            end
        else
            printf "[ !! ] %s does not exist or is neither a regular file nor a directory\n" "$item"
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
            printf "[ UPDATES ]\n:: You have \e[1;32m%d\e[0m updates available.\n:: Main: %d\n:: AUR: %d\n" $upd $ofc $aur
        case dnf
            set -l upd (dnf check-update -q 2>/dev/null | grep -cv '^$')
            printf "[ UPDATES ]\n:: You have \e[1;32m%d\e[0m updates available\n" $upd
        case zypper
            set -l upd (zypper lu --best-effort 2>/dev/null | grep -c 'v  |')
            printf "[ UPDATES ]\n:: You have \e[1;32m%d\e[0m updates available\n" $upd
        case apt
            set -l upd (apt list --upgradable 2>/dev/null | grep -c '\[upgradable from')
            printf "[ UPDATES ]\n:: You have \e[1;32m%d\e[0m updates available\n" $upd
        case '*'
            printf "\e[1;31m Unsupported package manager for now\e[1;0m\n"
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
            printf "\e[1;31m Unsupported package manager\e[1;0m\n"
            return 1
    end
end

# package install
function fn_install
    if test (count $argv) -eq 0
        printf "Usage: fn_install <package...>\n"
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
            printf "\e[1;31m Unsupported package manager\e[1;0m\n"
            return 1
    end
end

# package uninstall
function fn_uninstall
    if test (count $argv) -eq 0
        printf "Usage: fn_uninstall <package...>\n"
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
            printf "\e[1;31m Unsupported package manager\e[1;0m\n"
            return 1
    end
end

# compile cpp
function fn_compile_cpp
    if test (count $argv) -eq 0
        printf "Usage: fn_compile_cpp <file[.cpp]> [-o]\n"
        return 1
    end

    if not command -v g++ >/dev/null 2>&1
        printf "\e[1;91m[  ] - g++ not found. Please install g++ first.\e[0m\n"
        return 1
    end

    set -l base (string replace -r '\.cpp$' '' "$argv[1]")
    set -l source "$base.cpp"
    if not test -f "$source"
        printf "\e[1;91m[  ] - Source file %s not found.\e[0m\n" "$source"
        return 1
    end

    set -l output "$base"
    printf "\e[0;36m[ * ] - Compiling...!\e[0m\n"
    if g++ -std=c++20 "$source" -o "$output"
        printf "\e[1;92m[ ✓ ] - Successfully compiled.\e[0m\n"
        if test (count $argv) -ge 2; and test "$argv[2]" = "-o"
            printf "\e[1;92m        Output: \e[0m\n\n"
            if string match -q '/*' "$output"; or string match -q './*' "$output"
                "$output"
            else
                "./$output"
            end
        end
    else
        printf "\n\e[1;91m[  ] - Compilation failed.\e[0m\n"
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
        printf "!! Not inside a Git repository.\n"
        return 1
    end

    set -l branch_name (git branch --show-current 2>/dev/null)
    if test -z "$branch_name"
        printf "!! Detached HEAD or unknown branch. Please push manually.\n"
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

    test $untracked_count -gt 0; and printf "=> %s untracked files\n" "$untracked_count"
    test $unstaged_count -gt 0; and printf "=> %s uncommitted changes\n" "$unstaged_count"
    test $staged_count -gt 0; and printf "=> %s staged changes\n" "$staged_count"

    if test $untracked_count -eq 0 -a $unstaged_count -eq 0 -a $staged_count -eq 0
        printf "✓ Nothing to push.\n"
        return 0
    end

    printf "=> %s branch\n\nWrite the commit message\n" "$branch_name"

    set -l msg ""
    if command -v gum >/dev/null 2>&1
        set msg (gum input --placeholder "Write your commit message")
    else
        read -P "=> " msg
    end

    if test -z "$msg"
        printf "!! Aborting due to empty commit message.\n"
        return 1
    end

    git add .
    if not git commit -m "$msg"
        printf "!! Commit failed.\n"
        return 1
    end

    git push origin "$branch_name"
    set -l pstatus $status

    if test $pstatus -eq 0
        printf ":: Pushed successfully!\n"
    else
        printf "!! Sorry, push failed. Please check for errors.\n"
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
    set -l fish_config "$HOME/.config/fish/config.fish"
    set -l starship_dir "$HOME/.config/fish/starship"

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

        # Set in current environment immediately
        set -gx STARSHIP_CONFIG "$prompt_file"

        # Safely replace the line setting STARSHIP_CONFIG in config.fish
        if test -f "$fish_config"
            sed -i -E "s|^([[:space:]]*set -gx STARSHIP_CONFIG).*|\1 \"$prompt_file\"|g" "$fish_config"
        end

        printf "  \e[1;34m[*]\e[0m Applying changes immediately...\n"
        sleep 1; and clear
        exec fish
    else
        echo
        printf "\e[1;31m  [!] Invalid choice. Exiting.\e[0m\n"
        return 1
    end
end
