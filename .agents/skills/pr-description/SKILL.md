---
name: pr-description
description: Write or update clear, consumer-focused pull request descriptions with API examples and output changes. Use when creating or editing PR descriptions (via gh pr create, gh pr edit, or manually).
---

# PR description

## Who you are writing for

A developer who has not read this codebase and probably never will. They are often integrating
against it from another service or another app. They want three things.

1. What changed, in language a non-technical colleague could follow.
2. What calls to make, with real examples.
3. Whether any output they consume has changed shape.

Internals are not interesting to them. File names, class names, hook names and store names belong in
the diff, not the description. Mention one only when the reader has to touch it themselves.

## Shape

Keep the repo's own template if it has one, usually `.github/PULL_REQUEST_TEMPLATE.md`, and put the
sections below inside its description section. Fill in its checklist. Do not silently drop a section
it asks for, including screenshots. If you cannot supply one, say so and say why.

Lead with the ticket link, then:

**What this changes.** Two or three short paragraphs. Name the problem in terms of what it cost
someone, such as needing a release to swap a file, then say what happens instead now. No internals.

**The API calls.** Show them, do not describe them. A fenced `http` block for the request with the
headers that matter, and a fenced `json` block for the response with the status code and realistic
values. If there is a second step, such as following a returned URL, show it and say what is
different about it. A small table is good for enumerating accepted values and whether each works yet.

**Changes to outputs.** Any payload, schema or event a consumer reads. If nothing changed, say
"None" and name the file you checked, so the reader can see the question was actually asked rather
than skipped. Never assert this either way without checking the diff first.

**What happens when it fails.** What the user sees, and whether the feature degrades or stops.

**Deployment notes.** Anything that needs a fresh build, cannot ship over the air, needs a migration,
needs a secret, or changes config. Put it under its own heading so nobody merges past it.

**Still to do elsewhere.** Work this depends on from other teams, follow-ups you deliberately left,
and any decision that belongs to a human rather than to code. Say which is which.

## Rules

- Verify every claim about outputs against the diff before writing it. A wrong "no change here" is
  worse than no section at all.
- Give realistic example values, not `foo` and `bar`. Redact secrets and signatures.
- Say what a reader must do differently. If the answer is nothing, say that too.
- Keep failure behaviour concrete. "Handles errors gracefully" tells nobody anything. "Keeps the last
  file it downloaded, so the monitor carries on working" does.
- Separate what you did from what someone else still has to do.
- Mention pre-existing failures you noticed but did not cause, so a reviewer does not chase them.
- Apply the `unslop` skill to the whole thing. No em dashes anywhere. No colons as mid-sentence
  connectors. Sentence case headings. Active voice. Plain words over clever ones.
- Length follows the change. A one-line fix does not need an API section.

## Before posting

- Could someone who has never opened this repo follow it?
- Is every output claim checked, not assumed?
- Does any sentence read the same in another project's PR? Cut it, it says nothing.
- Em dash count is zero.
