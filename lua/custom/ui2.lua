local M = {}

local api = vim.api
local nvim_create_autocmd = api.nvim_create_autocmd
local nvim_win_set_config = api.nvim_win_set_config
local nvim_get_current_win = api.nvim_get_current_win

function M.setup()
  local ok, ui2 = pcall(require, 'vim._core.ui2')
  if not ok then return end
  local vom = vim.opt.messagesopt

  -- Configure timeout and maxheight via messagesopt (replaces msg.msg.timeout and msg.cmd.height)
  vom:append('timeout:4000')
  vom:append('maxheight:50')

  -- ui2 has no title option; it fires FileType with the msg window current,
  -- and later set_pos calls leave border = nil, so the title persists.
  nvim_create_autocmd('FileType', {
    group = api.nvim_create_augroup('custom.ui2', { clear = true }),
    pattern = 'msg',
    desc = 'ui2: title the message window',
    callback = function()
      pcall(nvim_win_set_config, nvim_get_current_win(), {
        title = ' Messages ',
        title_pos = 'center',
      })
    end,
  })

  ui2.enable({
    enable = true,
    msg = {
      targets = 'msg',

      cmd = {},

      msg = {
        height = 0.5,
      },

      dialog = {
        height = 0.5,
      },
    },
  })
end

return M
