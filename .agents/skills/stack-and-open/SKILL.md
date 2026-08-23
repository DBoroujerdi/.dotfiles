---
name: stack-and-open
description: Stack a new git branch on the current branch using gh-stack and open it in a Herdr workspace. Use when creating stacked branches or workspaces with gh-stack and Herdr.
argument-hint: "branch name, or what the new stacked layer is for"
disable-model-invocation: true
---

# Stack and open

## Overview

Two phases. `gh stack` creates the new branch as a layer on top of the base branch, then Herdr opens
that branch in its own workspace.

**The order is forced, not stylistic.** `gh stack` checks the new branch out in the tree you run it in,
and git refuses to let two worktrees hold the same branch. The branch has to be released before Herdr
can claim it. Step 3 exists for that reason alone and is the step that gets skipped.

**The base is an existing branch, not trunk.** The normal case is a feature branch with a PR already
open, checked out in a linked Herdr worktree. Trunk being the base is the rare case, and usually means
you are looking at the wrong tree rather than that the user wants to branch off trunk.

**Phase 1 runs in the tree that holds the base branch.** That is normally a linked Herdr worktree, not
the main checkout, so the metadata link from step 5 has to be applied there *first*. Step 1 covers this.

**REQUIRED BACKGROUND:** use the `herdr` skill for CLI discovery and safety rules before running any
`herdr` command. Herdr must be present: `test "${HERDR_ENV:-}" = 1`.

The `gh stack` extension must be installed:

```sh
gh extension list | grep gh-stack || gh extension install github/gh-stack
```

## When to use

- The current branch has a PR in flight and the next piece of work builds on it
- You want to keep working where you are while the stacked layer proceeds in its own workspace
- Several dependent layers need raising, each in its own workspace

**Not for:**

- Work that belongs on the current branch. Just commit it
- Work that starts from trunk. That is a plain `herdr worktree create --base origin/main`, with no stack
- Dispatching an agent into the new workspace. This skill stops at the open workspace, so use
  `claude-handoff` or `agy-handoff` for that

## 1. Work in the tree that holds the base branch

`gh stack` reads the current branch from the tree you run it in. The base branch is usually checked out
in a linked worktree — that is the situation this skill exists for — while the main checkout sits on
trunk. **Do not relocate to the main checkout in that case.** From there you would detect `main`, land
on the wrong row of step 2's table, and stack onto trunk instead of the branch the user meant.

```sh
git branch --show-current                 # already the base branch? then stay here
git worktree list                         # otherwise, which tree holds it
git rev-parse --git-dir --git-common-dir
```

The tree you run phase 1 in needs two things:

**Clean.** `git status --porcelain` must be empty. `gh stack` creates the branch at `HEAD`, so
uncommitted work follows you onto the new layer unless you pass `-A` or `-u` to commit it deliberately.
The main checkout often carries stray tooling edits; a Herdr worktree usually does not.

**Metadata linked**, if `--git-dir` is an absolute path under `.git/worktrees/`. gh-stack v0.1.0 looks
for its file next to `--git-dir` rather than in the shared common directory (see step 5). Link it now,
*before any `gh stack` command*, so the stack it writes is visible from every tree:

```sh
ln -sfn "$(git rev-parse --git-common-dir)/gh-stack" "$(git rev-parse --git-dir)/gh-stack"
```

This is safe when no stack exists yet. The target is dangling, and `gh stack init` writes through the
symlink and creates the real file in the common directory — verified: the symlink survives, and the
main checkout reads the same stack.

Confirm the new branch name is free, because `gh stack init` **adopts** an existing branch of that name
silently rather than failing:

```sh
git branch --list <new-branch>                  # both must be empty
git ls-remote --heads origin <new-branch>
```

## 2. Pick the right stack command

Run this in the tree from step 1:

```sh
gh stack view --json
```

`branches` is ordered bottom to top, so the last entry is the tip. `currentBranch` equals `trunk` when
you are on the trunk itself, and trunk is not listed in `branches`. On failure it exits 2 and prints a
plain-text error to stderr, not JSON.

**Check `currentBranch` is the branch you intend to stack on before reading the table.** A mismatch
means you are in the wrong tree — go back to step 1. It does not mean "on trunk".

| Situation | Detection | Command |
|---|---|---|
| **Loose base branch, no stack** — the usual case | exits 2, "not part of a stack" | `gh stack init <base-branch> <new-branch>` adopts the base branch as layer 1 |
| Base branch is the stack tip | exits 0, `currentBranch` is the **last** entry in `branches` | `gh stack add <new-branch>` |
| Base branch is mid-stack | exits 0, `currentBranch` is in `branches` but not last | Stop and ask. `gh stack modify` inserts a layer here. `gh stack top` moves you to the tip, which is a different request |
| `currentBranch` is trunk | exits 0 or 2, `currentBranch` equals `trunk` | Almost always the wrong tree. Return to step 1 and find the branch the user is stacking from. Only if they genuinely want a layer off trunk: `gh stack init <new-branch>`, or `gh stack add` on an existing stack's tip, and confirm which first |

Adopting the base branch matters in the loose-branch case, which is the common one for a branch with a
PR already open. `gh stack init <new-branch>` alone bases the new branch on the default branch and
leaves the branch you were on out of the stack entirely. `init` takes many branch names bottom to top,
adopting those that exist and creating those that do not, so `init <base> <new>` does both jobs at once
and reports `✓ Adopted 2 branches: main ← <base> ← <new>`.

Adopting does not touch the existing PR — it stays open against its original base. `gh stack submit`
links them into a GitHub stack later, once the new layer has commits.

Two errors you will hit, both of which mean what they say:

```
✗ can only add branches to the top of the stack; run `gh stack top` then `gh stack add`
```

Do not run `gh stack top` to clear this. It relocates the new layer to the stack tip rather than onto
the branch the user pointed at. Treat it as a question for the user.

```
✗ unable to determine default branch
```

`gh stack init` could not resolve the trunk from the remote. Pass `-b <trunk>`.

## 3. Release the branch

Both `add` and `init` leave you on the new top branch, in the tree you ran them in. A second worktree
cannot have it:

```
fatal: '<new-branch>' is already used by worktree at '<path>'
```

Switch back to the branch you stacked on:

```sh
git switch -
git branch --show-current    # must NOT be the new branch
```

Read that output. Skipping this step is the single most likely failure in this workflow, and its error
arrives later in step 4 where it looks like a Herdr problem.

## 4. Create the workspace for the new branch

A branch `gh stack` just created has no worktree, so `herdr worktree open` cannot take it:

```
{"error":{"code":"worktree_not_found","message":"worktree branch not found"}}
```

Expect that on every fresh layer — it is the normal state, not a symptom, so go straight to `create`.
Note the absence of `--base`: the branch exists and already has the right parent, and passing a base
here would misrepresent the stack.

```sh
herdr worktree create --cwd <main repo root> --branch <new-branch> \
  --path <worktrees-parent>/<slug> --label "<label>" --focus --json
```

- `--cwd` must be the main repo root, whatever tree you are calling from. A linked worktree gives
  `linked_worktree_source`
- `--path` is required here. Take the parent directory and naming style from the sibling entries in
  `git worktree list`, and use a lowercase slug of the branch name
- **`create` does not focus by default** — without `--focus` the response carries `"focused": false`.
  Read that field back, and if it is false: `herdr workspace focus <workspace_id>`. Landing in the new
  workspace is the point of the skill, so only leave it unfocused when the user is staying put
- Read `workspace_id` and pane IDs out of the JSON rather than guessing them

`herdr worktree open --branch <name>` is for re-entering a workspace whose worktree already exists, not
for a branch this skill just created.

## 5. Link the metadata inside the new workspace. Required.

The new workspace is a linked worktree, so it needs the same link as step 1 — gh-stack v0.1.0 reads its
metadata from `git rev-parse --git-dir`, which resolves to `.git/worktrees/<name>/` rather than the
shared common directory where the file actually lives. Without it, every stack command there fails:

```
✗ current branch "<new-branch>" is not part of a stack
```

The stack is intact. Only the lookup path is wrong. From inside the new worktree:

```sh
ln -sfn "$(git rev-parse --git-common-dir)/gh-stack" "$(git rev-parse --git-dir)/gh-stack"
gh stack view --short     # verify: shows the stack, with your branch as current
```

gh-stack writes this file in place rather than replacing it, so the symlink survives `add`, `submit`,
and `sync`, and edits made in the workspace are visible from the main checkout.

Re-check both link steps after a gh-stack upgrade. Once a version resolves the common directory itself
the symlink becomes harmless but unnecessary.

## Quick reference

| Step | Command |
|---|---|
| Find the tree holding the base branch | `git branch --show-current`, else `git worktree list` |
| Link metadata before phase 1 (linked worktree) | `ln -sfn "$(git rev-parse --git-common-dir)/gh-stack" "$(git rev-parse --git-dir)/gh-stack"` |
| Check the new name is free | `git branch --list <new>` and `git ls-remote --heads origin <new>` |
| Detect stack position | `gh stack view --json`, and check `currentBranch` is the base branch |
| Adopt a loose base branch and stack on it (usual) | `gh stack init <base-branch> <new-branch>` |
| Stack on an existing stack's tip | `gh stack add <new-branch>` |
| Release the branch | `git switch -` then `git branch --show-current` |
| Open the workspace | `herdr worktree create --cwd <main repo root> --branch <new> --path <parent>/<slug> --focus --json` |
| Focus it if `"focused": false` | `herdr workspace focus <workspace_id>` |
| Verify | `gh stack view --short` from inside the new workspace |
| Later, open the PRs | `gh stack submit` from any linked tree |

## Common mistakes

| Mistake | Consequence |
|---|---|
| Relocating to the main checkout because it is not a linked worktree | Detects trunk as the current branch, so step 2 picks a command that stacks onto trunk and drops the base branch |
| Taking trunk as the base because that is what the current tree is on | The layer lands on trunk. The base is an existing branch; find its tree instead |
| Running any `gh stack` command in a linked worktree before linking the metadata | Stack is written where only that worktree can see it |
| Opening the workspace before `git switch -` | `fatal: '<branch>' is already used by worktree at ...` |
| Treating `worktree_not_found` from `worktree open` as a real failure | It is expected for every new layer; use `worktree create` |
| Omitting `--focus` on `worktree create` | Workspace is created but never entered, which was the point of the skill |
| Running `gh stack top` to clear the mid-stack error | Layer lands on the stack tip, not the branch the user meant |
| `gh stack init <new>` on a loose base branch | New branch bases on trunk and the branch you were on is left out of the stack |
| `gh stack init` onto a name that already exists | Adopts that unrelated branch as the layer instead of failing |
| Skipping step 5 | Every `gh stack` command in the new workspace reports "not part of a stack" |
| Passing `--base` to `worktree create` for the stacked branch | Contradicts the parent gh stack already recorded |
| `--cwd $PWD` from inside a linked worktree | `linked_worktree_source` |
| Uncommitted work at `gh stack add` | Changes follow you onto the new layer |

## Red flags

- `gh stack view --json` reported a `currentBranch` that is not the branch being stacked on, and the
  table was read anyway
- About to run `gh stack` in a linked worktree without having checked for the `gh-stack` symlink
- About to run a `herdr worktree` command without having checked `git branch --show-current`
- `gh stack view --json` not run, so the choice between `add` and `init` was a guess
- Reporting the workspace ready without having run `gh stack view --short` inside it, or without having
  confirmed `focused` is true
- `gh stack add` refused and the response was to move the branch rather than ask
