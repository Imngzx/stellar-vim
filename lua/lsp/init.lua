---@module 'lsp.init'
--- LSP manager: server registration, formatter config, Mason tools

local M = {}

local servers = require('lsp.servers')

M.enabled_servers = {}
M.mason_tools = {}

--- Extract config module name (returns nil for simple string specs)
---@param spec string|table|boolean
---@return string|nil
local function get_config_module(spec)
  if type(spec) == 'string' or spec == true then
    return nil
  end
  -- Complex spec: first element is config module name
  -- If formatter_only, no config module
  if spec.formatter_only then
    return nil
  end
  return spec[1]
end

--- Extract Mason package name from spec
---@param name string
---@param spec string|table|boolean
---@return string|nil
local function get_mason_pkg(name, spec)
  if type(spec) == 'string' or spec == true then
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
  if type(spec) == 'string' or spec == true then
    return true
  end
  if spec.formatter_only then
    return spec.mason ~= false
  end
  return spec.mason ~= false
end

--- Extract config key
---@param name string
---@param spec string|table|boolean
---@return string
local function get_config_key(name, spec)
  if type(spec) == 'string' or spec == true then
    return name
  end
  return spec.config_key or name
end

function M.setup()
  -- Process all LSP servers from unified registry
  for name, spec in pairs(servers.servers) do
    local config_module = get_config_module(spec)
    local config_key = get_config_key(name, spec)
    local mason_pkg = get_mason_pkg(name, spec)
    local mason_enabled = is_mason_enabled(spec)

    -- Skip formatter-only entries (they don't have LSP config)
    if not spec.formatter_only and config_module then
      local mod = require('lsp.servers.' .. config_module)
      local config = vim.deepcopy(mod[config_key] or mod)

      table.insert(M.enabled_servers, name)
      if mason_enabled then
        table.insert(M.mason_tools, mason_pkg)
      end

      -- Strip internal fields not meant for vim.lsp.config
      config.mason = nil
      config.mason_name = nil
      config.config_key = nil
      config.formatter = nil

      vim.lsp.config(name, config)
    elseif not spec.formatter_only and not config_module then
      -- Simple string spec without config module (e.g., jsonls = 'json-lsp')
      -- Note: simple string specs don't support formatters
      -- Use complex spec { config_module = false, formatter = {...} } if formatter needed
      table.insert(M.enabled_servers, name)
      if mason_enabled then
        table.insert(M.mason_tools, mason_pkg)
      end
      vim.lsp.config(name, {})
    end
    -- formatter_only entries skipped for LSP config
  end

  -- Add non-LSP Mason tools (debuggers, linters, etc.)
  vim.list_extend(M.mason_tools, servers.tools)
end

--- Generate conform.nvim formatter config from registry
---@return table<string, string|string[]> formatters_by_ft
function M.get_conform_config()
  local fmt = {}

  for name, spec in pairs(servers.servers) do
    local ft_list = {}

    if spec.formatter_only then
      ft_list = spec.ft
    elseif spec.formatter then
      ft_list = spec.ft or { name }
    else
      goto continue
    end

    local formatter_name = spec.formatter and spec.formatter.name or
    (spec.formatter_only and spec.name)

    for _, ft in ipairs(ft_list) do
      if not fmt[ft] then
        fmt[ft] = { formatter_name }
      elseif type(fmt[ft]) == 'string' then
        fmt[ft] = { fmt[ft], formatter_name }
      else
        table.insert(fmt[ft], formatter_name)
      end
    end

    ::continue::
  end

  -- Deduplicate formatter lists
  for ft, v in pairs(fmt) do
    if type(v) == 'table' then
      local seen = {}
      local unique = {}
      for _, f in ipairs(v) do
        if not seen[f] then
          seen[f] = true
          table.insert(unique, f)
        end
      end
      fmt[ft] = unique
    end
  end

  return fmt
end

--- Generate Mason tools list from registry
---@return string[]
function M.get_mason_tools()
  local tools = {}

  for name, spec in pairs(servers.servers) do
    -- LSP server Mason package
    if not spec.formatter_only and is_mason_enabled(spec) then
      local mason_pkg = get_mason_pkg(name, spec)
      if mason_pkg then table.insert(tools, mason_pkg) end
    end

    -- Formatter Mason package (if different from LSP)
    if spec.formatter and spec.formatter.mason and spec.formatter.mason ~= false then
      local mason_pkg = spec.formatter.mason == true and (spec.formatter.name or name) or
      spec.formatter.mason
      if mason_pkg then table.insert(tools, mason_pkg) end
    elseif spec.formatter_only and is_mason_enabled(spec) then
      if spec.mason then table.insert(tools, spec.mason) end
    end
  end

  -- Add non-LSP tools
  vim.list_extend(tools, servers.tools)

  -- Deduplicate
  local seen = {}
  local unique = {}
  for _, t in ipairs(tools) do
    if not seen[t] then
      seen[t] = true
      table.insert(unique, t)
    end
  end

  return unique
end

return M

