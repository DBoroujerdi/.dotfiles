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
        format_on_save = {
          timeout_ms = 500,
          lsp_format = 'fallback',
        },
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
          c = { 'clang-format' },
          cpp = { 'clang-format' },

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
