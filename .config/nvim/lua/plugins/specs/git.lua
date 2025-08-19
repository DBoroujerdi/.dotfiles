-- Git plugin specifications
-- Git integration and version control tools

return {
  -- Neogit for git operations
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'nvim-telescope/telescope.nvim',
    },
    config = true,
    keys = {
      {
        '<leader>gg',
        function()
          local is_dir = function(path)
            local f = io.open(path, 'r')
            if f == nil then
              return false
            end
            local _, _, code = f:read(1)
            f:close()
            return code == 21
          end
          
          if vim.api.nvim_buf_get_option(0, 'filetype') == 'netrw' then
            local get_netrw_path = function()
              return vim.fn['netrw#Call']('NetrwFile', vim.fn['netrw#Call'] 'NetrwGetWord')
            end
            
            local path = get_netrw_path()
            
            if is_dir(path) then
              vim.cmd(':Neogit cwd=' .. path)
            else
              print 'is netrw file'
            end
          else
            vim.cmd ':Neogit cwd=%:p:h<cr>'
          end
        end,
        desc = 'git status',
      },
    },
    integration = {
      telescope = true,
      diffview = true,
    },
  },
}
