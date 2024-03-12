export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git fzf node nvm aws)

source $ZSH/oh-my-zsh.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

HISTFILE=~/.zsh_history
HISTSIZE=10000000
SAVEHIST=10000000

setopt hist_ignore_all_dups


eval "$(direnv hook zsh)"

# allow navigate by word in intellij 
if [[ -z $__INTELLIJ_COMMAND_HISTFILE__ ]]; then
    bindkey "\e\eb" backward-word
    bindkey "\e\ef" forward-word
fi

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export PATH=$PATH:$HOME/Library/Python/3.11/bin

eval "$(rbenv init - zsh)"

alias gs="git status"
alias v=nvim
alias vim=nvim
alias zc="nvim ~/.zshrc"
alias gs="git status"
alias mkdirp="mkdir -p"
alias vime="vim -u NONE -U NONE -N"

eval "$(jump shell)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export GPG_TTY=$(tty)

