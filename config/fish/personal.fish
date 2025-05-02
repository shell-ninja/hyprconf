# ====================================
# ┏━┓╻ ╻┏┓╻┏━╸┏━┓
# ┣━┫┃ ┃┃┗┫┃  ┗━┓
# ╹ ╹┗━┛╹ ╹┗━╸┗━┛

# Safe PATH builder with existence checks
function __add_path -d "Safely add directory to PATH"
    if test -d $argv[1]
        set -gx PATH $argv[1] $PATH
    else
        echo (set_color yellow)"⚠️ Path not found: "(set_color red)$argv[1](set_color normal)
    end
end

# Core paths
__add_path ~/.local/bin
__add_path ~/.bin

# Development tools
__add_path /opt/flutter/bin
__add_path /usr/lib/jvm/java-8-openjdk/bin

# Android SDK paths
set -gx ANDROID_SDK_ROOT /opt/android-sdk
for subdir in platform-tools tools/bin emulator tools cmdline-tools/latest/bin
    __add_path $ANDROID_SDK_ROOT/$subdir
end


# =====================================
# ┏━┓┏┳┓┏━╸╻ ╻┏━┓╺┳╸
# ┣━┫┃┃┃┣╸ ┃ ┃┣┳┛ ┃ 
# ╹ ╹╹ ╹┗━╸┗━┛╹┗╸ ╹ 

# Modern ls replacement
alias ls='eza -al --color=always --icons=always --group-directories-first --git --header'

# Secure sudo alternative
alias sudo='doas --'


# ==================================
# ┏━┓┏━╸╺┳┓
# ┣━┫┣╸  ┃┃
# ╹ ╹┗━╸╺┻┛

set -gx CHROME_EXECUTABLE "/usr/bin/zen-browser"
set -gx EDITOR nvim
set -gx VISUAL nvim

# ========================================
# ┏━┓╻ ╻┏━┓╺┳╸╻┏━┓┏┓╻
# ┣┳┛┃ ┃┣━┫ ┃ ┃┃ ┃┃┗┫
# ╹┗╸┗━┛╹ ╹ ╹ ╹┗━┛╹ ╹

function bw_session_load -d "Secure Bitwarden session loader"
    set -l bw_file ~/Documents/bw_fish
    set -l mp_file ~/Documents/bw_mp

    if not test -f $bw_file
        echo (set_color red)"❌ Bitwarden config missing:"
        echo (set_color yellow)"   Run: "(set_color white)"bw unlock --raw > $bw_file"(set_color normal)
        return 1
    end

    if not test -f $mp_file
        echo (set_color red)"❌ Master password file missing!"(set_color normal)
        return 1
    end

    set -l password (cat $mp_file | tr -d '\n')
    set -gx BW_SESSION (bw unlock $password --raw | tr -d '\n')

    if test -n "$BW_SESSION"
        echo (set_color green)"🔒 "(set_color white)"Bitwarden vault unlocked!"(set_color normal)
    else
        echo (set_color red)"🔐 Failed to unlock vault"(set_color normal)
    end
end
