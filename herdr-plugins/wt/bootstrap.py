#!/usr/bin/env python3
"""Bootstrap a Herdr worktree workspace from the repo's .wt.toml.

Runs as a Herdr plugin event hook on worktree.created and worktree.opened.

It reads <worktree>/.wt.toml (falling back to <main checkout>/.wt.toml), copies
the git-ignored files the fresh checkout needs, then builds the declared tabs
and panes and starts any agents among them.

Everything talks to Herdr through the CLI at HERDR_BIN_PATH, so this file has
no dependencies beyond a python3 with tomllib (3.11+).
"""

from __future__ import annotations

import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
import tomllib
from glob import glob
from pathlib import Path

HERDR = os.environ.get("HERDR_BIN_PATH") or "herdr"
CONFIG_NAME = ".wt.toml"
SPLIT_DIRECTIONS = ("right", "down")
PANE_READY_TIMEOUT = 8.0
AGENT_START_TIMEOUT = 180

# Fallback for `herdr agent start --kind`; the live list is read from the CLI.
FALLBACK_AGENT_KINDS = frozenset(
    {
        "agy", "amp", "claude", "cline", "codex", "copilot", "cursor", "devin",
        "droid", "gemini", "grok", "hermes", "kilo", "kimi", "kiro", "maki",
        "mastracode", "omp", "opencode", "pi", "qodercli",
    }
)

_log: list[str] = []
_failures = 0
_used_agent_names: set[str] = set()


def log(message: str) -> None:
    print(f"[wt] {message}", flush=True)
    _log.append(message)


def fail(message: str) -> None:
    global _failures
    _failures += 1
    print(f"[wt] error: {message}", file=sys.stderr, flush=True)
    _log.append(f"error: {message}")


def herdr(*args: str, timeout: int = 120) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            [HERDR, *args],
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.SubprocessError) as error:
        return subprocess.CompletedProcess([HERDR, *args], 1, "", str(error))


def herdr_json(*args: str, timeout: int = 120) -> dict | None:
    """Run a herdr command and return its `result` object."""
    completed = herdr(*args, timeout=timeout)
    if completed.returncode != 0:
        fail(f"{' '.join(args)}: {first_line(completed.stderr) or 'failed'}")
        return None
    try:
        payload = json.loads(completed.stdout)
    except json.JSONDecodeError:
        fail(f"{' '.join(args)}: response was not JSON")
        return None
    result = payload.get("result")
    return result if isinstance(result, dict) else None


def first_line(text: str) -> str:
    for line in (text or "").splitlines():
        line = line.strip()
        if line:
            return line
    return ""


# --- event / target resolution ------------------------------------------------


def load_event() -> dict:
    for name in ("HERDR_PLUGIN_EVENT_JSON", "HERDR_PLUGIN_CONTEXT_JSON"):
        raw = os.environ.get(name)
        if not raw:
            continue
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            continue
        if isinstance(parsed, dict):
            return parsed
    return {}


def resolve_target(event: dict) -> tuple[str | None, str | None, str | None, bool]:
    """Return (workspace_id, checkout_path, repo_root, already_open).

    Herdr wraps hook payloads as {"event": name, "data": {...}}; a hand-rolled
    flat payload (see the README's replay snippet) is accepted too.
    """
    payload = event.get("data") if isinstance(event.get("data"), dict) else event

    workspace = payload.get("workspace") if isinstance(payload.get("workspace"), dict) else {}
    worktree = payload.get("worktree") if isinstance(payload.get("worktree"), dict) else {}
    workspace_worktree = (
        workspace.get("worktree") if isinstance(workspace.get("worktree"), dict) else {}
    )

    workspace_id = (
        workspace.get("workspace_id")
        or worktree.get("open_workspace_id")
        or payload.get("workspace_id")
        or os.environ.get("HERDR_WORKSPACE_ID")
    )
    checkout = (
        worktree.get("path")
        or workspace_worktree.get("checkout_path")
        or workspace.get("cwd")
    )
    repo_root = workspace_worktree.get("repo_root")
    if not repo_root:
        source = payload.get("source")
        if isinstance(source, dict):
            repo_root = source.get("repo_root")
    already_open = bool(payload.get("already_open"))

    if workspace_id and not (checkout and repo_root):
        result = herdr_json("workspace", "get", workspace_id)
        info = (result or {}).get("workspace") or {}
        info_worktree = info.get("worktree") or {}
        checkout = checkout or info_worktree.get("checkout_path")
        repo_root = repo_root or info_worktree.get("repo_root")

    return workspace_id, checkout, repo_root, already_open


def load_config(checkout: str | None, repo_root: str | None) -> tuple[dict, Path | None]:
    # The main checkout wins over the worktree's own copy: .wt.toml is tracked,
    # so a new worktree carries whatever was committed on its branch, and
    # editing the file you are looking at should take effect without a commit.
    for base in (repo_root, checkout):
        if not base:
            continue
        candidate = Path(base) / CONFIG_NAME
        if candidate.is_file():
            try:
                with candidate.open("rb") as handle:
                    return tomllib.load(handle), candidate
            except (OSError, tomllib.TOMLDecodeError) as error:
                fail(f"could not read {candidate}: {error}")
                return {}, candidate
    return {}, None


# --- copying ------------------------------------------------------------------


def copy_files(patterns: list, source_root: str, dest_root: str) -> None:
    for raw in patterns:
        if not isinstance(raw, str) or not raw.strip():
            continue
        relative = os.path.normpath(raw.strip())
        if os.path.isabs(relative) or relative.startswith(".."):
            fail(f"copy_files entry must be inside the repo: {raw}")
            continue

        matches = sorted(glob(os.path.join(source_root, relative), recursive=True))
        if not matches:
            log(f"skip {relative} (not in {source_root})")
            continue

        for match in matches:
            name = os.path.relpath(match, source_root)
            destination = os.path.join(dest_root, name)
            if os.path.exists(destination):
                log(f"keep {name} (already present)")
                continue
            try:
                os.makedirs(os.path.dirname(destination) or dest_root, exist_ok=True)
                if os.path.isdir(match):
                    shutil.copytree(match, destination)
                else:
                    shutil.copy2(match, destination)
            except OSError as error:
                fail(f"could not copy {name}: {error}")
                continue
            log(f"copy {name}")


# --- config normalisation -----------------------------------------------------


def as_text(entry: dict, *keys: str) -> str | None:
    for key in keys:
        value = entry.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return None


def as_env(entry: dict) -> dict[str, str]:
    value = entry.get("env")
    if not isinstance(value, dict):
        return {}
    return {str(k): str(v) for k, v in value.items()}


def as_close_mode(entry: dict):
    """`close_when_done`: False (never), True (on success), or "always"."""
    for key in ("close_when_done", "close", "exit_when_done"):
        if key not in entry:
            continue
        value = entry[key]
        if isinstance(value, str):
            if value.strip().lower() == "always":
                return "always"
            fail(f"{key} must be true, false, or \"always\"; got {value!r}")
            return False
        return bool(value)
    return False


def close_wrapped(command: str, mode) -> str:
    """Append an `exit` so Herdr tears the pane down when the command finishes."""
    if mode == "always":
        return f"{{ {command} ; }} ; exit"
    if mode:
        return f"{{ {command} ; }} && exit"
    return command


def normalise_pane(entry: dict) -> dict:
    direction = (as_text(entry, "direction", "split") or "right").lower()
    if direction not in SPLIT_DIRECTIONS:
        fail(f"pane direction must be right or down, got {direction!r}; using right")
        direction = "right"
    ratio = entry.get("ratio")
    return {
        "name": as_text(entry, "name", "label", "title"),
        "command": as_text(entry, "command", "cmd", "run"),
        "direction": direction,
        "ratio": float(ratio) if isinstance(ratio, (int, float)) else None,
        "split_from": as_text(entry, "split_from", "from") or "previous",
        "agent": entry.get("agent"),
        "close": as_close_mode(entry),
        "env": as_env(entry),
    }


def normalise_tabs(config: dict) -> list[dict]:
    raw = None
    for key in ("tabs", "tmux_windows", "windows"):
        value = config.get(key)
        if isinstance(value, list) and value:
            raw = value
            break
    if raw is None:
        return []

    tabs = []
    for entry in raw:
        if not isinstance(entry, dict):
            fail(f"ignoring non-table tab entry: {entry!r}")
            continue
        panes = entry.get("panes")
        tabs.append(
            {
                "name": as_text(entry, "name", "label", "title"),
                "command": as_text(entry, "command", "cmd", "run"),
                "agent": entry.get("agent"),
                "close": as_close_mode(entry),
                "focus": bool(entry.get("focus")),
                "env": as_env(entry),
                "panes": [
                    normalise_pane(pane)
                    for pane in (panes if isinstance(panes, list) else [])
                    if isinstance(pane, dict)
                ],
            }
        )
    return tabs


# --- running commands ---------------------------------------------------------


def agent_kinds() -> frozenset[str]:
    completed = herdr("agent", "start", "--help", timeout=20)
    match = re.search(r"possible values:\s*([^\]]+)\]", completed.stdout or "")
    if match:
        kinds = {kind.strip() for kind in match.group(1).split(",") if kind.strip()}
        if kinds:
            return frozenset(kinds)
    return FALLBACK_AGENT_KINDS


def slug(value: str) -> str:
    """Lowercase, hyphenated, and safe for `herdr agent start <name>`."""
    return re.sub(r"[^a-z0-9_-]+", "-", value.lower()).strip("-")


def agent_name(label: str | None, workspace_id: str | None) -> str:
    base = slug(label or "agent")
    if not base or not base[0].isalpha():
        base = f"a{base}" if base else "agent"
    suffix = f"-{slug(workspace_id)}" if workspace_id else ""
    candidate = f"{base}{suffix}"[:32]
    index = 2
    while candidate in _used_agent_names:
        candidate = f"{base}{suffix}-{index}"[:32]
        index += 1
    _used_agent_names.add(candidate)
    return candidate


def wait_for_prompt(pane_id: str, timeout: float = PANE_READY_TIMEOUT) -> bool:
    """Wait until the pane's own shell is the foreground process."""
    deadline = time.monotonic() + timeout
    while True:
        result = herdr_json("pane", "process-info", "--pane", pane_id, timeout=20)
        info = (result or {}).get("process_info") or {}
        shell_pid = info.get("shell_pid")
        foreground = info.get("foreground_processes") or []
        if shell_pid and any(entry.get("pid") == shell_pid for entry in foreground):
            return True
        if time.monotonic() >= deadline:
            return False
        time.sleep(0.15)


def resolve_kind(command: str, preference, kinds: frozenset[str]) -> str | None:
    if preference is False:
        return None
    if isinstance(preference, str) and preference.strip():
        kind = preference.strip()
        if kind not in kinds:
            fail(f"unknown agent kind {kind!r}; running it as a plain command")
            return None
        return kind
    argv = shlex.split(command)
    if not argv:
        return None
    executable = Path(argv[0]).name
    return executable if executable in kinds else None


def run_in_pane(
    pane_id: str,
    command: str | None,
    *,
    label: str | None,
    workspace_id: str | None,
    preference,
    kinds: frozenset[str],
    close=False,
) -> None:
    if not command:
        return

    wait_for_prompt(pane_id)
    # A self-closing pane is a one-shot command, never an agent session.
    kind = None if close else resolve_kind(command, preference, kinds)

    if kind:
        argv = shlex.split(command)
        extra = argv[1:]
        for attempt in range(2):
            name = agent_name(label or kind, workspace_id)
            args = ["agent", "start", name, "--kind", kind, "--pane", pane_id]
            if extra:
                args += ["--", *extra]
            completed = herdr(*args, timeout=AGENT_START_TIMEOUT)
            if completed.returncode == 0:
                log(f"agent {kind} started as '{name}' in {pane_id}")
                return
            error = first_line(completed.stderr) or first_line(completed.stdout)
            if attempt == 0 and "name" in error.lower():
                continue
            fail(f"agent start {kind} in {pane_id}: {error}; running as plain command")
            break

    completed = herdr("pane", "run", pane_id, close_wrapped(command, close))
    if completed.returncode != 0:
        fail(f"pane run in {pane_id}: {first_line(completed.stderr) or 'failed'}")
        return
    closing = {"always": " (closes when done)", True: " (closes if it succeeds)"}.get(close, "")
    log(f"run {command!r} in {pane_id}{closing}")


# --- layout -------------------------------------------------------------------


def find_fresh_root(workspace_id: str) -> tuple[str, str] | None:
    """Return (tab_id, pane_id) when the workspace is still a single empty pane."""
    tabs = (herdr_json("tab", "list", "--workspace", workspace_id) or {}).get("tabs") or []
    if len(tabs) != 1:
        return None
    tab_id = tabs[0].get("tab_id")
    panes = (herdr_json("pane", "list", "--workspace", workspace_id) or {}).get("panes") or []
    in_tab = [pane for pane in panes if pane.get("tab_id") == tab_id]
    if len(in_tab) != 1 or in_tab[0].get("agent"):
        return None
    pane_id = in_tab[0].get("pane_id")
    return (tab_id, pane_id) if tab_id and pane_id else None


def create_tab(tab: dict, workspace_id: str, checkout: str) -> tuple[str, str] | None:
    args = ["tab", "create", "--workspace", workspace_id, "--cwd", checkout, "--no-focus"]
    if tab["name"]:
        args += ["--label", tab["name"]]
    for key, value in tab["env"].items():
        args += ["--env", f"{key}={value}"]
    result = herdr_json(*args)
    tab_id = ((result or {}).get("tab") or {}).get("tab_id")
    pane_id = ((result or {}).get("root_pane") or {}).get("pane_id")
    if not (tab_id and pane_id):
        fail(f"could not create tab {tab['name'] or '<unnamed>'}")
        return None
    return tab_id, pane_id


def split_pane(spec: dict, target: str, checkout: str) -> str | None:
    args = [
        "pane", "split",
        "--pane", target,
        "--direction", spec["direction"],
        "--cwd", checkout,
        "--no-focus",
    ]
    if spec["ratio"] is not None:
        args += ["--ratio", str(spec["ratio"])]
    for key, value in spec["env"].items():
        args += ["--env", f"{key}={value}"]
    result = herdr_json(*args)
    pane_id = ((result or {}).get("pane") or {}).get("pane_id")
    if not pane_id:
        fail(f"could not split {target} {spec['direction']}")
        return None
    return pane_id


def build_layout(
    tabs: list[dict],
    workspace_id: str,
    checkout: str,
    kinds: frozenset[str],
    *,
    fresh_root: tuple[str, str] | None,
) -> None:
    for index, tab in enumerate(tabs):
        if index == 0 and fresh_root:
            tab_id, root_pane = fresh_root
            if tab["name"]:
                herdr("tab", "rename", tab_id, tab["name"])
            log(f"reuse {tab_id} as {tab['name'] or tab_id}")
        else:
            created = create_tab(tab, workspace_id, checkout)
            if not created:
                continue
            tab_id, root_pane = created
            log(f"tab {tab_id} {tab['name'] or '<unnamed>'}")

        if tab["name"]:
            herdr("pane", "rename", root_pane, tab["name"])

        # Build the whole pane tree before running anything. A close_when_done
        # pane can exit the moment its command finishes, and a pane that has
        # gone cannot be split — so no command starts until every split is in.
        plan = [(root_pane, tab["command"], tab["name"], tab["agent"], tab["close"])]

        previous = root_pane
        # Named panes can be split later, which is what makes a balanced tree
        # expressible: space from a closing pane goes to its sibling, so what
        # you split determines where the room comes back.
        named = {tab["name"]: root_pane} if tab["name"] else {}
        for spec in tab["panes"]:
            source = spec["split_from"]
            if source.lower() == "root":
                target = root_pane
            elif source.lower() == "previous":
                target = previous
            elif source in named:
                target = named[source]
            else:
                fail(f"unknown split_from {source!r}; splitting the previous pane")
                target = previous

            pane_id = split_pane(spec, target, checkout)
            if not pane_id:
                continue
            log(f"pane {pane_id} {spec['direction']} of {target}")
            if spec["name"]:
                herdr("pane", "rename", pane_id, spec["name"])
                named[spec["name"]] = pane_id
            plan.append(
                (
                    pane_id,
                    spec["command"],
                    spec["name"] or tab["name"],
                    spec["agent"],
                    spec["close"],
                )
            )
            previous = pane_id

        for pane_id, command, label, preference, close in plan:
            run_in_pane(
                pane_id,
                command,
                label=label,
                workspace_id=workspace_id,
                preference=preference,
                kinds=kinds,
                close=close,
            )

        if tab["focus"]:
            herdr("tab", "focus", tab_id)


# --- entry point --------------------------------------------------------------


def write_state(event: dict) -> None:
    """Dump the raw event and this run's log for debugging."""
    # Event hooks are not currently given the plugin state/config dirs, so fall
    # back to the temp dir rather than dropping the dump on the floor.
    target = (
        os.environ.get("HERDR_PLUGIN_STATE_DIR")
        or os.environ.get("HERDR_PLUGIN_CONFIG_DIR")
        or os.path.join(tempfile.gettempdir(), "herdr-wt")
    )
    try:
        os.makedirs(target, exist_ok=True)
        Path(target, "last-event.json").write_text(
            json.dumps(event, indent=2), encoding="utf-8"
        )
        Path(target, "last-run.log").write_text("\n".join(_log) + "\n", encoding="utf-8")
        print(f"[wt] debug dump: {target}", flush=True)
    except OSError as error:
        print(f"[wt] note: could not write debug state to {target}: {error}", flush=True)


def main() -> int:
    event_name = os.environ.get("HERDR_PLUGIN_EVENT", "manual")
    event = load_event()
    workspace_id, checkout, repo_root, already_open = resolve_target(event)

    if not checkout:
        fail(f"{event_name}: no worktree checkout path in the event payload")
        write_state(event)
        return 1

    config, config_path = load_config(checkout, repo_root)
    if not config_path:
        log(f"no {CONFIG_NAME} in {checkout}; nothing to do")
        write_state(event)
        return 0

    log(f"{event_name}: {config_path}")

    patterns = config.get("copy_files")
    if isinstance(patterns, list) and patterns:
        if repo_root and os.path.realpath(repo_root) != os.path.realpath(checkout):
            copy_files(patterns, repo_root, checkout)
        else:
            log("skip copy_files (no separate source checkout)")

    tabs = normalise_tabs(config)
    if tabs and workspace_id:
        # Only ever lay out a workspace that is still a single empty pane. A
        # freshly created worktree always is; a reopened one only is when it has
        # nothing in it yet. This is what keeps `worktree.opened` from stacking
        # duplicate tabs, so it deliberately does not trust `already_open`.
        fresh_root = find_fresh_root(workspace_id)
        if fresh_root:
            build_layout(
                tabs, workspace_id, checkout, agent_kinds(), fresh_root=fresh_root
            )
        else:
            log(
                f"{workspace_id} already has a layout"
                f"{' (already open)' if already_open else ''}; leaving tabs alone"
            )
    elif tabs:
        fail("no workspace id in the event payload; skipped tabs")

    write_state(event)
    return 1 if _failures else 0


if __name__ == "__main__":
    sys.exit(main())
