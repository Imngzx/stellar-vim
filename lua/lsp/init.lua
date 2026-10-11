---@module 'lsp.init'
--- LSP manager: server registration, formatter config, Mason tools

local M = {}

local servers = require('lsp.servers')
local vim_deepcopy = vim.deepcopy
local vim_list_extend = vim.list_extend
local vim_lsp_config = vim.lsp.config
local type_check = type
local table_insert = table.insert

--- Type check hoisted
local function is_tbl(spec)
  return type_check(spec) == 'table'
end

M.enabled_servers = {}
M.mason_tools = {}

--- Dedupe with reused seen table (closure)
---@return any[]
local function make_dedupe()
  local seen = {}
  ---@param list any[]
  return function(list)
    for k in next, seen do seen[k] = nil end
    local unique = {}
    local idx = 1
    for i = 1, #list do
      local item = list[i]
      if not seen[item] then
        seen[item] = true
        unique[idx] = item
        idx = idx + 1
      end
    end
    return unique
  end
end
local dedupe = make_dedupe()


--- Extract config module name (nil for simple string specs and formatter-only rows)
---@param spec string|table|boolean
---@return string|nil
local function get_config_module(spec)
  if not is_tbl(spec) or spec.formatter_only then
    return nil
  end
  return spec[1]
end

--- Extract Mason package name from spec
---@param name string
---@param spec string|table|boolean
---@return string|nil
local function get_mason_pkg(name, spec)
  if not is_tbl(spec) then
    return spec == true and name or spec
  end
  if spec.formatter_only then
    return spec.mason
  end
  return spec.mason_name or name
end

--- Check if spec should be installed via Mason
---@param spec string|table|boolean
---@return boolean
local function is_mason_enabled(spec)
  if not is_tbl(spec) then
    return true
  end
  return spec.mason ~= false
end

--- Extract config key
---@param name string
---@param spec string|table|boolean
---@return string
local function get_config_key(name, spec)
  if not is_tbl(spec) then
    return name
  end
  return spec.config_key or name
end

---@param name string
---@param spec string|table|boolean
local function register_server(name, spec)
  local config_module = get_config_module(spec)
  local mason_pkg = get_mason_pkg(name, spec)

  table_insert(M.enabled_servers, name)
  if is_mason_enabled(spec) and mason_pkg then
    table_insert(M.mason_tools, mason_pkg)
  end

  if not config_module then
    vim_lsp_config(name, {})
    return
  end

  local mod = require('lsp.servers.' .. config_module)
  local config = vim_deepcopy(mod[get_config_key(name, spec)] or mod)
  config.mason = nil
  config.mason_name = nil
  config.config_key = nil
  config.formatter = nil
  vim_lsp_config(name, config)
end

function M.setup()
  -- Direct hash traversal via next (zero allocations, LuaJIT optimized)
  for name, spec in next, servers.servers do
    if not (is_tbl(spec) and spec.formatter_only) then
      register_server(name, spec)
    end
  end
  vim_list_extend(M.mason_tools, servers.tools)
end

--- Generate conform.nvim formatter config from registry
---@return table<string, string[]> formatters_by_ft
function M.get_conform_config()
  local fmt = {}

  -- Direct hash traversal via next (zero allocations, LuaJIT optimized)
  for name, spec in next, servers.servers do
    if is_tbl(spec) then
      local ft_list
      local formatter_name = spec.formatter and spec.formatter.name or
        (spec.formatter_only and spec.name)
      if spec.formatter_only then
        ft_list = spec.ft
      elseif spec.formatter then
        ft_list = spec.formatter.ft or { name }
      end

      if ft_list then
        for j = 1, #ft_list do
          local ft = ft_list[j]
          local list = fmt[ft]
          if not list then
            list = {}
            fmt[ft] = list
          end
          table_insert(list, formatter_name)
        end
      end
    end
  end

  for ft, list in next, fmt do
    fmt[ft] = dedupe(list)
  end

  return fmt
end

--- Generate Mason tools list from registry
---@return string[]
function M.get_mason_tools()
  local tools = {}

  -- Direct hash traversal via next (zero allocations, LuaJIT optimized)
  for name, spec in next, servers.servers do
    if is_tbl(spec) and spec.formatter_only then
      if is_mason_enabled(spec) and spec.mason then
        table_insert(tools, spec.mason)
      end
    else
      if is_mason_enabled(spec) then
        local mason_pkg = get_mason_pkg(name, spec)
        if mason_pkg then
          table_insert(tools, mason_pkg)
        end
      end

      local formatter = is_tbl(spec) and spec.formatter or nil
      if formatter and formatter.mason and formatter.mason ~= false then
        local mason_pkg = formatter.mason == true and (formatter.name or name) or formatter.mason
        if mason_pkg then
          table_insert(tools, mason_pkg)
        end
      end
    end
  end

  vim_list_extend(tools, servers.tools)
  return dedupe(tools)
end

return M
