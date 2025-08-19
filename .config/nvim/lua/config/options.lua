-- Core Neovim options configuration
-- This file contains all vim.opt, vim.g, and vim.o settings

-- Set leader keys
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Font and UI settings
vim.g.have_nerd_font = false

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Mouse support
vim.opt.mouse = 'a'

-- UI settings
vim.opt.showmode = false
vim.opt.termguicolors = true

-- Clipboard sync
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Indentation and formatting
vim.opt.breakindent = true
vim.opt.undofile = true

-- Search settings
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Sign column
vim.opt.signcolumn = 'yes'

-- Performance settings
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Split behavior
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Whitespace display
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Command preview
vim.opt.inccommand = 'split'

-- Cursor and scroll
vim.opt.cursorline = true
vim.opt.scrolloff = 10
