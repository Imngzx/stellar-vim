--[Functions]
local fn = vim.fn

vim.schedule(function()
  if vim.uv.os_uname().release:lower():find('microsoft') then
    local win32yank_paths = {
      '/mnt/c/Program Files/Neovim/bin/win32yank.exe',
      '/mnt/c/Users/Administrator/scoop/apps/neovim-nightly/current/bin/win32yank.exe',
    }

    local win32yank = nil

    -- Using a highly performant standard numeric loop
    for i = 1, #win32yank_paths do
      local path = win32yank_paths[i]
      if fn.executable(path) == 1 then
        win32yank = path
        break
      end
    end

    if win32yank then
      local system = vim.system
      local t_concat = table.concat
      local v_split = vim.split

      local copy_cmd = { win32yank, '-i', '--crlf' }
      local paste_cmd = { win32yank, '-o', '--lf' }
      local paste_opts = { text = true }
      local empty_res = {}
      local noop = function() end

      local function copy_handler(lines, _)
        if fn.reg_executing() ~= '' then return end
        system(copy_cmd, { stdin = t_concat(lines, '\n') }, noop)
      end

      local function paste_handler()
        local obj = system(paste_cmd, paste_opts):wait(1000)
        local text = obj.stdout

        if obj.code ~= 0 or type(text) ~= 'string' then return empty_res, 'v' end

        if text:byte(-1) == 10 then text = text:sub(1, -2) end
        return v_split(text, '\n', { plain = true }), 'v'
      end

      vim.g.clipboard = {
        name = 'AsyncWslClipboard',
        copy = {
          ['+'] = copy_handler,
          ['*'] = copy_handler,
        },
        paste = {
          ['+'] = paste_handler,
          ['*'] = paste_handler,
        },
        cache_enabled = 0,
      }
    end
  end

  local is_ssh = vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT or vim.env.SSH_TTY
  local clipboard = require('vim.ui.clipboard.osc52')
  if is_ssh then
    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = clipboard.copy('+'),
        ['*'] = clipboard.copy('*'),
      },
      paste = {
        ['+'] = clipboard.paste('+'),
        ['*'] = clipboard.paste('*'),
      },
    }
  end
  vim.opt.clipboard = 'unnamedplus'
end)
