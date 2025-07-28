# disable fish greeting and vi mode
set fish_greeting
fish_vi_key_bindings

#===============================================#
#           enable starship prompt
#===============================================#
set --export STARSHIP_CONFIG ~/.config/fish/starship/starship-simple.toml

if status is-interactive
    function starship_transient_prompt_func
      starship module character
    end
    starship init fish | source
    enable_transience
end


#===============================================#
#           aliases and functions
#===============================================#
source ~/.config/fish/conf.d/aliases.fish
source ~/.config/fish/functions/functions.fish
source ~/.config/fish/conf.d/personal.fish

#===============================================#
#           zoxide and thefuck
#===============================================#
zoxide init fish | source
thefuck --alias | source


if command -v fastfetch > /dev/null
    # Only run fastfetch if we're in an interactive shell
    if status --is-interactive
        if test -d "$HOME/.local/share/fastfetch"
            set ffconfig ascii-art
            fastfetch --config "$ffconfig"
        else
            fastfetch
        end
    end
end
