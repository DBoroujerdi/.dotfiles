-- LSP plugin specifications
-- Language Server Protocol and related tools

return {
  -- Automatically install LSPs and related tools
  { 'williamboman/mason.nvim', config = true },
  { 'williamboman/mason-lspconfig.nvim', dependencies = { 'mason.nvim' } },
  { 'WhoIsSethDaniel/mason-tool-installer.nvim', dependencies = { 'mason.nvim' } },
  
  -- LSP configuration
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('lsp.servers')
    end,
  },
  
  -- Useful status updates for LSP
  { 'j-hui/fidget.nvim', opts = {} },
  
  -- Completion integration with LSP
  'hrsh7th/cmp-nvim-lsp',
  
  -- Lua LSP for Neovim config
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true },
}
