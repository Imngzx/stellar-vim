local M = {}

local servers = require('lsp.servers')

M.enabled_servers = {}
M.mason_tools = {}

function M.setup()
  -- Process all LSP servers from unified registry
  for name, spec in pairs(servers.servers) do
    local config, mason_pkg, mason_enabled, config_key

    if type(spec) == 'string' or spec == true then
      -- Simple spec: name = mason_package (string) or true (same name)
      config = {}
      mason_pkg = spec == true and name or spec
      mason_enabled = true
      config_key = name
    else
      -- Complex spec: { config_module, mason?, mason_name?, config_key? }
      local mod = require('lsp.servers.' .. spec[1])
      config_key = spec.config_key or name
      config = vim.deepcopy(mod[config_key] or mod)
      mason_pkg = spec.mason_name or name
      mason_enabled = spec.mason ~= false
    end

    table.insert(M.enabled_servers, name)
    if mason_enabled then
      table.insert(M.mason_tools, mason_pkg)
    end

    -- Strip internal fields not meant for vim.lsp.config
    config.mason = nil
    config.mason_name = nil
    config.config_key = nil

    vim.lsp.config(name, config)
  end

  -- Add non-LSP Mason tools
  vim.list_extend(M.mason_tools, servers.tools)
end

return M

