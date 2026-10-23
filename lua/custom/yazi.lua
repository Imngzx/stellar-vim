local M = {}

function M.open()
  if vim.fn.executable('yazi') == 0 then
    vim.notify('Yazi is not installed or not in PATH!', vim.log.levels.ERROR,
      { title = 'Stellar:Yazi' })
    return
  end

  local tmpfile = os.tmpname()

  local win = require('snacks').win({
    position = 'float',
    width = 0.8,
    height = 0.8,
    border = 'rounded',
    backdrop = 60,
    title = ' 󰇥 Yazi ',
    title_pos = 'center',
    zindex = 45,
    enter = true,
  })

  vim.fn.jobstart(string.format('yazi --chooser-file="%s"', tmpfile), {
    term = true,
    on_exit = function(_, code, _)
      vim.schedule(function()
        win:close()
        if code == 0 then
          local fd = io.open(tmpfile, 'r')
          if fd then
            local is_first = true
            for target_file in fd:lines() do
              if target_file and target_file ~= '' then
                if is_first then
                  vim.cmd.edit(target_file)
                  is_first = false
                else
                  vim.cmd.badd(target_file)
                end
              end
            end
            fd:close()
            os.remove(tmpfile)
          end
        end
      end)
    end
  })

  vim.cmd('startinsert')

  vim.keymap.set('t', '<Esc><Esc>', '<Esc><Esc>', { buf = win.buf, nowait = true })
  vim.keymap.set('t', '<C-\\><C-n>', '<NOP>', { buf = win.buf, nowait = true })
end

return M
