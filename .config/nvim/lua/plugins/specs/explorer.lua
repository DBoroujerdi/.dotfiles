-- File explorer plugin specifications
-- File tree and file management tools

return {
  -- Nvim-tree file explorer
  {
    'nvim-tree/nvim-tree.lua',
    lazy = false,
    init = function()
      -- Ensure FileExplorer augroup exists so nvim-tree's manage_netrw VimEnter autocmd doesn't throw E216
      vim.api.nvim_create_augroup('FileExplorer', { clear = true })
    end,
    keys = {
      { '<C-n>', '<cmd>NvimTreeFindFileToggle<CR>', desc = 'Toggle file tree on current file' },
    },
    config = function()
      local api = require 'nvim-tree.api'

      require('nvim-tree').setup {
        hijack_cursor = true,
        disable_netrw = true,
        update_focused_file = {
          enable = true,
          update_root = {
            enable = false,
          },
        },
        view = {
          side = 'right',
          width = 30,
          preserve_window_proportions = true,
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
          api.map.on_attach.default(bufnr)

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
    config = function(_, opts)
      require('oil').setup(opts)
      vim.keymap.set('n', '-', '<cmd>Oil<cr>', { desc = 'Open parent directory' })
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
