# Nvim Keybindings

**Leader:** `Space`

## LSP

- `gd` - go to definition
- `gr` - references
- `gI` - implementation
- `gD` - declaration
- `K` - hover docs
- `<leader>D` - type definition
- `<leader>rn` - rename
- `<leader>ca` - code action
- `[d` - prev diagnostic
- `]d` - next diagnostic
- `<leader>e` - diagnostic float
- `<leader>q` - diagnostic quickfix

## Navigation

- `h/j/k/l` - left/down/up/right
- `w/b` - next/prev word
- `gg/G` - top/bottom of file
- `0/$` - start/end of line
- `<C-h/j/k/l>` - focus left/lower/upper/right window
- `<leader>[` - go back (`<C-o>`)
- `<leader>]` - go forward (`<C-i>`)

## Tabs/Buffers

- `gt/gT` - next/prev tab
- `<leader><leader>` - MRU buffer switcher (recent at bottom)
- `:tabnew` - new tab
- `:tabclose` - close tab

## Windows/Splits

- `<leader>wv` - split vertical
- `<leader>wh` - split horizontal
- `<leader>wx` - close split
- `<leader>o` - close other windows

## Files

- `<C-n>` - nvim-tree toggle
- `-` - oil (parent dir)
- `<leader>p` - find files
- `<leader>pf` - find files (all, including ignored)
- `<leader>pg` - find git files
- `<leader>pp` - project picker

## Find / Telescope

- `<leader>ff` - find files
- `<leader>fg` - live grep
- `<leader>fg` (visual) - live grep selection
- `<leader>fw` - grep word under cursor (or visual selection)
- `<leader>fh` - find help
- `<leader>fk` - find keymaps
- `<leader>fs` - telescope picker
- `<leader>fd` - find diagnostics
- `<leader>fr` - resume last search
- `<leader>f.` - recent files
- `<leader>fn` - neovim config files
- `<leader>f/` - grep in open files (supports visual selection)
- `<leader>/` - fuzzy search current buffer (supports visual selection)
- `<leader>r` - recent files (telescope-recent-files)
- `<leader>P` - command palette
- `s` (in Telescope normal mode) - jump to result with Flash
- `<C-s>` (in Telescope insert mode) - jump to result with Flash

## Git

- `<leader>gg` - neogit status
- `<leader>gc` - git commits
- `<leader>gp` - git buffer commits

## Editing

- `v` - visual mode
- `V` - visual line mode
- `<C-v>` - visual block mode
- `d/dd/D` - delete/delete line/delete to end
- `c/cc/C` - change/change line/change to end
- `y/yy/Y` - yank/yank line/yank to end
- `<leader>yr` (normal/visual) - yank code reference (`path/to/file:10-25`)
- `<leader>ya` (normal/visual) - yank `@` code reference (`@path/to/file:10-25`)
- `<leader>ym` (normal/visual) - yank markdown code block with reference header
- `p/P` - paste after/before
- `u/<C-r>` - undo/redo
- `<leader>rw` - replace word under cursor
- `J/K` (visual) - move line(s) down/up
- `<leader>u` - undo tree
- `<leader>cf` - format buffer (conform)

## Completion (Insert Mode)

- `<C-n>` - next completion
- `<C-p>` - prev completion
- `<C-y>` - accept completion
- `<C-Space>` - trigger completion
- `<C-l>` - snippet jump forward
- `<C-h>` - snippet jump back

## Mini.surround

- `sa` - add surrounding
- `sd` - delete surrounding
- `sr` - replace surrounding

## Flash

- `s` - Flash jump (normal, visual, operator-pending)
- `S` - Flash Treesitter (normal, visual, operator-pending)
- `r` - Remote Flash (operator-pending)
- `R` - Treesitter Search (operator-pending, visual)
- `<C-s>` - Toggle Flash Search (command-line)

## AI (CodeCompanion)

- `<leader>aa` - toggle chat
- `<leader>ac` - CodeCompanion Actions
- `<leader>ai` - inline assist
- `<leader>ap` (visual) - add selection to chat
- `ga` (visual) - add selection to chat

## NvimTree (in-tree buffer)

- `s` - open vertical split
- `h` - open horizontal split

## Terminal

- `<leader>j` - toggle terminal
- `<Esc><Esc>` - exit terminal mode

## Misc

- `<Esc>` - clear search highlight
- `<leader>so` / `<leader>R` - reload Neovim configuration
- `:w` - save
- `:q` - quit
- `:wq` - save & quit
- `:q!` - quit without saving
