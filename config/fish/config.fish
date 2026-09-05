# ~/.config/fish/config.fish

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

# Source Aliases and Functions
if test -f "$HOME/.config/fish/functions.fish"
    source "$HOME/.config/fish/functions.fish"
end

if test -f "$HOME/.config/fish/alias.fish"
    source "$HOME/.config/fish/alias.fish"
end

# Disable fish greeting
set -g fish_greeting

if status is-interactive
    # Fastfetch on launch
    if command -v fastfetch >/dev/null 2>&1
        # Clear any inherited global variable shadowing universal ffconfig
        set -e -g ffconfig
        if not set -q ffconfig
            set -U ffconfig minimal
        end
        fastfetch
    end

    # Starship prompt configuration
    set -gx STARSHIP_CONFIG "/home/shell-ninja/.config/fish/starship/starship-macchiato_bubbles.toml"
    if command -v starship >/dev/null 2>&1
        starship init fish | source
    end

    # Zoxide integration
    if command -v zoxide >/dev/null 2>&1
        zoxide init fish | source
    end

    # FZF integration
    if command -v fzf >/dev/null 2>&1
        if fzf --fish >/dev/null 2>&1
            fzf --fish | source
        end
    end
end

# User specific PATH
fish_add_path $HOME/.local/bin $HOME/bin $HOME/.opencode/bin

# Environment Variables
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx SUDO_EDITOR nvim
set -gx FCEDIT nvim
set -gx BROWSER com.brave.Browser

if command -v bat >/dev/null 2>&1
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -gx PAGER bat
end

if command -v fzf >/dev/null 2>&1
    set -gx FZF_DEFAULT_OPTS " \
      --info=inline-right \
      --ansi \
      --layout=reverse \
      --border=rounded \
      --color=border:#27a1b9 \
      --color=fg:#c0caf5 \
      --color=gutter:#16161e \
      --color=header:#ff9e64 \
      --color=hl+:#2ac3de \
      --color=hl:#2ac3de \
      --color=info:#545c7e \
      --color=marker:#ff007c \
      --color=pointer:#ff007c \
      --color=prompt:#2ac3de \
      --color=query:#c0caf5:regular \
      --color=scrollbar:#27a1b9 \
      --color=separator:#ff9e64 \
      --color=spinner:#ff007c"
end
