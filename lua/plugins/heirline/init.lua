require('resonance').load({
  {
    'https://github.com/rebelot/heirline.nvim',
    event = { 'BufReadPost', 'BufNewFile', 'BufEnter' },
    config = function()
      local heirline = require('heirline')
      local utils = require('heirline.utils')
      local colors = require('plugins.heirline.colors')

      heirline.load_colors(colors.setup_colors())

      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = function() utils.on_colorscheme(colors.setup_colors) end,
      })

      require('libs.git').setup({
        get_git_root = function(filepath)
          local ok, snacks = pcall(require, 'snacks')
          return ok and snacks.git.get_root(filepath) or nil
        end
      })

      local StatusLine = require('plugins.heirline.statusline')
      local TabLine = require('plugins.heirline.tabline')
      local WinBar = require('plugins.heirline.winbar')

      heirline.setup({
        statusline = StatusLine,
        tabline = TabLine,
        winbar = WinBar,
        opts = {
          disable_winbar_cb = function(args)
            if vim.api.nvim_win_get_config(0).zindex then
              return true
            end
            local buf = args.buf
            local bt = vim.api.nvim_get_option_value('buftype', { buf = buf })
            local ft = vim.api.nvim_get_option_value('filetype', { buf = buf })
            local name = vim.api.nvim_buf_get_name(buf)
            if bt == '' and name == '' and not vim.api.nvim_get_option_value('modified', { buf = buf }) then
              return true
            end
            return bt == 'nofile' or bt == 'prompt' or bt == 'help' or
              ft == 'snacks_dashboard' or ft:match('^snacks_picker')
          end,
        }
      })
    end
  },

  {
    'https://github.com/aurora0x27/bpm.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('bpm').setup()
    end
  },
})
