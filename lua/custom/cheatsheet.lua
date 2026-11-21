local M = {}

local api = vim.api
local fn = vim.fn

local ok_tc, tc = pcall(require, 'table.clear')
---@diagnostic disable-next-line: undefined-field
local table_clear = ok_tc and tc or table.clear or function(t)
  local k = next(t)
  while k ~= nil do
    t[k] = nil
    k = next(t)
  end
end
local math_floor = math.floor
local table_concat = table.concat
local table_sort = table.sort

local string_rep = string.rep
local string_sub = string.sub
local string_gsub = string.gsub
local string_find = string.find

local nvim_buf_set_lines = api.nvim_buf_set_lines
local nvim_buf_set_extmark = api.nvim_buf_set_extmark
local nvim_get_keymap = api.nvim_get_keymap
local nvim_buf_get_keymap = api.nvim_buf_get_keymap
local nvim_get_current_buf = api.nvim_get_current_buf
local nvim_get_option_value = api.nvim_get_option_value
local nvim_strwidth = api.nvim_strwidth
local strcharpart = fn.strcharpart

local ns = api.nvim_create_namespace('VibeCheatsheet')

local active_win = nil
local cache_lines = nil
local last_bufnr = -1

local cache_em_row, cache_em_col, cache_em_end, cache_em_hl = {}, {}, {}, {}
local cache_em_count = 0

local _maps_dict = {}
local _maps_list = {}
local _cols_data = {}
local _cols_count = {}
local _lines = {}
local _line_parts = {}
local _groups = {}
local _other_group = { name = ' General / Others', hl = 'Title', keys = {}, count = 0 }

api.nvim_create_autocmd('VimResized', {
  group = api.nvim_create_augroup('VibeCheatsheetResize', { clear = true }),
  callback = function() cache_lines = nil end,
})

local group_rules = {
  { p = ' a', n = ' AI / CodeCompanion', hl = 'Special' },
  { p = ' b', n = '󰓩 Buffer / Workspace', hl = 'String' },
  { p = ' c', n = ' Code / LSP', hl = 'Type' },
  { p = ' d', n = ' Debug (DAP)', hl = 'DiagnosticError' },
  { p = ' f', n = '󰈞 Find / Search', hl = 'DiagnosticInfo' },
  { p = ' g', n = '󰊢 Git / Neogit', hl = 'Constant' },
  { p = ' j', n = '󰚔 Multicursor', hl = 'Keyword' },
  { p = ' n', n = '🗺️ Minimap', hl = 'Function' },
  { p = ' p', n = '󰏖 Panel / Tools', hl = 'Operator' },
  { p = ' q', n = '󰗼 Quit / Restart', hl = 'DiagnosticWarn' },
  { p = ' r', n = ' Code Runner', hl = 'DiagnosticInfo' },
  { p = ' s', n = ' Search Meta', hl = 'Type' },
  { p = ' t', n = ' Translate', hl = 'Function' },
  { p = ' T', n = ' Telegram', hl = 'DiagnosticError' },
  { p = ' u', n = '󰙵 UI & Toggles', hl = 'DiagnosticHint' },
  { p = ' w', n = '󰆓 Write / Save', hl = 'String' },
  { p = ' z', n = ' Zettelkasten', hl = 'Label' },
  { p = ' <Tab>', n = '󰓩 Workspace/Tabs', hl = 'String' },

  { p = 'g', n = '󰜎 Goto / LSP', hl = 'Macro' },
  { p = '[', n = '󰒮 Prev / Jump', hl = 'WarningMsg' },
  { p = ']', n = '󰒭 Next / Jump', hl = 'WarningMsg' },
  { p = 's', n = '󰑄 Surround', hl = 'Keyword' },
  { p = 'z', n = '󱃅 Fold / UFO', hl = 'DiagnosticHint' },
  { p = '<C-', n = '󰘴 Ctrl / Window', hl = 'Special' },
  { p = '<A-', n = '󰘵 Alt / Move', hl = 'Number' },
  { p = '<S-', n = '󰘲 Shift / Buffer', hl = 'String' },
}

for i = 1, #group_rules do
  _groups[group_rules[i].p] = { name = group_rules[i].n, hl = group_rules[i].hl, keys = {}, count = 0 }
end

-- Only the leading space is the leader; any other space is a literal <Space>.
local function format_lhs(lhs)
  lhs = string_gsub(lhs, '<lt>', '<')
  if string_sub(lhs, 1, 1) == ' ' then
    return '<Space> + ' .. string_gsub(string_sub(lhs, 2), ' ', '<Space>')
  end
  return (string_gsub(lhs, ' ', '<Space>'))
end

-- <Plug> hooks and Neovim's own defaults (desc ":help …" / "vim.…") are noise.
local function is_hidden(m)
  return string_sub(m.lhs, 1, 6) == '<Plug>'
    or string_sub(m.desc, 1, 6) == ':help '
    or string_find(m.desc, '^vim%.') ~= nil
end

local function sort_fn(a, b) return a.lhs < b.lhs end

local function build_data()
  if cache_lines then return end

  table_clear(_maps_dict)
  table_clear(_maps_list)
  table_clear(_lines)
  _other_group.count = 0
  for i = 1, #group_rules do _groups[group_rules[i].p].count = 0 end

  local COL_WIDTH = 54
  local BADGE_BYTES = 9 -- ' [NVIOT] '
  local LHS_DISP_WIDTH = 28
  local _maps_count = 0

  -- Global and buffer-local maps are keyed separately, so a buffer map with
  -- the same lhs (e.g. the dashboard's <CR>) never hides the global one.
  local function process_map(m, mode, is_buf)
    if not (m.desc and m.desc ~= '' and m.lhs ~= '') or is_hidden(m) then return end
    local key = (is_buf and 'b' or 'g') .. m.lhs
    local ex = _maps_dict[key]
    if not ex then
      ex = { lhs = m.lhs, desc = m.desc, is_buf = is_buf }
      _maps_dict[key] = ex
      _maps_count = _maps_count + 1
      _maps_list[_maps_count] = ex
    end
    ex[mode] = true
  end

  local em_idx = 0
  local function push_em(r, c_start, c_end, hl)
    em_idx = em_idx + 1
    cache_em_row[em_idx] = r
    cache_em_col[em_idx] = c_start
    cache_em_end[em_idx] = c_end
    cache_em_hl[em_idx] = hl
  end

  local function pad_cell(str)
    local pad = COL_WIDTH - nvim_strwidth(str)
    return pad > 0 and (str .. string_rep(' ', pad)) or str
  end

  -- Buffer maps only from real file buffers (LSP keys); special buffers like
  -- the dashboard only add their own one-letter actions.
  local with_buf = nvim_get_option_value('buftype', { buf = 0 }) == ''

  local function fetch_maps(mode)
    local global_maps = nvim_get_keymap(mode)
    for i = 1, #global_maps do process_map(global_maps[i], mode, false) end
    if not with_buf then return end
    local buf_maps = nvim_buf_get_keymap(0, mode)
    for i = 1, #buf_maps do process_map(buf_maps[i], mode, true) end
  end

  local modes = { 'n', 'v', 'i', 'o', 't' }
  for i = 1, #modes do fetch_maps(modes[i]) end

  for i = 1, _maps_count do
    local map = _maps_list[i]
    local matched = false

    for j = 1, #group_rules do
      local prefix = group_rules[j].p
      if string_sub(map.lhs, 1, #prefix) == prefix then
        local g = _groups[prefix]
        g.count = g.count + 1
        g.keys[g.count] = map
        matched = true
        break
      end
    end

    if not matched then
      _other_group.count = _other_group.count + 1
      _other_group.keys[_other_group.count] = map
    end
  end

  for i = 1, #group_rules do
    local g = _groups[group_rules[i].p]
    if g.count > 0 then
      local valid_keys = {}
      for k = 1, g.count do valid_keys[k] = g.keys[k] end
      table_sort(valid_keys, sort_fn)
      g.keys = valid_keys
    end
  end
  if _other_group.count > 0 then
    local valid_keys = {}
    for k = 1, _other_group.count do valid_keys[k] = _other_group.keys[k] end
    table_sort(valid_keys, sort_fn)
    _other_group.keys = valid_keys
  end

  local win_inner_cols = vim.o.columns * 0.8 - 4
  local columns_count = math_floor(win_inner_cols / COL_WIDTH)
  if columns_count < 1 then columns_count = 1 end

  for i = 1, columns_count do
    if not _cols_data[i] then _cols_data[i] = {} end
    table_clear(_cols_data[i])
    _cols_count[i] = 0
  end

  local function add_to_col(col_idx, item)
    local c = _cols_count[col_idx] + 1
    _cols_count[col_idx] = c
    _cols_data[col_idx][c] = item
  end

  local function append_group(g)
    if g.count == 0 then return end
    local shortest_col, min_lines = 1, 99999
    for i = 1, columns_count do
      if _cols_count[i] < min_lines then
        min_lines = _cols_count[i]
        shortest_col = i
      end
    end

    add_to_col(shortest_col, { is_title = true, text = g.name, hl = g.hl })
    for i = 1, g.count do
      add_to_col(shortest_col, { is_title = false, map = g.keys[i] })
    end
    add_to_col(shortest_col, { is_empty = true })
  end

  for i = 1, #group_rules do append_group(_groups[group_rules[i].p]) end
  append_group(_other_group)

  local max_rows = 0
  for i = 1, columns_count do
    if _cols_count[i] > max_rows then max_rows = _cols_count[i] end
  end

  for row = 1, max_rows do
    table_clear(_line_parts)
    local current_byte = 0

    for col = 1, columns_count do
      local item = _cols_data[col][row]
      local cell_str = ''

      if not item or item.is_empty then
        cell_str = string_rep(' ', COL_WIDTH)
      elseif item.is_title then
        cell_str = ' ' .. item.text
        push_em(row - 1, current_byte, current_byte + #cell_str, item.hl)
        cell_str = pad_cell(cell_str)
      else
        local m = item.map
        local mode_str = ' [' .. (m.n and 'N' or '-') .. (m.v and 'V' or '-')
          .. (m.i and 'I' or '-') .. (m.o and 'O' or '-') .. (m.t and 'T' or '-') .. '] '
        local lhs_str = format_lhs(m.lhs)
        local raw_lhs = mode_str .. lhs_str

        -- always at least one space between the key and its description
        local pad_len = LHS_DISP_WIDTH - nvim_strwidth(raw_lhs)
        if pad_len < 1 then pad_len = 1 end
        local full_lhs = raw_lhs .. string_rep(' ', pad_len)
        local full_lhs_bytes = #full_lhs

        push_em(row - 1, current_byte, current_byte + BADGE_BYTES, 'NonText')
        push_em(row - 1, current_byte + BADGE_BYTES, current_byte + BADGE_BYTES + #lhs_str, 'Keyword')

        local desc_str = m.is_buf and ('󰈙 ' .. m.desc) or m.desc
        local desc_max = COL_WIDTH - nvim_strwidth(full_lhs) - 2
        if desc_max < 8 then desc_max = 8 end
        if nvim_strwidth(desc_str) > desc_max then
          desc_str = strcharpart(desc_str, 0, desc_max - 3) .. '...'
        end

        push_em(row - 1, current_byte + full_lhs_bytes, current_byte + full_lhs_bytes + #desc_str,
          'Comment')

        cell_str = pad_cell(full_lhs .. desc_str)
      end

      _line_parts[col] = cell_str
      current_byte = current_byte + #cell_str
    end
    _lines[row] = table_concat(_line_parts)
  end

  cache_lines = _lines
  cache_em_count = em_idx
end

function M.toggle()
  if active_win and active_win:valid() then
    active_win:close()
    active_win = nil
    return
  end

  local current_buf = nvim_get_current_buf()
  if last_bufnr ~= current_buf then
    cache_lines = nil
    last_bufnr = current_buf
  end

  build_data()

  active_win = require('snacks').win({
    position = 'float',
    width = 0.8,
    height = 0.8,
    border = 'rounded',
    backdrop = 60,
    title = ' 🚀 Cheatsheet ',
    title_pos = 'center',
    zindex = 45,
    enter = true,
    bo = {
      modifiable = true,
      buftype = 'nofile',
      filetype = 'nvcheatsheet',
    },
    wo = {
      winhighlight = 'NormalFloat:Normal,FloatBorder:FloatBorder',
      spell = false,
      wrap = false,
      signcolumn = 'no',
      statuscolumn = ' ',
    },
    keys = {
      q = 'close',
      ['<Esc>'] = 'close',
    }
  })

  local buf = active_win.buf
  if not buf or not cache_lines then return end

  nvim_buf_set_lines(buf, 0, -1, false, cache_lines)

  local ext_opts = { end_row = 0, end_col = 0, hl_group = '' }
  for i = 1, cache_em_count do
    ext_opts.end_row = cache_em_row[i]
    ext_opts.end_col = cache_em_end[i]
    ext_opts.hl_group = cache_em_hl[i]
    nvim_buf_set_extmark(buf, ns, cache_em_row[i], cache_em_col[i], ext_opts)
  end

  vim.bo[buf].modifiable = false
end

return M
