---@module 'lsp.init'
--- LSP manager: server registration, formatter config, Mason tools

local M = {}

local servers = require('lsp.servers')
local vim_deepcopy = vim.deepcopy
local vim_list_extend = vim.list_extend
local vim_lsp_config = vim.lsp.config
local pairs_iter = pairs
local type_check = type
local table_insert = table.insert

M.enabled_servers = {}
M.mason_tools = {}

--- First-seen order. Callers rely on that order for enable and install lists.
---@param list any[]
---@return any[]
local function dedupe(list)
  local seen = {}
  local unique = {}
  for i = 1, #list do
    local item = list[i]
    if not seen[item] then
      seen[item] = true
      table_insert(unique, item)
    end
  end
  return unique
end

--- Extract config module name (nil for simple string specs and formatter-only rows)
---@param spec string|table|boolean
---@return string|nil
local function get_config_module(spec)
  if type_check(spec) ~= 'table' or spec.formatter_only then
    return nil
  end
  return spec[1]
end

--- Extract Mason package name from spec
---@param name string
---@param spec string|table|boolean
---@return string|nil
local function get_mason_pkg(name, spec)
  if type_check(spec) ~= 'table' then
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
  if type_check(spec) ~= 'table' then
    return true
  end
  return spec.mason ~= false
end

--- Extract config key
---@param name string
---@param spec string|table|boolean
---@return string
local function get_config_key(name, spec)
  if type_check(spec) ~= 'table' then
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
  for name, spec in pairs_iter(servers.servers) do
    local skip = type_check(spec) == 'table' and spec.formatter_only
    if not skip then
      register_server(name, spec)
    end
  end

  vim_list_extend(M.mason_tools, servers.tools)
end

--- Generate conform.nvim formatter config from registry
---@return table<string, string[]> formatters_by_ft
function M.get_conform_config()
  local fmt = {}

  for name, spec in pairs_iter(servers.servers) do
    if type_check(spec) == 'table' then
      local ft_list
      -- formatter.name wins; a missing ft list falls back to the server key.
      local formatter_name = spec.formatter and spec.formatter.name or
        (spec.formatter_only and spec.name)
      if spec.formatter_only then
        ft_list = spec.ft
      elseif spec.formatter then
        ft_list = spec.formatter.ft or { name }
      end

      if ft_list then
        for i = 1, #ft_list do
          local ft = ft_list[i]
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

  for ft, list in pairs_iter(fmt) do
    fmt[ft] = dedupe(list)
  end

  return fmt
end

--- Generate Mason tools list from registry
---@return string[]
function M.get_mason_tools()
  local tools = {}

  for name, spec in pairs_iter(servers.servers) do
    if type_check(spec) == 'table' and spec.formatter_only then
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

      local formatter = type_check(spec) == 'table' and spec.formatter or nil
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

