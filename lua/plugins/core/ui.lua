return {
  {
    'https://github.com/nvim-mini/mini.icons',
    lazy = true,
    config = function()
      local mini_icons = require('mini.icons')

      mini_icons.setup()
      mini_icons.mock_nvim_web_devicons()
    end
  },

  {
    'https://github.com/Imngzx/showkeys',
    keys = {
      { 'n', '<leader>sK', '<cmd>ShowkeysToggle<cr>', { desc = 'Toggle ShowkeysToggle' } },
    },
    config = function()
      require('showkeys').setup({
        position = 'bottom-center',
        maxkeys = 5
      })
    end
  },

  {
    'https://github.com/kevinhwang91/nvim-hlslens',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('hlslens').setup({
        calm_down = true,
        nearest_only = true,
        nearest_float_when = 'auto',
        float_shadow_blend = 50,
        virt_priority = 100,
      })

      local kopts = { noremap = true, silent = true }

      local vim_key = vim.keymap.set
      vim_key('n', 'n', function()
        if package.loaded['flash-any'] and vim.fn.getreg('/') == '' then
          return [[<Cmd>lua require('flash-any').search_repeat('n')<CR><Cmd>normal! zv<CR>]]
        end
        return [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>normal! zv<CR><Cmd>lua require('hlslens').start()<CR>]]
      end, { expr = true, silent = true, desc = 'Next search result' })
      vim_key('n', 'N', function()
        if package.loaded['flash-any'] and vim.fn.getreg('/') == '' then
          return [[<Cmd>lua require('flash-any').search_repeat('N')<CR><Cmd>normal! zv<CR>]]
        end
        return [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>normal! zv<CR><Cmd>lua require('hlslens').start()<CR>]]
      end, { expr = true, silent = true, desc = 'Prev search result' })
      vim_key('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim_key('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim_key('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim_key('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)

      vim_key('n', '<Leader>l', '<Cmd>noh<CR>', kopts)
    end
  },
}
