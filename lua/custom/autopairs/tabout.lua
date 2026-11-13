local M = {}

local api = vim.api
local fn = vim.fn
local str_byte = string.byte
local get_line = api.nvim_get_current_line
local get_cursor = api.nvim_win_get_cursor
local set_cursor = api.nvim_win_set_cursor
local pumvisible = fn.pumvisible
local replace_termcodes = api.nvim_replace_termcodes
local feedkeys = api.nvim_feedkeys
local tabout_pairs = require('custom.autopairs.spec').tabout_pairs

local open_to_close = {}
local close_to_open = {}
for i = 1, #tabout_pairs do
  local pair = tabout_pairs[i]
  open_to_close[pair.l_byte] = pair.r_byte
  close_to_open[pair.r_byte] = pair.l_byte
end

local TAB = '<Tab>'
local SHIFT_TAB = '<S-Tab>'
local RIGHT = '<Right>'

local function find_close(line, open_pos, open_byte, close_byte)
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

local function find_open(line, close_pos, open_byte, close_byte)
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
      if find_open(line, col + 1, next_byte, next_byte) then return col + 1 end
    end
    return find_close(line, col + 1, next_byte, close_byte)
  end

  if close_to_open[next_byte] then return col + 1 end
end

local function get_tabout_back_col(line, col)
  if col == 0 then return nil end

  local close_byte = str_byte(line, col)
  local open_byte = close_to_open[close_byte]
  if not open_byte then return nil end

  local open_pos = find_open(line, col, open_byte, close_byte)
  if open_pos then return open_pos end
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

local function fallback_shift_tab()
  feedkeys(replace_termcodes(SHIFT_TAB, true, true, true), 'n', false)
end

function M.tabout_back()
  if pumvisible() ~= 0 then
    fallback_shift_tab()
    return false
  end

  local line = get_line()
  local cursor = get_cursor(0)
  local target_col = get_tabout_back_col(line, cursor[2])
  if not target_col then
    fallback_shift_tab()
    return false
  end

  set_cursor(0, { cursor[1], target_col })
  return true
end

function M.setup()
  local keymap_opts = {
    expr = true,
    replace_keycodes = true,
    silent = true,
  }
  vim.keymap.set('i', '<Tab>', M.tabout, vim.tbl_extend('force', keymap_opts, {
    desc = 'Tab out of pair',
  }))
  vim.keymap.set('i', '<S-Tab>', M.tabout_back, {
    silent = true,
    desc = 'Tab backwards out of pair',
  })
end

return M
