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
}
