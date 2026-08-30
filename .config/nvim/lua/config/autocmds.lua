-- Autocommands configuration
-- This file contains all vim.api.nvim_create_autocmd calls

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Auto-check if open buffers have changed on disk (e.g., when switching back to nvim or after idling)
local checktime_group = vim.api.nvim_create_augroup('auto-checktime', { clear = true })
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI', 'TermClose' }, {
  desc = 'Check if buffers changed on disk',
  group = checktime_group,
  callback = function()
    if vim.fn.getcmdwintype() == '' and vim.fn.mode() ~= 'c' then
      vim.cmd('checktime')
    end
  end,
})

-- Notification when a buffer is reloaded due to external file changes
vim.api.nvim_create_autocmd('FileChangedShellPost', {
  desc = 'Notify when file changed on disk and buffer was reloaded',
  group = vim.api.nvim_create_augroup('auto-reload-notify', { clear = true }),
  callback = function(event)
    vim.notify('File changed on disk. Buffer reloaded.', vim.log.levels.INFO, {
      title = vim.fn.fnamemodify(event.file, ':t'),
    })
  end,
})
