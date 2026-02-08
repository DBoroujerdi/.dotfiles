-- Treesitter plugin specifications
-- Syntax highlighting and code parsing

return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = {
        'bash', 'c', 'html', 'lua', 'markdown', 'vim', 'vimdoc',
        'css', 'javascript', 'typescript', 'json', 'yaml', 'python',
        'go', 'terraform'
      },
      auto_install = true,
    },
  },
}
