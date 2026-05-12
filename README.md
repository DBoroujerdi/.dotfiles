# .dotfiles

https://www.youtube.com/watch?v=y6XCebnB9gs

GNU Stow

```
brew install stow
```

## Add a file

`mv ~/.file ~/.dotfiles/`
`cd ~/.dotfiles`
`stow .`


## Setup

### git
 
Before cloning, configure git to authenticate with GitHub via the `gh` CLI:

```sh
gh auth login
gh auth setup-git
```

`gh auth setup-git` wires `gh` in as git's credential helper, avoiding password prompts (and broken Git Credential Manager fallbacks) on clone/push.


### tmux

Install TPM (Tmux Plugin Manager) before sourcing `.tmux.conf`:

```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then inside tmux press `prefix + I` to install the plugins listed in `.tmux.conf`.
