-- Linting plugin specifications
-- Code linting and diagnostics

return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require('lint')
      local uv = vim.uv or vim.loop

      -- Configure linters by filetype
      lint.linters_by_ft = {
        javascript = { 'eslint_d' },
        typescript = { 'eslint_d' },
        javascriptreact = { 'eslint_d' },
        typescriptreact = { 'eslint_d' },
      }

      -- Create autocommand to trigger linting
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })

      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(uv.fs_stat, vim.api.nvim_buf_get_name(0))
          if not (ok and stats and stats.size < max_filesize) then
            return
          end

          local ft_linters = lint.linters_by_ft[vim.bo.filetype] or {}
          local available = {}
          for _, name in ipairs(ft_linters) do
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
