-- Core plugin specifications
-- Essential plugins that provide basic functionality

return {
  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- Git integration
  'tpope/vim-fugitive',

  -- Comment functionality
  { 'numToStr/Comment.nvim', opts = {} },

  -- Git signs in the gutter
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  -- Undo tree
  'mbbill/undotree',

  -- Session manager (required by neovim-project)
  {
    'Shatur/neovim-session-manager',
    opts = {
      autosave_last_session = true,
      autosave_ignore_not_normal = true,
      autosave_ignore_dirs = {},
      autosave_ignore_filetypes = {
        'gitcommit',
        'gitrebase',
      },
      autosave_ignore_buftypes = {},
      autosave_only_in_session = false,
      max_path_length = 80,
    },
  },

  -- Project management
  {
    'coffebar/neovim-project',
    opts = {
      projects = { -- define project roots
        '~/projects/*/*',
      },
      picker = {
        type = 'telescope', -- or 'fzf-lua'
      },
    },
    init = function()
      -- enable saving the state when changing directories
      vim.opt.sessionoptions:append('globals')
    end,
  },
}
