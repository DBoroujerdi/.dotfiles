-- Treesitter plugin specifications
-- Parser installation and queries for Neovim's built-in treesitter
--
-- Pinned to the `main` branch, which is required from Neovim 0.12 onwards. The
-- legacy `master` branch is frozen for Neovim 0.11 and crashes on 0.12: its
-- bundled markdown queries call a custom `set-lang-from-info-string!` directive
-- whose handler assumes `match[capture_id]` is a single node, but Neovim 0.11
-- changed that to a list of nodes. The result is an `attempt to call method
-- 'range' (a nil value)` every time a markdown buffer parses its injections.
--
-- On `main` the plugin only installs parsers and ships queries. Highlighting,
-- folding and indentation are Neovim's job now, which is why highlighting is
-- started from the autocommand below rather than configured on the plugin.
--
-- Requires the tree-sitter CLI on $PATH: `brew install tree-sitter-cli`.

local ensure_installed = {
  'bash', 'c', 'cpp', 'html', 'lua', 'markdown', 'markdown_inline', 'vim', 'vimdoc',
  'css', 'javascript', 'typescript', 'json', 'yaml', 'python',
  'go', 'terraform',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    -- The `main` branch does not support lazy-loading.
    lazy = false,
    build = ':TSUpdate',
    config = function()
      -- No-op for parsers that are already present. Runs asynchronously.
      require('nvim-treesitter').install(ensure_installed)

      -- `language.add` returns falsy when the parser is missing, which also
      -- covers parsers that are still compiling on first startup.
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-highlight', { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)
          if lang and vim.treesitter.language.add(lang) then
            pcall(vim.treesitter.start, ev.buf, lang)
          end
        end,
      })
    end,
  },
}
