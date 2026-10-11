local common_exclude = { '.git', '~', '.idea', '.DS_Store' }

return {
  enabled = true,
  matcher = {
    cwd_bonus = true, -- 当前目录加权。更倾向于当前路径下的文件
    frecency = true, -- 开启记忆加权。打开次数越多越靠前。
    sort_empty = false, --  首次打开时预览器就显示排序后的结果
  },
  hidden = true,
  prompt = ' ',
  layouts = {
    my_default_layout = {
      layout = {
        width = 0.8,
        height = 0.8,
        border = 'none',
        backdrop = 60,
        box = 'horizontal',
        {
          box = 'vertical',
          { win = 'input', height = 1, border = 'rounded', title = '{title} {live} {flags}', title_pos = 'left' },
          { win = 'list', border = 'rounded' },
        },
        { win = 'preview', border = 'rounded', title = '{preview:Preview}', title_pos = 'left', width = 0.65 },
      },
    },
    my_vertical_layout = {
      layout = {
        width = 0.8,
        height = 0.9,
        border = 'rounded',
        backdrop = false,
        box = 'vertical',
        { win = 'input', border = 'rounded', height = 1, title = '{title} {live} {flags}', title_pos = 'left' },
        { win = 'list', border = 'rounded', height = 8 },
        { win = 'preview', border = 'rounded' },
      },
    },
  },
  layout = {
    preset = function()
      return vim.o.columns >= 100 and 'my_default_layout' or 'my_vertical_layout'
    end,
  },
  icons = {
    files = {
      enabled = true,
      dir = I.basic.dir .. ' ',
      dir_open = I.basic.dir_open .. ' ',
      file = I.basic.file .. ' '
    },
    tree = {
      vertical = I.basic.indent,
      middle = I.basic.indent,
      last = I.basic.indent,
    },
    git = {
      enabled = true,
      commit = I.git.commit .. ' ',
      staged = I.git.staged,
      added = I.git.added,
      deleted = I.git.deleted,
      ignored = I.git.ignored,
      modified = I.git.modified,
      renamed = I.git.renamed,
      unmerged = I.git.branch,
      untracked = I.git.untracked,
    },
    diagnostics = {
      Error = I.lsp.error .. ' ',
      Warn = I.lsp.warn .. ' ',
      Hint = I.lsp.hint .. ' ',
      Info = I.lsp.info .. ' ',
    },
  },
  sources = {
    files = { exclude = common_exclude },
    grep = { exclude = common_exclude },
    explorer = {
      exclude = common_exclude,
      diagnostics = true,
      diagnostics_open = false,
      git_status = true,
      git_status_open = false,
      git_untracked = true,
      layout = function()
        return {
          preview = false,
          layout = {
            position = 'left',
            width = (vim.g.explorer_size or { width = 30 }).width,
            box = 'vertical',
            { win = 'input', height = 1, border = 'rounded', title = '{title} {live} {flags}', title_pos = 'center' },
            { win = 'list', border = 'none' },
            { win = 'preview', title = '{preview}', height = 0.4, border = 'top' },
          },
        }
      end,
      on_show = function(picker)
        local show = true
        local gap = 1
        local clamp_width = function(value) return math.max(20, math.min(42, value)) end
        local position = picker.resolved_layout.layout.position
        local rel = picker.layout.root
        local update = function(win)
          local border = win:border_size().left + win:border_size().right
          win.opts.row = vim.api.nvim_win_get_position(rel.win)[1]
          win.opts.height = 0.6
          if position == 'left' then
            win.opts.col = vim.api.nvim_win_get_width(rel.win) + gap
            win.opts.width = clamp_width(vim.o.columns - border - win.opts.col)
          end
          if position == 'right' then
            win.opts.col = -vim.api.nvim_win_get_width(rel.win) - gap
            win.opts.width = clamp_width(vim.o.columns - border + win.opts.col)
          end
          win:update()
        end

        local preview_win = Snacks.win.new {
          relative = 'editor', external = false, focusable = false,
          border = 'rounded', backdrop = false, show = show,
          bo = { filetype = 'snacks_float_preview', buftype = 'nofile', buflisted = false, swapfile = false, undofile = false },
          on_win = function(win) update(win) end,
        }

        rel:on('WinLeave', function()
          vim.schedule(function()
            if not picker:is_focused() then
              if picker.preview and picker.preview.win then
                picker.preview.win:close()
              end
            end
          end)
        end)
        rel:on('WinResized', function() update(preview_win) end)

        picker.preview = picker.preview or {}
        picker.preview.win = preview_win
        picker.main = preview_win.win

        local orig_show_preview = picker.show_preview

        picker.show_preview = require('snacks').util.debounce(function()
          if picker.preview and picker.preview.win and picker.preview.win:valid() then
            ---@diagnostic disable-next-line: redundant-parameter
            orig_show_preview(picker)
          end
        end, { ms = 60 })

        picker:show_preview()
      end,
      on_close = function(picker)
        vim.g.explorer_size = picker.layout.root:size()
        if picker.preview and picker.preview.win then
          picker.preview.win:close()
        end
      end,
      actions = {
        toggle_preview = function(picker)
          if picker.preview and picker.preview.win then
            picker.preview.win:toggle()
          end
        end,
        explorer_add = function(picker)
          local item = picker:current()
          local dir = vim.uv.cwd()
          if item and item.file then
            local stat = vim.uv.fs_stat(item.file)
            local is_dir = stat and stat.type == 'directory'
            dir = is_dir and item.file or vim.fs.dirname(item.file)
          end
          vim.ui.input({ prompt = 'Add a new file or directory (directories end with a "/"): ' },
            function(input)
              if not input or input == '' then return end
              local path = vim.fs.normalize(dir .. '/' .. input)
              local is_dir = input:sub(-1) == '/'
              local target_dir = is_dir and path or vim.fs.dirname(path)
              local stat = vim.uv.fs_stat(target_dir)
              if not stat or stat.type ~= 'directory' then
                pcall(vim.fs.mkdir, target_dir,
                  { parents = true })
              end
              if is_dir then
                picker:update()
              else
                local fd = io.open(path, 'w')
                if fd then
                  fd:close(); picker:update()
                end
                vim.schedule(function()
                  vim.cmd('edit ' .. vim.fn.fnameescape(path))
                  picker:close()
                  if not fd then
                    vim.notify(
                      '\n[Explorer] Read-only directory.\nFile opened in memory. Sudo will be required on save.',
                      vim.log.levels.WARN)
                  end
                end)
              end
            end)
        end,
      },
    }
  }
}
