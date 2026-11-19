-- lazy.nvim-style spec import for resonance: scan a lua/ subfolder, require
-- every module in it, and register the specs the modules return.
local M = {}

local uv = vim.uv
local uv_fs_scandir = uv.fs_scandir
local uv_fs_scandir_next = uv.fs_scandir_next
local uv_fs_stat = uv.fs_stat

local utils = require('libs.utils')
local safe_load = utils.safe_load
local safe_setup = utils.safe_setup

local lua_dir = vim.fn.stdpath('config') .. '/lua/'

-- Every mod passed to import(). A scan never returns a folder that is
-- imported on its own (plugins/core/), even if it gains an init.lua --
-- otherwise import('plugins') would register its specs a second time.
local imported = {}

-- A single spec: a URL string first, or an explicit src/url/plugin field.
local function is_spec(t)
  if type(t) ~= 'table' then return false end
  local first = t[1]
  return (type(first) == 'string' and first:find('://', 1, true) ~= nil)
    or type(t.src) == 'string' or type(t.url) == 'string'
    or t.plugin ~= nil
end

--- Module names directly under lua/<mod>/, sorted.
---
--- Top level only: subfolders (heirline/statusline.lua, core/snacks/logos/*)
--- are components, not specs; a folder counts only through its init.lua.
--- That is also why import('plugins') never reaches plugins/core/.
--- Sorted, because scandir order is filesystem-dependent.
---@param mod string e.g. 'plugins'
---@return string[]
function M.scan(mod)
  local dir = lua_dir .. mod:gsub('%.', '/')
  local handle, err = uv_fs_scandir(dir)
  if not handle then
    vim.notify('[config] Cannot scan ' .. dir .. ': ' .. tostring(err), vim.log.levels.ERROR)
    return {}
  end

  local list, n = {}, 0
  while true do
    local name, kind = uv_fs_scandir_next(handle)
    if not name then break end

    local entry
    if kind == 'file' then
      entry = name:match('^(.+)%.lua$')
    elseif kind == 'directory' and not imported[mod .. '.' .. name]
      and uv_fs_stat(dir .. '/' .. name .. '/init.lua') then
      entry = name
    end

    if entry then
      n = n + 1
      list[n] = entry
    end
  end

  table.sort(list)
  return list
end

local function by_priority(a, b)
  if a.priority ~= b.priority then return a.priority > b.priority end
  return a.order < b.order
end

--- Require every module under lua/<mod>/ and register what it returns.
---
--- A module may `return { spec }` / `return { {spec}, {spec} }` (lazy.nvim
--- style), or call require('resonance').load() itself and return nothing;
--- anything else it returns (lsp.lua's helper table) is ignored.
---
--- Returned specs are registered after every module is required, highest
--- `priority` first (default 0), ties in file order. `priority` is ours,
--- not resonance's, so it is stripped before resonance.load(). Each module
--- and each spec runs under its own pcall: one bad file doesn't stop the
--- rest. Disable a plugin with the spec's `cond`.
---@param mod string e.g. 'plugins', 'plugins.core'
function M.import(mod)
  imported[mod] = true
  local names = M.scan(mod)

  local entries, n = {}, 0
  local function add(name, spec)
    n = n + 1
    entries[n] = { name = name, spec = spec, priority = spec.priority or 0, order = n }
  end

  for i = 1, #names do
    local name = mod .. '.' .. names[i]
    if safe_load(name) then
      local ret = package.loaded[name]
      if is_spec(ret) then
        add(name, ret)
      elseif type(ret) == 'table' and is_spec(ret[1]) then
        for j = 1, #ret do
          add(name, ret[j])
        end
      end
    end
  end

  table.sort(entries, by_priority)

  local resonance = package.loaded['resonance'] or require('resonance')
  local load = resonance.load
  for i = 1, n do
    local e = entries[i]
    local spec = e.spec
    if spec.priority ~= nil then
      local copy = {}
      for k, v in pairs(spec) do copy[k] = v end
      copy.priority = nil
      spec = copy
    end
    safe_setup(e.name, load, spec)
  end
end

return M
