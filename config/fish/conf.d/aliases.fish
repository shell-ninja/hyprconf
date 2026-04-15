source ~/.config/fish/functions/functions.fish

#==============================================================================

# ███████╗██╗  ██╗███████╗██╗         ███╗   ██╗██╗███╗   ██╗     ██╗ █████╗ 
# ██╔════╝██║  ██║██╔════╝██║         ████╗  ██║██║████╗  ██║     ██║██╔══██╗
# ███████╗███████║█████╗  ██║         ██╔██╗ ██║██║██╔██╗ ██║     ██║███████║
# ╚════██║██╔══██║██╔══╝  ██║         ██║╚██╗██║██║██║╚██╗██║██   ██║██╔══██║
# ███████║██║  ██║███████╗███████╗    ██║ ╚████║██║██║ ╚████║╚█████╔╝██║  ██║
# ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═╝
                                                                            
#==============================================================================

## list ##
alias ls='eza -T --level=1 --color=always --icons=always'
alias la='eza -a --icons=always'
alias ll='eza -l -a --icons=always --no-time'
alias lst='eza -T --level=2 --color=always --icons=always'
alias lsf='eza -f -a --color=always --icons=always'
alias lstd='eza -D -T --level=2 --color=always --icons=always'
alias tree='eza -T --level=3 --color=always --icons=always'
alias l.='eza --color=always --icons=always | egrep "^\."'
alias l.='eza --color=always --icons=always --group-directories-first ../' # ls on the PARENT directory
alias l..='eza -al --color=always --group-directories-first ../../' # ls on directory 2 levels up
alias l...='eza -al --color=always --group-directories-first ../../../' # ls on directory 3 levels up

alias cat='bat --style header --style snip --style changes --style header'  # cat

alias grubup="sudo update-grub" # most other distros like Arch, Ubuntu
alias susegrub="sudo grub2-mkconfig -o /boot/grub2/grub.cfg"    # opensuse
alias fedbup="sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg" # fedora
alias ..='cd ..'    # go back
alias ...='cd ../..'    # go back 2 steps
alias .='cd /'  # go to root dir
alias cd='z'

# other
alias src='clear && source ~/.config/fish/config.fish'
alias clr='clear'   #clear
alias cls='clear'
alias clar='clear'
alias c='clear'
alias q='exit'
alias s='pacman -Ss'
alias i='sudo pacman -S'

# disk spaces and RAM usage
alias du='du -sh'
alias mem='fn_resources __memory'
alias disk='fn_resources __disk'

# change your default USER shell
alias tobash="sudo chsh $USER -s /bin/bash && echo 'Log out and log back in for change to take effect.'"
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Log out and log back in for change to take effect.'"
alias tofish="sudo chsh $USER -s /bin/fish && echo 'Log out and log back in for change to take effect.'"

#fzf
alias find='nvim $(fzf --preview="bat --color=always {}")'

#nvim
alias nv='nvim'
alias nvm='nvim .'
alias open='nvim .'
alias snv='sudo -E nvim -d'
alias vi='nvim'
alias vim='nvim'
alias svi='sudo nvim'
alias vis='nvim "+set si"'
alias vi='vim'
alias svi='sudo vim'
alias vis='vim "+set si"'

# check updates
alias cu='fn_check_updates'

# updates
alias dup='sudo zypper dup -y' # distro update for opensuse
alias update='fn_update'

# install and remove package
alias install='fn_install'
alias remove='fn_uninstall'

# compiling c++ file using gcc
alias cpp='fn_compile_cpp'

# git alias
alias add='git add .'
alias clone='git clone'
alias cloned='git clone --depth=1'
alias branch='git branch -M main'
alias commit='git commit -m'
alias push='git push'
alias pushm='git push -u origin main'
alias pusho='git push origin' # and add your branch name 
alias pull='git pull'
alias info='git_info'

# others
alias nc='clr && neofetch'
alias ff='clr && fastfetch'
alias sys='btop'
alias clock='tty-clock -c -t -D -s'

alias mkdir='mkdir -pv'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias cat='bat'

alias fzf='fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'
alias ipexternal="curl -s ifconfig.me && echo"
alias ipexternal="wget -qO- ifconfig.me && echo"
alias exe='chmod +x'

alias sddt='sddm-greeter-qt6 --test-mode --theme'

alias style='~/.config/fish/functions/change_style.sh'
alias ffstyle='~/.config/fish/functions/ffstyle.sh'
# alias ffimg='~/.config/fish/functions/ffimg.sh'
