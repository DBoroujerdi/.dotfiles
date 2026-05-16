-- Formatting plugin specifications
-- Autoformatting and code formatting tools

return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = function()
      local util = require('conform.util')

      local function uses_oxfmt(bufnr)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == '' then return false end
        return vim.fs.find({ '.oxfmtrc.json' }, {
          upward = true,
          path = vim.fs.dirname(fname),
          type = 'file',
        })[1] ~= nil
      end

      local function js_like(bufnr)
        if uses_oxfmt(bufnr) then return { 'oxfmt' } end
        return { 'prettierd', 'prettier', stop_after_first = true }
      end

      return {
        notify_on_error = false,
        format_on_save = function(bufnr)
          -- Disable "format_on_save lsp_fallback" for languages that don't
          -- have a well standardized coding style
          local disable_filetypes = { c = true, cpp = true }
          local lsp_format_opt
          if disable_filetypes[vim.bo[bufnr].filetype] then
            lsp_format_opt = 'never'
          else
            lsp_format_opt = 'fallback'
          end
          return {
            timeout_ms = 500,
            lsp_format = lsp_format_opt,
          }
        end,
        formatters = {
          oxfmt = {
            command = util.from_node_modules('oxfmt'),
            args = { '--stdin-filepath', '$FILENAME' },
            stdin = true,
          },
        },
        formatters_by_ft = {
          lua = { 'stylua' },
          go = { 'goimports', 'gofmt' },

          -- JS/TS/JSON: oxfmt if project has .oxfmtrc.json, else prettier
          javascript = js_like,
          typescript = js_like,
          javascriptreact = js_like,
          typescriptreact = js_like,
          json = js_like,
          jsonc = js_like,

          -- oxfmt doesn't handle these (yet) — stick with prettier
          css = { 'prettierd', 'prettier', stop_after_first = true },
          scss = { 'prettierd', 'prettier', stop_after_first = true },
          html = { 'prettierd', 'prettier', stop_after_first = true },
          markdown = { 'prettierd', 'prettier', stop_after_first = true },
          yaml = { 'prettierd', 'prettier', stop_after_first = true },
          graphql = { 'prettierd', 'prettier', stop_after_first = true },
        },
      }
    end,
  },
}
