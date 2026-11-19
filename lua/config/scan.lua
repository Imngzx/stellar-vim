local M = {}

local uv = vim.uv
local uv_fs_scandir = uv.fs_scandir
local uv_fs_scandir_next = uv.fs_scandir_next
local uv_fs_stat = uv.fs_stat

local plugins_dir = vim.fn.stdpath('config') .. '/lua/plugins'

-- Loaded explicitly at top level in config/resonance.lua; the scan skips them.
local EAGER = {
  catppuccin = true,
  snacks = true,
  cmdline = true,
  ui = true,
  tool = true,
  discord = true,
}

-- Top level of lua/plugins only: subfolders (heirline/statusline.lua,
-- snacks/logos/*) are components, not specs. Sorted, because scandir order
-- is filesystem-dependent.
function M.scan_plugins()
  local handle, err = uv_fs_scandir(plugins_dir)
  if not handle then
    vim.notify('[config] Cannot scan ' .. plugins_dir .. ': ' .. tostring(err), vim.log.levels.ERROR)
    return {}
  end

  local list, n = {}, 0
  while true do
    local name, kind = uv_fs_scandir_next(handle)
    if not name then break end

    local mod
    if kind == 'file' then
      mod = name:match('^(.+)%.lua$')
    elseif kind == 'directory' and uv_fs_stat(plugins_dir .. '/' .. name .. '/init.lua') then
      mod = name
    end

    if mod and not EAGER[mod] then
      n = n + 1
      list[n] = mod
    end
  end

  table.sort(list)
  return list
end

return M
