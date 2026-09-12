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

    # Starship prompt configuration (cached for instant load)
    set -gx STARSHIP_CONFIG "$HOME.config/fish/starship/starship-arch_purist.toml"
    if command -v starship >/dev/null 2>&1
        set -l starship_cache "$HOME/.config/fish/starship_init.fish"
        if not test -f "$starship_cache"; or test (command -v starship) -nt "$starship_cache"
            starship init fish --print-full-init > "$starship_cache"
        end
        source "$starship_cache"
    end

    # Zoxide integration (cached)
    if command -v zoxide >/dev/null 2>&1
        set -l zoxide_cache "$HOME/.config/fish/zoxide_init.fish"
        if not test -f "$zoxide_cache"; or test (command -v zoxide) -nt "$zoxide_cache"
            zoxide init fish > "$zoxide_cache"
        end
        source "$zoxide_cache"
    end

    # FZF integration (cached)
    if command -v fzf >/dev/null 2>&1
        set -l fzf_cache "$HOME/.config/fish/fzf_init.fish"
        if not test -f "$fzf_cache"; or test (command -v fzf) -nt "$fzf_cache"
            fzf --fish > "$fzf_cache"
        end
        source "$fzf_cache"
    end

    # thefuck integration (instant native wrapper, eliminates ~350ms Python startup overhead)
    if command -v thefuck >/dev/null 2>&1
        function __thefuck_run -d "thefuck wrapper"
            set -l alias_name $argv[1]
            set -l fucked_up_command $history[1]
            env TF_SHELL=fish TF_ALIAS=$alias_name PYTHONIOENCODING=utf-8 thefuck $fucked_up_command THEFUCK_ARGUMENT_PLACEHOLDER $argv[2..-1] | read -l unfucked_command
            if test -n "$unfucked_command"
                eval $unfucked_command
                builtin history delete --exact --case-sensitive -- $fucked_up_command
                builtin history merge
            end
        end
        function fuck -d "Correct your previous console command"
            __thefuck_run fuck $argv
        end
        function hell -d "Correct your previous console command"
            __thefuck_run hell $argv
        end
        function damn -d "Correct your previous console command"
            __thefuck_run damn $argv
        end
    end

    # Fastfetch on launch
    if command -v fastfetch >/dev/null 2>&1
        # Clear any inherited global variable shadowing universal ffconfig
        set -e -g ffconfig
        if not set -q ffconfig
            set -U ffconfig minimal
        end
        fastfetch
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
