-- Global keymaps configuration
-- This file contains all vim.keymap.set calls for global mappings

local map = vim.keymap.set

-- Clear highlights on search when pressing <Esc> in normal mode
map('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
map('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
map('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Terminal mode exit
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Split navigation with CTRL+<hjkl>
map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Split management
map('n', '<leader>wv', '<C-w>v', { desc = 'Split window vertically' })
map('n', '<leader>wh', '<C-w>s', { desc = 'Split window horizontally' })
map('n', '<leader>wx', ':close<CR>', { desc = 'Close current split window' })
map('n', '<leader>o', ':only<cr>', { desc = 'Close other windows' })

-- Text manipulation
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move highlighted line(s) down' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move highlighted line(s) up' })

-- Word replacement
map('n', '<leader>rw', [[:%s/\<<C-r><C-w>\>//gI<Left><Left><Left>]], { desc = 'Replace current word' })

-- Project picker
map('n', '<leader>pp', '<cmd>NeovimProjectDiscover<cr>', { desc = 'Open project picker' })

-- TIP: Disable arrow keys in normal mode (uncomment if desired)
-- map('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- map('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- map('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- map('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')
