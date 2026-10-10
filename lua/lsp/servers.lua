---@module 'lsp.servers'
--- Unified LSP server + formatter registry
--- Single source of truth for: LSP configs, formatters, Mason packages

local M = {}

--[[
Server spec format:
  - Simple (string/boolean): name = mason_package_name or true (same name)
    jsonls = 'json-lsp',        -- Mason package 'json-lsp', server name 'jsonls'
    -- Note: simple specs don't support formatters

  - Complex (table): name = { config_module, mason?, mason_name?, config_key?, formatter? }
    clangd = { 'c-language', mason = false, formatter = { name = 'clang_format', mason = 'clang-format', ft = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' } } }
    ruff = { 'python', mason = true, config_key = 'ruff', formatter = { name = 'ruff_format', mason = false, ft = { 'python' } } }
    ['lua-language-server'] = { 'lua', mason = true, config_key = 'lua_ls' }  -- uses lua-ls built-in formatter
    taplo = { false, mason = true, formatter = { name = 'taplo', mason = false, ft = { 'toml' } } }  -- no config module, has formatter
    bashls = { false, mason = true, mason_name = 'bash-language-server', formatter = { name = 'shfmt', mason = 'shfmt', ft = { 'sh', 'bash' } } }

  - Formatter-only (no LSP server): name = { formatter_only = true, ft = {...}, mason = ..., name = ... }
    prettier = { formatter_only = true, ft = { 'javascript', 'html', 'css' }, mason = 'prettier', name = 'prettier' }
    shfmt = { formatter_only = true, ft = { 'sh', 'bash' }, mason = 'shfmt', name = 'shfmt' }

formatter sub-spec:
  - name: conform.nvim formatter name (required)
  - mason: false (bundled with LSP), true (same name), string (Mason package name)
  - ft: filetypes this formatter applies to (required if formatter present)

config_module:
  - string: module name under 'lsp.servers.*' (e.g., 'c-language' -> lsp.servers.c-language)
  - false: no config module (uses default nvim-lspconfig config)
--]]

M.servers = {
  -- ============ Simple servers (no custom config, no formatter) ============
  -- [json]
  jsonls = 'json-lsp',

  -- [for .fish files]
  fish_lsp = 'fish-lsp',

  -- [HTML]
  emmet_language_server = 'emmet-language-server',

  -- ============ Complex servers (require config modules or formatters) ============
  -- [toml]
  taplo = { false, mason = true, formatter = { name = 'taplo', mason = false, ft = { 'toml' } } },

  -- [bash, sh]
  bashls = {
    false,
    mason = true,
    mason_name = 'bash-language-server',
    formatter = { name = 'shfmt', mason = 'shfmt', ft = { 'sh', 'bash' } },
  },

  -- [HTML]
  html = {
    false,
    mason = true,
    mason_name = 'html-lsp',
    formatter = { name = 'prettier', mason = 'prettier', ft = { 'html' } },
  },

  -- [c, c++]
  clangd = {
    'c-language',
    mason = false,
    formatter = { name = 'clang_format', mason = 'clang-format', ft = { 'c', 'c.doxygen', 'cpp', 'cpp.doxygen', 'objc', 'objcpp', 'cuda' } },
  },

  -- [zig]
  zls = {
    'zig',
    mason = true,
    mason_name = 'zls',
    formatter = { name = 'zigfmt', mason = 'zig', ft = { 'zig', 'zir' } },
  },

  -- [rust]
  rust_analyzer = {
    'rust',
    mason = false,
    formatter = { name = 'rustfmt', mason = false, ft = { 'rust' } },
  },

  -- [qml] (for quickshell)
  qmlls6 = { 'qml', mason = false },

  -- luau (Roblox)
  ['luau-lsp'] = { 'luau', mason = 'luau-lsp' },

  -- [lua]
  ['lua-language-server'] = {
    'lua',
    mason = true,
    config_key = 'lua_ls',
    -- uses lua-ls built-in formatter, no external formatter
  },

  -- [python]
  -- basedpyright = { 'python', mason = true, config_key = 'basedpyright', formatter = { name = 'ruff_format', mason = false, ft = { 'python' } } },
  ruff = {
    'python',
    mason = true,
    config_key = 'ruff',
    formatter = { name = 'ruff_format', mason = false, ft = { 'python' } },
  },
  ty = { 'python', mason = true, config_key = 'ty' },

  -- [markdown]
  rumdl = {
    'markdown',
    mason = true,
    config_key = 'rumdl',
    formatter = { name = 'rumdl', mason = false, ft = { 'markdown' } },
  },
  ['markdown-oxide'] = { 'markdown', mason = true, config_key = 'markdown_oxide' },

  -- vue (commented)
  -- vtsls = { 'vue', mason = 'vue-language-server', config_key = 'vtsls', formatter = { name = 'prettier', mason = 'prettier', ft = { 'vue', 'typescript', 'javascript' } } },

  -- ============ Formatter-only (no LSP server) ============
  prettier = {
    formatter_only = true,
    ft = {
      'javascript',
      'javascriptreact',
      'typescript',
      'typescriptreact',
      'html',
      'css',
      'json',
      'yaml',
      'markdown',
    },
    mason = 'prettier',
    name = 'prettier',
  },
  prettierd = {
    formatter_only = true,
    ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'html', 'css' },
    mason = 'prettierd',
    name = 'prettierd',
  },
  shfmt = { formatter_only = true, ft = { 'sh', 'bash' }, mason = 'shfmt', name = 'shfmt' },
  cmake_format = {
    formatter_only = true,
    ft = { 'cmake' },
    mason = 'cmakelang',
    name = 'cmake_format',
  },
  jq = { formatter_only = true, ft = { 'json' }, mason = 'jq', name = 'jq' },
}

-- Non-LSP tools installed via Mason (debuggers, linters, etc. - no formatter entry)
M.tools = {
  'codelldb', -- C/C++/Rust debugger
  'debugpy', -- Python debugger
  'htmlhint', -- HTML linter
  'shellcheck', -- Shell linter (used by bashls)
  'mpls', -- Markdown preview LSP
  -- 'vue-language-server', -- Vue LSP (commented)
}

return M