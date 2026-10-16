# Go Language Support Documentation

## Overview

Complete Go development setup: LSP (gopls), formatting, linting, debugging, project running, and syntax highlighting.

## Components

| Component | Tool | Config Location |
|-----------|------|-----------------|
| **LSP** | gopls | `lua/lsp/servers/golang.lua` |
| **Formatters** | gofumpt + goimports | `lua/lsp/servers.lua` (formatter spec) |
| **Linter** | golangci-lint | `lua/lsp/servers.lua` (M.linters) |
| **Debugger** | delve + nvim-dap-go | `lua/plugins/dap.lua` |
| **Project Runner** | coderunner | `lua/custom/coderunner.lua` |
| **Treesitter** | go, gomod, gowork, gosum | `lua/plugins/treesitter.lua` |

## LSP Configuration (`golang.lua`)

### gopls Settings

```lua
settings = {
  gopls = {
    gofumpt = true,           -- Stricter formatting
    staticcheck = true,       -- Static analysis
    usePlaceholders = true,   -- Function parameter placeholders
    completeUnimported = true, -- Auto-import on completion
    analyses = {
      nilness = true,
      unusedparams = true,
      unusedwrite = true,
      useany = true,
    },
    hints = {
      assignVariableTypes = true,
      compositeLiteralFields = true,
      compositeLiteralTypes = true,
      constantValues = true,
      functionTypeParameters = true,
      parameterNames = true,
      rangeVariableTypes = true,
    },
    codelenses = {
      gc_details = false,
      generate = true,
      regenerate_cgo = true,
      run_govulncheck = true,
      test = true,
      tidy = true,
      upgrade_dependency = true,
      vendor = true,
    },
    semanticTokens = true,
    directoryFilters = { '-.git', '-.vscode', '-.idea', '-.vscode-test', '-node_modules' },
  },
}
```

### Filetypes & Root

- Filetypes: `go`, `gomod`, `gowork`, `gotmpl`
- Root markers: `go.work`, `go.mod`, `.git`

## Formatters (conform.nvim)

| Formatter | Mason Package | Purpose |
|-----------|---------------|---------|
| `gofumpt` | `gofumpt` | Stricter gofmt (enforces more rules) |
| `goimports` | `goimports` | Import organization + formatting |

**Order**: `goimports` runs first (organizes imports), then `gofumpt` (formats).

## Linter (nvim-lint)

| Linter | Mason Package | Trigger Events |
|--------|---------------|----------------|
| `golangcilint` | `golangci-lint` | `BufEnter`, `BufWritePost`, `InsertLeave` |

## Debugger (DAP)

### Adapter: delve (via nvim-dap-go)

- Auto-configured by `require('dap-go').setup({})`
- No manual adapter/config needed

### Keymaps (shared with DAP core)

| Key | Action |
|-----|--------|
| `<leader>dc` | Start/Continue debugging |
| `<leader>db` | Toggle breakpoint |
| `<leader>di` / `<leader>dO` / `<leader>do` | Step into/over/out |
| `<leader>du` | Toggle DAP UI |

### Go-specific Features (dap-go)

- Auto-detects test functions
- Supports `go test -v -run` patterns
- Integrates with `go.mod` module paths

## Coderunner (`custom/coderunner.lua`)

### Single File

```lua
go = { 'go run $fileName' }
```

Keys: `<leader>rc` / `<leader>rf` (via `M.run()`), `<F5>` / `<C-F5>`

### Project

```lua
if uv_fs_stat(cwd .. '/go.mod') then return 'go run .' end
```

Key: `<leader>rp` (via `M.run_project()`)

Detects `go.mod` in project root.

## Mason Packages

```lua
-- From M.tools + server spec + formatters + linters
'gopls', 'gofumpt', 'goimports', 'golangci-lint',
'gomodifytags', 'impl', 'delve'
```

| Package | Purpose |
|---------|---------|
| `gopls` | Language server |
| `gofumpt` | Formatter (stricter) |
| `goimports` | Import organizer |
| `golangci-lint` | Linter |
| `gomodifytags` | Struct tag manipulation |
| `impl` | Interface implementation generator |
| `delve` | Debugger (DAP adapter) |

## Treesitter Parsers

Added to `lua/plugins/treesitter.lua`:

- `go` — Go source
- `gomod` — go.mod files
- `gowork` — go.work files
- `gosum` — go.sum files

## Keymaps Summary

| Key | Action | Source |
|-----|--------|--------|
| `gd` | Goto Definition | LSP |
| `gr` | Goto References | LSP |
| `<leader>ca` | Code Action | LSP |
| `<leader>cr` | Rename | LSP |
| `K` | Hover | LSP |
| `<leader>cf` | Format (goimports + gofumpt) | conform.nvim |
| `<leader>rc` / `<leader>rf` / `<F5>` / `<C-F5>` | Run file | coderunner |
| `<leader>rp` | Run project | coderunner |
| `<leader>dc` | Debug | DAP |
| `<leader>du` | Toggle DAP UI | DAP |
| `<leader>rr` (visual) | Exec selected code | REPL |

## Adding Go-specific Features

### Code Actions (via gopls codelenses)

- `generate` — Run `go generate`
- `test` — Run tests
- `tidy` — Run `go mod tidy`
- `run_govulncheck` — Security scan
- `upgrade_dependency` — Upgrade deps

### Struct Tags (gomodifytags)

```vim
:GoAddTags json
:GoRemoveTags
```

### Interface Implementation (impl)

```vim
:Impl interface_name
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| gopls not starting | Check `go` in PATH, `gopls` installed via Mason |
| Format on save not working | Verify conform.nvim config, check `format_on_save` |
| Lint not running | Check `golangci-lint` installed, verify nvim-lint autocmds |
| Debug not launching | Ensure `delve` installed, check `dap-go` setup |
| Imports not organizing | Verify `goimports` in formatters_by_ft, check Mason install |

## Version Compatibility

- gopls: v0.16+ (semantic tokens default changed in v0.22)
- delve: Latest compatible with Go version
- golangci-lint: v1.60+ recommended
