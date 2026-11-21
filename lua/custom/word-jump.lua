local M = {}
local api = vim.api

-- Cache C-API handles to bypass metatable lookups in hot loops (LuaJIT optimization)
local set_extmark = api.nvim_buf_set_extmark
local clear_namespace = api.nvim_buf_clear_namespace
local get_cursor = api.nvim_win_get_cursor
local set_cursor = api.nvim_win_set_cursor
local fn_mode = vim.fn.mode
local ns_id = api.nvim_create_namespace('flash_diy')

-- Pre-split character pools to avoid runtime slicing
local lower = 'asdfghjklqwertyuiopzxcvbnm'
local upper = 'ASDFGHJKLQWERTYUIOPZXCVBNM'
local digits = '1234567890'

local lower_chars, upper_chars, digit_chars = {}, {}, {}
for i = 1, 26 do lower_chars[i] = lower:sub(i, i) end
for i = 1, 26 do upper_chars[i] = upper:sub(i, i) end
for i = 1, 10 do digit_chars[i] = digits:sub(i, i) end

-- Max capacity: 26 (lower) + 676 (upper+lower) + 260 (digit+lower) = 962
local MAX_MATCHES = 962

local function init_hl()
  local set_hl = api.nvim_set_hl
  set_hl(0, 'FlashDiyBackdrop', { fg = '#545c7e', default = false })
  set_hl(0, 'FlashDiyMatch', { fg = '#c0caf5', bg = '#3d59a1', bold = true, default = false })
  set_hl(0, 'FlashDiyLabel', { fg = '#15161e', bg = '#ff007c', bold = true, default = false })
end

api.nvim_create_autocmd('ColorScheme', {
  group = api.nvim_create_augroup('FlashDiyHL', { clear = true }),
  callback = init_hl,
})
init_hl()

local function cleanup()
  clear_namespace(0, ns_id, 0, -1)
  vim.cmd.redraw()
end

-- Hierarchical label generator: Single > Double Letter > Digit+Letter
local function generate_labels(N)
  local P = 0 -- Required uppercase prefixes
  local D = 0 -- Required digit prefixes
  local U_singles = 26

  if N <= 52 then
    U_singles = N > 26 and (N - 26) or 0
  elseif N <= 702 then
    P = math.ceil((N - 52) / 25)
    U_singles = 26 - P
  else
    P = 26
    U_singles = 0
    D = math.ceil((N - 702) / 26)
    if D > 10 then D = 10 end
  end

  local labels, label_to_idx, prefix_map = {}, {}, {}
  local idx = 1

  local function add_label(lbl)
    if idx > N then return end
    labels[idx] = lbl
    label_to_idx[lbl] = idx
    idx = idx + 1
  end

  -- Priority 1: Lowercase singles
  for i = 1, math.min(N, 26) do add_label(lower_chars[i]) end

  -- Priority 2: Uppercase singles
  for i = 1, U_singles do add_label(upper_chars[i]) end

  -- Priority 3: Double letters (Prefix Z, X, C... to preserve home row singles)
  for i = 1, P do
    local prefix = upper_chars[26 - P + i]
    prefix_map[prefix] = true
    for j = 1, 26 do add_label(prefix .. lower_chars[j]) end
  end

  -- Priority 4: Digit + Letter
  for i = 1, D do
    local prefix = digit_chars[i]
    prefix_map[prefix] = true
    for j = 1, 26 do add_label(prefix .. lower_chars[j]) end
  end

  return labels, label_to_idx, prefix_map
end

--- Move to a 0-indexed column. After an operator a forward jump goes through
--- charwise visual so it includes the target, like the built-in `f`; a
--- backward jump stays exclusive, like `F`.
local function jump_to(row, col)
  if fn_mode(1):sub(1, 2) == 'no' then
    local cur = get_cursor(0)
    if row > cur[1] or (row == cur[1] and col > cur[2]) then
      vim.cmd('normal! v')
    end
  end
  set_cursor(0, { row, col })
end

function M.jump()
  print('⚡ Flash ❯  ')
  local ok, target_char = pcall(vim.fn.getcharstr)

  if not ok or not target_char or target_char == '' or target_char:byte() == 27 then
    cleanup()
    return
  end

  local top = vim.fn.line('w0')
  local bot = vim.fn.line('w$')

  -- SoA (Struct of Arrays) design for cache-friendly access
  local match_rows, match_cols = {}, {}
  local count = 0

  -- Fetch buffer lines once to minimize C-API overhead
  local lines = api.nvim_buf_get_lines(0, top - 1, bot, false)

  for i = 1, #lines do
    local line = lines[i]
    local lnum = top + i - 1
    local col = 1
    while true do
      local s, e = line:find(target_char, col, true)
      if not s then break end
      count = count + 1
      match_rows[count] = lnum
      match_cols[count] = s
      if count >= MAX_MATCHES then break end
      col = e + 1
    end
    if count >= MAX_MATCHES then break end
  end

  if count == 0 then
    cleanup()
    return
  elseif count == 1 then
    cleanup()
    jump_to(match_rows[1], match_cols[1] - 1)
    return
  end

  local labels, label_to_idx, prefix_map = generate_labels(count)

  local function fast_render(prefix_filter)
    clear_namespace(0, ns_id, 0, -1)
    local e_row = math.min(bot, api.nvim_buf_line_count(0))

    -- Batch backdrop dimming in a single call
    set_extmark(0, ns_id, top - 1, 0, {
      end_row = e_row,
      end_col = 0,
      hl_group = 'FlashDiyBackdrop',
      priority = 4000,
    })

    for i = 1, count do
      local char = labels[i]
      -- Use byte comparison for faster prefix filtering
      if not prefix_filter or char:byte(1) == prefix_filter:byte(1) then
        local display_char = prefix_filter and char:sub(2) or char
        local r, c = match_rows[i] - 1, match_cols[i] - 1

        set_extmark(0, ns_id, r, c, {
          end_col = c + 1,
          hl_group = 'FlashDiyMatch',
          priority = 5000,
        })

        set_extmark(0, ns_id, r, c + 1, {
          virt_text = { { display_char, 'FlashDiyLabel' } },
          virt_text_pos = 'overlay',
          priority = 6000,
        })
      end
    end
    vim.cmd.redraw()
  end

  fast_render(nil)

  print('⚡ Flash ❯  ')
  local ok1, char1 = pcall(vim.fn.getcharstr)
  if not ok1 or not char1 or char1 == '' or char1:byte() == 27 then
    cleanup()
    return
  end

  -- Case A: Single character match, jump immediately
  if label_to_idx[char1] then
    local idx = label_to_idx[char1]
    cleanup()
    jump_to(match_rows[idx], match_cols[idx] - 1)
    return
  end

  -- Case B: Prefix match, filter view and wait for second char
  if prefix_map[char1] then
    fast_render(char1)

    print('⚡ Flash ❯ ' .. char1)
    local ok2, char2 = pcall(vim.fn.getcharstr)
    cleanup()
    if not ok2 or not char2 or char2 == '' or char2:byte() == 27 then return end

    local full_char = char1 .. char2
    local idx = label_to_idx[full_char]
    if idx then
      jump_to(match_rows[idx], match_cols[idx] - 1)
    end
  else
    cleanup()
  end
end

vim.keymap.set({ 'n', 'x', 'o' }, 'f', M.jump, { desc = 'DIY Flash Jump' })

return M
