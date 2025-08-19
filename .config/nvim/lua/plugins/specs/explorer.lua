-- File explorer plugin specifications
-- File tree and file management tools

return {
  -- Nvim-tree file explorer
  {
    'nvim-tree/nvim-tree.lua',
    lazy = false,
    keys = {
      { '<C-n>', ':NvimTreeToggle<CR>' },
    },
    config = function()
      local api = require 'nvim-tree.api'
      
      require('nvim-tree').setup {
        hijack_cursor = true,
        disable_netrw = true,
        view = {
          adaptive_size = true,
          float = {
            enable = true,
          },
        },
        renderer = {
          indent_markers = { enable = true },
        },
        actions = {
          open_file = {
            window_picker = {
              enable = false,
            },
          },
        },
        on_attach = function(bufnr)
          api.config.mappings.default_on_attach(bufnr)
          
          local opts = { buffer = bufnr, silent = true, nowait = true }
          local map = vim.keymap.set
          
          map('n', 's', api.node.open.vertical, opts)
          map('n', 'h', api.node.open.horizontal, opts)
        end,
      }
    end,
  },
  
  -- Oil.nvim for file operations
  {
    'stevearc/oil.nvim',
    opts = {},
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('oil').setup()
      vim.keymap.set('n', '-', ':Oil<cr>', { desc = 'Open parent directory' })
    end,
  },
  
  -- YAML support
  {
    'cuducos/yaml.nvim',
    ft = { 'yaml' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-telescope/telescope.nvim',
    },
  },
}
