-- LSP buffer-local mappings
-- This file provides the on_attach function for LSP keybindings

local M = {}

function M.on_attach(bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  -- LSP keybindings
  map('n', 'gd', vim.lsp.buf.definition, 'LSP: Go to Definition')
  map('n', 'K', vim.lsp.buf.hover, 'LSP: Hover')
  map('n', 'gr', vim.lsp.buf.references, 'LSP: References')
  map('n', 'gI', vim.lsp.buf.implementation, 'LSP: Implementation')
  map('n', '<leader>D', vim.lsp.buf.type_definition, 'LSP: Type Definition')
  map('n', '<leader>rn', vim.lsp.buf.rename, 'LSP: Rename')
  map('n', '<leader>ca', vim.lsp.buf.code_action, 'LSP: Code Action')
  map('n', 'gD', vim.lsp.buf.declaration, 'LSP: Declaration')
end

return M
