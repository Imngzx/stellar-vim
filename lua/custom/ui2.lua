local M = {}

function M.setup()
  local ok, ui2 = pcall(require, 'vim._core.ui2')
  if not ok then return end
  local vom = vim.opt.messagesopt

  -- Configure timeout and maxheight via messagesopt (replaces msg.msg.timeout and msg.cmd.height)
  vom:append('timeout:4000')
  vom:append('maxheight:50')

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
