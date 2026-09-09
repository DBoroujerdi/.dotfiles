# Herdr PR Status Plugin (`danielb.pr-status`)

A native Herdr plugin that displays active (open) GitHub Pull Request number and review state directly underneath each worktree/workspace in the Herdr sidebar.

---

## Key Features

- **Under-Worktree Display:** PR numbers and review state appear cleanly on their own line underneath each workspace/worktree row.
- **Global Multi-Repo Tracking:** Simultaneously tracks and maps PRs across all active repositories and worktrees. PR tokens stay persistent and do **not** disappear or flicker when you switch focus between workspaces.
- **Complete Toggle On/Off:** Instantly toggle PR status tracking on or off with a keybinding or CLI command. When toggled off, all PR tokens are cleared from the sidebar.
- **Parallel Multi-Repo Sync:** Fetches GitHub PRs across unique repository remotes in parallel with disk caching and token diffing for fast, non-blocking sidebar updates.
- **Browser & TUI Actions:** Open the active workspace's PR directly in your browser or view open PRs in an interactive overlay table.

---

## Visual Presentation

In the Herdr sidebar, workspaces with an open pull request show the PR number and review state underneath the branch row:

```
● yba-561-runtime-config-files
  YBA-561-runtime-config-files
  #371 ⏳ review
```

### Review State Color Indicators:
- **`#332 ✓ approved`** (`#50fa7b` Green) – Approved by reviewers
- **`#123 ✕ changes`** (`#ff5555` Red) – Changes requested
- **`#371 ⏳ review`** (`#ffb86c` Yellow) – Pending review
- **`#375 📝 draft`** (`#6272a4` Gray) – Draft pull request

Workspaces with no open PR (or when the plugin is toggled off) show only the normal workspace and branch rows.

---

## Herdr Configuration (`~/.config/herdr/config.toml`)

### Sidebar Row Layout
```toml
[ui.sidebar.spaces]
rows = [
  ["state_icon", "workspace"],
  ["branch", "git_status"],
  [
    { token = "$pr_number", fg = "#7aa2f7" },
    { token = "$pr_approved", fg = "#50fa7b" },
    { token = "$pr_changes", fg = "#ff5555" },
    { token = "$pr_review", fg = "#ffb86c" },
    { token = "$pr_draft", fg = "#6272a4", dim = true }
  ]
]
```

### Keybindings
```toml
# Toggle PR status display on/off globally
[[keys.command]]
key = "prefix+alt+p"
type = "plugin_action"
command = "danielb.pr-status.toggle"
description = "toggle PR status display"

# Open current workspace's PR in default browser
[[keys.command]]
key = "prefix+alt+o"
type = "plugin_action"
command = "danielb.pr-status.open-pr"
description = "open workspace PR in browser"

# List all open PRs in the current repo in a TUI popup
[[keys.command]]
key = "prefix+alt+l"
type = "plugin_action"
command = "danielb.pr-status.view-prs"
description = "list repo open PRs"
```

Apply changes:
```bash
herdr server reload-config   # or § r
```

---

## Available Tokens

For custom sidebar formatting, the plugin reports the following metadata tokens per workspace:

| Token | Description | Example |
|---|---|---|
| `$pr_number` | PR number prefixed with `#` | `#371` |
| `$pr_approved` | Formatted status if approved (cleared otherwise) | `✓ approved` |
| `$pr_changes` | Formatted status if changes requested (cleared otherwise) | `✕ changes` |
| `$pr_review` | Formatted status if pending review (cleared otherwise) | `⏳ review` |
| `$pr_draft` | Formatted status if draft (cleared otherwise) | `📝 draft` |
| `$pr_status` | Combined number + status icon & text | `#371 ⏳ review` |
| `$pr_state` | Raw state label | `APPROVED`, `REVIEW_REQUIRED`, `DRAFT` |
| `$pr_title` | Pull request title | `feat: support multiple remotes` |
| `$pr_url` | Full GitHub PR URL | `https://github.com/.../pull/371` |

---

## CLI Usage

```bash
# Toggle PR status tracking on or off (with Herdr toast notification)
python3 ~/.dotfiles/herdr-plugins/pr-status/pr_status.py --toggle

# Force refresh PR status across all repositories
python3 ~/.dotfiles/herdr-plugins/pr-status/pr_status.py --force

# Open current workspace's PR in browser
python3 ~/.dotfiles/herdr-plugins/pr-status/pr_status.py --open

# List repo open PRs in a formatted table
python3 ~/.dotfiles/herdr-plugins/pr-status/pr_status.py --ui

# Check plugin enabled/disabled status
python3 ~/.dotfiles/herdr-plugins/pr-status/pr_status.py --status
```
