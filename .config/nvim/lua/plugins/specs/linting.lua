-- Linting plugin specifications
-- Code linting and diagnostics

return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require('lint')
      local uv = vim.uv or vim.loop

      local function find_upward(bufnr, names)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == '' then return nil end
        return vim.fs.find(names, {
          upward = true,
          path = vim.fs.dirname(fname),
          type = 'file',
        })[1]
      end

      local function uses_oxlint(bufnr)
        return find_upward(bufnr, {
          '.oxlintrc.json', '.oxlintrc.jsonc',
          'oxlintrc.json', 'oxlint.json',
        }) ~= nil
      end

      local js_filetypes = {
        javascript = true,
        typescript = true,
        javascriptreact = true,
        typescriptreact = true,
      }

      local function linters_for(bufnr)
        local ft = vim.bo[bufnr].filetype
        if js_filetypes[ft] then
          return { uses_oxlint(bufnr) and 'oxlint' or 'eslint_d' }
        end
        return lint.linters_by_ft[ft] or {}
      end

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })

      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function(args)
          local bufnr = args.buf
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
          if not (ok and stats and stats.size < max_filesize) then
            return
          end

          local available = {}
          for _, name in ipairs(linters_for(bufnr)) do
            local linter = lint.linters[name]
            local cmd = type(linter) == 'table' and linter.cmd
            if type(cmd) == 'function' then
              cmd = cmd()
            end
            if cmd and vim.fn.executable(cmd) == 1 then
              table.insert(available, name)
            end
          end

          if #available > 0 then
            lint.try_lint(available)
          end
        end,
      })
    end,
  },
}
