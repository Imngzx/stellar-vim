local M = {}
local win_cache = {}

local api = vim.api
local fn = vim.fn
local nvim_win_is_valid = api.nvim_win_is_valid
local nvim_win_get_buf = api.nvim_win_get_buf
local nvim_win_get_config = api.nvim_win_get_config
local nvim_buf_is_valid = api.nvim_buf_is_valid
local nvim_buf_get_name = api.nvim_buf_get_name
local nvim_win_get_width = api.nvim_win_get_width
local nvim_win_get_cursor = api.nvim_win_get_cursor
local nvim_win_call = api.nvim_win_call
local nvim_tabpage_list_wins = api.nvim_tabpage_list_wins
local nvim_win_set_config = api.nvim_win_set_config
local nvim_buf_set_lines = api.nvim_buf_set_lines
local nvim_buf_clear_namespace = api.nvim_buf_clear_namespace
local nvim_buf_set_extmark = api.nvim_buf_set_extmark
local nvim_set_hl = api.nvim_set_hl
local nvim_create_buf = api.nvim_create_buf
local nvim_open_win = api.nvim_open_win
local bpm = require('libs.bpm')
local nvim_buf_delete = api.nvim_buf_delete
local nvim_create_namespace = api.nvim_create_namespace
local nvim_create_augroup = api.nvim_create_augroup
local nvim_create_autocmd = api.nvim_create_autocmd
local nvim_get_current_win = api.nvim_get_current_win

local strdisplaywidth = api.nvim_strwidth
local line = fn.line
local pcall = pcall

local ns = nvim_create_namespace('HandcraftedIncline')

-- NOTE: 可选 'none', 'rounded', 'single'
M.config = {
  border = 'none',
  panel_bg = '#44406e',
}

local function get_contrast_color(hex_str)
  local Snacks = require('snacks')
  local bg_hex = Snacks.util.color('Normal', 'bg') or '#1e1e2e'
  local fg_hex = Snacks.util.color('Normal', 'fg') or '#cdd6f4'
  if not hex_str or #hex_str ~= 7 then return bg_hex end
  local r, g, b = tonumber(hex_str:sub(2, 3), 16), tonumber(hex_str:sub(4, 5), 16),
    tonumber(hex_str:sub(6, 7), 16)
  return (0.299 * r + 0.587 * g + 0.114 * b) > 128 and bg_hex or fg_hex
end

local function update_incline()
  local ok_wins, visible_wins = pcall(nvim_tabpage_list_wins, 0)
  if not ok_wins then return end

  for i = 1, #visible_wins do
    local win_id = visible_wins[i]
    if not nvim_win_is_valid(win_id) then
      M.close(win_id)
      goto continue
    end

    local buf_id = nvim_win_get_buf(win_id)
    local ok_conf, config = pcall(nvim_win_get_config, win_id)

    if not ok_conf or config.zindex or config.relative ~= '' or not nvim_buf_is_valid(buf_id) or vim.bo[buf_id].buftype ~= '' then
      M.close(win_id)
      goto continue
    end

    local should_hide = false
    local cursor = nvim_win_get_cursor(win_id)
    local topline = nvim_win_call(win_id, function()
      return line('w0')
    end)
    if cursor[1] == topline then
      should_hide = true
    end

    local buf_path = nvim_buf_get_name(buf_id)
    local filename = '[No Name]'
    if buf_path ~= '' then
      filename = bpm.call('resolve_bufname', buf_id) or vim.fs.basename(buf_path)
      if require('libs.utils').is_windows() then
        filename = vim.fs.basename(buf_path)
      end
    end
    local modified = vim.bo[buf_id].modified
    local win_width = nvim_win_get_width(win_id)

    local state_hash = string.format('%d_%s_%s_%d_%s', buf_id, tostring(modified), filename,
      win_width, tostring(should_hide))
    local state = win_cache[win_id] or {}

    if state.hash == state_hash and state.win and nvim_win_is_valid(state.win) and state.buf and nvim_buf_is_valid(state.buf) then
      goto continue
    end

    if should_hide then
      if state.win and nvim_win_is_valid(state.win) then
        pcall(nvim_win_set_config, state.win, { hide = true })
      end
      state.hash = state_hash
      win_cache[win_id] = state
      goto continue
    end

    local icon, hl = require('snacks').util.icon(filename, 'file')

    icon = icon or ''
    hl = hl or 'Normal'

    local ft_color = require('snacks').util.color(hl, 'fg') or '#ABB2BF'
    local contrast_fg = get_contrast_color(ft_color)

    local safe_hl = hl:gsub('[^%w_]', '_')
    nvim_set_hl(0, 'CIncIcon_' .. safe_hl, { fg = contrast_fg, bg = ft_color })
    nvim_set_hl(0, 'CIncArrow_' .. safe_hl, { fg = ft_color, bg = M.config.panel_bg })
    nvim_set_hl(0, 'CIncText', { fg = '#cdd6f4', bg = M.config.panel_bg, bold = modified })
    nvim_set_hl(0, 'CIncMod', { fg = '#ff9e64', bg = M.config.panel_bg, bold = true })

    local chunks = {
      { ' ' .. icon .. ' ', 'CIncIcon_' .. safe_hl },
      { ' ', 'CIncArrow_' .. safe_hl },
      { filename, 'CIncText' }
    }
    if modified then table.insert(chunks, { ' [+]', 'CIncMod' }) end
    table.insert(chunks, { ' ', 'CIncText' })

    if not state.buf or not nvim_buf_is_valid(state.buf) then
      state.buf = nvim_create_buf(false, true)
      vim.bo[state.buf].bufhidden = 'wipe'
    end

    local text_parts = {}
    for j = 1, #chunks do
      text_parts[j] = chunks[j][1]
    end
    local line_text = table.concat(text_parts)

    nvim_buf_set_lines(state.buf, 0, -1, false, { line_text })
    nvim_buf_clear_namespace(state.buf, ns, 0, -1)

    local byte_col = 0
    for c = 1, #chunks do
      local chunk = chunks[c]
      nvim_buf_set_extmark(state.buf, ns, 0, byte_col, {
        end_col = byte_col + #chunk[1],
        hl_group = chunk[2],
      })
      byte_col = byte_col + #chunk[1]
    end

    local text_width = strdisplaywidth(line_text)
    local win_opts = {
      relative = 'win',
      win = win_id,
      anchor = 'NE',
      row = 0,
      col = win_width - 1,
      width = text_width,
      height = 1,
      style = 'minimal',
      focusable = false,
      zindex = 40,
      border = M.config.border,
      hide = false,
    }

    if not state.win or not nvim_win_is_valid(state.win) then
      state.win = nvim_open_win(state.buf, false, win_opts)
      local winhl = M.config.border == 'none' and 'NormalFloat:Normal,FloatBorder:Normal' or
        'NormalFloat:Normal'
      vim.wo[state.win].winhighlight = winhl
    else
      pcall(nvim_win_set_config, state.win, win_opts)
    end

    state.hash = state_hash
    win_cache[win_id] = state
    ::continue::
  end
end

function M.close(win_id)
  local state = win_cache[win_id]
  if state then
    if state.win and nvim_win_is_valid(state.win) then
      pcall(nvim_win_close, state.win, true)
    end
    if state.buf and nvim_buf_is_valid(state.buf) then
      pcall(nvim_buf_delete, state.buf, { force = true })
    end
    win_cache[win_id] = nil
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  local group = nvim_create_augroup('HandcraftedIncline', { clear = true })

  local update_queued = false
  local last_state = { win = -1, row = -1 }

  nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = function()
      win_cache = {}
      vim.schedule(update_incline)
    end
  })

  nvim_create_autocmd(
    { 'WinScrolled', 'BufEnter', 'WinEnter', 'TextChanged', 'BufWritePost', 'VimResized',
      'CursorMoved' }, {
      group = group,
      callback = function(args)
        if args.event == 'CursorMoved' then
          local cur_win = nvim_get_current_win()
          local cur_row = nvim_win_get_cursor(cur_win)[1]

          if cur_row == last_state.row and cur_win == last_state.win then
            return
          end

          last_state.row = cur_row
          last_state.win = cur_win
        end

        if update_queued then return end
        update_queued = true

        vim.schedule(function()
          update_queued = false
          update_incline()
        end)
      end
    })

  nvim_create_autocmd('WinClosed', {
    group = group, callback = function(args) M.close(tonumber(args.match)) end
  })
end

return M
