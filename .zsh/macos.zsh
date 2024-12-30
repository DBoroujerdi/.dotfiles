autoload bashcompinit && bashcompinit
source $(brew --prefix)/etc/bash_completion.d/az
eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH=$PATH:/opt/homebrew/bin

