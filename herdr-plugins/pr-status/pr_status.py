#!/usr/bin/env python3
"""
Herdr PR Status Plugin
Displays current active (open) PRs and their approval status in the Herdr sidebar,
strictly scoped to the currently focused Git repository.
"""

import sys
import os
import json
import subprocess
import time
import re
from pathlib import Path

PLUGIN_DIR = Path(__file__).parent.resolve()
CACHE_DIR = Path.home() / ".cache" / "herdr-pr-status"
CACHE_TTL = 30  # seconds

def run_cmd(cmd, cwd=None, timeout=10):
    try:
        res = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            cwd=cwd,
            timeout=timeout
        )
        if res.returncode == 0:
            return res.stdout.strip()
    except Exception:
        pass
    return None

def get_herdr_snapshot():
    output = run_cmd(["herdr", "api", "snapshot"])
    if not output:
        return None
    try:
        data = json.loads(output)
        if data.get("type") == "session_snapshot":
            return data.get("result", {}).get("snapshot", {})
        elif "result" in data and "snapshot" in data["result"]:
            return data["result"]["snapshot"]
    except Exception:
        pass
    return None

def resolve_workspace_repo(workspace):
    """Determine git repo_root for a workspace."""
    wt = workspace.get("worktree")
    if wt:
        repo_root = wt.get("repo_root")
        if repo_root:
            return os.path.realpath(repo_root)
        checkout_path = wt.get("checkout_path")
        if checkout_path and os.path.isdir(checkout_path):
            return os.path.realpath(checkout_path)

    # Fallback: check checkout_path or workspace label
    checkout_path = workspace.get("worktree", {}).get("checkout_path")
    if checkout_path and os.path.exists(checkout_path):
        top = run_cmd(["git", "-C", checkout_path, "rev-parse", "--show-toplevel"])
        if top:
            return os.path.realpath(top)

    return None

def get_workspace_branch(workspace):
    """Determine git branch for a workspace."""
    wt = workspace.get("worktree")
    if wt:
        checkout_path = wt.get("checkout_path")
        if checkout_path and os.path.isdir(checkout_path):
            branch = run_cmd(["git", "-C", checkout_path, "branch", "--show-current"])
            if branch:
                return branch
            head = run_cmd(["git", "-C", checkout_path, "rev-parse", "--abbrev-ref", "HEAD"])
            if head and head != "HEAD":
                return head
    return workspace.get("label", "")

def fetch_open_prs(repo_dir, bypass_cache=False):
    """Fetch open PRs for a repository using gh CLI, with disk caching."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    repo_hash = str(abs(hash(repo_dir)))
    cache_file = CACHE_DIR / f"prs_{repo_hash}.json"

    if not bypass_cache and cache_file.exists():
        try:
            mtime = cache_file.stat().st_mtime
            if time.time() - mtime < CACHE_TTL:
                with open(cache_file, "r") as f:
                    return json.load(f)
        except Exception:
            pass

    cmd = [
        "gh", "pr", "list",
        "--json", "number,title,headRefName,isDraft,reviewDecision,state,url,reviews",
        "--limit", "50"
    ]
    raw = run_cmd(cmd, cwd=repo_dir, timeout=15)
    if not raw:
        return []

    try:
        prs = json.loads(raw)
        with open(cache_file, "w") as f:
            json.dump(prs, f)
        return prs
    except Exception:
        return []

def format_pr_approval_status(pr):
    """
    Format approval status indicator string.
    Returns (short_status, approval_label)
    e.g. ("#369 ⏳", "REVIEW_REQUIRED") or ("#332 ✓", "APPROVED")
    """
    number = f"#{pr['number']}"
    review_decision = pr.get("reviewDecision") or ""
    is_draft = pr.get("isDraft", False)

    if is_draft:
        icon = "📝"
        label = "DRAFT"
    elif review_decision == "APPROVED":
        icon = "✓"
        label = "APPROVED"
    elif review_decision == "CHANGES_REQUESTED":
        icon = "✕"
        label = "CHANGES_REQUESTED"
    elif review_decision == "REVIEW_REQUIRED":
        icon = "⏳"
        label = "REVIEW_REQUIRED"
    else:
        reviews = pr.get("reviews", [])
        has_approved = any(r.get("state") == "APPROVED" for r in reviews)
        has_changes = any(r.get("state") == "CHANGES_REQUESTED" for r in reviews)
        if has_approved and not has_changes:
            icon = "✓"
            label = "APPROVED"
        elif has_changes:
            icon = "✕"
            label = "CHANGES_REQUESTED"
        else:
            icon = "⏳"
            label = "REVIEW_REQUIRED"

    return f"{number} {icon}", label

def normalize_slug(text):
    if not text:
        return ""
    text = text.lower().strip()
    text = re.sub(r'[^a-z0-9]+', '-', text)
    return text.strip('-')

def match_pr_to_workspace(workspace, prs):
    """Match open PRs to a workspace by branch name or workspace label."""
    branch = get_workspace_branch(workspace)
    label = workspace.get("label", "")

    branch_norm = normalize_slug(branch)
    label_norm = normalize_slug(label)

    best_match = None

    for pr in prs:
        head_ref = pr.get("headRefName", "")
        head_norm = normalize_slug(head_ref)

        # 1. Exact match
        if branch and branch == head_ref:
            return pr
        if label and label == head_ref:
            return pr

        # 2. Normalized slug match
        if branch_norm and branch_norm == head_norm:
            return pr
        if label_norm and label_norm == head_norm:
            return pr

        # 3. Partial substring match
        if branch_norm and (branch_norm in head_norm or head_norm in branch_norm):
            best_match = pr
        elif label_norm and (label_norm in head_norm or head_norm in label_norm):
            if not best_match:
                best_match = pr

    return best_match

def update_workspace_metadata(workspace_id, tokens_to_set=None, tokens_to_clear=None):
    """Call herdr workspace report-metadata."""
    cmd = ["herdr", "workspace", "report-metadata", workspace_id, "--source", "pr-status"]

    if tokens_to_clear:
        for t in tokens_to_clear:
            cmd.extend(["--clear-token", t])

    if tokens_to_set:
        for k, v in tokens_to_set.items():
            cmd.extend(["--token", f"{k}={v}"])

    run_cmd(cmd)

def sync_pr_status(bypass_cache=False):
    """Main sync pass."""
    snapshot = get_herdr_snapshot()
    if not snapshot:
        return

    workspaces = snapshot.get("workspaces", [])
    if not workspaces:
        return

    focused_ws_id = snapshot.get("focused_workspace_id")
    focused_ws = None
    active_env_ws = os.environ.get("HERDR_ACTIVE_WORKSPACE_ID")

    if focused_ws_id:
        focused_ws = next((ws for ws in workspaces if ws.get("workspace_id") == focused_ws_id), None)
    if not focused_ws:
        focused_ws = next((ws for ws in workspaces if ws.get("focused")), None)
    if not focused_ws and active_env_ws:
        focused_ws = next((ws for ws in workspaces if ws.get("workspace_id") == active_env_ws), None)

    # If Herdr snapshot reports no focused workspace (e.g. window unfocused or background event),
    # preserve existing sidebar tokens and return early.
    if not focused_ws:
        return

    focused_repo = resolve_workspace_repo(focused_ws)

    # If the focused workspace is explicitly NOT in a Git repo, clear PR metadata
    if not focused_repo:
        for ws in workspaces:
            update_workspace_metadata(
                ws["workspace_id"],
                tokens_to_clear=["pr_status", "pr_approval", "pr_number", "pr_title", "pr_url"]
            )
        return


    # Fetch open PRs for the focused repository
    open_prs = fetch_open_prs(focused_repo, bypass_cache=bypass_cache)

    # Process all workspaces
    for ws in workspaces:
        ws_id = ws["workspace_id"]
        ws_repo = resolve_workspace_repo(ws)

        # STRICT REQUIREMENT: Only update workspaces belonging to the currently focused git repo
        if ws_repo and (ws_repo == focused_repo):
            pr = match_pr_to_workspace(ws, open_prs)
            if pr:
                short_status, approval_label = format_pr_approval_status(pr)
                update_workspace_metadata(
                    ws_id,
                    tokens_to_set={
                        "pr_status": short_status,
                        "pr_approval": approval_label,
                        "pr_number": f"#{pr['number']}",
                        "pr_title": pr.get("title", ""),
                        "pr_url": pr.get("url", "")
                    }
                )
            else:
                update_workspace_metadata(
                    ws_id,
                    tokens_to_clear=["pr_status", "pr_approval", "pr_number", "pr_title", "pr_url"]
                )
        else:
            # Workspace belongs to a DIFFERENT repository than focused repo -> Clear PR tokens
            update_workspace_metadata(
                ws_id,
                tokens_to_clear=["pr_status", "pr_approval", "pr_number", "pr_title", "pr_url"]
            )

def open_pr_in_browser():
    """Open current workspace PR in default browser."""
    snapshot = get_herdr_snapshot()
    if not snapshot:
        return

    workspaces = snapshot.get("workspaces", [])
    focused_id = snapshot.get("focused_workspace_id") or os.environ.get("HERDR_ACTIVE_WORKSPACE_ID")
    focused_ws = next((ws for ws in workspaces if ws.get("workspace_id") == focused_id or ws.get("focused")), None)
    if not focused_ws:
        print("No focused workspace found.")
        return

    repo = resolve_workspace_repo(focused_ws)
    if not repo:
        print("Focused workspace is not in a Git repository.")
        return

    prs = fetch_open_prs(repo)
    pr = match_pr_to_workspace(focused_ws, prs)
    if pr and pr.get("url"):
        print(f"Opening PR #{pr['number']}: {pr['url']}")
        if sys.platform == "darwin":
            subprocess.run(["open", pr["url"]])
        else:
            subprocess.run(["xdg-open", pr["url"]])
    else:
        print(f"No open PR found for workspace '{focused_ws.get('label')}'")

def display_ui():
    """Render a visual TUI table of open PRs in the focused repo."""
    snapshot = get_herdr_snapshot()
    if not snapshot:
        print("Herdr snapshot unavailable.")
        return

    workspaces = snapshot.get("workspaces", [])
    focused_id = snapshot.get("focused_workspace_id") or os.environ.get("HERDR_ACTIVE_WORKSPACE_ID")
    focused_ws = next((ws for ws in workspaces if ws.get("workspace_id") == focused_id or ws.get("focused")), None)
    if not focused_ws:
        print("No focused workspace found.")
        return

    repo = resolve_workspace_repo(focused_ws)
    if not repo:
        print("Focused workspace is not in a Git repository.")
        return

    repo_name = os.path.basename(repo)
    prs = fetch_open_prs(repo, bypass_cache=True)

    print(f"\x1b[1;36m=== Open Pull Requests: {repo_name} ===\x1b[0m\n")

    if not prs:
        print("No active open pull requests found.")
        return

    print(f"{'PR':<8} {'STATUS':<20} {'BRANCH':<30} {'TITLE'}")
    print("=" * 80)

    for pr in prs:
        short_st, approval_lbl = format_pr_approval_status(pr)
        num_str = f"#{pr['number']}"
        branch = pr.get("headRefName", "")[:28]
        title = pr.get("title", "")[:40]

        if "APPROVED" in approval_lbl:
            status_fmt = f"\x1b[32m✓ APPROVED\x1b[0m"
        elif "CHANGES" in approval_lbl:
            status_fmt = f"\x1b[31m✕ CHANGES\x1b[0m"
        elif "DRAFT" in approval_lbl:
            status_fmt = f"\x1b[90m📝 DRAFT\x1b[0m"
        else:
            status_fmt = f"\x1b[33m⏳ REVIEW\x1b[0m"

        print(f"{num_str:<8} {status_fmt:<29} {branch:<30} {title}")

def main():
    if "--open" in sys.argv:
        open_pr_in_browser()
        sys.exit(0)

    if "--ui" in sys.argv:
        display_ui()
        sys.exit(0)

    if "--force" in sys.argv:
        sync_pr_status(bypass_cache=True)
        sys.exit(0)

    if "--clear" in sys.argv:
        snapshot = get_herdr_snapshot()
        if snapshot:
            for ws in snapshot.get("workspaces", []):
                update_workspace_metadata(
                    ws["workspace_id"],
                    tokens_to_clear=["pr_status", "pr_approval", "pr_number", "pr_title", "pr_url"]
                )
        sys.exit(0)

    if "--daemon" in sys.argv or "--watch" in sys.argv:
        while True:
            try:
                sync_pr_status()
            except Exception:
                pass
            time.sleep(15)
    else:
        sync_pr_status()

if __name__ == "__main__":
    main()
