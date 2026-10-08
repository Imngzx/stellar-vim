local M = {}

local api = vim.api
local fn = vim.fn
local system = vim.system
local schedule = vim.schedule
local trim = vim.trim
local executable = fn.executable
local create_augroup = api.nvim_create_augroup
local create_autocmd = api.nvim_create_autocmd

local FCITX5_REMOTE = executable('fcitx5-remote') == 1 and 'fcitx5-remote' or nil
if not FCITX5_REMOTE then
  return M
end

local CMD_GET = { FCITX5_REMOTE }
local CMD_OFF = { FCITX5_REMOTE, '-c' }
local CMD_ON = { FCITX5_REMOTE, '-o' }

function M.setup()
  local aug = create_augroup('DIY_Fcitx5', { clear = true })

  create_autocmd('InsertLeave', {
    group = aug,
    callback = function()
      system(CMD_GET, { text = true }, function(obj)
        if obj.code == 0 and obj.stdout then
          schedule(function()
            vim.b.saved_im = trim(obj.stdout)
          end)
        end
      end)
      system(CMD_OFF)
    end,
  })

  create_autocmd('InsertEnter', {
    group = aug,
    callback = function()
      local target = vim.b.saved_im
      if target == '2' then
        system(CMD_ON)
      end
    end,
  })

  create_autocmd({ 'VimEnter', 'FocusGained', 'CmdlineLeave' }, {
    group = aug,
    callback = function()
      system(CMD_OFF, { text = true }):wait()
    end,
  })
end

return M