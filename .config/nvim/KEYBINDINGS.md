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
- `<leader><leader>` - buffer picker
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

## Search

- `<leader>sf` - search files
- `<leader>sg` - live grep
- `<leader>sw` - grep word under cursor
- `<leader>sh` - search help
- `<leader>sk` - search keymaps
- `<leader>ss` - telescope picker
- `<leader>sd` - search diagnostics
- `<leader>sr` - resume last search
- `<leader>s.` - recent files
- `<leader>sp` - git files
- `<leader>sn` - neovim config files
- `<leader>s/` - grep in open files
- `<leader>/` - fuzzy search current buffer
- `<leader>r` - recent files (telescope-recent-files)
- `<leader>P` - command palette

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
- `p/P` - paste after/before
- `u/<C-r>` - undo/redo
- `<leader>rw` - replace word under cursor
- `J/K` (visual) - move line(s) down/up
- `<leader>u` - undo tree
- `<leader>f` - format buffer (conform)

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
- `:w` - save
- `:q` - quit
- `:wq` - save & quit
- `:q!` - quit without saving
