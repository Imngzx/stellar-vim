# Go Language Support Documentation

## Overview

Go setup: LSP (gopls), formatting, linting, debugging, file/project running, and syntax highlighting.

## Components

| Component | Tool | Config Location |
|-----------|------|-----------------|
| **LSP** | gopls | `lua/lsp/servers/golang.lua`, registry entry `gopls` in `lua/lsp/servers.lua` |
| **Formatters** | gofumpt + goimports | `lua/lsp/servers.lua` (gopls `formatter` + `goimports` formatter-only entry) |
| **Linter** | golangci-lint | `lua/lsp/servers.lua` (`M.linters.golangcilint`) |
| **Debugger** | delve via nvim-dap-go | `lua/plugins/dap.lua` |
| **Runner** | coderunner | `lua/custom/coderunner.lua` |
| **Completion menu** | colorful-menu (`gopls` entry) | `lua/plugins/colorful-lsp-menu.lua` |
| **Treesitter** | go, gomod, gowork, gosum | `lua/plugins/treesitter.lua` |

## LSP (`golang.lua`)

- Filetypes: `go`, `gomod`, `gowork`, `gotmpl`; root markers: `go.work`, `go.mod`, `.git`
- Notable gopls settings: `gofumpt`, `staticcheck`, `usePlaceholders`, `completeUnimported`, `semanticTokens`;
  extra analyses (`nilness`, `unusedparams`, `unusedwrite`, `useany`); all inlay hints on; codelenses on except
  `gc_details`; `directoryFilters` excludes `.git`, `.vscode`, `.idea`, `.vscode-test`, `node_modules`.
- Inlay hints are auto-enabled on attach (see `lsp.md`).

## Formatters (conform.nvim)

| Formatter | Mason Package |
|-----------|---------------|
| `gofumpt` | `gofumpt` |
| `goimports` | `goimports` |

Both run on save (go is not in the `stop_after_first` list). Their relative order is **not** guaranteed:
`get_conform_config()` builds the list by hash-iterating the registry.

## Linter (nvim-lint)

`golangcilint` (Mason `golangci-lint`), run on `BufEnter` and `BufWritePost`.

## Debugger (DAP)

`require('dap-go').setup({})` registers the delve adapter and Go launch configurations; no manual adapter config.
No dap-go-specific keymaps are defined (e.g. `debug_test()` is not mapped); use the core DAP keys from `dap.md`
(`<leader>dc` start/continue, `<leader>db` breakpoint, `<leader>du` UI, ...).

## Coderunner (`custom/coderunner.lua`)

- **File** (`M.run()`; `<F5>`/`<leader>rc`, `<C-F5>`/`<leader>rf`): `go run $fileName`. `<S-F5>`/`<leader>rx` closes the runner.
- **Project** (`M.run_project()`; `<leader>rp`): `go run .` if `go.mod` exists in the **current buffer's directory**
  (checked after Cargo, `Makefile`, `build.zig`, `package.json`).

> [!NOTE]
> The Go file command has no `cd $dir`, so it runs from Neovim's cwd with only the file's basename.

## Mason Packages

`gopls`, `gofumpt`, `goimports`, `golangci-lint`, `gomodifytags`, `impl`, `delve` — installed when `<leader>pm`
(Mason panel) is used. `gomodifytags` and `impl` are only installed; no commands or keymaps wrap them in this config.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| gopls not starting | Check `go` in PATH and `gopls` installed (`<leader>pm`) |
| Lint not running | Check `golangci-lint` installed |
| Debug not launching | Ensure `delve` installed |
| Imports not organizing | Verify `goimports` appears in `require('lsp').get_conform_config().go` |
