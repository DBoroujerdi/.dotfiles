# Emacs Configuration

Personal Emacs configuration with Evil mode (Vim keybindings), LSP support, and modern development tools.

Based on blog post: https://sam217pa.github.io/2016/09/02/how-to-build-your-own-spacemacs/

## Features

- **Evil Mode**: Full Vim emulation with Evil Collection
- **Modern Completion**: Vertico + Consult + Prescient
- **Project Management**: Projectile with ripgrep/ag integration
- **Git Integration**: Magit with todos support
- **LSP Support**: Eglot with TypeScript, Go, Terraform support
- **Tree-sitter**: Native syntax highlighting (Emacs 29+)
- **File Explorer**: Treemacs sidebar
- **Code Formatting**: Prettier integration
- **Theme**: Doom One theme with all-the-icons

## Prerequisites

### Required Software

```bash
# Emacs 29+ (macOS)
brew install emacs-plus@29 --with-native-comp

# Build tools
brew install cmake  # Required for vterm

# Search tools (for optimal performance)
brew install ripgrep
brew install the_silver_searcher
brew install fzf

# Fonts
brew tap homebrew/cask-fonts
brew install --cask font-inconsolata

# Node.js (for TypeScript/JavaScript development)
brew install node
yarn global add typescript-language-server prettier

# Other language servers
go install golang.org/x/tools/gopls@latest
brew install terraform-ls
```

## Installation

```bash
git clone git@github.com:DBoroujerdi/.emacs.d.git ~/.emacs.d
```

Start Emacs - packages will auto-install on first run.

### Testing Configuration

To test configuration without affecting your main setup:
```bash
env HOME=/path/to/test/dir emacs -q --load ~/projects/personal/.emacs.d/init.el
```

## Emacs Server/Client Usage

This configuration automatically starts an Emacs server for faster file opening and better integration with external tools.

### Starting Emacs Server

#### Option 1: Daemon Mode (Recommended)
Start Emacs as a daemon in the background:
```bash
# Start the daemon
emacs --daemon

# Or with a named server
emacs --daemon=myserver
```

#### Option 2: Regular Emacs with Server
Just start Emacs normally - the server will auto-start:
```bash
emacs
```

### Connecting with Emacs Client

```bash
# Open file in existing Emacs
emacsclient file.txt

# Create a new frame (window)
emacsclient -c file.txt

# Open in terminal (no GUI)
emacsclient -t file.txt

# Create new frame if no server running, otherwise use existing
emacsclient -c -a "" file.txt

# Connect to named server
emacsclient -s myserver file.txt
```

### Shell Aliases (Recommended)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Quick edit with emacsclient
alias e='emacsclient -n'
alias ec='emacsclient -c -n'
alias et='emacsclient -t'

# Start/stop daemon
alias emacs-start='emacs --daemon'
alias emacs-stop='emacsclient -e "(kill-emacs)"'
alias emacs-restart='emacs-stop && emacs-start'

# Use emacsclient as default editor
export EDITOR='emacsclient -t'
export VISUAL='emacsclient -c -a emacs'
```

### macOS Launch Agent (Auto-start on login)

Create `~/Library/LaunchAgents/gnu.emacs.daemon.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>gnu.emacs.daemon</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/local/bin/emacs</string>
      <string>--daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/emacs-daemon.stderr</string>
    <key>StandardOutPath</key>
    <string>/tmp/emacs-daemon.stdout</string>
  </dict>
</plist>
```

Then load it:
```bash
launchctl load -w ~/Library/LaunchAgents/gnu.emacs.daemon.plist
```

### Managing Server Sessions

```bash
# Check if server is running
emacsclient -e "(server-running-p)"

# List all server instances
ls /tmp/emacs$(id -u)/

# Kill server from client
emacsclient -e "(kill-emacs)"

# Save all buffers and kill
emacsclient -e "(save-buffers-kill-emacs)"
```

### Tips for Server/Client Usage

1. **Finish editing**: Use `C-x #` to finish editing and close client frame
2. **Keep server running**: The server stays running even after closing all frames
3. **Persistent sessions**: Your buffers remain open in the server between client connections
4. **Fast startup**: Client connections are nearly instant
5. **Terminal fallback**: Use `-t` flag when SSH'd or without GUI

## Key Bindings

Leader key: `SPC` (Space)

### Essential Commands

| Key | Command |
|-----|---------|
| `SPC p p` | Project commander |
| `SPC p f` | Find file in project |
| `SPC /` | Search project (ripgrep) |
| `SPC s l` | Search current buffer |
| `SPC g g` | Magit status |
| `SPC t t` | Toggle Treemacs |
| `SPC b b` | Switch buffer |
| `SPC \|` | Split window vertically |
| `SPC -` | Split window horizontally |

### LSP Commands

| Key | Command |
|-----|---------|
| `SPC l a` | Code actions |
| `SPC l r` | Rename symbol |
| `SPC l f` | Format file |
| `SPC l d` | Go to definition |
| `SPC l R` | Find references |

### Search Commands

| Key | Command |
|-----|---------|
| `SPC s l` | Search buffer (consult-line) |
| `SPC s c` | Grep with preview (consult) |
| `SPC s r` | Ripgrep project |
| `SPC s a` | Silver searcher |
| `/` | Quick buffer search (in normal mode) |

### Code Formatting

| Key | Command |
|-----|---------|
| `SPC c f` | Format file (prettier) |
| `SPC c F` | Format region |

### Window Navigation

| Key | Command |
|-----|---------|
| `C-h` | Move to left window |
| `C-l` | Move to right window |
| `C-j` | Move to window below |
| `C-k` | Move to window above |

## LSP - Required Language Servers

Ensure all language servers are available on `PATH`

### TypeScript/JavaScript

```bash
yarn global add typescript-language-server
```

### Golang

```bash
go install golang.org/x/tools/gopls@latest
```

### Terraform

```bash
brew install terraform-ls
```

## Troubleshooting

### Server Issues

If server fails to start:
```bash
# Remove stale server files
rm -rf /tmp/emacs$(id -u)/
rm ~/.emacs.d/server/

# Restart Emacs
emacs --daemon
```

### Package Installation

If packages fail to install:
```elisp
M-x package-refresh-contents
M-x package-install-selected-packages
```

### Tree-sitter Issues

Install missing grammars:
```elisp
M-x treesit-install-language-grammar
```

## Customization

- User customizations: Edit `init.el`
- Custom functions: Add to `init-functions.el`
- Additional keybindings: Add to `init-keys.el`
- Machine-specific settings: `custom.el` (auto-generated)
