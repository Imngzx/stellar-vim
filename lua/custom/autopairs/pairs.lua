local M = {}

local api = vim.api
local fn = vim.fn
local str_sub = string.sub
local str_byte = string.byte
local get_line = api.nvim_get_current_line
local get_cursor = api.nvim_win_get_cursor
local spec = require('custom.autopairs.spec')

local open_pairs = spec.open_pairs
local close_pairs = spec.close_pairs
local quotes = spec.quotes

local BYTE_0 = str_byte('0')
local BYTE_9 = str_byte('9')
local BYTE_A_UPPER = str_byte('A')
local BYTE_Z_UPPER = str_byte('Z')
local BYTE_A_LOWER = str_byte('a')
local BYTE_Z_LOWER = str_byte('z')

--- alphanumeric check using descriptive cached ASCII bytes
local function is_alphanumeric(char)
  if not char or char == '' then return false end
  local b = str_byte(char)
  if not b then return false end

  return (b >= BYTE_0 and b <= BYTE_9)
    or (b >= BYTE_A_UPPER and b <= BYTE_Z_UPPER)
    or (b >= BYTE_A_LOWER and b <= BYTE_Z_LOWER)
end

--- Get context based on the evaluated mode
local function get_context(mode)
  local line, col
  if mode == 'i' then
    line = get_line()
    col = get_cursor(0)[2]
  else
    line = fn.getcmdline()
    col = fn.getcmdpos() - 1
  end
  return str_sub(line, col, col), str_sub(line, col + 1, col + 1), line, col
end

local function make_bs_handler(mode)
  local triple_quotes = { ['"'] = '"""', ["'"] = "'''", ['`'] = '```' }

  return function()
    local prev_char, next_char, line, col = get_context(mode)

    if open_pairs[prev_char] == next_char or (quotes[prev_char] and prev_char == next_char) then
      local t_quote = triple_quotes[prev_char]
      if t_quote and col >= 3 and str_sub(line, col - 2, col) == t_quote and str_sub(line, col + 1, col + 3) == t_quote then
        return '<BS><BS><BS><Del><Del><Del>'
      end
      return '<BS><Del>'
    end

    return '<BS>'
  end
end

local function make_cr_handler(mode)
  return function()
    local prev_char, next_char = get_context(mode)
    if fn.pumvisible() == 1 then return '<CR>' end
    if open_pairs[prev_char] == next_char then return '<CR><C-o>O' end
    return '<CR>'
  end
end

local function make_open_handler(key, mode)
  local insert_str = key .. open_pairs[key] .. '<Left>'

  return function()
    local _, next_char = get_context(mode)
    if is_alphanumeric(next_char) then return key end
    return insert_str
  end
end

local function make_close_handler(key, mode)
  return function()
    local _, next_char = get_context(mode)
    if next_char == key then return '<Right>' end
    return key
  end
end

local function make_quote_handler(key, mode)
  local double_key = key .. key
  local insert_str = double_key .. '<Left>'
  local triple_insert_str = double_key .. double_key .. '<Left><Left><Left>'

  return function()
    local prev_char, next_char, line, col = get_context(mode)

    if next_char == key then return '<Right>' end
    if is_alphanumeric(prev_char) or is_alphanumeric(next_char) then return key end

    if col >= 2 and str_sub(line, col - 1, col) == double_key then
      return triple_insert_str
    end

    return insert_str
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  local keymap_opts = { expr = true, replace_keycodes = true }

  local function bind(key, factory)
    vim.keymap.set('i', key, factory(key, 'i'), keymap_opts)
    if M.config.enable_cmdline and key ~= '<CR>' then
      vim.keymap.set('c', key, factory(key, 'c'), keymap_opts)
    end
  end

  bind('<BS>', make_bs_handler)
  bind('<CR>', make_cr_handler)

  for key in pairs(open_pairs) do bind(key, make_open_handler) end
  for key in pairs(close_pairs) do bind(key, make_close_handler) end
  for key in pairs(quotes) do bind(key, make_quote_handler) end
end

M.config = {
  enable_cmdline = true,
}

return M
