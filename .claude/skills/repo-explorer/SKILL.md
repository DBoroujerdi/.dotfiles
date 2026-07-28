---
name: repo-explorer
description: Clone and inspect external open source repositories in a reusable local exploration cache. Use this skill when the user asks to explore, inspect, investigate, compare, read the source of, or answer questions about how a repository or library works internally — especially one that is not already in the current workspace.
allowed-tools: Bash(mkdir -p ~/projects/explore), Bash(ls -la ~/projects/explore), Bash(git clone *)
---

# Repo Explorer

Use this skill to explore repositories without cluttering the active workspace.

## Repository Cache

Use `~/projects/explore` as the local cache directory for repositories being explored. Create it if it does not exist.

## Current Cache Contents

```!
mkdir -p ~/projects/explore
ls -la ~/projects/explore
```

## Flow

1. List the current cache contents before deciding what to use.
   - In hosts that support skill shell injection, use the rendered `Current Cache Contents` section above.
   - Otherwise, run `ls -la ~/projects/explore` before deciding what to use.

2. Check whether the target repository is already present in `~/projects/explore`.
   - Prefer a stable directory name based on the repository owner and name, such as `owner__repo`.
   - If the repository is already present, use that local checkout for exploration.

3. If the repository is not present, clone it into `~/projects/explore`, then explore it there.
   - Create `~/projects/explore` first if it does not exist.
   - Do a shallow clone (`git clone --depth 1 <url> ~/projects/explore/owner__repo`) unless full history is needed for the question.
   - Use the HTTPS clone URL unless the user specifies SSH.

4. Explore the local checkout to answer the user's question.
   - Read the source, docs, tests, and examples directly from the checkout.
   - Reference findings with concrete file paths and line numbers from the checkout.
   - Do not modify the cloned repository; treat it as read-only.

## Notes

- If a cached checkout looks stale and freshness matters, `git -C ~/projects/explore/owner__repo pull` before exploring.
- Keep the cache flat: one directory per repository, named `owner__repo`.
