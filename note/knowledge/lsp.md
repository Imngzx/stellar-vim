# LSP System Documentation

## Overview

Unified LSP server + formatter + linter + Mason tool registry. Single source of truth in `lua/lsp/servers.lua`.
`lua/plugins/lsp.lua` (loaded on `User VeryLazy`) calls `require('lsp').setup()` and `lsp_config()`, then registers the
completion/format/lint plugins.

## Architecture

```text
lua/lsp/
├── init.lua       # LSP manager: registration, formatter/linter config, Mason tools
├── servers.lua    # Unified registry (servers, formatters, linters, tools)
└── servers/       # Per-language config modules
    ├── c-language.lua  # clangd (currently unused; clangd entry is commented out)
    ├── cmake.lua       # neocmake
    ├── golang.lua      # gopls
    ├── lua.lua         # lua_ls, emmylua_ls (only lua_ls is registered)
    ├── luau.lua        # luau-lsp
    ├── markdown.lua    # rumdl, markdown_oxide
    ├── python.lua      # ruff, ty, basedpyright, pyrefly (only ruff + ty registered)
    ├── qml.lua         # qmlls6
    ├── rust.lua        # rust_analyzer
    ├── vue.lua         # vtsls (currently unused; entry commented out)
    └── zig.lua         # zls
```

## Registry (`servers.lua`)

The spec format (simple / complex / formatter-only entries, formatter sub-spec, `config_module`) is documented in the
header comment of `lua/lsp/servers.lua`. Gotchas not obvious from that comment:

- **`config_key` picks a sub-table of the config module**, it does not rename the server. `register_server()` always calls
  `vim.lsp.config(name, ...)` with the registry key as `name`, using `mod[config_key or name] or mod` as the config.
  Modules returning several configs (`lua.lua`, `python.lua`, `markdown.lua`) rely on this.
- **`mason` is only checked for `~= false`** on server entries; the package name comes from `mason_name` or the server
  name. A string value (e.g. `['luau-lsp'] = { 'luau', mason = 'luau-lsp' }`) is not used as the package name.
  On formatter-only entries and formatter sub-specs, `mason` *is* the package name (`true` = formatter name).
- Several servers use `mason = have_exe('<bin>') == 0` so Mason installs them only if no system binary exists.
- Entries with `false` as config module rely on nvim-lspconfig's `lsp/<name>.lua` defaults.

### Registered servers

| Server | Filetypes / purpose | Config module | Formatter |
|--------|---------------------|---------------|-----------|
| `mesonlsp` | Meson | — | — |
| `jsonls` | JSON | — | (`jq`, formatter-only) |
| `fish_lsp` | fish | — | — |
| `emmet_language_server` | HTML/CSS abbreviations | — | — |
| `taplo` | TOML | — | `taplo` |
| `bashls` | sh, bash | — | `shfmt` |
| `html` | HTML | — | `prettier` |
| `clice` | C/C++ (system binary, not Mason) | — | `clang-format` |
| `neocmake` | CMake | `cmake` | `cmake_format` (Mason `cmakelang`) |
| `gopls` | Go | `golang` | `gofumpt` (+ `goimports`, formatter-only) |
| `zls` | Zig | `zig` | `zigfmt` |
| `rust_analyzer` | Rust | `rust` | `rustfmt` |
| `qmlls6` | QML (quickshell), system binary | `qml` | — |
| `luau-lsp` | Luau (Roblox) | `luau` | — |
| `lua_ls` | Lua | `lua` | built-in |
| `ruff` | Python lint/format | `python` | `ruff_format` |
| `ty` | Python type checker | `python` | — |
| `rumdl` | Markdown lint | `markdown` | `rumdl` |
| `md_oxide` | Markdown notes/wiki-links (Mason `markdown-oxide`) | `markdown` (`markdown_oxide` key) | — |

Formatter-only entries: `prettier` (js/jsx/ts/tsx/html/css/yaml), `shfmt`, `jq` (json), `goimports`.

Commented out: `clangd`, `basedpyright`, `vtsls` (Vue).

### Linters (`M.linters`)

`htmlhint` (html), `golangcilint` (go). Used for nvim-lint `linters_by_ft` and Mason install list.

### Mason tools (`M.tools`)

`codelldb`, `debugpy`, `shellcheck`, `mpls`, `gomodifytags`, `impl`, `delve`.

## LSP Manager (`lua/lsp/init.lua`, required as `lsp`)

### Public API

| Function / field | Description |
|------------------|-------------|
| `setup()` | Registers every non-formatter-only server via `vim.lsp.config()`, fills `enabled_servers` and `mason_tools` |
| `lsp_config()` | `vim.lsp.enable(enabled_servers)`, installs the `LspAttach` autocmd (group `LspKeymaps`), sets diagnostics config |
| `get_conform_config()` | `formatters_by_ft` for conform.nvim |
| `get_lint_config()` | `linters_by_ft` for nvim-lint |
| `get_mason_tools()` | Deduplicated list of all Mason packages: servers, formatters, linters, `M.tools` |
| `enabled_servers` | Server names passed to `vim.lsp.enable()` |
| `mason_tools` | Server packages + `M.tools` only (no formatters/linters); use `get_mason_tools()` for the full list |

Internal helpers: `register_server`, `build_by_ft`, `make_dedupe`/`dedupe`.

> [!NOTE]
> `build_by_ft()` walks the registry in sorted key order, so the order of multiple formatters for one filetype is
> deterministic and follows the registry key names (e.g. go: `goimports` from the `goimports` entry, then `gofumpt`
> from `gopls`). Rename a key to change the order.

### LspAttach behavior & keymaps (buffer-local)

Inlay hints are enabled automatically when the client supports `textDocument/inlayHint`.

| Key | Action |
|-----|--------|
| `gd` | Goto Definition |
| `gr` | Goto References |
| `gI` | Goto Implementation |
| `<leader>D` | Type Definition |
| `<leader>dS` | Document Symbols |
| `<leader>cS` | Workspace Symbols |
| `<leader>cr` | Rename Symbol |
| `<leader>ca` | Code Action (n, x) |
| `K` | Hover |
| `gK` (n) / `<C-k>` (i) | Signature Help |
| `<leader>pl` | `:checkhealth vim.lsp` |
| `<leader>cl` | Line Diagnostics (float) |
| `]d` / `[d` | Next/Prev Diagnostic (opens float after jump, honors count) |
| `]e` / `[e` | Next/Prev Error |
| `]w` / `[w` | Next/Prev Warning |

### Diagnostics config

- `virtual_text = false` (tiny-inline-diagnostic renders inline instead)
- `underline = true`, `update_in_insert = false`, `severity_sort = true`
- Rounded float border
- Sign text from the global `I.lsp` icons

## Plugins (`lua/plugins/lsp.lua`)

| Plugin | Trigger | Notes |
|--------|---------|-------|
| `mason.nvim` | `:Mason*` cmds, `<leader>pm` | `<leader>pm` opens Mason, refreshes the registry and installs anything missing from `get_mason_tools()` — Mason packages are **not** auto-installed otherwise |
| `nvim-lspconfig` | `BufReadPre`, `BufNewFile` | Provides default `lsp/<name>.lua` configs |
| `conform.nvim` | `BufReadPost`, `<leader>cf` | `formatters_by_ft` from registry; format on save (`timeout_ms = 800`, `lsp_format = 'fallback'`); `stop_after_first` only for js/jsx/ts/tsx/html/css. `<leader>cf` formats async |
| `nvim-lint` | `BufReadPre`, `BufNewFile` | `linters_by_ft` from registry; `try_lint()` on `BufEnter`/`BufWritePost` (augroup `DIY_Linting`) |
| `lazydev.nvim` | `ft = lua` | Library includes several plugins, the config `lua/` dir, yazi `types.yazi`, and Hyprland stubs (`/usr/share/hypr/stubs`) |
| `blink.cmp` (v1) | `InsertEnter`, `CmdlineEnter` | `enter` preset; disabled in prompt buffers, snacks picker input, and inside treesitter comment nodes; sources: `lazydev` first for lua, `telegram` source for telegram ft; cmdline completion enabled (`<C-y>` select+accept); labels via colorful-menu |
| `tiny-inline-diagnostic.nvim` | `BufReadPre`, `BufNewFile` | `modern` preset, shows source |

Also sets `vim.g.markdown_fenced_languages`.

## Adding a New Language

1. If custom config is needed, create `lua/lsp/servers/<name>.lua` returning a `vim.lsp.Config` (or a table of configs keyed by `config_key`)
2. Add an entry to `M.servers` in `lua/lsp/servers.lua` (formatter via `formatter` sub-spec or a formatter-only entry)
3. Linters → `M.linters`; debuggers/other tools → `M.tools`
4. Treesitter parsers → `lua/plugins/treesitter.lua`
5. Test: `nvim --headless -c "luafile ~/.config/nvim/tests/smoke.lua" -c "qall"`

> [!TIP]
> Each name only needs to be mentioned **once** in `servers.lua`; duplication is discouraged.
