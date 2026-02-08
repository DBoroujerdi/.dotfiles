export PATH="$HOME/.tfenv/bin:$PATH"

# Omarchy envs
export SUDO_EDITOR="$EDITOR"
export BAT_THEME=ansi

# Omarchy aliases - file system
if command -v eza &> /dev/null; then
    alias ls='eza -lh --group-directories-first --icons=auto'
    alias lsa='ls -a'
    alias lt='eza --tree --level=2 --long --icons --git'
    alias lta='lt -a'
fi

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

open() { xdg-open "$@" >/dev/null 2>&1 & }

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Omarchy aliases - tools
alias c='opencode'
alias d='docker'
alias r='rails'
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }

# Omarchy aliases - git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# Omarchy functions
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress="tar -xzf"

# Tool integrations
command -v mise &> /dev/null && eval "$(mise activate zsh)"
command -v zoxide &> /dev/null && eval "$(zoxide init zsh)"

if command -v zoxide &> /dev/null; then
    alias cd="zd"
    zd() {
        if [ $# -eq 0 ]; then
            builtin cd ~ && return
        elif [ -d "$1" ]; then
            builtin cd "$1"
        else
            z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
        fi
    }
fi
