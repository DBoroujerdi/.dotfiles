# herdr keybindings

Mirrors `~/.dotfiles/.tmux.conf`. Config: `~/.config/herdr/config.toml`
(stowed from `~/.dotfiles/.config/herdr/`).

Prefix is **`§`** — same as tmux. `§ x` below means: press `§`, release, then `x`.
Bindings written as `alt+h` are direct (no prefix).

Terminology: a herdr **tab** is a tmux window, a herdr **workspace** is a tmux
session.

## Tabs (tmux windows)

| Keys | Action | tmux |
|---|---|---|
| `§ c` | New tab | `bind c new-window` |
| `§ n` | Next tab | `next-window` |
| `§ p` | Previous tab | `previous-window` |
| `§ 1`–`§ 9` | Jump to tab N | `select-window` |
| `§ ,` | Rename tab | `rename-window` |
| `§ &` | Close tab | `bind & confirm-before kill-window` |

## Panes

| Keys | Action | tmux |
|---|---|---|
| `§ \|` | Split side-by-side | `bind \| split-window -h` |
| `§ v` | Split side-by-side (alias) | — |
| `§ -` | Split stacked | `bind - split-window -v` |
| `alt+h` / `alt+j` / `alt+k` / `alt+l` | Focus pane left/down/up/right | `bind -n M-h/j/k/l select-pane` |
| `§ h` / `§ j` / `§ k` / `§ l` | Focus pane (prefixed fallback) | — |
| `§ tab` | Cycle pane forward | — |
| `§ shift+tab` | Cycle pane backward | — |
| `§ x` | Close pane | `kill-pane` |
| `§ z` | Zoom pane | `resize-pane -Z` |
| `§ shift+p` | Rename pane | — |
| `§ e` | Edit scrollback in `$EDITOR` | nearest to `copy-mode` |
| `§ alt+r` | Resize mode → then `h/j/k/l`, `esc` to exit | see [deltas](#deltas-from-tmux) |

## Workspaces (tmux sessions)

| Keys | Action | tmux |
|---|---|---|
| `§ f` | Workspace picker | `@sessionx-bind 'f'` |
| `§ w` | Workspace picker (alias) | `choose-tree` |
| `§ s` | Workspace picker (alias) | `choose-tree -s` |
| `§ shift+n` | New workspace | — |
| `§ shift+w` | Rename workspace | `rename-session` |
| `§ shift+d` | Close workspace | `kill-session` |
| `§ space` | Navigate mode | — |

Inside the workspace list / navigate mode:

| Keys | Moves |
|---|---|
| `j` / `k` (or `↓` / `↑`) | Between workspaces |
| `h` / `l` | Between panes, left/right |
| `ctrl+j` / `ctrl+k` | Between panes, down/up |
| `enter` | Switch to selection |

`j`/`k` are claimed by workspaces, which is why pane up/down sits on `ctrl+j` /
`ctrl+k` — binding both pairs to `j`/`k` silently disables the pane pair
(workspaces win the collision).

herdr's picker is a flat workspace list, not tmux's expandable
session→window→pane tree, and it can't kill entries. For tree-style browsing use
`§ space` (navigate mode).

## Worktrees

tmux had these behind the `§ W` menu (calling the `wt` scripts). herdr does
them natively, into the same directory `wt` uses — `~/projects/worktrees`, laid
out as `<repo>/<branch-slug>`.

| Keys | Action |
|---|---|
| `§ shift+g` | New worktree |
| `§ shift+o` | Open worktree |
| — | Remove worktree (**unbound** — destructive; set `remove_worktree` to enable) |

## Session / app

| Keys | Action | tmux |
|---|---|---|
| `§ ?` | Help / active bindings | `list-keys` |
| `§ d` | Detach | `detach-client` |
| `§ r` | Reload config | `bind r source-file ~/.tmux.conf` |
| `§ shift+s` | Settings | — |
| `§ b` | Toggle sidebar | — |
| `§ o` | Jump to notifying agent | — |

## Popups

Same keys and sizes as the tmux `display-popup` bindings, except magit
(see [deltas](#deltas-from-tmux)).

| Keys | Command | Size |
|---|---|---|
| `§ g` | lazygit | 80×80% |
| `§ alt+g` | magit | 60×60% |
| `§ shift+r` | ranger | 80×80% |
| `§ shift+t` | scratch zsh | 75×75% |
| `§ shift+k` | nvim keybindings cheatsheet | 80×80% |
| `§ alt+k` | this file | 80×80% |
| `§ a` | idle session picker | 75×40% |
| `§ shift+c` | agent session picker | 75×40% |

## Deltas from tmux

Four keys had to move because herdr's own action collided with a tmux binding:

| What | tmux | herdr | Why |
|---|---|---|---|
| Settings | — | `§ shift+s` | herdr's default `§ s` is tmux's session picker, so `§ s` opens the workspace picker instead |
| magit popup | `§ G` | `§ alt+g` | `§ shift+g` is herdr's new-worktree |
| Resize | `alt+H/J/K/L` (direct, ±5) | `§ alt+r` then `h/j/k/l` | herdr has a resize *mode*, not directional actions; `§ r` is reload and `§ shift+r` is ranger |
| Navigate mode | — | `§ space` | herdr's default `§ g` is lazygit here |

## Not carried over

| tmux binding | Why |
|---|---|
| `§ v` watch-session popup | The script is tmux-specific (`display-popup -x` pinning, `#{session_name}`). `§ v` is a split alias instead. |
| `§ M` dotfiles menu | herdr has no `display-menu` equivalent. |
| `§ o` tmux-sessionizer | Script shells out to `tmux neww`. Closest: `§ f` picker or `§ shift+n`. |
| `§ (` / `§ )` session switching | Left unbound; `previous_workspace` / `next_workspace` exist if you want them. |
| copy-mode `v` / `y` | Not configurable. herdr copies on mouse selection (`copy_on_select`); `§ e` opens scrollback in `$EDITOR`. |
| `§ §` send-prefix | No pass-through binding. |
| status bar, `base-index`, `renumber-windows`, pane dimming | No herdr analogue (theme set to tokyo-night, accent `#7aa2f7`). |

## Also configured

- Prefix `§`, tokyo-night theme, accent `#7aa2f7`
- `default_shell = "/bin/zsh"` (tmux `default-command`)
- `new_cwd = "follow"` — new panes/tabs inherit the current path (tmux `-c "#{pane_current_path}"`)
- `mouse_capture` + `copy_on_select` (tmux `set -g mouse on`)

## Editing

```sh
$EDITOR ~/.config/herdr/config.toml   # symlink into ~/.dotfiles
herdr config check                    # validates keys, reports collisions
herdr server reload-config            # or press § r
```

`herdr --default-config` prints every option with defaults;
`herdr config reset-keys` backs up and strips custom keybindings.
