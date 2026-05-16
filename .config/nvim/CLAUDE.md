# CLAUDE.md — nvim config

## Keep KEYBINDINGS.md in sync

`KEYBINDINGS.md` (this directory) is the user-facing cheatsheet for the nvim
config. It is displayed via a tmux popup (`prefix + K`, defined in
`~/.dotfiles/.tmux.conf`) — so it has to stay accurate.

**Whenever you add, change, or remove a keymap, update `KEYBINDINGS.md` in the
same change.** This applies to:

- `vim.keymap.set` calls anywhere under `lua/`
- Lazy plugin spec `keys = { ... }` tables in `lua/plugins/specs/*.lua`
- LSP `on_attach` keymaps (`lua/plugins/specs/lsp.lua`)
- Plugin-buffer keymaps that the user invokes (e.g. nvim-tree `on_attach`)

**Don't** document built-in vim motions (`h/j/k/l`, `w/b`, `gg/G`, `0/$`, etc.)
beyond the small reference block already present — those aren't user-customized.

Group new entries under the existing sections (Navigation, Files, Search, LSP,
Git, Editing, AI, Terminal, Misc…). Add a new section only if the binding
doesn't fit any existing one.
