-- Plugin manager entry point
-- This file sets up lazy.nvim and imports all plugin specifications

-- Install lazy.nvim if not already installed
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

-- Add lazy.nvim to runtime path
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
local ok, lazy = pcall(require, 'lazy')
if not ok then
  return
end

lazy.setup({
  spec = {
    -- Import all plugin specifications from the specs directory
    { import = 'plugins.specs' },
    
    -- Keep existing kickstart plugins until fully migrated
    { import = 'kickstart.plugins' },
    
    -- Keep existing custom plugins until fully migrated
    { import = 'custom.plugins' },
  },
  ui = {
    -- Icons configuration
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
  change_detection = { notify = false },
})
