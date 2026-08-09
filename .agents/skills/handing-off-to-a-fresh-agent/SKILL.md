---
name: handing-off-to-a-fresh-agent
description: Use when work investigated in this session should be built by a different agent in its own session, branch, or worktree — a diagnosed bug to fix elsewhere, a spike to productionise, or a phase that needs a clean context. Also use when asked to "hand this off", "spin up an agent for this", or "set an agent to work on it".
---

# Handing Off to a Fresh Agent

## Overview

A handoff transfers *findings*, not a transcript. The receiving agent starts empty: everything you
established through investigation is invisible unless you write it down.

**Core principle: the handoff document is the deliverable. The prompt just points at it.**

A prompt long enough to carry real findings is too long to paste reliably, can't hold evidence
files, and scrolls away. A document persists, can be re-read mid-task, and can cite artifacts.

## When to Use

- You diagnosed something and the fix belongs on a different branch or PR
- The next phase needs a clean context (yours is full of investigation)
- Work should proceed in parallel with what you're doing
- The user asks for an agent to be set to work

**Not for:** work you can finish now, or a task the user is about to do themselves.

## The Document Contract

1. **Task** — the deliverable in one line. Branch, PR, scope boundaries.
2. **Established facts** — what you proved, and the evidence proving it. State plainly:
   *"Confirmed by reproduction; do not re-investigate. Verify, then fix."*
3. **Open judgement** — what you did *not* settle. Sketches marked as sketches:
   *"A starting point, not a spec. Form your own view."*
4. **Verification** — exact commands, expected output before and after.
5. **Constraints** — project rules, test commands, things that will bite them.
6. **Prior art** — related branches, tickets, earlier attempts.
7. **Evidence files** — absolute paths to logs, dumps, captures.

**Separating 2 from 3 is the whole job.** Blur them and the agent picks a failure mode: re-deriving
what you already proved, or implementing your half-formed sketch as gospel.

**Store the document outside the repo** — a file left in the worktree gets committed by an agent
tidying its branch. Use a sibling directory (`<worktrees-parent>/.handoff-<slug>/`), copy evidence
in alongside it, and rewrite paths that pointed at your session scratchpad, which is not durable.

## The Prompt Contract

- The document's absolute path, first line
- A short summary so the agent knows what it's walking into
- The established/open split, restated — worth the duplication
- Deliverable and hard constraints (branch, PR, never push to main)
- "Read the handoff and <project instructions>, then plan before you edit."

## Isolating the Work

Give the agent its own worktree unless the work belongs on the current branch — a fresh agent that
switches branches disturbs whatever you are doing.

**REQUIRED BACKGROUND:** Use the `herdr` skill for CLI discovery and safety rules before running any
`herdr` command. Common failures show up specifically in handoffs:

| Symptom | Cause | Fix |
|---|---|---|
| `linked_worktree_source` | Ran `worktree create` from inside a linked worktree | Pass `--cwd <main repo root>`, not `$PWD` |
| `agent_pane_busy` | New workspace auto-ran an editor in its root pane | Find a pane at a bare shell or split one — don't kill the editor |
| `agent_prompt_stalled` | Multi-line prompt landed in the composer unsubmitted | `agent send-keys <name> enter`, then re-check status |
| `prompt_dropped_during_signing_in` | Sent prompt via Herdr before `agy` or `claude` finished signing in / initialization | Wait for sign-in to complete (`>` prompt visible / state `idle`) before sending prompt |

### Launching & Prompting Agents via Herdr (`agy` and `claude`)

Do not pass prompts as CLI start arguments. Instead, launch the agent CLI, wait for signing-in and initialization to finish until text input is available, and then send the prompt via Herdr:

1. **Launch the Agent CLI**:
   - Launch `agy` or `claude` in the target pane:
     `herdr pane run <shell-pane> "agy --dangerously-skip-permissions"`

2. **Wait for Signing-In / Initialization to Finish**:
   - `agy` and `claude` display startup screens (e.g. `⣽ Signing in...`) while initializing. Do NOT send prompt text while signing in is in progress.
   - **Using Herdr Agent lifecycle**: `herdr agent start <name> --kind agy --pane <shell-pane> --timeout 120000` automatically blocks until signing in completes and state becomes `idle`.
   - **Using Herdr Pane wait-output**: `herdr pane wait-output <shell-pane> --match ">" --timeout 60000` waits until the input prompt `>` appears on screen.

3. **Send the Prompt via Herdr**:
   - Once text input is available, send the prompt:
     `herdr agent prompt <name> "<prompt>" --wait --timeout 180000`
     *(or `herdr pane run <shell-pane> "<prompt>"`)*
   - If the prompt lands in the composer unsubmitted, send Enter:
     `herdr agent send-keys <name> enter`

```bash
# From a linked worktree: name the parent repo, not the cwd
herdr worktree create --cwd /path/to/main/repo \
  --branch fix/some-slug --base origin/main \
  --path /path/to/worktrees/some-slug --label "some-slug" --no-focus --json

herdr pane process-info --pane <root-pane>      # editor? use another pane

# Step 1 & 2: Launch agy and wait for signing-in to finish until input prompt is available
herdr agent start worker-1 --kind agy --pane <shell-pane> --timeout 120000

# Step 3: Send the prompt via Herdr once text input is ready
herdr agent prompt worker-1 "<prompt>" --wait --timeout 180000
herdr agent send-keys worker-1 enter            # if the prompt landed unsubmitted
```

Confirm the agent is actually working (`agent get` → `working`, `agent read` → it read the doc)
before reporting the handoff done. A stalled agent looks identical to a working one until you look.

## Common Mistakes

| Mistake | Consequence |
|---|---|
| Findings in the prompt only | Agent can't re-read them |
| Handoff doc inside the repo | Gets committed to the branch |
| Paths into your session scratchpad | Dead links for the receiving agent |
| Prompting `agy`/`claude` during sign-in | Prompt gets dropped or swallowed before text input is ready |
| Not waiting for prompt `>` / `idle` | Input is typed into the pre-login stream and lost |
| Sketch presented as settled | Half-formed design implemented without judgement |
| Findings presented as tentative | Agent re-runs your whole investigation |
| No verification steps | Success declared without reproducing the original failure |
| Reporting done at `agent start` | The prompt may never have submitted |
