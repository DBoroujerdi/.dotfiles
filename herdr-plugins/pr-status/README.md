# Herdr PR Status Plugin (`danielb.pr-status`)

A native Herdr plugin that displays current active (open) GitHub Pull Requests and their review/approval status directly in the Herdr sidebar.

> [!IMPORTANT]
> **Repo-Scoped Display:** As requested, PR statuses are strictly scoped to the **currently focused Git repository**. Workspaces that belong to other repositories automatically have their PR tokens cleared so only the active repository's open PRs are displayed in the sidebar.

---

## Features

- **Sidebar Integration:** Renders open PR numbers and approval indicators (e.g. `#369 ⏳`, `#332 ✓`, `#359 📝`, `#367 ✕`) directly on workspace rows in the sidebar.
- **Strict Repository Scoping:** Automatically determines the Git repository of the currently focused workspace and updates only matching workspaces. Non-focused repository workspaces remain clean.
- **Approval Indicators:**
  - `✓` (`APPROVED`) – Approved by reviewers.
  - `✕` (`CHANGES_REQUESTED`) – Changes requested.
  - `⏳` (`REVIEW_REQUIRED`) – Pending review.
  - `📝` (`DRAFT`) – Draft pull request.
- **Automatic Event-Driven Sync:** Triggers instantly on `workspace.focused`, `workspace.created`, `workspace.updated`, `worktree.created`, and `worktree.opened`.
- **Background Daemon & Caching:** Includes 30-second TTL disk caching and a background watcher loop to avoid GitHub API rate limits.
- **Interactive Commands & Keybindings:**
  - `prefix+alt+o`: Open the current workspace's PR directly in your browser.
  - `prefix+alt+p`: Display a formatted terminal table of all open PRs in the current repo.

---

## Installation & Link

The plugin is located at:
`~/.dotfiles/herdr-plugins/pr-status`

To link or re-link into Herdr:
```bash
herdr plugin link ~/.dotfiles/herdr-plugins/pr-status
```

---

## Herdr Configuration (`~/.config/herdr/config.toml`)

To render `$pr_status` tokens in the sidebar, ensure your `config.toml` includes `$pr_status` under `[ui.sidebar.spaces]`:

```toml
[ui.sidebar.spaces]
rows = [["state_icon", "workspace"], ["branch", "git_status", "$pr_status"]]

[[keys.command]]
key = "prefix+alt+o"
type = "plugin_action"
command = "danielb.pr-status.open-pr"
description = "open workspace PR in browser"

[[keys.command]]
key = "prefix+alt+p"
type = "plugin_action"
command = "danielb.pr-status.view-prs"
description = "list repo open PRs"
```

Reload Herdr config at any time using:
```bash
herdr server reload-config
```

---

## CLI Usage & Plugin Actions

You can invoke actions directly from the CLI or within Herdr panes:

```bash
# Force refresh PR status for the focused repository
herdr plugin action invoke --plugin danielb.pr-status refresh

# List all open PRs in the focused repository in a styled table
python3 ~/.dotfiles/herdr-plugins/pr-status/pr_status.py --ui

# Open current workspace's PR in browser
python3 ~/.dotfiles/herdr-plugins/pr-status/pr_status.py --open
```

---

## Plugin Tokens Available

The following metadata tokens are published by this plugin for each workspace:

- `$pr_status`: Formatted badge (e.g. `#369 ⏳` or `#332 ✓`).
- `$pr_approval`: Status label (`APPROVED`, `CHANGES_REQUESTED`, `REVIEW_REQUIRED`, `DRAFT`).
- `$pr_number`: PR number (e.g. `#369`).
- `$pr_title`: PR title string.
- `$pr_url`: Web link to GitHub PR.
