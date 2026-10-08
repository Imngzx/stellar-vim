local M = {}

local api = vim.api
local uv = vim.uv
local pcall = pcall
local nvim_win_is_valid = api.nvim_win_is_valid
local nvim_win_close = api.nvim_win_close
local nvim_buf_is_valid = api.nvim_buf_is_valid
local nvim_buf_delete = api.nvim_buf_delete
local nvim_create_buf = api.nvim_create_buf
local nvim_buf_set_lines = api.nvim_buf_set_lines
local nvim_buf_clear_namespace = api.nvim_buf_clear_namespace
local nvim_buf_set_extmark = api.nvim_buf_set_extmark
local nvim_open_win = api.nvim_open_win
local nvim_win_set_config = api.nvim_win_set_config
local nvim_create_namespace = api.nvim_create_namespace
local nvim_create_augroup = api.nvim_create_augroup
local nvim_create_autocmd = api.nvim_create_autocmd
local nvim_buf_line_count = api.nvim_buf_line_count
local nvim_buf_get_lines = api.nvim_buf_get_lines

local str_byteindex = vim.str_byteindex
local str_utfindex = vim.str_utfindex
local str_sub = string.sub
local strdisplaywidth = api.nvim_strwidth
local math_max = math.max
local string_rep = string.rep
local string_format = string.format

-- [config area]
local config = {
  spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
  icons = { check = '✓', error = '✗' },
  highlights = {
    spinner = 'DiagnosticWarn',
    check = 'DiagnosticOk',
    text = 'Comment',
    client = 'String',
    title = 'Normal',
  },
  border = 'none', -- none, single or rounded
  keep_done_ms = 1000,
  ignore_clients = { 'rumdl' },
}

-- O(1) ignore lookup (hoisted, built once)
local ignore_set = {}
for _, name in ipairs(config.ignore_clients) do
  ignore_set[name] = true
end

-- ⚡ Struct of Arrays (SoA) for extreme performance
local t_tokens = {}
local t_clients = {}
local t_titles = {}
local t_messages = {}
local t_percentages = {}
local t_dones = {}
local t_idx = {}
local t_count = 0

local frame = 1
local timer = nil
local win_id = nil
local buf_id = nil
local ns = nvim_create_namespace('diy_lsp_loading')

local function cleanup()
  timer = require('snacks').util.stop(timer)
  if win_id and nvim_win_is_valid(win_id) then
    nvim_win_close(win_id, true)
    win_id = nil
  end
  if buf_id and nvim_buf_is_valid(buf_id) then
    nvim_buf_delete(buf_id, { force = true })
    buf_id = nil
  end
end

local function truncate(str, max_len)
  if not str or str == '' then return '' end
  if #str <= max_len then return str end
  local char_len = str_utfindex(str)
  if char_len > max_len then
    local byte_idx = str_byteindex(str, max_len - 3)
    return str_sub(str, 1, byte_idx) .. '...'
  end
  return str
end

local function remove_task(token)
  local idx = t_idx[token]
  if not idx then return end
  for i = idx, t_count - 1 do
    t_tokens[i] = t_tokens[i + 1]
    t_clients[i] = t_clients[i + 1]
    t_titles[i] = t_titles[i + 1]
    t_messages[i] = t_messages[i + 1]
    t_percentages[i] = t_percentages[i + 1]
    t_dones[i] = t_dones[i + 1]
    t_idx[t_tokens[i]] = i
  end
  t_tokens[t_count] = nil
  t_clients[t_count] = nil
  t_titles[t_count] = nil
  t_messages[t_count] = nil
  t_percentages[t_count] = nil
  t_dones[t_count] = nil
  t_idx[token] = nil
  t_count = t_count - 1
end

local function get_win_config(width, height)
  return {
    relative = 'editor',
    anchor = 'SE',
    row = vim.o.lines - (vim.o.laststatus > 0 and 2 or 1),
    col = vim.o.columns,
    width = width,
    height = height,
    style = 'minimal',
    border = config.border,
    focusable = false,
    noautocmd = true,
    zindex = 40,
  }
end

local function update_window()
  if t_count == 0 then
    cleanup()
    return
  end

  local lines = {}
  local extmarks = {}
  local ext_count = 0
  local max_line_width = 1

  -- Pass 1: compute widths and chunks (天然有序，消灭了 table.sort)
  local all_chunks = {}
  local line_widths = {}

  for i = 1, t_count do
    local icon = t_dones[i] and config.icons.check or config.spinner[frame]
    local icon_hl = t_dones[i] and config.highlights.check or config.highlights.spinner

    local title = t_titles[i]
    title = title ~= '' and (title .. ' ') or ''

    local msg = truncate(t_messages[i], 40)
    local perc = t_percentages[i] and string_format('%3d%%', t_percentages[i]) or ''

    local left_part = msg
    if perc ~= '' then left_part = left_part .. (left_part ~= '' and ' ' or '') .. perc end
    if left_part ~= '' then left_part = ' ' .. left_part end

    local client_name = '[' .. t_clients[i] .. '] '

    local chunks = {
      { icon .. ' ', icon_hl },
      { client_name, config.highlights.client },
      { title,       config.highlights.title },
      { left_part,   config.highlights.text },
    }
    all_chunks[i] = chunks

    local line_width = 0
    for j = 1, 4 do
      line_width = line_width + strdisplaywidth(chunks[j][1])
    end
    line_widths[i] = line_width
    if line_width > max_line_width then max_line_width = line_width end
  end

  -- Pass 2: format padding and extmarks
  for i = 1, t_count do
    local padding_len = max_line_width - line_widths[i]
    local padding = string_rep(' ', padding_len)

    local line_text = padding
    local current_byte = #padding

    for j = 1, 4 do
      local text = all_chunks[i][j][1]
      local hl = all_chunks[i][j][2]
      if text ~= '' then
        line_text = line_text .. text
        ext_count = ext_count + 1
        extmarks[ext_count] = {
          line = i - 1,
          start_col = current_byte,
          end_col = current_byte + #text,
          hl_group = hl,
        }
        current_byte = current_byte + #text
      end
    end
    lines[i] = line_text
  end

  if #lines == 0 then
    cleanup()
    return
  end

  if not buf_id or not nvim_buf_is_valid(buf_id) then
    buf_id = nvim_create_buf(false, true)
    vim.bo[buf_id].bufhidden = 'wipe'
  end
  nvim_buf_set_lines(buf_id, 0, -1, false, lines)
  nvim_buf_clear_namespace(buf_id, ns, 0, -1)

  for i = 1, ext_count do
    local em = extmarks[i]
    pcall(nvim_buf_set_extmark, buf_id, ns, em.line, em.start_col, {
      end_row = em.line,
      end_col = em.end_col,
      hl_group = em.hl_group,
      priority = 20,
    })
  end

  if not win_id or not nvim_win_is_valid(win_id) then
    win_id = nvim_open_win(buf_id, false, get_win_config(max_line_width, t_count))
    vim.wo[win_id].winblend = 0
    vim.wo[win_id].winhl = 'Normal:NONE'
  else
    nvim_win_set_config(win_id, get_win_config(max_line_width, t_count))
  end
end

local function start_animation()
  if timer and not timer:is_closing() then return end
  if timer and timer:is_closing() then timer = nil end

  timer = uv.new_timer()
  if timer then
    timer:start(0, 80, vim.schedule_wrap(function()
      frame = (frame % #config.spinner) + 1
      update_window()
    end))
  end
end

function M.setup()
  local group = nvim_create_augroup('diy_lsp_loading', { clear = true })

  nvim_create_autocmd('LspProgress', {
    group = group,
    callback = function(args)
      local client_id = args.data.client_id
      local token = args.data.params.token
      local value = args.data.params.value
      local client = vim.lsp.get_client_by_id(client_id)

      if not client or not token then return end

      -- Ignore configured clients
      if ignore_set[client.name] then return end

      if value.kind == 'begin' then
        t_count = t_count + 1
        t_idx[token] = t_count
        t_tokens[t_count] = token
        t_clients[t_count] = client.name
        t_titles[t_count] = value.title or ''
        t_messages[t_count] = value.message or ''
        t_percentages[t_count] = value.percentage
        t_dones[t_count] = false
        start_animation()
      elseif value.kind == 'report' then
        local idx = t_idx[token]
        if idx and not t_dones[idx] then
          if value.message then t_messages[idx] = value.message end
          if value.percentage then t_percentages[idx] = value.percentage end
        end
      elseif value.kind == 'end' then
        local idx = t_idx[token]
        if idx then
          t_dones[idx] = true
          t_percentages[idx] = nil
          t_messages[idx] = value.message or 'Done'

          vim.schedule(update_window)

          vim.defer_fn(function()
            remove_task(token)
            update_window()
          end, config.keep_done_ms)
        end
      end
    end,
  })

  nvim_create_autocmd('LspDetach', {
    group = group,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then return end

      local i = 1
      while i <= t_count do
        if t_clients[i] == client.name then
          remove_task(t_tokens[i])
        else
          i = i + 1
        end
      end
      vim.schedule(update_window)
    end
  })

  nvim_create_autocmd('VimResized', {
    group = group,
    callback = function()
      if win_id and buf_id and nvim_win_is_valid(win_id) and nvim_buf_is_valid(buf_id) then
        local max_width = 10
        local lines = nvim_buf_get_lines(buf_id, 0, -1, false)
        for i = 1, #lines do
          max_width = math_max(max_width, strdisplaywidth(lines[i]))
        end
        nvim_win_set_config(win_id,
          get_win_config(max_width, nvim_buf_line_count(buf_id)))
      end
    end
  })
end

return M
