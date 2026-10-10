---@module 'lsp.servers'
--- Unified LSP server registry
--- Single source of truth for: server configs, Mason packages, enabled servers

local M = {}

--[[
Server spec format:
  - Simple (string/boolean): name = mason_package_name or true (same name)
    jsonls = 'json-lsp',        -- Mason package 'json-lsp', server name 'jsonls'
    taplo = true,               -- Mason package 'taplo', server name 'taplo'

  - Complex (table): name = { config_module, mason?, mason_name?, config_key? }
    clangd = { 'c-language', mason = false },                              -- no Mason install
    luau_lsp = { 'luau', mason = 'luau-lsp' },                            -- Mason pkg differs from server name
    ['lua-language-server'] = { 'lua', mason = true, config_key = 'lua_ls' }, -- config key differs from server name
    ruff = { 'python', mason = true, config_key = 'ruff' },               -- multi-config module
--]]

M.servers = {
  -- ============ Simple servers (Mason package = value, or true = same name) ============
  -- [markdown]
  -- marksman = true,

  -- [json]
  jsonls = 'json-lsp',

  -- [toml]
  taplo = true,

  -- [for .fish files]
  fish_lsp = 'fish-lsp',

  -- [bash, sh]
  bashls = 'bash-language-server', -- HACK: install shellcheck for inline diagnostic

  -- [HTML]
  html = 'html-lsp',
  emmet_language_server = 'emmet-language-server',

  -- ============ Complex servers (require config modules) ============
  -- c, c++
  clangd = { 'c-language', mason = false },

  -- zig
  zls = { 'zig', mason = true },

  -- rust
  rust_analyzer = { 'rust', mason = false },

  -- qml (for quickshell)
  qmlls6 = { 'qml', mason = false },

  -- luau (Roblox)
  ['luau-lsp'] = { 'luau', mason = 'luau-lsp' },

  -- lua
  ['lua-language-server'] = { 'lua', mason = true, config_key = 'lua_ls' },

  -- python
  -- basedpyright = { 'python', mason = true, config_key = 'basedpyright' },
  ruff = { 'python', mason = true, config_key = 'ruff' },
  ty = { 'python', mason = true, config_key = 'ty' },

  -- markdown
  rumdl = { 'markdown', mason = true, config_key = 'rumdl' },
  ['markdown-oxide'] = { 'markdown', mason = true, config_key = 'markdown_oxide' },

  -- vue (commented)
  -- vtsls = { 'vue', mason = 'vue-language-server', config_key = 'vtsls' },
}

-- Non-LSP tools installed via Mason (formatters, linters, debuggers, etc.)
M.tools = {
  'codelldb', -- C/C++/Rust debugger
  'debugpy', -- Python debugger
  'shfmt', -- Shell formatter
  'prettier', -- Formatter
  'prettierd', -- Formatter daemon
  'cmakelang', -- CMake formatter/linter
  'htmlhint', -- HTML linter
  'shellcheck', -- Shell linter (used by bashls)
  'mpls', -- Markdown preview LSP
  -- 'vue-language-server', -- Vue LSP (commented)
}

return M
