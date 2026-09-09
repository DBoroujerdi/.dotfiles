#!/usr/bin/env python3
"""
Herdr PR Status Plugin
Displays active GitHub Pull Request number and review state underneath each workspace/worktree
in the Herdr sidebar, with support for toggling on/off globally and parallel multi-repo fetching.
"""

import sys
import os
import json
import subprocess
import time
import re
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

PLUGIN_DIR = Path(__file__).parent.resolve()
CACHE_DIR = Path.home() / ".cache" / "herdr-pr-status"
STATE_FILE = CACHE_DIR / "state.json"
LAST_TOKENS_FILE = CACHE_DIR / "last_tokens.json"
CACHE_TTL = 60  # seconds

ALL_PR_TOKENS = [
    "pr_number",
    "pr_status",
    "pr_approval",
    "pr_state",
    "pr_approved",
    "pr_changes",
    "pr_review",
    "pr_draft",
    "pr_info",
    "pr_title",
    "pr_url"
]

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

def is_enabled():
    """Check if PR status plugin is enabled."""
    if not STATE_FILE.exists():
        return True
    try:
        with open(STATE_FILE, "r") as f:
            data = json.load(f)
            return data.get("enabled", True)
    except Exception:
        return True

def set_enabled(enabled: bool):
    """Persist enabled state."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with open(STATE_FILE, "w") as f:
        json.dump({"enabled": enabled, "updated_at": time.time()}, f, indent=2)

def notify_herdr(title, body=None, sound="none"):
    """Send an in-app toast notification to Herdr if running."""
    cmd = ["herdr", "notification", "show", title]
    if body:
        cmd.extend(["--body", body])
    if sound and sound in ("none", "done", "request"):
        cmd.extend(["--sound", sound])
    run_cmd(cmd, timeout=3)

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

def normalize_slug(text):
    if not text:
        return ""
    text = text.lower().strip()
    text = re.sub(r'[^a-z0-9]+', '-', text)
    return text.strip('-')

def extract_ticket(text):
    if not text:
        return None
    m = re.search(r'([A-Za-z]{2,10}-\d+)', text)
    return m.group(1).upper() if m else None

def format_pr_approval_status(pr):
    """
    Format approval status indicator string and state.
    Returns (status_text, state_label, badge_text)
    e.g. ("✓ approved", "APPROVED", "#332 ✓ approved")
    """
    number = f"#{pr['number']}"
    review_decision = pr.get("reviewDecision") or ""
    is_draft = pr.get("isDraft", False)
    pr_state = pr.get("state", "OPEN").upper()

    if pr_state == "MERGED":
        status_text = "⎇ merged"
        state_label = "MERGED"
    elif pr_state == "CLOSED":
        status_text = "⊘ closed"
        state_label = "CLOSED"
    elif is_draft:
        status_text = "📝 draft"
        state_label = "DRAFT"
    elif review_decision == "APPROVED":
        status_text = "✓ approved"
        state_label = "APPROVED"
    elif review_decision == "CHANGES_REQUESTED":
        status_text = "✕ changes"
        state_label = "CHANGES_REQUESTED"
    elif review_decision == "REVIEW_REQUIRED":
        status_text = "⏳ review"
        state_label = "REVIEW_REQUIRED"
    else:
        reviews = pr.get("reviews", [])
        has_approved = any(r.get("state") == "APPROVED" for r in reviews)
        has_changes = any(r.get("state") == "CHANGES_REQUESTED" for r in reviews)
        if has_approved and not has_changes:
            status_text = "✓ approved"
            state_label = "APPROVED"
        elif has_changes:
            status_text = "✕ changes"
            state_label = "CHANGES_REQUESTED"
        else:
            status_text = "⏳ review"
            state_label = "REVIEW_REQUIRED"

    badge_text = f"{number} {status_text}"
    return status_text, state_label, badge_text

def match_pr_to_workspace(ws_info, prs):
    """
    Match open PRs to a workspace using branch, label, slug, and ticket keys.
    """
    branch = ws_info.get("branch", "")
    label = ws_info.get("label", "")

    branch_norm = normalize_slug(branch)
    label_norm = normalize_slug(label)
    ticket = extract_ticket(branch) or extract_ticket(label)

    # 1. Exact match on branch
    if branch:
        for pr in prs:
            if pr.get("headRefName") == branch:
                return pr

    # 2. Exact match on label
    if label:
        for pr in prs:
            if pr.get("headRefName") == label:
                return pr

    # 3. Normalized slug match on branch
    if branch_norm:
        for pr in prs:
            if normalize_slug(pr.get("headRefName")) == branch_norm:
                return pr

    # 4. Normalized slug match on label
    if label_norm:
        for pr in prs:
            if normalize_slug(pr.get("headRefName")) == label_norm:
                return pr

    # 5. Ticket ID match (e.g. YBA-566)
    if ticket:
        for pr in prs:
            pr_ticket = extract_ticket(pr.get("headRefName", "")) or extract_ticket(pr.get("title", ""))
            if pr_ticket and pr_ticket == ticket:
                return pr

    # 6. Normalized substring match (branch or label longer than 4 chars)
    if branch_norm and len(branch_norm) > 4:
        for pr in prs:
            head_norm = normalize_slug(pr.get("headRefName"))
            if branch_norm in head_norm or head_norm in branch_norm:
                return pr

    if label_norm and len(label_norm) > 4:
        for pr in prs:
            head_norm = normalize_slug(pr.get("headRefName"))
            if label_norm in head_norm or head_norm in label_norm:
                return pr

    return None

def fetch_prs_for_remote(remote_url, sample_path, bypass_cache=False):
    """Fetch open PRs for a git remote using gh CLI, with disk caching."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    remote_hash = str(abs(hash(remote_url)))
    cache_file = CACHE_DIR / f"prs_{remote_hash}.json"

    if not bypass_cache and cache_file.exists():
        try:
            mtime = cache_file.stat().st_mtime
            if time.time() - mtime < CACHE_TTL:
                with open(cache_file, "r") as f:
                    return remote_url, json.load(f)
        except Exception:
            pass

    cmd = [
        "gh", "pr", "list",
        "--json", "number,title,headRefName,isDraft,reviewDecision,state,url,reviews",
        "--limit", "50"
    ]
    raw = run_cmd(cmd, cwd=sample_path, timeout=12)
    if not raw:
        if cache_file.exists():
            try:
                with open(cache_file, "r") as f:
                    return remote_url, json.load(f)
            except Exception:
                pass
        return remote_url, []

    try:
        prs = json.loads(raw)
        with open(cache_file, "w") as f:
            json.dump(prs, f)
        return remote_url, prs
    except Exception:
        return remote_url, []

def update_workspace_metadata(workspace_id, tokens_to_set=None, tokens_to_clear=None):
    """Report metadata tokens to Herdr for a workspace."""
    cmd = ["herdr", "workspace", "report-metadata", workspace_id, "--source", "pr-status"]

    if tokens_to_clear:
        for t in tokens_to_clear:
            cmd.extend(["--clear-token", t])

    if tokens_to_set:
        for k, v in tokens_to_set.items():
            cmd.extend(["--token", f"{k}={v}"])

    run_cmd(cmd, timeout=3)

def load_last_tokens():
    if LAST_TOKENS_FILE.exists():
        try:
            with open(LAST_TOKENS_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def save_last_tokens(data):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    try:
        with open(LAST_TOKENS_FILE, "w") as f:
            json.dump(data, f)
    except Exception:
        pass

def clear_all_metadata(snapshot=None):
    """Clear all PR metadata tokens across all workspaces in snapshot."""
    if not snapshot:
        snapshot = get_herdr_snapshot()
    if not snapshot:
        return

    workspaces = snapshot.get("workspaces", [])
    if not workspaces:
        return

    with ThreadPoolExecutor(max_workers=16) as pool:
        list(pool.map(
            lambda ws: update_workspace_metadata(ws["workspace_id"], tokens_to_clear=ALL_PR_TOKENS),
            workspaces
        ))
    save_last_tokens({})

def sync_pr_status(bypass_cache=False):
    """Main sync loop across all workspaces in the Herdr session."""
    if not is_enabled():
        clear_all_metadata()
        return

    snapshot = get_herdr_snapshot()
    if not snapshot:
        return

    workspaces = snapshot.get("workspaces", [])
    if not workspaces:
        return

    panes = snapshot.get("panes", [])
    ws_panes = {}
    for p in panes:
        wid = p.get("workspace_id")
        if wid not in ws_panes:
            ws_panes[wid] = []
        ws_panes[wid].append(p)

    def discover_ws(ws):
        ws_id = ws["workspace_id"]
        label = ws.get("label", "")
        wt = ws.get("worktree")
        path = wt.get("checkout_path") if wt else None

        if not path and ws_id in ws_panes:
            for p in ws_panes[ws_id]:
                cwd = p.get("foreground_cwd") or p.get("cwd")
                if cwd and os.path.exists(cwd):
                    path = cwd
                    break

        remote_url = None
        branch = None

        if path and os.path.exists(path):
            try:
                remote_url = run_cmd(["git", "-C", path, "config", "--get", "remote.origin.url"], timeout=2)
                branch = run_cmd(["git", "-C", path, "branch", "--show-current"], timeout=2)
                if not branch or branch == "HEAD":
                    branch = run_cmd(["git", "-C", path, "rev-parse", "--abbrev-ref", "HEAD"], timeout=2)
            except Exception:
                pass

        if not branch:
            branch = label

        return {
            "ws_id": ws_id,
            "label": label,
            "path": path,
            "branch": branch,
            "remote": remote_url
        }

    with ThreadPoolExecutor(max_workers=16) as pool:
        ws_git_info = list(pool.map(discover_ws, workspaces))

    remotes_to_fetch = {}
    for info in ws_git_info:
        r = info.get("remote")
        p = info.get("path")
        if r and p and r not in remotes_to_fetch:
            remotes_to_fetch[r] = p

    # Fetch PRs for all unique remotes concurrently
    remote_prs = {}
    if remotes_to_fetch:
        with ThreadPoolExecutor(max_workers=min(8, len(remotes_to_fetch))) as executor:
            futures = [
                executor.submit(fetch_prs_for_remote, r_url, s_path, bypass_cache)
                for r_url, s_path in remotes_to_fetch.items()
            ]
            for fut in futures:
                try:
                    r_url, prs = fut.result()
                    remote_prs[r_url] = prs
                except Exception:
                    pass

    last_tokens_map = load_last_tokens() if not bypass_cache else {}
    current_tokens_map = {}
    updates = []

    for info in ws_git_info:
        ws_id = info["ws_id"]
        remote = info["remote"]
        prs = remote_prs.get(remote, []) if remote else []

        matched_pr = match_pr_to_workspace(info, prs) if prs else None

        if matched_pr:
            status_text, state_label, badge_text = format_pr_approval_status(matched_pr)
            pr_num = f"#{matched_pr['number']}"

            tokens_to_set = {
                "pr_number": pr_num,
                "pr_status": badge_text,
                "pr_info": f"{pr_num} {status_text}",
                "pr_state": state_label,
                "pr_title": matched_pr.get("title", ""),
                "pr_url": matched_pr.get("url", "")
            }

            tokens_to_clear = []
            if state_label == "APPROVED":
                tokens_to_set["pr_approved"] = status_text
                tokens_to_clear.extend(["pr_changes", "pr_review", "pr_draft"])
            elif state_label == "CHANGES_REQUESTED":
                tokens_to_set["pr_changes"] = status_text
                tokens_to_clear.extend(["pr_approved", "pr_review", "pr_draft"])
            elif state_label == "DRAFT":
                tokens_to_set["pr_draft"] = status_text
                tokens_to_clear.extend(["pr_approved", "pr_changes", "pr_review"])
            else:
                tokens_to_set["pr_review"] = status_text
                tokens_to_clear.extend(["pr_approved", "pr_changes", "pr_draft"])

            current_tokens_map[ws_id] = tokens_to_set

            # Only send update if tokens changed or bypass_cache
            if bypass_cache or last_tokens_map.get(ws_id) != tokens_to_set:
                updates.append((ws_id, tokens_to_set, tokens_to_clear))
        else:
            current_tokens_map[ws_id] = {}
            if bypass_cache or last_tokens_map.get(ws_id):
                updates.append((ws_id, None, ALL_PR_TOKENS))

    save_last_tokens(current_tokens_map)

    if updates:
        def perform_update(args):
            wid, to_set, to_clear = args
            update_workspace_metadata(wid, tokens_to_set=to_set, tokens_to_clear=to_clear)

        with ThreadPoolExecutor(max_workers=16) as pool:
            list(pool.map(perform_update, updates))

def toggle_plugin():
    """Toggle PR status tracking on or off."""
    enabled = not is_enabled()
    set_enabled(enabled)

    if enabled:
        notify_herdr("PR Status: ON", "Tracking active pull requests across workspaces", sound="done")
        print("PR Status enabled. Syncing pull requests...")
        sync_pr_status(bypass_cache=True)
    else:
        notify_herdr("PR Status: OFF", "PR indicators disabled and cleared", sound="none")
        print("PR Status disabled. Clearing metadata...")
        clear_all_metadata()

def open_pr_in_browser():
    """Open current workspace's PR in default browser."""
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

    wt = focused_ws.get("worktree")
    path = wt.get("checkout_path") if wt else None
    if not path:
        panes = snapshot.get("panes", [])
        for p in panes:
            if p.get("workspace_id") == focused_ws["workspace_id"]:
                cwd = p.get("foreground_cwd") or p.get("cwd")
                if cwd and os.path.exists(cwd):
                    path = cwd
                    break

    if not path:
        print(f"Workspace '{focused_ws.get('label')}' is not associated with a directory.")
        return

    remote_url = run_cmd(["git", "-C", path, "config", "--get", "remote.origin.url"], timeout=3)
    if not remote_url:
        print(f"Workspace '{focused_ws.get('label')}' is not a Git repository.")
        return

    branch = run_cmd(["git", "-C", path, "branch", "--show-current"], timeout=3) or focused_ws.get("label", "")
    info = {
        "ws_id": focused_ws["workspace_id"],
        "label": focused_ws.get("label", ""),
        "path": path,
        "branch": branch,
        "remote": remote_url
    }

    _, prs = fetch_prs_for_remote(remote_url, path, bypass_cache=False)
    matched_pr = match_pr_to_workspace(info, prs)

    if matched_pr and matched_pr.get("url"):
        print(f"Opening PR #{matched_pr['number']}: {matched_pr['url']}")
        if sys.platform == "darwin":
            subprocess.run(["open", matched_pr["url"]])
        else:
            subprocess.run(["xdg-open", matched_pr["url"]])
    else:
        print(f"No open PR found for workspace '{focused_ws.get('label')}' ({branch})")

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

    wt = focused_ws.get("worktree")
    path = wt.get("checkout_path") if wt else None
    if not path:
        panes = snapshot.get("panes", [])
        for p in panes:
            if p.get("workspace_id") == focused_ws["workspace_id"]:
                cwd = p.get("foreground_cwd") or p.get("cwd")
                if cwd and os.path.exists(cwd):
                    path = cwd
                    break

    if not path:
        print(f"Workspace '{focused_ws.get('label')}' has no path.")
        return

    remote_url = run_cmd(["git", "-C", path, "config", "--get", "remote.origin.url"], timeout=3)
    if not remote_url:
        print("Workspace is not in a Git repository.")
        return

    repo_name = os.path.basename(path)
    _, prs = fetch_prs_for_remote(remote_url, path, bypass_cache=True)

    print(f"\x1b[1;36m=== Open Pull Requests: {repo_name} ===\x1b[0m\n")

    if not prs:
        print("No active open pull requests found.")
        return

    print(f"{'PR':<8} {'STATUS':<20} {'BRANCH':<30} {'TITLE'}")
    print("=" * 80)

    for pr in prs:
        status_text, state_label, badge_text = format_pr_approval_status(pr)
        num_str = f"#{pr['number']}"
        branch = pr.get("headRefName", "")[:28]
        title = pr.get("title", "")[:40]

        if "APPROVED" in state_label:
            status_fmt = f"\x1b[32m{status_text:<18}\x1b[0m"
        elif "CHANGES" in state_label:
            status_fmt = f"\x1b[31m{status_text:<18}\x1b[0m"
        elif "DRAFT" in state_label:
            status_fmt = f"\x1b[90m{status_text:<18}\x1b[0m"
        else:
            status_fmt = f"\x1b[33m{status_text:<18}\x1b[0m"

        print(f"{num_str:<8} {status_fmt:<27} {branch:<30} {title}")

def main():
    if "--toggle" in sys.argv:
        toggle_plugin()
        sys.exit(0)

    if "--enable" in sys.argv:
        set_enabled(True)
        notify_herdr("PR Status: ON", "Tracking active pull requests across workspaces", sound="done")
        print("PR Status enabled.")
        sync_pr_status(bypass_cache=True)
        sys.exit(0)

    if "--disable" in sys.argv:
        set_enabled(False)
        notify_herdr("PR Status: OFF", "PR indicators disabled and cleared", sound="none")
        print("PR Status disabled.")
        clear_all_metadata()
        sys.exit(0)

    if "--status" in sys.argv:
        status_str = "ENABLED" if is_enabled() else "DISABLED"
        print(f"PR Status Plugin is currently: {status_str}")
        sys.exit(0)

    if "--open" in sys.argv:
        open_pr_in_browser()
        sys.exit(0)

    if "--ui" in sys.argv:
        display_ui()
        sys.exit(0)

    if "--force" in sys.argv or "--refresh" in sys.argv:
        sync_pr_status(bypass_cache=True)
        sys.exit(0)

    if "--clear" in sys.argv:
        clear_all_metadata()
        sys.exit(0)

    if "--daemon" in sys.argv or "--watch" in sys.argv:
        while True:
            try:
                sync_pr_status()
            except Exception:
                pass
            time.sleep(30)
    else:
        sync_pr_status()

if __name__ == "__main__":
    main()
