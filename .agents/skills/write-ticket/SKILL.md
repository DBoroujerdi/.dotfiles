---
name: write-ticket
description: Write a clear Jira or Linear ticket from raw notes, specs, or requirements. Use when creating or drafting a new ticket or issue in Jira or Linear.
---

# Write a ticket

A good ticket gives anyone enough context to build the right thing and verify it works without needing follow-up questions.

## Before writing

1. **Understand the problem.** Identify what is broken, what is missing, and who is affected.
2. **Know the audience.** Keep language clear and high level. Focus on user behavior and system expectations rather than low-level implementation details.
3. **Keep the scope single-purpose.** One ticket should solve one cohesive problem.

## Ticket structure

Use these sections in order. Skip a section only if it has no content.

### Summary

Two to four sentences explaining what we are doing, why, and the expected outcome. Lead with the human or user problem, not the code change.

Good: "Users cannot complete checkout when a discount code fails. We need to show a clear inline error and let them retry or remove the code so they can finish paying."

Bad: "Update discount validation handler in checkout service."

### Background

Bullet points only. Add relevant context, links to designs, customer feedback, or related tickets. Technical references (endpoints, table names, queries) are strictly optional and only needed if they constrain the work.

### Scope

Two sub-lists:
- **In scope:** What will be delivered.
- **Out of scope:** Related work deliberately left out to prevent scope creep.

### Acceptance criteria

Use Given / When / Then format. Each item must be verifiable by someone testing the feature:
- The happy path.
- Error and fallback states.
- Reversal or undo (if user data is changed).
- The unblocked outcome.

### Technical notes

Optional. High-level architecture notes, dependencies, or migrations. Avoid dictating internal code design or pasting snippets unless essential.

### Definition of done

Short checklist matching the team's release standards (for example: code reviewed, unit tests passing, QA verified).

## Rules

- **Title describes the outcome, not the task.** "Allow users to remove invalid discount codes during checkout" works. "Fix discount codes" does not.
- **Keep it focused.** If the acceptance criteria do not fit on one screen, split the work into multiple tickets.
- **Never invent business rules.** If an edge case is missing from your notes, flag it as an open question instead of guessing.
- **Link related tickets.** Use blocking relationships (`Blocks` in Jira, `Blocked by` in Linear) only for strict blockers. Use related links for general context.

## Creating the issue

Both Jira and Linear support standard Markdown formatting.

- **In Jira:** Use the Jira / Atlassian CLI or MCP tools (`createJiraIssue` with `contentFormat: "markdown"`).
- **In Linear:** Use the Linear CLI, API, or paste directly into the issue description.
- **Drafting:** If no CLI or MCP tool is connected, output the markdown directly for the user to copy.

See `references/example.md` for a complete example.
