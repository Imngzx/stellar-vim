local M = {}

local pandoc = require('custom.md-paste.pandoc')

local function inclusive_end_column(row, col)
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ''
  local b = string.byte(line, col + 1)
  if not b then return col end
  local len = 1
  if b < 0x80 then
    len = 1
  elseif b < 0xE0 then
    len = 2
  elseif b < 0xF0 then
    len = 3
  else
    len = 4
  end
  return col + len - 1
end

local function is_url(text)
  text = vim.trim(text or '')

  return text:match('^https?://[^%s]+$') ~= nil
    or text:match('^ftp://[^%s]+$') ~= nil
end

local function get_visual_range()
  local mode = vim.fn.mode()
  local is_visual = mode == 'v' or mode == 'V'
  local start_row
  local start_col
  local end_row
  local end_col

  if is_visual then
    local anchor = vim.fn.getpos('v')
    local cursor = vim.api.nvim_win_get_cursor(0)

    start_row = anchor[2] - 1
    start_col = anchor[3] - 1
    end_row = cursor[1] - 1
    end_col = cursor[2]
  else
    local start_pos = vim.api.nvim_buf_get_mark(0, '<')
    local end_pos = vim.api.nvim_buf_get_mark(0, '>')

    start_row = start_pos[1] - 1
    start_col = start_pos[2]
    end_row = end_pos[1] - 1
    end_col = end_pos[2]
  end

  if start_row > end_row
    or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end


  if mode == 'v' then
    if vim.o.selection == 'exclusive' then
      end_col = end_col - 1
    else
      end_col = inclusive_end_column(end_row, end_col)
    end
  end

  return {
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

local function get_visual_text(mode)
  local range = get_visual_range()

  if mode == 'V' then
    return table.concat(
      vim.api.nvim_buf_get_lines(
        0,
        range.start_row,
        range.end_row + 1,
        false
      ),
      '\n'
    )
  end

  if mode ~= 'v' then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(
    0,
    range.start_row,
    range.end_row + 1,
    false
  )

  if #lines == 1 then
    return (lines[1] or ''):sub(
      range.start_col + 1,
      range.end_col + 1
    )
  end

  lines[1] = (lines[1] or ''):sub(range.start_col + 1)
  lines[#lines] = (lines[#lines] or ''):sub(1, range.end_col + 1)

  return table.concat(lines, '\n')
end

local function leave_visual_mode()
  vim.api.nvim_input(vim.keycode('<Esc>'))
end

local function replace_visual(text, mode)
  local range = get_visual_range()
  local replacement = vim.split(text, '\n', { plain = true })

  if mode == 'V' then
    vim.api.nvim_buf_set_lines(
      0,
      range.start_row,
      range.end_row + 1,
      false,
      replacement
    )

    leave_visual_mode()
    return
  end

  vim.api.nvim_buf_set_text(
    0,
    range.start_row,
    range.start_col,
    range.end_row,
    range.end_col + 1,
    replacement
  )

  leave_visual_mode()
end

function M.paste_url_in_visual(lines)
  local mode = vim.fn.mode()

  if mode ~= 'v' and mode ~= 'V' then
    return false
  end

  local url = vim.trim(table.concat(lines, '\n'))

  if not is_url(url) then
    return false
  end

  local label = get_visual_text(mode)

  if not label or label == '' then
    return false
  end

  replace_visual(('[%s](%s)'):format(label, url), mode)

  return true
end

local function insert_text(text)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]

  local current_line = vim.api.nvim_get_current_line()
  local lines = vim.split(text, '\n', {
    plain = true,
  })

  if #lines == 1 then
    vim.api.nvim_set_current_line(
      current_line:sub(1, col)
      .. lines[1]
      .. current_line:sub(col + 1)
    )

    vim.api.nvim_win_set_cursor(0, {
      row,
      col + #lines[1],
    })

    return
  end

  local before = current_line:sub(1, col)
  local after = current_line:sub(col + 1)

  lines[1] = before .. lines[1]
  lines[#lines] = lines[#lines] .. after

  vim.api.nvim_buf_set_lines(
    0,
    row - 1,
    row,
    false,
    lines
  )

  vim.api.nvim_win_set_cursor(0, {
    row + #lines - 1,
    #lines[#lines] - #after,
  })
end

function M.paste_html(html)
  if vim.trim(html or '') == '' then
    return false
  end

  pandoc.html_to_markdown(html, function(markdown, pandoc_err)
    if not markdown then
      vim.notify(
        'pandoc conversion failed\n'
        .. tostring(pandoc_err),
        vim.log.levels.ERROR, { title = 'Stellar:Paste' }
      )

      return
    end

    insert_text(markdown)
  end)
end

return M
