local M = {}

local api = vim.api
local fn = vim.fn
local str_byte = string.byte
local get_line = api.nvim_get_current_line
local get_cursor = api.nvim_win_get_cursor
local set_cursor = api.nvim_win_set_cursor
local pumvisible = fn.pumvisible
local math_min = math.min

local ESC_KEY = api.nvim_replace_termcodes('<Esc>', true, false, true)
local TITLE = 'Stellar:Surround'

local surrounds = {
  ['('] = { '(', ')' },
  [')'] = { '(', ')' },
  ['b'] = { '(', ')' },
  ['['] = { '[', ']' },
  [']'] = { '[', ']' },
  ['{'] = { '{', '}' },
  ['}'] = { '{', '}' },
  ['<'] = { '<', '>' },
  ['>'] = { '<', '>' },
  ['"'] = { '"', '"' },
  ["'"] = { "'", "'" },
  ['`'] = { '`', '`' },
}

for _, pair in pairs(surrounds) do
  pair.l_byte = str_byte(pair[1])
  pair.r_byte = str_byte(pair[2])
  pair.is_bracket = pair[1] ~= pair[2]
end
local tabout_pairs = {
  surrounds['('],
  surrounds['['],
  surrounds['{'],
  surrounds['"'],
  surrounds["'"],
  surrounds['`'],
}

local open_to_close = {}
local close_to_open = {}
for i = 1, #tabout_pairs do
  local pair = tabout_pairs[i]
  open_to_close[pair.l_byte] = pair.r_byte
  close_to_open[pair.r_byte] = pair.l_byte
end

local TAB = '<Tab>'
local RIGHT = '<Right>'
--- Ask user safely
local function get_char(prompt)
  api.nvim_echo({ { prompt, 'Question' } }, false)
  local ok, char = pcall(fn.getcharstr)
  api.nvim_echo({ { '', 'Normal' } }, false)
  if not ok or char == '\27' or char == '\r' or char == '' then return nil end
  return char
end

--- Get UTF-8 character byte length without ANY string allocations (Zero GC)
local function get_utf8_len(line, col)
  if col >= #line then return 0 end
  local b = str_byte(line, col + 1)
  if not b then return 0 end
  if b >= 240 then return 4 end
  if b >= 224 then return 3 end
  if b >= 192 then return 2 end
  return 1
end

local function find_surround(char)
  local pair = surrounds[char] or {
    char,
    char,
    l_byte = str_byte(char),
    r_byte = str_byte(char),
    is_bracket = false
  }

  local l_byte, r_byte = pair.l_byte, pair.r_byte
  local is_bracket = pair.is_bracket

  local line = api.nvim_get_current_line()
  local cursor_col = api.nvim_win_get_cursor(0)[2] + 1
  local l_pos, r_pos, depth = nil, nil, 0

  for i = cursor_col, 1, -1 do
    local b = str_byte(line, i)
    if is_bracket and b == r_byte then
      depth = depth + 1
    elseif b == l_byte then
      if depth > 0 then
        depth = depth - 1
      else
        l_pos = i; break
      end
    end
  end

  depth = 0
  for i = cursor_col + 1, #line do
    local b = str_byte(line, i)
    if is_bracket and b == l_byte then
      depth = depth + 1
    elseif b == r_byte then
      if depth > 0 then
        depth = depth - 1
      else
        r_pos = i; break
      end
    end
  end

  return l_pos, r_pos
end

local function safe_set_text(s_row, s_col, e_row, e_col, l_char, r_char)
  local line_s = api.nvim_buf_get_lines(0, s_row, s_row + 1, false)[1] or ''
  local line_e = api.nvim_buf_get_lines(0, e_row, e_row + 1, false)[1] or ''

  s_col = math_min(s_col, #line_s)
  e_col = math_min(e_col, #line_e)
  e_col = e_col + get_utf8_len(line_e, e_col)

  api.nvim_buf_set_text(0, e_row, e_col, e_row, e_col, { r_char })
  api.nvim_buf_set_text(0, s_row, s_col, s_row, s_col, { l_char })
end
local function find_tabout_close(line, open_pos, open_byte, close_byte)
  if open_byte == close_byte then
    for i = open_pos + 1, #line do
      if str_byte(line, i) == close_byte then return i end
    end
    return nil
  end

  local depth = 0
  for i = open_pos + 1, #line do
    local byte = str_byte(line, i)
    if byte == open_byte then
      depth = depth + 1
    elseif byte == close_byte then
      if depth == 0 then return i end
      depth = depth - 1
    end
  end
end

local function find_tabout_open(line, close_pos, open_byte, close_byte)
  if open_byte == close_byte then
    for i = close_pos - 1, 1, -1 do
      if str_byte(line, i) == open_byte then return i end
    end
    return nil
  end

  local depth = 0
  for i = close_pos - 1, 1, -1 do
    local byte = str_byte(line, i)
    if byte == close_byte then
      depth = depth + 1
    elseif byte == open_byte then
      if depth == 0 then return i end
      depth = depth - 1
    end
  end
end

local function get_tabout_col(line, col)
  local next_byte = str_byte(line, col + 1)
  if not next_byte then return nil end

  local close_byte = open_to_close[next_byte]
  if close_byte then
    if close_byte == next_byte then
      if str_byte(line, col) == next_byte then return col + 1 end
      if find_tabout_open(line, col + 1, next_byte, next_byte) then return col + 1 end
    end
    return find_tabout_close(line, col + 1, next_byte, close_byte)
  end

  if close_to_open[next_byte] then return col + 1 end
end

local function get_tabout_back_col(line, col)
  if col == 0 then return nil end

  local close_byte = str_byte(line, col)
  local open_byte = close_to_open[close_byte]
  if not open_byte then return nil end

  local open_pos = find_tabout_open(line, col, open_byte, close_byte)
  if open_pos then return open_pos - 1 end
end

local function apply_visual_surround(l_char, r_char)
  local s_row, s_col = fn.line('v') - 1, fn.col('v') - 1
  local e_row, e_col = fn.line('.') - 1, fn.col('.') - 1

  if s_row > e_row or (s_row == e_row and s_col > e_col) then
    s_row, e_row, s_col, e_col = e_row, s_row, e_col, s_col
  end

  api.nvim_feedkeys(ESC_KEY, 'n', false)

  vim.schedule(function()
    safe_set_text(s_row, s_col, e_row, e_col, l_char, r_char)
  end)
end

function M.add_normal()
  local char = get_char('Surround with: ')
  if not char then return '<Esc>' end
  vim.o.operatorfunc = function()
    local pair = surrounds[char] or { char, char }
    local s_pos, e_pos = api.nvim_buf_get_mark(0, '['), api.nvim_buf_get_mark(0, ']')
    safe_set_text(s_pos[1] - 1, s_pos[2], e_pos[1] - 1, e_pos[2], pair[1], pair[2])
  end
  return 'g@'
end

function M.add_visual_interactive()
  local char = get_char('Surround with: ')
  if not char then return end
  local pair = surrounds[char] or { char, char }
  apply_visual_surround(pair[1], pair[2])
end

function M.delete()
  local char = get_char('Delete surround: ')
  if not char then return end
  local l_pos, r_pos = find_surround(char)
  if not l_pos or not r_pos then
    return vim.notify('Surround not found', vim.log.levels.WARN,
      { title = TITLE })
  end

  local row = api.nvim_win_get_cursor(0)[1] - 1
  local pair = surrounds[char] or { char, char }

  api.nvim_buf_set_text(0, row, r_pos - 1, row, r_pos - 1 + #pair[2], { '' })
  api.nvim_buf_set_text(0, row, l_pos - 1, row, l_pos - 1 + #pair[1], { '' })
end

function M.replace()
  local old_char = get_char('Replace surround: ')
  if not old_char then return end
  local new_char = get_char('With: ')
  if not new_char then return end

  local l_pos, r_pos = find_surround(old_char)
  if not l_pos or not r_pos then
    return vim.notify('Surround not found', vim.log.levels.WARN,
      { title = TITLE })
  end

  local row = api.nvim_win_get_cursor(0)[1] - 1
  local old_pair = surrounds[old_char] or { old_char, old_char }
  local new_pair = surrounds[new_char] or { new_char, new_char }

  api.nvim_buf_set_text(0, row, r_pos - 1, row, r_pos - 1 + #old_pair[2], { new_pair[2] })
  api.nvim_buf_set_text(0, row, l_pos - 1, row, l_pos - 1 + #old_pair[1], { new_pair[1] })
end

function M.tabout()
  if pumvisible() ~= 0 then return TAB end

  local line = get_line()
  local cursor = get_cursor(0)
  local row, col = cursor[1], cursor[2]
  local target_col = get_tabout_col(line, col)
  if not target_col then return TAB end
  if target_col == col + 1 then return RIGHT end

  set_cursor(0, { row, target_col })
  return ''
end

function M.tabout_back()
  if pumvisible() ~= 0 then return SHIFT_TAB end

  local line = get_line()
  local cursor = get_cursor(0)
  local target_col = get_tabout_back_col(line, cursor[2])
  if not target_col then return SHIFT_TAB end

  set_cursor(0, { cursor[1], target_col })
  return ''
end

--------------------------------------------------------------------------------
-- Closure Factory (VS Code Visual Auto-Wrap)
--------------------------------------------------------------------------------

local function make_visual_handler(char)
  local pair = surrounds[char]
  local l_char, r_char = pair[1], pair[2]
  return function()
    apply_visual_surround(l_char, r_char)
  end
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

function M.setup()
  vim.keymap.set('n', 'sa', M.add_normal,
    { expr = true, silent = true, desc = 'Add surround (Motion)' })
  vim.keymap.set('x', 'sa', M.add_visual_interactive,
    { silent = true, desc = 'Add surround (Visual)' })
  vim.keymap.set('n', 'sd', M.delete, { silent = true, desc = 'Delete surround' })
  vim.keymap.set('n', 'sr', M.replace, { silent = true, desc = 'Replace surround' })

  local keymap_opts = {
    expr = true,
    replace_keycodes = true,
    silent = true,
  }
  vim.keymap.set('i', '<Tab>', M.tabout, vim.tbl_extend('force', keymap_opts, {
    desc = 'Tab out of pair',
  }))
  vim.keymap.set('i', '<S-Tab>', M.tabout_back, vim.tbl_extend('force', keymap_opts, {
    desc = 'Tab backwards out of pair',
  }))

  local visual_auto_pairs = { '(', '[', '{', '"', "'", '`' }
  for i = 1, #visual_auto_pairs do
    local char = visual_auto_pairs[i]
    vim.keymap.set('x', char, make_visual_handler(char),
      { silent = true, desc = 'VSCode Wrap ' .. char })
  end
end

return M
