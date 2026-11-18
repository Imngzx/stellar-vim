# DAP (Debug Adapter Protocol) Documentation

## Overview

Debug configuration using `nvim-dap` with UI, virtual text, and language-specific adapters.

## Plugin Spec (`lua/plugins/dap.lua`)

### Plugins Loaded

| Plugin | Purpose |
|--------|---------|
| `mfussenegger/nvim-dap` | Core DAP client |
| `rcarriga/nvim-dap-ui` | Debug UI (panels, watches, stacks) |
| `theHamsta/nvim-dap-virtual-text` | Inline variable values |
| `mfussenegger/nvim-dap-python` | Python debug adapter (debugpy) |
| `leoluz/nvim-dap-go` | Go debug adapter (delve) |

### Dependencies

- `nvim-neotest/nvim-nio` (required by dap-ui)

### Keymaps

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>du` | `dapui.toggle()` | Toggle DAP UI |
| `<leader>db` | `dap.toggle_breakpoint()` | Toggle breakpoint |
| `<leader>dB` | `dap.set_breakpoint(condition)` | Conditional breakpoint |
| `<leader>dc` | `dap.continue()` | Continue / Start debugging |
| `<leader>dC` | `dap.run_to_cursor()` | Run to cursor |
| `<leader>dg` | `dap.goto_()` | Go to line (no execute) |
| `<leader>di` | `dap.step_into()` | Step into |
| `<leader>dO` | `dap.step_over()` | Step over |
| `<leader>do` | `dap.step_out()` | Step out |
| `<leader>dj` | `dap.down()` | Down stack frame |
| `<leader>dk` | `dap.up()` | Up stack frame |
| `<leader>dl` | `dap.run_last()` | Run last configuration |
| `<leader>dp` | `dap.pause()` | Pause execution |
| `<leader>dr` | `dap.repl.toggle()` | Toggle REPL |
| `<leader>ds` | `dap.session()` | Show session info |
| `<leader>dt` | `dap.terminate()` | Terminate session |
| `<leader>dw` | `dap.ui.widgets.hover()` | Evaluate expression under cursor |

**Python-specific** (note the inconsistent prefixes):

| Key | Action |
|-----|--------|
| `<localleader>dT` | `dap-python.test_method()` |
| `<leader>dTC` | `dap-python.test_class()` |

The whole spec is lazy-loaded on first use of any of these keys.

## Configuration (`config` function)

- **Signs**: custom icons for `DapBreakpoint`, `DapBreakpointCondition`, `DapLogPoint`, `DapStopped`, `DapBreakpointRejected`.
- **Auto UI**: dap-ui opens on `event_initialized` and closes on `event_terminated` / `event_exited` (listener key `dapui-auto-open` / `dapui-auto-close`).
- **nvim-dap-virtual-text**: default setup.

### Adapters & configurations

| Language | Adapter | Configuration |
|----------|---------|---------------|
| C / C++ / Rust | `codelldb` (server, Mason binary; `codelldb.cmd` on Windows) | `Launch file`: prompts for executable (default `cwd/`), `stopOnEntry = false`. `c` and `rust` reuse the `cpp` table |
| Zig | `codelldb` | `Launch Zig`: prompts for executable (default `cwd/zig-out/bin/`), `stopOnEntry = true` |
| Go | delve, registered by `require('dap-go').setup({})` | from dap-go |
| Python | debugpy, via `require('dap-python').setup('python3', {})` | from dap-python |

> [!NOTE]
> dap-python is given `python3` from PATH, so debugpy must be importable by that interpreter; the Mason `debugpy`
> package is not wired into this config.

## Mason Packages

Listed in `M.tools` (`lua/lsp/servers.lua`); installed when the Mason panel is opened with `<leader>pm`.


| Package | Language | Purpose |
|---------|----------|---------|
| `codelldb` | C/C++/Rust/Zig | Debug adapter |
| `debugpy` | Python | Listed in `M.tools`, but not used by dap-python here (see note above) |
| `delve` | Go | Debug adapter (used by dap-go) |

## Adding a New Language

1. **Ensure Mason package** exists for the debug adapter
2. **Add adapter** in `dap.adapters.<name>` (if not auto-registered by plugin)
3. **Add configuration** in `dap.configurations.<filetype>`
4. **Add keymaps** if language-specific actions needed
5. **Add to `M.tools`** in `lua/lsp/servers.lua` so `<leader>pm` installs it

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Adapter not found | Check Mason package installed, verify `command` path |
| Breakpoints not hit | Ensure debug build (`-g` flag), check `stopOnEntry` |
| UI not opening | Verify `dapui.setup()` called, check listeners |
| Python not working | `python3 -c "import debugpy"` must succeed |
| Go not working | Ensure `delve` (`dlv`) is installed |

