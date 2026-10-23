local uv = vim.uv

local clipboard = require('custom.md-paste.clipboard')

local M = {}
local TITLE = 'Stellar:Paste'

local image_exts = {
  png = true,
  jpg = true,
  jpeg = true,
  gif = true,
  webp = true,
  bmp = true,
  tif = true,
  tiff = true,
  svg = true,
}

local function expand_dir(opts)
  local dir = vim.fn.expand(opts.img_dir or '')
  local file = vim.api.nvim_buf_get_name(0)

  if file ~= '' then
    dir = dir:gsub('%%(:[^/\\]+)', function(mod)
      return vim.fn.fnamemodify(file, mod)
    end)
  end

  return dir
end

local function is_absolute(path)
  return path:match('^[/\\]') ~= nil
    or path:match('^%a:[/\\]') ~= nil
end

local function markdown_path(path)
  return path:gsub('[^%w%-%._~/:]', function(char)
    return ('%%%02X'):format(string.byte(char))
  end)
end

local function image_path(opts, name)
  local dir = expand_dir(opts)

  if dir == '' then
    return name, name
  end

  local storage_dir = dir
  local file = vim.api.nvim_buf_get_name(0)

  if file ~= '' and not is_absolute(dir) then
    storage_dir = vim.fs.dirname(file) .. '/' .. dir
  end

  vim.fn.mkdir(storage_dir, 'p')

  return storage_dir .. '/' .. name, dir .. '/' .. name
end

local function insert_image(path)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]

  local text = '![](' .. path .. ')'
  local line = vim.api.nvim_get_current_line()

  vim.api.nvim_set_current_line(
    line:sub(1, col)
    .. text
    .. line:sub(col + 1)
  )

  vim.api.nvim_win_set_cursor(0, {
    row,
    col + #text,
  })
end

local function normalize_path(path)
  path = vim.trim(path or '')
    :gsub('^"(.*)"$', '%1')
    :gsub("^'(.*)'$", '%1')

  if jit.os == 'Windows' then
    local drive, rest = path:match('^/([a-zA-Z])/(.*)$')

    if drive then
      path = drive:upper() .. ':/' .. rest
    end

    path = path:gsub('\\', '/')
  end

  return vim.fn.fnamemodify(path, ':p')
end

local function escape_save_path(path)
  if jit.os == 'Windows' then
    return path:gsub("'", "''")
  end

  return path:gsub("'", "'\"'\"'")
end

function M.save(opts, info)
  local name = tostring(
    opts.img_name or os.date('%Y-%m-%d-%H-%M-%S')
  ):gsub('%.png$', '') .. '.png'
  local path, link_path = image_path(opts, name)
  local save = info.commands.save
  local command = type(save) == 'function'
    and save(path)
    or save:format(escape_save_path(path))

  vim.system(clipboard.shell_command(command), { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 or vim.fn.filereadable(path) == 0 then
        vim.notify('failed to save image', vim.log.levels.ERROR, { title = TITLE })
        return
      end

      insert_image(markdown_path(link_path))
    end)
  end)
end

function M.drop(opts, raw_path)
  local path = normalize_path(raw_path)

  local ext = vim.fn.fnamemodify(path, ':e'):lower()

  if not image_exts[ext]
    or vim.fn.filereadable(path) == 0 then
    return false
  end

  local target, link_path = image_path(
    opts,
    vim.fn.fnamemodify(path, ':t')
  )

  local source_abs = vim.fn.fnamemodify(path, ':p')
  local target_abs = vim.fn.fnamemodify(target, ':p')

  if source_abs ~= target_abs then
    local ok, err = uv.fs_copyfile(path, target)

    if not ok then
      vim.notify(
        'failed to copy image\n'
        .. tostring(err),
        vim.log.levels.ERROR, { title = TITLE }
      )

      -- The paste event was handled even though copying failed.
      return true
    end
  end

  insert_image(markdown_path(link_path))

  return true
end

return M
