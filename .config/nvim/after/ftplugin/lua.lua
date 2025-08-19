-- Lua filetype-specific configuration
-- Buffer-local settings for Lua files

-- Set local options
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Buffer-local keymaps
local map = vim.keymap.set
local opts = { buffer = 0, silent = true }

-- Lua-specific keymaps
map('n', '<leader>rr', ':source %<CR>', { buffer = 0, desc = 'Source current Lua file' })
map('n', '<leader>rt', ':luafile %<CR>', { buffer = 0, desc = 'Execute current Lua file' })
