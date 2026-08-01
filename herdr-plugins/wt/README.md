# Worktree Bootstrap (`danielb.wt`)

A Herdr plugin that bootstraps a new worktree workspace from a file in the repo
itself. Herdr creates the checkout and the workspace; this fills it in.

On `worktree.created` and `worktree.opened` it:

1. reads `.wt.toml` from the main checkout, falling back to the worktree's copy,
2. copies the git-ignored files listed in `copy_files` into the new checkout,
3. builds the declared tabs and panes, running each command,
4. starts recognised coding agents through `herdr agent start` so Herdr tracks
   their `idle`/`working`/`blocked` lifecycle instead of treating them as raw
   terminal output.

## Install

```sh
herdr plugin link ~/.dotfiles/herdr-plugins/wt
herdr plugin list
```

Registration is global to your user, so every repo with a `.wt.toml` gets it.
`herdr plugin disable danielb.wt` turns it off without unlinking.

Requires a `python3` with `tomllib` (3.11+). `run.sh` probes `PATH` for one
because macOS `/usr/bin/python3` is 3.9; set `WT_PYTHON` to pin an interpreter.

## `.wt.toml`

Drop this in a repo root and commit it — every worktree of that repo is then
reproducible.

```toml
# Git-ignored files the fresh checkout needs, relative to the repo root.
# Globs and directories work. Existing files are never overwritten.
copy_files = [".env", "config/local.json", "certs/*.pem"]

[[tabs]]
name = "dev"
command = "nvim ."

  [[tabs.panes]]
  name = "agent"
  direction = "right"      # right or down — Herdr's two split axes
  ratio = 0.5              # share the pane being split keeps
  command = "claude"       # recognised agent -> herdr agent start --kind claude

  [[tabs.panes]]
  name = "install"
  direction = "down"
  ratio = 0.6
  command = "npm install"
  close_when_done = true   # pane exits once the command succeeds
```

### Keys

| Key | Where | Meaning |
| --- | --- | --- |
| `copy_files` | top level | List of paths/globs copied from the main checkout. Never overwrites. |
| `tabs` | top level | List of tabs. `tmux_windows` and `windows` are accepted aliases. |
| `name` | tab, pane | Tab label / pane label. |
| `command` | tab, pane | Command to run. Aliases: `cmd`, `run`. |
| `agent` | tab, pane | `false` forces a plain command; a kind string (`"codex"`) forces that agent. Default: auto-detect from the command. |
| `close_when_done` | tab, pane | `true` closes the pane when the command *succeeds*, leaving failures on screen to read; `"always"` closes either way. Implies a plain command, never an agent. |
| `env` | tab, pane | Table of environment variables for the new tab/pane. |
| `focus` | tab | Focus this tab once it is built. Default: focus stays put. |
| `panes` | tab | List of panes to split into the tab. |
| `direction` | pane | `right` (side by side) or `down` (stacked). Default `right`. |
| `ratio` | pane | Share of the split kept by the pane being split, matching Herdr's `--ratio`. `0.5` halves it. |
| `split_from` | pane | Which pane to split: `previous` (default), `root`, or the `name` of any earlier pane in the tab (the tab's own name refers to its root pane). |

The first tab reuses the workspace's existing root tab and pane, so there is no
empty leftover tab.

### Which `.wt.toml` wins

The **main checkout's** copy is read first, with the worktree's own copy as a
fallback. `.wt.toml` is tracked, so a new worktree carries whatever was committed
on its branch — reading the main checkout means edits take effect on the next
worktree without committing them first.

### Space when a pane closes

A closing pane hands its space to its sibling in the split tree, not to the
first pane — so *what* each pane splits matters as much as its `ratio`.

For four equal panes whose last two are short-lived, and whose space should come
back to the first two, build a balanced tree with `split_from`: split the root
once to claim the right half, then split each half in two. Panes are declared in
split order, which is not the same as left-to-right order.

```toml
[[tabs]]
name = "dev"
command = "nvim ."

  [[tabs.panes]]           # right half, home of the short-lived panes
  name = "install"
  ratio = 0.5
  command = "npm install"
  close_when_done = true

  [[tabs.panes]]           # splits the left half
  name = "agent"
  split_from = "dev"
  ratio = 0.5
  command = "claude"

  [[tabs.panes]]           # splits the right half
  name = "codegen"
  split_from = "install"
  ratio = 0.5
  command = "npm run codegen"
  close_when_done = true
```

That renders `dev | agent | install | codegen` at 25% each, and settles to an
even 50/50 once the right half exits. Chaining each pane off the previous one
would instead hand all the reclaimed space to one pane (25/75).

## Behaviour worth knowing

- **Idempotent copying.** A file already present at the destination is left
  alone, so reopening a worktree never clobbers a local edit.
- **No duplicate layouts.** On `worktree.opened`, tabs are only built when the
  workspace is still a single empty pane. Reopening a populated workspace copies
  files and stops.
- **Agent fallback.** If `agent start` fails (agent not installed, prompt not
  ready), the command runs as a plain pane command instead, so the pane is still
  useful — the failure is recorded in the plugin log.
- **Readiness.** Before running a command the plugin waits for the pane's own
  shell to be the foreground process, so keystrokes are not lost to a shell
  that is still starting.

## Debugging

```sh
herdr plugin log list --plugin danielb.wt --limit 20
```

Every run also dumps the raw event payload and its own log as `last-event.json`
and `last-run.log` under `HERDR_PLUGIN_STATE_DIR`, which resolves to
`~/.local/state/herdr/plugins/danielb.wt/`. The destination is printed as the
last line of each run.

To exercise it without creating a worktree, replay an event by hand:

```sh
HERDR_PLUGIN_EVENT=worktree.created \
HERDR_PLUGIN_EVENT_JSON='{"data":{"workspace":{"workspace_id":"w9","worktree":{"checkout_path":"/path/to/worktree","repo_root":"/path/to/main"}}}}' \
sh run.sh
```
