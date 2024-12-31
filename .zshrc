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
export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:$HOME/bin

alias gs="git status"
alias v=nvim
alias vim=nvim
alias zc="nvim ~/.zshrc"
alias gs="git status"
alias mkdirp="mkdir -p"
alias vime="vim -u NONE -U NONE -N"


# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export GPG_TTY=$(tty)


# sst
export PATH=$HOME/.sst/bin:$PATH
export PATH="/opt/homebrew/opt/openssl@1.1/bin:$PATH"

autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

# functions
interval() {
    local cmd="$1"
    local interval=${2:-10}

    while true; do
        eval "$cmd"
        echo ""
        sleep "$interval"
    done
}

if [[ -d "$HOME/.zsh" ]]; then
    if [[ $(uname) == "Darwin" ]]; then
        [[ -f "$HOME/.zsh/macos.zsh" ]] && source "$HOME/.zsh/macos.zsh"
    elif command -v apt > /dev/null; then
        [[ -f "$HOME/.zsh/ubuntu.zsh" ]] && source "$HOME/.zsh/ubuntu.zsh"
    else
        echo 'Unknown OS!'
    fi
fi

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

function export_op_secret() {
    local secret_path="$1"
    local env_var_name="$2"

    if ! value=$(op read "$secret_path"); then
        echo "Failed to read $env_var_name from 1Password at path $secret_path"
        return 1
    fi
    export "$env_var_name=$value"
}

load_secrets() {
    export_op_secret "op://Private/anthropic/api_key" "ANTHROPIC_API_KEY"
    export_op_secret "op://Private/openai/api_key" "OPENAI_API_KEY"
}

if command -v op >/dev/null 2>&1; then
    echo -n "1Password? (y/N): "
    read answer

    if [[ "$answer" =~ ^[Yy]$ ]]; then
        if ! op whoami &>/dev/null; then
            echo "Please sign in to 1Password"
            eval $(op signin)
        fi

        load_secrets
    fi
fi

. "$HOME/.deno/env"

command -v rbenv >/dev/null 2>&1 && eval "$(rbenv init - zsh)"
command -v jump >/dev/null 2>&1 && eval "$(jump shell)"
