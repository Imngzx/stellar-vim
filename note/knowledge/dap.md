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

**Python-specific** (`<localleader>` prefix):

| Key | Action |
|-----|--------|
| `<localleader>dT` | `dap-python.test_method()` |
| `<localleader>dC` | `dap-python.test_class()` |

## Configuration (`config` function)

### Sign Definitions

Custom breakpoint signs:

- `DapBreakpoint` — `` (normal)
- `DapBreakpointCondition` — `` (conditional)
- `DapLogPoint` — `` (log point)
- `DapStopped` — `` (current line)
- `DapBreakpointRejected` — `` (rejected)

### Auto UI Management

```lua
dap.listeners.after.event_initialized['dapui-auto-open'] = function() dapui.open() end
dap.listeners.before.event_terminated['dapui-auto-close'] = function() dapui.close() end
dap.listeners.before.event_exited['dapui-auto-close'] = function() dapui.close() end
```

### Adapters

#### codelldb (C/C++/Rust/Zig)

```lua
dap.adapters.codelldb = {
  type = 'server',
  port = '${port}',
  executable = {
    command = codelldb_cmd,  -- Mason path: ~/.local/share/nvim/mason/bin/codelldb
    args = { '--port', '${port}' },
  },
}
```

### Configurations

#### Zig

```lua
dap.configurations.zig = {
  {
    type = 'codelldb',
    request = 'launch',
    name = 'Launch Zig',
    program = function()
      return vim.fn.input('Path to executable: ', vim.uv.cwd() .. '/zig-out/bin/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = true,
    args = {},
  },
}
```

#### C/C++/Rust (shared)

```lua
dap.configurations.cpp = {
  {
    name = 'Launch file',
    type = 'codelldb',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to executable: ', vim.uv.cwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
  },
}
dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp
```

#### Go

Uses `nvim-dap-go` adapter (configured via `require('dap-go').setup({})`).
No manual configuration needed — delve adapter auto-registers.

#### Python

Uses `nvim-dap-python` with `debugpy` (configured via `require('dap-python').setup('python3', {})`).

## Mason Packages Required

| Package | Language | Purpose |
|---------|----------|---------|
| `codelldb` | C/C++/Rust/Zig | Debug adapter |
| `debugpy` | Python | Debug adapter |
| `delve` | Go | Debug adapter (used by dap-go) |

## Adding a New Language

1. **Ensure Mason package** exists for the debug adapter
2. **Add adapter** in `dap.adapters.<name>` (if not auto-registered by plugin)
3. **Add configuration** in `dap.configurations.<filetype>`
4. **Add keymaps** if language-specific actions needed
5. **Add to `M.tools`** in `lua/lsp/servers.lua` for Mason auto-install

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Adapter not found | Check Mason package installed, verify `command` path |
| Breakpoints not hit | Ensure debug build (`-g` flag), check `stopOnEntry` |
| UI not opening | Verify `dapui.setup()` called, check listeners |
| Python/Go not working | Ensure `dap-python`/`dap-go` setup called with correct Python/delve path |

## Integration with LSP

- DAP is independent of LSP but often uses same Mason packages
- LSP provides code intelligence; DAP provides runtime debugging
- `dap-go`/`dap-python` handle language-specific launch configurations
