-- AI plugin specifications
-- AI-powered coding assistance tools

return {
  {
    'olimorris/codecompanion.nvim',
    version = '^19.0.0',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    cmd = { 'CodeCompanion', 'CodeCompanionChat', 'CodeCompanionActions', 'CodeCompanionCmd' },
    keys = {
      { '<leader>aa', '<cmd>CodeCompanionChat Toggle<cr>',  mode = { 'n', 'v' }, desc = 'CodeCompanion Toggle Chat' },
      { '<leader>ac', '<cmd>CodeCompanionActions<cr>',      mode = { 'n', 'v' }, desc = 'CodeCompanion Actions' },
      { '<leader>ai', '<cmd>CodeCompanion<cr>',             mode = { 'n', 'v' }, desc = 'CodeCompanion Inline Assist' },
      { '<leader>ap', '<cmd>CodeCompanionChat Add<cr>',     mode = { 'v' },      desc = 'CodeCompanion Add Selection' },
      { 'ga',         '<cmd>CodeCompanionChat Add<cr>',     mode = { 'v' },      desc = 'CodeCompanion Add Selection' },
    },
    opts = {
      strategies = {
        chat = {
          adapter = 'claude_code',
        },
        inline = {
          adapter = 'claude_code',
        },
      },
    },
  },
}
