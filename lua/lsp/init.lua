local M = {}

-- 【1】this section just handles lsp installation
local default_servers = {

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

  --[HTML]
  html = 'html-lsp',
  emmet_language_server = 'emmet-language-server',
}

-- 【2】this section can handle installation + configurations
-- tools that noted with mason=false wont be installed via Mason automatically
local custom_servers = setmetatable({}, {
  __index = function(t, k)
    if k == 'clangd' then return require('lsp.servers.c-language') end
    if k == 'zls' then return require('lsp.servers.zig') end
    if k == 'rumdl' then return require('lsp.servers.markdown').rumdl end
    if k == 'markdown-oxide' then return require('lsp.servers.markdown').markdown_oxide end
    if k == 'rust_analyzer' then return require('lsp.servers.rust') end
    if k == 'qmlls6' then return require('lsp.servers.qml') end
    if k == 'luau_lsp' then return require('lsp.servers.luau') end

    -- single file with multiple lsp's config
    if k == 'lua_ls' then return require('lsp.servers.lua').lua_ls end
    -- if k == 'basedpyright' then return require('lsp.servers.python').basedpyright end
    if k == 'ty' then return require('lsp.servers.python').ty end
    if k == 'ruff' then return require('lsp.servers.python').ruff end

    -- if k == 'vtsls' then return require('lsp.servers.vue') end
  end
})

-- pls type in which one do you want to use (custom lsp)
local custom_server_keys = {
  -- c, c++
  'clangd',

  -- zig

  'zls',

  -- rust
  'rust_analyzer',

  -- qml (for quickshell)
  'qmlls6',

  -- luau (Roblox)
  'luau_lsp',

  -- lua
  'lua_ls',

  -- python
  -- 'basedpyright',
  'ruff',
  'ty',

  'rumdl',
  'markdown-oxide'
}

-- 【3】this handles tool installation from mason other than lsp
M.mason_tools = {
  'codelldb', -- C/C++/Rust 调试器
  'debugpy', -- Python 调试器
  'shfmt', -- Shell 格式化器
  'prettier',
  'prettierd',
  'luau-lsp',
  'cmakelang',
  'htmlhint',
  'shellcheck',
  'mpls', -- Markdown preview LSP
  -- 'vue-language-server',
}

M.enabled_servers = {}

function M.setup()
  for name, mason_pkg in pairs(default_servers) do
    table.insert(M.enabled_servers, name)
    table.insert(M.mason_tools, type(mason_pkg) == 'string' and mason_pkg or name)
    vim.lsp.config(name, {})
  end

  for i = 1, #custom_server_keys do
    local name = custom_server_keys[i]
    local config = custom_servers[name]

    table.insert(M.enabled_servers, name)
    if config.mason ~= false then
      table.insert(M.mason_tools, config.mason_name or name)
    end

    local safe_config = vim.deepcopy(config)
    safe_config.mason = nil
    safe_config.mason_name = nil

    vim.lsp.config(name, safe_config)
  end
end

return M
