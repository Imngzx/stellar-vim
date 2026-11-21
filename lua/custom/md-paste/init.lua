local M = {}

local clipboard = require('custom.md-paste.clipboard')
local image = require('custom.md-paste.image')
local markdown = require('custom.md-paste.markdown')

M.opts = {
  img_dir = 'img/%:t:r',
  filetypes = {
    'markdown',
    'markdownx',
  },
  img_name = nil,

  drag_and_drop = true,
  visual_url = true,
  rich_text = true,
}

local original_paste

local function enabled()
  return vim.tbl_contains(
    M.opts.filetypes,
    vim.bo.filetype
  )
end

local function setup_paste()
  if original_paste then
    return
  end

  original_paste = vim.paste

  rawset(vim, 'paste', function(lines, phase)
    if not enabled() then
      return original_paste(lines, phase)
    end

    if phase == -1 then
      if M.opts.visual_url
        and markdown.paste_url_in_visual(lines) then
        return true
      end

      if #lines == 1
        and image.drop(M.opts, lines[1]) then
        return true
      end
    end

    return original_paste(lines, phase)
  end)
end

local function paste_text(text)
  if vim.fn.mode():match('[vV]')
    and markdown.paste_url_in_visual(
      vim.split(text, '\n', { plain = true })
    ) then
    return
  end

  vim.api.nvim_paste(text, false, -1)
end

local function detect_and_paste(fallback_text)
  clipboard.detect(function(kind, value)
    if kind == 'image' then
      image.save(M.opts, value)
      return
    end

    if kind == 'html' and M.opts.rich_text then
      markdown.paste_html(value)
      return
    end

    if fallback_text ~= nil then
      paste_text(fallback_text)
      return
    end

    clipboard.read_text(function(text)
      if text == nil then
        text = vim.fn.getreg('"')
      end

      paste_text(text)
    end)
  end, M.opts.rich_text)
end

local function smart_paste()
  if not enabled() then
    return
  end

  if vim.fn.mode():match('[vV]') then
    clipboard.read_text(function(text)
      if text and markdown.paste_url_in_visual(
          vim.split(text, '\n', { plain = true })
        ) then
        return
      end

      detect_and_paste(text)
    end)

    return
  end

  detect_and_paste(nil)
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend(
    'force',
    M.opts,
    opts or {}
  )

  if M.opts.drag_and_drop
    or M.opts.visual_url then
    setup_paste()
  end

  vim.keymap.set(
    { 'n', 'v' },
    '<leader>cp',
    smart_paste,
    {
      buf = 0,
      silent = true,
      desc = '[Markdown] Smart paste',
    }
  )
end

return M
