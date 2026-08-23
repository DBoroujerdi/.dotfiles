# Handoff contract

Shared background for the `claude-handoff` and `agy-handoff` skills. Both link to this file.
Edit it here, not in either skill.

## Why a document and not a prompt

A handoff transfers findings, not a transcript. The receiving agent starts empty. Everything you
established through investigation is invisible to it unless you write it down.

**The handoff document is the deliverable. The prompt just points at it.**

A prompt long enough to carry real findings is too long to paste reliably, cannot hold evidence
files, and scrolls away. A document persists, can be re-read mid-task, and can cite artifacts.

## The document contract

Seven sections, in this order.

1. **Task.** The deliverable in one line, plus branch, PR, and scope boundaries.
2. **Established facts.** What you proved, and the evidence proving it. Say so plainly:
   "Confirmed by reproduction. Do not re-investigate. Verify, then fix."
3. **Open judgement.** What you did not settle. Mark sketches as sketches:
   "A starting point, not a spec. Form your own view."
4. **Verification.** Exact commands, with expected output before and after the fix.
5. **Constraints.** Project rules, test commands, things that will bite them.
6. **Prior art.** Related branches, tickets, earlier attempts.
7. **Evidence files.** Absolute paths to logs, dumps, captures.

Separating 2 from 3 is the whole job. Blur them and the agent picks a failure mode: re-deriving what
you already proved, or building your half-formed sketch as gospel.

## Where the document lives

Store it outside the repo. A file left in the worktree gets committed by an agent tidying its
branch.

Use a sibling of the worktrees parent directory, `<worktrees-parent>/.handoff-<slug>/`. Copy
evidence in alongside it, then rewrite any path that pointed at your session scratchpad. That
scratchpad is not durable and its paths are dead links for the receiving agent.

## The prompt contract

Five parts, in this order.

1. The document's absolute path, on the first line.
2. A one-line summary, so the agent knows what it is walking into.
3. The established/open split, restated. Worth the duplication.
4. The deliverable and the hard constraints: branch, PR, never push to main.
5. Where to stop. Plan first, wait for approval, then edit.

## Isolating the work

Give the agent its own worktree unless the work belongs on the current branch. A fresh agent that
switches branches disturbs whatever you are doing.

**REQUIRED BACKGROUND:** use the `herdr` skill for CLI discovery and safety rules before running any
`herdr` command.

```sh
herdr worktree create --cwd <main repo root> \
  --branch <branch> --base origin/main \
  --path <worktrees-parent>/<slug> --label "<slug>" --no-focus --json
```

`--cwd` must be the main repo root. Passing a linked worktree fails with `linked_worktree_source`,
so `$PWD` is only correct when you are already in the main checkout. Read `workspace_id` and pane
IDs out of the JSON rather than guessing them or inferring them from sidebar order. If the branch
already exists, run `herdr worktree open --branch <branch> --no-focus --json` instead.

## Finding a pane for the agent

Discover the pane, do not assume it. A repo's `.wt.toml` can auto-provision panes, so the layout
differs per repo and an agent is sometimes already running before you do anything.

```sh
herdr pane list --workspace <workspace_id>
herdr pane process-info --pane <id>
```

Only a pane sitting at a bare interactive shell prompt is available. Claiming the auto-provisioned
editor or install pane returns `agent_pane_busy`, and killing that editor loses the user's work.
Split a new pane instead:

```sh
herdr pane split --pane <shell-pane> --direction right --cwd <worktree path> --no-focus
```

## Never prompt an agent that is still signing in

Both CLIs show a startup screen while they authenticate and initialize. Text sent during that window
lands in the pre-login stream and disappears.

`herdr agent start` returns only once the agent is ready for input, which is what makes it safe to
prompt. Use it with a generous `--timeout` rather than `pane run` plus a guess. If you do launch the
CLI by hand, wait for the input prompt first:

```sh
herdr pane wait-output <shell-pane> --match ">" --timeout 60000
```

## Confirm the prompt submitted. Required.

`agent prompt` is documented as sending text and Enter atomically. It does not always submit. The
text sits in the composer, the agent stays `idle`, and a stalled agent looks identical to a working
one until you look.

```sh
herdr agent get <name>                # expect agent_status: working
herdr agent send-keys <name> enter    # only if still idle
herdr agent get <name>                # re-check: must now be working
herdr agent read <name>               # confirm it opened the document
```

Never report a handoff you have not seen reach `working`.

## Failure table

| Symptom | Cause | Fix |
|---|---|---|
| `linked_worktree_source` | Ran `worktree create` from inside a linked worktree | Pass `--cwd <main repo root>`, not `$PWD` |
| `agent_pane_busy` | The new workspace auto-ran an editor in its root pane | Split a pane or find one at a bare shell. Do not kill the editor |
| Agent stays `idle` after `agent prompt` | Multi-line prompt landed in the composer unsubmitted | `herdr agent send-keys <name> enter`, then re-check `agent get` |
| Prompt vanished with no trace | Sent before the CLI finished signing in | Wait for `agent start` to return, or for `>` via `pane wait-output` |
| Agent asks questions the document answers | Prompt did not name the document path first | Re-prompt with the absolute path on the first line |

## Common mistakes

| Mistake | Consequence |
|---|---|
| Findings in the prompt only | The agent cannot re-read them |
| Handoff document inside the repo | It gets committed to the branch |
| Paths into your session scratchpad | Dead links for the receiving agent |
| Sketch presented as settled | Half-formed design built without judgement |
| Findings presented as tentative | The agent re-runs your whole investigation |
| No verification steps | Success declared without reproducing the original failure |
| Reporting done at `agent start` | The prompt may never have submitted |
| Guessing a pane or workspace ID | Prompt sent to an editor, or to nothing |
