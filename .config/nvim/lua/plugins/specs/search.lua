-- Search and finder plugin specifications
-- Telescope and related search functionality

return {
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = 'master',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
      'debugloop/telescope-undo.nvim',
      {
        'smartpde/telescope-recent-files',
        config = function()
          vim.keymap.set('n', '<leader>r', function()
            require('telescope').extensions.recent_files.pick()
          end, { silent = true })
        end,
      },
    },
    config = function()
      local function flash(prompt_bufnr)
        require('flash').jump {
          pattern = '^',
          label = { after = { 0, 0 } },
          search = {
            mode = 'search',
            exclude = {
              function(win)
                return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'TelescopeResults'
              end,
            },
          },
          action = function(match)
            local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
            picker:set_selection(match.pos[1] - 1)
          end,
        }
      end

      require('telescope').setup {
        defaults = {
          mappings = {
            i = {
              ['<c-s>'] = flash,
            },
            n = {
              s = flash,
            },
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
          ['undo'] = {},
        },
      }
      
      require('telescope').load_extension 'undo'
      
      -- Enable telescope extensions
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
      
      local function get_visual_selection()
        local saved_reg = vim.fn.getreg 'v'
        local saved_regtype = vim.fn.getregtype 'v'
        vim.cmd [[noautocmd silent normal! "vy]]
        local selection = vim.fn.getreg 'v'
        local regtype = vim.fn.getregtype 'v'
        vim.fn.setreg('v', saved_reg, saved_regtype)
        selection = selection:gsub('\r\n', '\n'):gsub('\r', '\n')
        if regtype == 'V' then
          selection = selection:gsub('\n$', '')
          selection = selection:match '^%s*(.-)%s*$' or selection
        else
          selection = selection:gsub('\n$', '')
          selection = selection:gsub('\n', ' ')
        end
        return selection
      end

      -- Telescope keymaps
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>p', builtin.find_files, {})
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord / Selection' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('v', '<leader>sg', function()
        local text = get_visual_selection()
        builtin.live_grep { default_text = text ~= '' and text or nil }
      end, { desc = '[S]earch by [G]rep (visual selection)' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', function()
        builtin.buffers {
          sort_mru = true,
          sort_lastused = true,
          ignore_current_buffer = true,
          sorting_strategy = 'descending',
        }
      end, { desc = '[ ] Find existing buffers (MRU, bottom-up)' })
      
      -- Git shortcuts
      vim.keymap.set('n', '<leader>gc', builtin.git_commits, { desc = '[G]it [C]ommits' })
      vim.keymap.set('n', '<leader>gp', builtin.git_bcommits, { desc = '[G]it commits with [P]review' })
      
      -- Undo
      vim.keymap.set('n', '<leader>u', '<cmd>Telescope undo<cr>')
      
      -- Fuzzy search in current buffer
      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })
      vim.keymap.set('v', '<leader>/', function()
        local text = get_visual_selection()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
          default_text = text ~= '' and text or nil,
        })
      end, { desc = '[/] Fuzzily search in current buffer (visual selection)' })
      
      -- Search in open files
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })
      vim.keymap.set('v', '<leader>s/', function()
        local text = get_visual_selection()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
          default_text = text ~= '' and text or nil,
        }
      end, { desc = '[S]earch [/] in Open Files (visual selection)' })
      
      -- Search neovim config files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },
}
