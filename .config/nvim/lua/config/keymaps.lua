-- Global keymaps configuration
-- This file contains all vim.keymap.set calls for global mappings

local map = vim.keymap.set

-- Prevent <Space> from falling through to its default (move right) when a
-- <leader>… sequence isn't matched (e.g. <leader>D in a buffer without LSP).
map({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Clear highlights on search when pressing <Esc> in normal mode
map('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
map('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
map('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Terminal mode exit
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Split navigation with CTRL+<hjkl>
map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Split management
map('n', '<leader>wv', '<C-w>v', { desc = 'Split window vertically' })
map('n', '<leader>wh', '<C-w>s', { desc = 'Split window horizontally' })
map('n', '<leader>wx', ':close<CR>', { desc = 'Close current split window' })
map('n', '<leader>o', ':only<cr>', { desc = 'Close other windows' })

-- Text manipulation
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move highlighted line(s) down' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move highlighted line(s) up' })

-- Copy code reference / markdown snippet for agent chats & clipboard
local function copy_code_reference(opts)
  opts = opts or {}
  local mode = vim.fn.mode()
  local start_line, end_line

  if mode:match('[vV\22]') then
    start_line = vim.fn.line('v')
    end_line = vim.fn.line('.')
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
  else
    start_line = vim.fn.line('.')
    end_line = start_line
  end

  local filepath = vim.fn.expand('%:.')
  if filepath == '' then
    vim.notify('No file associated with buffer', vim.log.levels.WARN, { title = 'Code Reference' })
    return
  end

  local line_range = (start_line == end_line) and tostring(start_line) or string.format('%d-%d', start_line, end_line)

  local result
  if opts.markdown then
    local ft = vim.bo.filetype
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    local code = table.concat(lines, '\n')
    result = string.format('`%s:%s`\n```%s\n%s\n```', filepath, line_range, ft, code)
  else
    local prefix = opts.prefix or ''
    result = string.format('%s%s:%s', prefix, filepath, line_range)
  end

  vim.fn.setreg('+', result)
  vim.fn.setreg('"', result)
  vim.notify(string.format('Copied: %s', result), vim.log.levels.INFO, { title = 'Code Reference' })
end

map({ 'n', 'v' }, '<leader>yr', function()
  copy_code_reference()
end, { desc = '[Y]ank code [R]eference (path:lines)' })

map({ 'n', 'v' }, '<leader>ya', function()
  copy_code_reference({ prefix = '@' })
end, { desc = '[Y]ank [@]-mention code reference' })

map({ 'n', 'v' }, '<leader>ym', function()
  copy_code_reference({ markdown = true })
end, { desc = '[Y]ank [M]arkdown code block with reference' })

-- Word replacement
map('n', '<leader>rw', [[:%s/\<<C-r><C-w>\>//gI<Left><Left><Left>]], { desc = 'Replace current word' })

-- Project picker
map('n', '<leader>pp', '<cmd>NeovimProjectDiscover<cr>', { desc = 'Open project picker' })

map('n', '<leader>pf', '<cmd>Telescope find_files hidden=true no_ignore=true no_ignore_parent=true follow=true<cr>', {
  desc = 'Find files (all, including ignored)',
})
map('n', '<leader>pg', '<cmd>Telescope git_files<cr>', { desc = 'Find git files' })

map('n', '<leader>P', '<cmd>Telescope commands<cr>', { desc = 'Command palette (VSCode-like)' })

-- Cmd+[ and Cmd+] for navigation
map('n', '<leader>[', '<C-o>', { desc = 'Go back' })
map('n', '<leader>]', '<C-i>', { desc = 'Go forward' })

-- Reload Neovim configuration
local function reload_config()
  for name, _ in pairs(package.loaded) do
    if name:match('^config') or name:match('^plugins') or name:match('^lsp') then
      package.loaded[name] = nil
    end
  end

  require('config.options')
  require('config.keymaps')
  require('config.autocmds')
  pcall(require, 'config.ui')
  pcall(require, 'config.commands')

  -- Re-source plugin specs so new keymaps/specs take effect immediately
  local specs_path = vim.fn.stdpath('config') .. '/lua/plugins/specs'
  for _, file in ipairs(vim.fn.glob(specs_path .. '/*.lua', true, true)) do
    pcall(dofile, file)
  end

  vim.notify('Neovim configuration reloaded!', vim.log.levels.INFO, { title = 'Config Reload' })
end

map('n', '<leader>so', reload_config, { desc = '[S]ource/[O]verhaul config reload' })
map('n', '<leader>R', reload_config, { desc = '[R]eload Neovim config' })

-- Terminal toggle function
local terminal_buf = nil
local terminal_win = nil

local function toggle_terminal()
  if terminal_win and vim.api.nvim_win_is_valid(terminal_win) then
    -- Terminal is open, close it
    vim.api.nvim_win_close(terminal_win, false)
    terminal_win = nil
  else
    -- Open terminal at the bottom
    vim.cmd 'botright 15split'
    if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) then
      -- Reuse existing terminal buffer
      vim.api.nvim_set_current_buf(terminal_buf)
    else
      -- Create new terminal
      vim.cmd 'terminal'
      terminal_buf = vim.api.nvim_get_current_buf()
      -- Start in insert mode
      vim.cmd 'startinsert'
    end
    terminal_win = vim.api.nvim_get_current_win()
  end
end

map('n', '<leader>j', toggle_terminal, { desc = 'Toggle terminal' })
map('t', '<leader>j', toggle_terminal, { desc = 'Toggle terminal' })

-- TIP: Disable arrow keys in normal mode (uncomment if desired)
-- map('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- map('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- map('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- map('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')
