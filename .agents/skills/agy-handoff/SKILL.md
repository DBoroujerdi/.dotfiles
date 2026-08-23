---
name: agy-handoff
description: Hand off investigation findings to a fresh Antigravity (agy) agent in an isolated Herdr worktree. Use when delegating work to agy, spinning up an agy agent, or asked to hand off to Antigravity.
argument-hint: "what the fresh agy agent should build"
disable-model-invocation: true
---

# Agy handoff

## Overview

Write your findings to a durable document, create an isolated worktree through Herdr, start `agy` in
it, and point that agent at the document.

**REQUIRED BACKGROUND:** read `references/handoff-contract.md` in this skill directory. It holds the
document contract, the prompt contract, the worktree and pane rules, and the dispatch verification
steps. This file covers only what is specific to Antigravity.

**REQUIRED BACKGROUND:** use the `herdr` skill for CLI discovery and safety rules before running any
`herdr` command. Herdr must be present: `test "${HERDR_ENV:-}" = 1`.

## When to use

- You diagnosed something and the fix belongs on a different branch or PR
- The next phase needs a clean context and yours is full of investigation
- Work should proceed in parallel with what you are doing
- The user asked for an agy agent to be set to work

**Not for:** work you can finish now, a task the user is about to do themselves, or work that already
has a Jira ticket. A ticket is its own handoff document, so use `ticket-to-agent` instead.

Reach for `claude-handoff` when the receiving agent should be Claude Code rather than Antigravity.

## 1. Write the document

Follow the document contract. Store it at `<worktrees-parent>/.handoff-<slug>/handoff.md`, outside
every repo, and copy evidence files in beside it.

## 2. Create the worktree

Per the contract, from the main repo root:

```sh
herdr worktree create --cwd <main repo root> \
  --branch fix/<slug> --base origin/main \
  --path <worktrees-parent>/<slug> --label "<slug>" --no-focus --json
```

## 3. Start agy in a shell pane

`--kind agy` is the canonical kind. Pass Antigravity's own flags after `--`.

```sh
herdr agent start handoff-<slug> --kind agy --pane <shell-pane> --timeout 120000 \
  -- --dangerously-skip-permissions --mode plan --effort high
```

`--mode plan` is the structural way to make the agent plan before it edits. It beats asking for it in
the prompt, because the harness enforces it and the prompt only requests it. The other mode is
`accept-edits`, for when the user wants the agent to go straight to implementing.

`--effort high` is worth setting for anything you had to investigate to understand. `agy --help` lists
the current flags, and `agy models` lists what `--model` accepts.

Antigravity's sign-in screen is slow and shows a spinner. `agent start` blocks until it clears, which
is exactly why you use it rather than `pane run` followed by a guess. Give it the full 120000ms.

## 4. Prompt it

The prompt names the document and the boundaries. It does not restate the findings.

```sh
herdr agent prompt handoff-<slug> "Read the handoff document at <abs path>/handoff.md before anything else. It is the spec. Summary: <one line>. Its Established facts section is proven, so verify it but do not re-investigate it. Its Open judgement section is a sketch, so form your own view. Read AGENTS.md and GEMINI.md, then run /<skill> for the skills you need. Present a plan and wait for my approval before you change any code. Work only on branch fix/<slug> and never push to main."
```

Antigravity-specific points to put in the prompt:

- **Project instructions are `AGENTS.md` and `GEMINI.md`.** Antigravity reads both and ignores
  `CLAUDE.md` entirely, so a repo whose conventions live only in `CLAUDE.md` leaves agy blind. Check
  which files the repo actually has, and if the rules are Claude-only, either say so in the handoff
  document or hand off to Claude instead.
- **Skills load as slash commands**, from `~/.gemini/config/skills`, which is a symlink to
  `~/.agents/skills`. Name them as `/<skill>`, not as Skill tool calls. Plugin-namespaced names such
  as `superpowers:systematic-debugging` are Claude Code's convention and will not resolve.
- **The document path goes on the first line.** Agy starts acting on the opening instruction before it
  finishes parsing a long prompt.

## 5. Confirm the dispatch

```sh
herdr agent get handoff-<slug>     # expect agent_status: working
herdr agent read handoff-<slug>    # confirm it opened handoff.md
```

If it is still `idle`, the prompt is stranded in the composer. Send Enter and re-check, per the
contract. Agy is the more common offender here, because its composer accepts multi-line text without
submitting.

## Quick reference

| Step | Command |
|---|---|
| Create worktree | `herdr worktree create --cwd <main repo root> --branch fix/<slug> --base origin/main --no-focus --json` |
| Reopen existing branch | `herdr worktree open --branch fix/<slug> --no-focus --json` |
| Find a free pane | `herdr pane list --workspace <id>` then `herdr pane process-info --pane <id>` |
| Split one | `herdr pane split --pane <id> --direction right --cwd <worktree> --no-focus` |
| Start agy | `herdr agent start <name> --kind agy --pane <id> --timeout 120000 -- --mode plan --effort high` |
| Dispatch | `herdr agent prompt <name> "<prompt>"` |
| Confirm it landed | `herdr agent get <name>` gives `working` |
| Rescue a stall | `herdr agent send-keys <name> enter` |
| List models | `agy models` |

## Common mistakes

Everything in the contract's table applies. These are the Antigravity-specific additions.

| Mistake | Consequence |
|---|---|
| `--kind claude` or a bare kind label | `agent start` fails to detect the agent it expected |
| Agy's flags before `--` | Herdr parses them as its own and rejects them |
| Asking for a plan in prose while running without `--mode plan` | Agent edits first and plans after |
| Telling it to read `CLAUDE.md` | Agy does not read that file. It reads `AGENTS.md` and `GEMINI.md` |
| Naming skills as `plugin:skill` | Those names are Claude Code's and do not resolve under agy |
| Short `--timeout` on `agent start` | Sign-in has not finished, so the prompt is typed into the pre-login stream and lost |
| Handing off a repo whose rules live only in `CLAUDE.md` | Agy works without the project's conventions |
