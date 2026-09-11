---
name: work-ticket
description: Read the ticket referenced in the branch name, implement the changes, ask clarifying questions on gaps, verify work, open a draft PR, and move the ticket to In Review.
disable-model-invocation: true
---

# Work ticket

Implement a ticket from start to finish: extract the ticket ID from the branch name, fetch issue details, clarify open questions, build and verify changes, open a draft pull request, and move the ticket to In Review.

## 1. Extract ticket key from branch

Get the current branch:

```sh
git branch --show-current
```

Extract the ticket key prefix (for example, `TICKET-582` from `TICKET-582-description-of-work` or `YAHE-198`).

**Abandon if missing:** If the branch does not contain a valid ticket key, stop immediately. Report to the user: "No ticket identifier found in branch `<branch-name>`. Abandoning." Do not attempt to guess or implement without a ticket key.

## 2. Identify the ticketing system

Decide between Jira and Linear:

1. **Check context:** Look for board names, URLs, or explicit tracker settings in agent context, `CLAUDE.md`, or repository notes.
2. **Jira:** Default when `acli` is available or Jira keys match the board.
3. **Linear:** Use when Linear workspace or team is specified in context, or when Linear MCP tools / API keys are configured.

## 3. Read the ticket

Fetch full ticket context before touching code.

**In Jira:**

```sh
acli jira workitem view <KEY>
acli jira workitem view <KEY> --json --fields comment | jq -r '.fields.comment.comments[] | "--- \(.author.displayName) \(.created[0:10])\n" + ([.body | .. | .text? // empty] | join(" "))'
```

**In Linear:**
Fetch issue details, description, and comments via Linear tools or API.

Read acceptance criteria and comments carefully. Comments often contain recent decisions that override earlier descriptions. Note out-of-scope boundaries to prevent scope creep.

## 4. Resolve gaps and clarify

If the ticket leaves key requirements ambiguous, contradictory, or open:
- Ask the user focused questions in a single batched message.
- Provide concrete options and state the recommended path first.
- If everything is clear and well-specified, proceed without asking redundant questions.

## 5. Implement and verify

- Inspect the codebase to follow existing patterns, types, and architecture.
- Write the changes and keep them strictly within scope.
- Run tests, builds, and linters to verify acceptance criteria pass.

## 6. Open a draft pull request

Push the branch and open a draft PR:

```sh
git push -u origin HEAD
gh pr create --draft --title "<Title>" --body "<Body>"
```

- Follow the `pr-description` skill for the PR description structure (consumer-focused summary, API changes, output changes, test verification).
- Incorporate testing evidence and output proofs in the description.
- Link the ticket key in the PR description.

## 7. Move ticket to In Review

After creating the draft PR, transition the ticket status.

**In Jira:**

```sh
acli jira workitem transition --key <KEY> --status "In Review" --yes
```

If the project uses a different status name (such as `in-review` or `Review`), adapt accordingly.

**In Linear:**
Update the Linear issue state to `In Review`.

Output the draft PR link and confirm the ticket transition to the user.
