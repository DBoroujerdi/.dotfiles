-- Treesitter plugin specifications
-- Syntax highlighting and code parsing

return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = { 
          'bash', 'c', 'html', 'lua', 'markdown', 'vim', 'vimdoc', 
          'css', 'javascript', 'typescript', 'json', 'yaml', 'python',
          'go', 'terraform'
        },
        -- Autoinstall languages that are not installed
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = { enable = true },
      }
    end,
  },
}
