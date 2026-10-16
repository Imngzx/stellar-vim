# LSP System Documentation

## Overview

Unified LSP server + formatter + linter + Mason tool registry. Single source of truth in `lua/lsp/servers.lua`.

## Architecture

```text
lua/lsp/
├── init.lua       # LSP manager: registration, formatter/linter config, Mason tools
├── servers.lua    # Unified registry (servers, formatters, linters, tools)
└── servers/       # Per-language server configs (return vim.lsp.Config)
    ├── c-language.lua
    ├── golang.lua
    ├── lua.lua
    ├── python.lua
    ├── rust.lua
    └── ...
```

## Registry Spec (`servers.lua`)

### Server Spec Formats

**Simple** (no custom config, no formatter):

```lua
jsonls = 'json-lsp',  -- Mason package name
```

**Complex** (custom config module, optional formatter):

```lua
clangd = {
  'c-language',           -- config module: lsp.servers.c-language
  mason = false,          -- don't install via Mason (system clangd)
  formatter = {
    name = 'clang_format', -- conform.nvim formatter name
    mason = 'clang-format', -- Mason package for formatter
    ft = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' }
  }
}
```

**Complex fields:**

| Field | Type | Description |
|-------|------|-------------|
| `[1]` | string | Config module under `lsp.servers.*` |
| `mason` | boolean | Auto-install via Mason (default: true) |
| `mason_name` | string | Mason package name if different from server name |
| `config_key` | string | Override server name for `vim.lsp.config()` |
| `formatter` | table | Formatter sub-spec (see below) |

**Formatter-only** (no LSP server):

```lua
prettier = {
  formatter_only = true,
  ft = { 'javascript', 'html', 'css' },
  mason = 'prettier',
  name = 'prettier'
}
```

**Formatter sub-spec:**

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | conform.nvim formatter name (required) |
| `mason` | false\|true\|string | false=bundled, true=same name, string=Mason package |
| `ft` | string[] | Filetypes this formatter applies to (required) |

### Linters Registry (`M.linters`)

```lua
M.linters = {
  golangcilint = { ft = { 'go' }, mason = 'golangci-lint' },
  htmlhint = { ft = { 'html' }, mason = 'htmlhint' },
}
```

Used by `nvim-lint` for `linters_by_ft` and Mason auto-install.

### Mason Tools (`M.tools`)

```lua
M.tools = {
  'codelldb', 'debugpy', 'shellcheck', 'mpls',
  'gomodifytags', 'impl', 'delve',  -- Go tools
}
```

Non-LSP tools installed via Mason (debuggers, linters, etc.).

## LSP Manager (`init.lua`)

### Public API

| Function | Returns | Description |
|----------|---------|-------------|
| `setup()` | nil | Registers all servers, builds `enabled_servers` + `mason_tools` |
| `get_conform_config()` | table | `formatters_by_ft` for conform.nvim |
| `get_lint_config()` | table | `linters_by_ft` for nvim-lint |
| `get_mason_tools()` | string[] | Deduplicated Mason packages list |
| `lsp_config()` | nil | Enables servers, sets up LspAttach keymaps, diagnostics |

### Internal Helpers

- `register_server(name, spec)` — loads config module, calls `vim.lsp.config(name, config)`
- `build_by_ft(registry, name_getter, ft_getter)` — generic `{ft = {names}}` builder
- `dedupe(list)` — closure-based deduplication (zero allocations)

### LspAttach Keymaps (set in `lsp_config()`)

| Key | Action |
|-----|--------|
| `gd` | Goto Definition |
| `gr` | Goto References |
| `gI` | Goto Implementation |
| `<leader>D` | Type Definition |
| `<leader>ds` | Document Symbols |
| `<leader>ws` | Workspace Symbols |
| `<leader>cr` | Rename Symbol |
| `<leader>ca` | Code Action |
| `K` | Hover |
| `gK` / `<C-k>` | Signature Help |
| `]d` / `[d` | Next/Prev Diagnostic |
| `]e` / `[e` | Next/Prev Error |
| `]w` / `[w` | Next/Prev Warning |

### Diagnostics Config

- `virtual_text = false` (using tiny-inline-diagnostic)
- `underline = true`
- `severity_sort = true`
- Rounded float border
- Custom signs from `I.lsp` icons

## Server Config Modules (`lsp/servers/*.lua`)

Each returns a `vim.lsp.Config` table (or table of configs keyed by server name).

Example (`golang.lua`):

```lua
---@type vim.lsp.Config
return {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_markers = { 'go.work', 'go.mod', '.git' },
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
      -- ... all gopls settings
    },
  },
}
```

## Adding a New Language

1. **Create config module**: `lua/lsp/servers/<name>.lua` returning `vim.lsp.Config`
2. **Add to registry**: Edit `lua/lsp/servers.lua`, add entry to `M.servers`
   - Use complex spec if custom config/formatter needed
   - Use simple spec for default nvim-lspconfig behavior
3. **Add formatter** (if needed): Add `formatter` sub-spec or `formatter_only` entry
4. **Add linter** (if needed): Add to `M.linters`
5. **Add Mason tools**: Add debugger/tools to `M.tools`
6. **Add treesitter parsers**: Update `lua/plugins/treesitter.lua`
7. **Test**: `nvim --headless -c "luafile ~/.config/nvim/tests/smoke.lua" -c "qall"`

> [!TIP]
> Each name just needed to be mentioned **once** in servers.lua, duplication is discouraged

## Integration Points

| Plugin | Config Source |
|--------|---------------|
| `nvim-lspconfig` | `vim.lsp.config()` via `register_server()` |
| `conform.nvim` | `get_conform_config()` → `formatters_by_ft` |
| `nvim-lint` | `get_lint_config()` → `linters_by_ft` |
| `mason.nvim` | `get_mason_tools()` → `ensure_installed` |

## Performance Notes

- LuaJIT optimized: `next` for hash traversal, hoisted locals, closure-based dedupe
- Lazy loading: All plugins triggered via `User VeryLazy` autocmd
- Bytecode cache enabled in `custom/startup.lua`
