-- LSP capabilities configuration
-- This file provides enhanced capabilities for LSP integration

local capabilities = vim.lsp.protocol.make_client_capabilities()

-- Add nvim-cmp capabilities if available
local ok_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
if ok_cmp then
  capabilities = vim.tbl_deep_extend('force', capabilities, cmp_nvim_lsp.default_capabilities())
end

return capabilities
