---
name: no-comments
description: "Spawn Comment Sicko on the current diff or given files, review its report, fix accepted findings, and offer encodings for claimed constraints."
disable-model-invocation: true
---

# No comments

Spawn Comment Sicko. Act on accepted findings.

Authoring agents defend their own comments. Defer to Comment Sicko's fresh perspective.

## Scope

Use the caller's files or diff. Otherwise use the current diff against the base branch, default `main`, including the working tree.

## Steps

1. Spawn a subagent with `subagent_type: "Comment Sicko"`. Pass the scope. Do not restate its rules.
2. Review its report and the resulting diff. Reject application-code edits, scope escapes, and deletions that match one of its listed exceptions. Restore a deleted comment only by naming the exact exception it falls under. Decide each `UNSURE` item yourself by reading the code; when still in doubt, keep the comment and say so in the report. Do not rerun Comment Sicko.
3. Fix accepted `MUST KILL` flags with the smallest in-scope change: rename, extract, type, delete the dead path, drop the parameter, or use the real API. Do not widen the scope to fix instances elsewhere. If the real fix is out of scope, land the smallest in-scope improvement and report the rest as open.
4. Constraint comments say things like `do not remove`, `do not change wording`, or `talk to X before changing`. For each one, offer the cheapest in-scope encoding: a type, a runtime check, a test, or a lint rule. Wait for approval. If approved, encode it then delete the comment. Otherwise keep the comment and report the constraint as unenforced.
5. Report the deletion count, restored comments, `UNSURE` decisions, fixes made, encoding offers and outcomes, and open work.
