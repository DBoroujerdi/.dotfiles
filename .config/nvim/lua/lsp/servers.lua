-- LSP server configurations
-- This file configures all language servers

local ok_mason, mason = pcall(require, 'mason')
if ok_mason then 
  mason.setup() 
end

local ok_mason_lsp, mason_lsp = pcall(require, 'mason-lspconfig')
if ok_mason_lsp then 
  mason_lsp.setup() 
end

local lspconfig = require('lspconfig')
local capabilities = require('lsp.capabilities')
local on_attach = require('lsp.mappings').on_attach

-- Configure LSP servers
local servers = {
  gopls = {},
  ts_ls = {},
  terraformls = {},
  lua_ls = {
    settings = {
      Lua = {
        completion = {
          callSnippet = 'Replace',
        },
      },
    },
  },
}

-- Ensure the servers and tools above are installed
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
  'stylua', -- Used to format Lua code
  'eslint_d', -- Used to lint JavaScript/TypeScript code
  'prettierd', -- Used to format JavaScript/TypeScript and other files
  'prettier', -- Fallback formatter if prettierd is not available
})

local ok_mason_tool, mason_tool = pcall(require, 'mason-tool-installer')
if ok_mason_tool then
  mason_tool.setup { ensure_installed = ensure_installed }
end

-- Setup each server
if ok_mason_lsp then
  mason_lsp.setup {
    handlers = {
      function(server_name)
        local server = servers[server_name] or {}
        -- This handles overriding only values explicitly passed
        -- by the server configuration above
        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
        require('lspconfig')[server_name].setup(server)
      end,
    },
  }
end

-- LSP attach configuration
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Jump to the definition of the word under your cursor
    map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    
    -- Find references for the word under your cursor
    map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    
    -- Jump to the implementation of the word under your cursor
    map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
    
    -- Jump to the type of the word under your cursor
    map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
    
    -- Fuzzy find all the symbols in your current document
    map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
    
    -- Rename the variable under your cursor
    map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    
    -- Execute a code action
    map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
    
    -- Goto Declaration
    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    
    -- Document highlighting
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end
    
    -- Toggle inlay hints
    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})
