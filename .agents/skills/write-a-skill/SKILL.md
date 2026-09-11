---
name: write-a-skill
description: Create and install new agent skills with proper structure, progressive disclosure, and automatic Stow integration into dotfiles. Use when creating, writing, codifying, or building a new skill.
---

# Write a skill

## Where skills live

- **Personal / authored skills**: Stored in `~/.dotfiles/.agents/skills/<skill-name>/` and version-controlled in git.
- **Active hub**: `~/.agents/skills/` aggregates both personal (symlinked via Stow) and third-party skills.
- **Rule**: Never write personal skills directly to `~/.agents/skills/`. Always write to `~/.dotfiles/.agents/skills/<skill-name>/` and run GNU Stow to activate.

## Process

### 1. Gather requirements and design
- **Purpose**: What domain or task does this skill solve?
- **Triggers**: What phrases, commands, tools, or contexts should make an agent load this skill?
- **Scope**: Is it pure instructions (`SKILL.md`), or does it need deterministic scripts or reference material?

### 2. Write the skill directory
Create `~/.dotfiles/.agents/skills/<skill-name>/` with the following structure:

```
~/.dotfiles/.agents/skills/<skill-name>/
├── SKILL.md             # Main instructions (required)
├── references/          # Deep documentation, schemas, or large guides (>100 lines)
├── scripts/             # Deterministic helper scripts (if needed)
└── examples/            # Concrete examples (if needed)
```

### 3. SKILL.md requirements

#### Frontmatter
```yaml
---
name: skill-name
description: What the skill does. Use when [specific trigger phrases, keywords, or contexts].
---
```

- **Description is critical**: It is the only text the agent reads to decide whether to load the skill.
- Sentence 1: Clear, active-voice summary of capability.
- Sentence 2: Exact trigger conditions prefixed with `Use when...`.
- Max 1024 characters.

#### Body content
- Keep `SKILL.md` under 100 lines. Offload long reference material to `references/` or `REFERENCE.md`.
- Use sentence case headings.
- Active voice and plain words over clever prose.
- Include concrete code or output examples, not generic placeholders (`foo`/`bar`).

### 4. Activate with GNU Stow
Immediately after writing or editing files in `~/.dotfiles/.agents/skills/<skill-name>/`, re-stow the dotfiles repository to link the skill into `~/.agents/skills/`:

```bash
stow -R --dir="${HOME}/.dotfiles" --target="${HOME}" .
```

Verify that the symlink exists and resolves:
```bash
test -L "${HOME}/.agents/skills/<skill-name>"
```

### 5. Final review and report
- Confirm the skill is active and symlinked in `~/.agents/skills/<skill-name>`.
- Inform the user that the skill has been created in `~/.dotfiles` and is untracked, ready to be reviewed and committed when they are ready. Do not auto-commit unless explicitly asked.
