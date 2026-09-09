-- UI plugin specifications
-- Colorscheme, statusline, and visual enhancement plugins

return {
  -- Colorscheme with dynamic light/dark system sync
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      local function get_system_dark_mode()
        if vim.fn.has('mac') == 1 then
          local res = vim.system({ 'defaults', 'read', '-g', 'AppleInterfaceStyle' }):wait()
          return res.code == 0 and res.stdout:match('Dark') ~= nil
        end
        return vim.o.background == 'dark'
      end

      local function apply_theme(is_dark)
        if is_dark == nil then
          is_dark = get_system_dark_mode()
        end

        if is_dark then
          vim.o.background = 'dark'
          vim.cmd.colorscheme 'tokyonight-night'
        else
          vim.o.background = 'light'
          vim.cmd.colorscheme 'tokyonight-day'
        end
        vim.cmd.hi 'Comment gui=none'
      end

      -- Apply initial theme based on current system appearance
      apply_theme()

      -- User command and keymap (<leader>tt) to toggle theme
      vim.api.nvim_create_user_command('ToggleTheme', function()
        if vim.fn.has('mac') == 1 then
          vim.fn.system('theme-toggle')
        else
          apply_theme(vim.o.background == 'light')
        end
      end, { desc = 'Toggle between dark and light theme' })

      vim.keymap.set('n', '<leader>tt', '<cmd>ToggleTheme<CR>', { desc = '[T]oggle [T]heme' })

      -- Listen for SIGUSR1 to reload theme immediately across all running instances
      local uv = vim.uv or vim.loop
      if uv then
        local sig = uv.new_signal()
        if sig then
          sig:start('sigusr1', function()
            vim.schedule(function()
              apply_theme()
            end)
          end)
        end
      end

      -- Re-check theme whenever Neovim regains focus
      vim.api.nvim_create_autocmd('FocusGained', {
        group = vim.api.nvim_create_augroup('ThemeAutoSync', { clear = true }),
        callback = function()
          apply_theme()
        end,
      })
    end,
  },

  -- Which-key for keybinding discovery
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 500, -- Delay in milliseconds before showing which-key popup
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },
      spec = {
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]ocument' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>f', group = '[F]ind' },
        { '<leader>w', group = '[W]orkspace' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },

  -- Mini plugins for various UI enhancements
  {
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings
      require('mini.surround').setup()

      -- Simple statusline
      local statusline = require 'mini.statusline'
      statusline.setup()
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },

  -- Todo comments highlighting
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
}
