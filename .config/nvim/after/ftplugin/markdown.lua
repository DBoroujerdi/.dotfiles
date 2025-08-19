-- Markdown filetype-specific configuration
-- Buffer-local settings for Markdown files

-- Set local options
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.textwidth = 80
vim.opt_local.spell = true
vim.opt_local.spelllang = 'en_us'

-- Buffer-local keymaps
local map = vim.keymap.set

-- Markdown-specific keymaps
map('n', '<leader>mp', ':MarkdownPreview<CR>', { buffer = 0, desc = 'Preview Markdown' })
map('n', '<leader>mt', ':TableModeToggle<CR>', { buffer = 0, desc = 'Toggle table mode' })
