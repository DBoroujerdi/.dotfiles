---
name: claude-handoff
description: Hand off investigation findings to a fresh Claude Code agent in an isolated Herdr worktree. Use when delegating work to Claude, spinning up a Claude agent, or asked to hand off to Claude.
argument-hint: "what the fresh Claude agent should build"
disable-model-invocation: true
---

# Claude handoff

## Overview

Write your findings to a durable document, create an isolated worktree through Herdr, start `claude`
in it, and point that agent at the document.

**REQUIRED BACKGROUND:** read `references/handoff-contract.md` in this skill directory. It holds the
document contract, the prompt contract, the worktree and pane rules, and the dispatch verification
steps. This file covers only what is specific to Claude Code.

**REQUIRED BACKGROUND:** use the `herdr` skill for CLI discovery and safety rules before running any
`herdr` command. Herdr must be present: `test "${HERDR_ENV:-}" = 1`.

## When to use

- You diagnosed something and the fix belongs on a different branch or PR
- The next phase needs a clean context and yours is full of investigation
- Work should proceed in parallel with what you are doing
- The user asked for a Claude agent to be set to work

**Not for:** work you can finish now, a task the user is about to do themselves, or work that already
has a Jira ticket. A ticket is its own handoff document, so use `ticket-to-agent` instead.

Reach for `agy-handoff` when the receiving agent should be Antigravity rather than Claude.

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

## 3. Start claude in a shell pane

`--kind claude` is the canonical kind. Pass Claude's own flags after `--`.

```sh
herdr agent start handoff-<slug> --kind claude --pane <shell-pane> --timeout 120000 \
  -- --dangerously-skip-permissions --permission-mode plan
```

`--permission-mode plan` is the structural way to make the agent plan before it edits. It beats
asking for it in the prompt, because the harness enforces it and the prompt only requests it. Drop it
only when the user wants the agent to go straight to implementing.

`agent start` blocks until Claude is ready for input, so do not follow it with a sleep or a guess.

## 4. Prompt it

The prompt names the document and the boundaries. It does not restate the findings.

```sh
herdr agent prompt handoff-<slug> "Read the handoff document at <abs path>/handoff.md before anything else. It is the spec. Summary: <one line>. Its Established facts section is proven, so verify it but do not re-investigate it. Its Open judgement section is a sketch, so form your own view. Read CLAUDE.md, then use the Skill tool for <skills>. Present a plan and wait for my approval before you change any code. Work only on branch fix/<slug> and never push to main."
```

Claude-specific points to put in the prompt:

- **Project instructions are `CLAUDE.md`.** Name the file. Nested `CLAUDE.md` files in subdirectories
  apply too.
- **Skills load through the Skill tool**, from `~/.claude/skills`, which is a symlink to
  `~/.agents/skills`. Name the ones the agent should invoke, for example
  `superpowers:systematic-debugging`, `tdd`, `diagnose`. Naming them is worth the tokens; a fresh
  agent picks worse skills than you can from what you already know about the work.
- **The document path goes on the first line.** Claude reads and acts on the opening instruction
  before it finishes parsing a long prompt.

## 5. Confirm the dispatch

```sh
herdr agent get handoff-<slug>     # expect agent_status: working
herdr agent read handoff-<slug>    # confirm it opened handoff.md
```

If it is still `idle`, the prompt is stranded in the composer. Send Enter and re-check, per the
contract.

## Quick reference

| Step | Command |
|---|---|
| Create worktree | `herdr worktree create --cwd <main repo root> --branch fix/<slug> --base origin/main --no-focus --json` |
| Reopen existing branch | `herdr worktree open --branch fix/<slug> --no-focus --json` |
| Find a free pane | `herdr pane list --workspace <id>` then `herdr pane process-info --pane <id>` |
| Split one | `herdr pane split --pane <id> --direction right --cwd <worktree> --no-focus` |
| Start claude | `herdr agent start <name> --kind claude --pane <id> --timeout 120000 -- --permission-mode plan` |
| Dispatch | `herdr agent prompt <name> "<prompt>"` |
| Confirm it landed | `herdr agent get <name>` gives `working` |
| Rescue a stall | `herdr agent send-keys <name> enter` |

## Common mistakes

Everything in the contract's table applies. These are the Claude-specific additions.

| Mistake | Consequence |
|---|---|
| `--kind agy` or a bare kind label | `agent start` fails to detect the agent it expected |
| Claude's flags before `--` | Herdr parses them as its own and rejects them |
| Asking for a plan in prose while running without `--permission-mode plan` | Agent edits first and plans after |
| Telling it to read `AGENTS.md` or `GEMINI.md` | Claude Code does not read those. It reads `CLAUDE.md` |
| Leaving skill selection to the agent | It picks worse skills than you can name from what you already know |
