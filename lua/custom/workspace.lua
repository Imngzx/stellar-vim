local M = {}

function M.setup()
  local cwd = vim.uv.cwd()
  if not cwd then return end

  local matches = vim.fs.find('.nvim.lua', { path = cwd, upward = true, limit = 1 })
  local local_config = matches[1]

  if not local_config then return end

  local utils = require('libs.utils')
  if utils.is_windows() then
    local_config = vim.fs.normalize(local_config)
  end

  if vim.uv.fs_stat(local_config) then
    local content = vim.secure.read(local_config)

    if type(content) == 'string' and content ~= '' then
      local chunk, syntax_err = load(content, '@' .. local_config)

      if not chunk then
        vim.notify(
          string.format('\n[Workspace] Syntax error in %s:\n%s', local_config, syntax_err),
          vim.log.levels.ERROR
        )
        return
      end

      local ok, exec_err = xpcall(chunk, debug.traceback)
      if not ok then
        vim.notify(
          string.format('\n[Workspace] Execution error in %s:\n%s', local_config, exec_err),
          vim.log.levels.ERROR
        )
      end
    end
  end
end

function M.picker()
  local api = vim.api
  local bpm = require('libs.bpm')
  local nvim_win_get_buf = api.nvim_win_get_buf
  local nvim_buf_get_name = api.nvim_buf_get_name
  local nvim_tabpage_get_win = api.nvim_tabpage_get_win

  local cur_tab = api.nvim_get_current_tabpage()
  local tabs = api.nvim_list_tabpages()
  local is_ac = require('libs.power').is_ac()

  local items = {}

  for i = 1, #tabs do
    local tab = tabs[i]
    local name = bpm.call('resolve_tabname', tab) or ('Tab ' .. tab)

    local buf_count = 0
    if bpm.call('get_attached_buf', tab) then
      local attached_bufs = bpm.call('get_attached_buf', tab)
      buf_count = attached_bufs and #attached_bufs or 0
    else
      local unique_bufs = {}
      local wins = api.nvim_tabpage_list_wins(tab)
      for w = 1, #wins do
        local b = nvim_win_get_buf(wins[w])
        if b ~= -1 and api.nvim_buf_is_loaded(b) then
          unique_bufs[b] = true
        end
      end
      buf_count = 0
      for _ in pairs(unique_bufs) do buf_count = buf_count + 1 end
    end

    local focused_win = nvim_tabpage_get_win(tab)
    local focused_buf = nvim_win_get_buf(focused_win)
    local buf_name = nvim_buf_get_name(focused_buf)
    local active_file = buf_name:match('[^/\\]+$') or '[No Name]'

    items[i] = {
      text = name,
      tabpage = tab,
      is_current = (tab == cur_tab),
      buf_count = buf_count,
      active_file = active_file,
    }
  end

  if is_ac then
    -- ==========================================
    -- 🔌 交流电: Snacks.picker (完美 UI)
    -- ==========================================
    require('snacks').picker({
      title = ' 🏢 Workspaces ',
      items = items,

      layout = {
        preset = 'select',
        layout = {
          width = 0.45,
          height = 0.4,
          backdrop = 60
          -- border = 'rounded',
          -- box = 'vertical',
          -- { win = 'input', height = 1, border = 'bottom' },
          -- { win = 'list', border = 'none' },
        }
      },
      format = function(item, _)
        local is_cur = item.is_current

        local hl_text = is_cur and 'DiagnosticOk' or 'Normal'
        local hl_icon = is_cur and 'DiagnosticOk' or 'DiagnosticHint'
        local icon = is_cur and '󰓩 ' or '󰓨 '
        local suffix = is_cur and ' (Current)' or ''

        return {
          { ' ' .. icon .. ' ', hl_icon },
          { item.text .. suffix, hl_text },
          { '  [' .. item.buf_count .. ' bufs]', 'Comment' },
          { ' 󰍎 ' .. item.active_file, 'NonText' },
        }
      end,
      confirm = function(picker, item)
        picker:close()
        if item and api.nvim_tabpage_is_valid(item.tabpage) then
          api.nvim_set_current_tabpage(item.tabpage)
        end
      end,
    })
  else
    -- ==========================================
    -- 🔋 电池: Fzf-lua (性能拉满)
    -- ==========================================
    local ok_loader, loader = pcall(require, 'resonance.loader')
    if ok_loader and loader.specs['fzf-lua'] then
      loader.specs['fzf-lua']._force_load()
    else
      vim.cmd('packadd fzf-lua')
    end

    local fzf = require('fzf-lua')
    local fzf_utils = require('fzf-lua.utils')

    local fzf_items = {}
    local item_map = {}

    for i = 1, #items do
      local item = items[i]
      local is_cur = item.is_current

      local hl_text = is_cur and 'DiagnosticOk' or 'Normal'
      local hl_icon = is_cur and 'DiagnosticOk' or 'DiagnosticHint'
      local icon = is_cur and '󰓩' or '󰓨'
      local suffix = is_cur and ' (Current)' or ''

      local colored_icon = fzf_utils.ansi_from_hl(hl_icon, ' ' .. icon .. ' ')
      local colored_text = fzf_utils.ansi_from_hl(hl_text, item.text .. suffix)
      local colored_buf = fzf_utils.ansi_from_hl('Comment', '  [' .. item.buf_count .. ' bufs]')
      local colored_file = fzf_utils.ansi_from_hl('NonText', ' 󰍎 ' .. item.active_file)

      local fzf_str = colored_icon .. colored_text .. colored_buf .. colored_file

      table.insert(fzf_items, fzf_str)
      item_map[fzf_str] = item
    end

    fzf.fzf_exec(fzf_items, {
      prompt = '🏢 Workspaces> ',
      fzf_opts = { ['--ansi'] = true },
      winopts = {
        width = 0.45,
        height = 0.4,
        row = 0.5,
        col = 0.5,
        border = 'rounded',
        preview = { hidden = true },
      },
      actions = {
        ['default'] = function(selected)
          local item = item_map[selected[1]]
          if item and api.nvim_tabpage_is_valid(item.tabpage) then
            api.nvim_set_current_tabpage(item.tabpage)
          end
        end
      }
    })
  end
end

return M
