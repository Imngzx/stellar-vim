---@module 'lsp.init'
--- LSP manager: server registration, formatter config, linter config, Mason tools

local M = {}

local servers = require('lsp.servers')
local vim_deepcopy = vim.deepcopy
local vim_list_extend = vim.list_extend
local type_check = type
local table_insert = table.insert

local vim_api = vim.api
local vim_lsp = vim.lsp
local vim_lsp_config = vim_lsp.config
local vim_lsp_buf = vim_lsp.buf
local vim_lsp_buf_sign = vim_lsp.buf.signature_help
local vim_diagnostic = vim.diagnostic
local vim_diagnostic_severity = vim_diagnostic.severity
local icon = I.lsp

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


--- Generic helper: build {ft = {names}} from a registry
---@param registry table
---@param name_getter fun(key, spec): string|nil  -- returns name to insert, or nil to skip
---@param ft_getter fun(key, spec): string[]|nil  -- returns filetypes array, or nil to skip
---@return table<string, string[]>
local function build_by_ft(registry, name_getter, ft_getter)
  local result = {}

  for key, spec in next, registry do
    local name = name_getter(key, spec)
    local ft_list = ft_getter(key, spec)
    if name and ft_list then
      for j = 1, #ft_list do
        local ft = ft_list[j]
        local list = result[ft]
        if not list then
          list = {}
          result[ft] = list
        end
        table_insert(list, name)
      end
    end
  end

  for ft, list in next, result do
    result[ft] = dedupe(list)
  end

  return result
end


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
  return build_by_ft(servers.servers,
    -- name_getter
    function(_, spec)
      if not is_tbl(spec) then return nil end
      if spec.formatter_only then return spec.name end
      if spec.formatter then return spec.formatter.name end
      return nil
    end,
    -- ft_getter
    function(_, spec)
      if not is_tbl(spec) then return nil end
      if spec.formatter_only then return spec.ft end
      if spec.formatter then return spec.formatter.ft end
      return nil
    end
  )
end

--- Generate nvim-lint linter config from M.linters registry
---@return table<string, string[]> linters_by_ft
function M.get_lint_config()
  return build_by_ft(servers.linters,
    -- name_getter
    function(name, _) return name end,
    -- ft_getter
    function(_, spec) return spec.ft end
  )
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

  -- Linters from M.linters registry
  for _, linter_spec in next, servers.linters do
    if linter_spec.mason then
      table_insert(tools, linter_spec.mason)
    end
  end

  vim_list_extend(tools, servers.tools)
  return dedupe(tools)
end

function M.lsp_config()
  vim_lsp.enable(M.enabled_servers)

  vim_api.nvim_create_autocmd('LspAttach', {
    group = vim_api.nvim_create_augroup('LspKeymaps', { clear = true }),
    callback = function(args)
      local bufnr = args.buf
      local client = vim_lsp.get_client_by_id(args.data.client_id)

      if client and client:supports_method('textDocument/inlayHint') then
        vim.lsp.inlay_hint.enable(
          not vim_lsp.inlay_hint.is_enabled({ bufnr = args.buf }),
          { bufnr = args.buf }
        )
      end

      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      map('n', 'gd', vim_lsp_buf.definition, 'Goto Definition')
      map('n', 'gr', vim_lsp_buf.references, 'Goto References')
      map('n', 'gI', vim_lsp_buf.implementation, 'Goto Implementation')
      map('n', '<leader>D', vim_lsp_buf.type_definition, 'Type Definition')
      map('n', '<leader>ds', vim_lsp_buf.document_symbol, 'Document Symbols')
      map('n', '<leader>ws', vim_lsp_buf.workspace_symbol, 'Workspace Symbols')
      map('n', '<leader>cr', vim_lsp_buf.rename, 'Rename symbol')
      map({ 'n', 'x' }, '<leader>ca', vim_lsp_buf.code_action, 'Code Action')
      map('n', 'K', vim_lsp_buf.hover, 'LSP Hover')
      map('n', 'gK', vim_lsp_buf_sign, 'Signature Help')
      map('i', '<C-k>', vim_lsp_buf_sign, 'Signature Help')
      map('n', '<leader>pl', '<cmd>che vim.lsp<cr>', '[Panel] LSP Info')

      local diagnostic_goto = function(next, severity)
        return function()
          vim_diagnostic.jump({
            count = (next and 1 or -1) * vim.v.count1,
            severity = severity and vim_diagnostic_severity[severity] or nil,
            on_jump = function()
              vim_diagnostic.open_float()
            end,
          })
        end
      end
      map('n', '<leader>cl', vim_diagnostic.open_float, 'Line Diagnostics')
      map('n', ']d', diagnostic_goto(true), 'Next Diagnostic')
      map('n', '[d', diagnostic_goto(false), 'Prev Diagnostic')
      map('n', ']e', diagnostic_goto(true, 'ERROR'), 'Next Error')
      map('n', '[e', diagnostic_goto(false, 'ERROR'), 'Prev Error')
      map('n', ']w', diagnostic_goto(true, 'WARN'), 'Next Warning')
      map('n', '[w', diagnostic_goto(false, 'WARN'), 'Prev Warning')
    end,
  })

  vim.diagnostic.config({
    virtual_text = false, --leave this with false when you using this plugin
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
      border = 'rounded',
    },
    signs = {
      text = {
        [vim_diagnostic_severity.ERROR] = icon.error,
        [vim_diagnostic_severity.WARN] = icon.warn,
        [vim_diagnostic_severity.HINT] = icon.hint,
        [vim_diagnostic_severity.INFO] = icon.info,
      },
    },
  })
end

return M
