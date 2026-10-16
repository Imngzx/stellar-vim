# coderunner.lua — Build & Run Code with Project Detection

> **Purpose**: Compile and run single files or entire projects (C/C++, Rust, Go, Python, etc.) with project-aware commands.
> **Location**: `lua/custom/coderunner.lua`
> **Triggers**: `<F5>` / `<C-F5>` / `<leader>rc` / `<leader>rf` (run file), `<leader>rp` (run project)

---

## Overview

Minimal build/run system (~400 lines) featuring:

- **Filetype-aware commands** — Per-language run commands (cached)
- **Project detection** — Cargo.toml, Makefile, go.mod, package.json, build.zig
- **OS-specific commands** — Windows (MSVC) vs Unix (GCC/Clang)
- **Terminal execution** — Snacks.nvim terminal with pause-on-exit
- **User config** — Override via `vim.g.coderunner`

---

## Configuration (via `vim.g.coderunner`)

```lua
vim.g.coderunner = {
  c_build_type = 2,           -- 1=Release, 2=Debug (sanitizers)
  cpp_build_type = 2,
  c_extra_flags = '',         -- Extra compiler flags
  cpp_extra_flags = '',
  project_commands = {        -- Custom per-filetype commands
    -- go = { 'go run $fileName' },
  },
}
```

---

## Filetype Commands (Cached)

### Unix (GCC/Clang)

```lua
c = get_c_mode(),              -- Based on C_BUILD_TYPE
cpp = get_cpp_mode(),          -- Based on CPP_BUILD_TYPE
python = { 'cd $dir &&', 'python3 -u $fileName' },
java = { 'cd $dir &&', 'javac $fileName &&', 'java $fileNameWithoutExt' },
rust = { 'cd $dir &&', 'rustc $fileName &&', './$fileNameWithoutExt' },
typescript = { 'deno run $fileName' },
zig = { 'cd $dir &&', 'zig build run' },
go = { 'go run $fileName' },   -- Single file
```

### Windows (MSVC)

```lua
cpp = { 'cd $dir && cl /utf-8 /nologo /EHsc /O2 /std:c++latest /Zc:__cplusplus $fileName /Fe:$fileNameWithoutExt.exe && $fileNameWithoutExt.exe' },
c = { 'cd $dir && cl /utf-8 /nologo /O2 $fileName /Fe:$fileNameWithoutExt.exe && $fileNameWithoutExt.exe' },
python = { 'cd $dir &&', 'python -u $fileName' },
java = { 'cd $dir; javac $fileName; java $fileNameWithoutExt' },
rust = { 'cd $dir; rustc $fileName; .\\$fileNameWithoutExt.exe' },
typescript = { 'deno run $fileName' },
zig = { 'cd $dir &&', 'zig build run' },
```

---

## Project Detection (`build_project_command`)

| Project File | Command |
|--------------|---------|
| `Cargo.toml` | `cargo run` (with binary detection) |
| `Makefile` | `make` |
| `build.zig` | `zig build run` |
| `package.json` | `npm start` |
| `go.mod` | `go run .` |

---

## Core Functions

| Function | Description |
|----------|-------------|
| `M.build_run_command()` | Returns command for current filetype |
| `M.run()` | Execute single file command |
| `M.build_project_command()` | Detects project, returns project command |
| `M.run_project()` | Execute project command |
| `M.close()` | Kill active terminal |

---

## Keymappings

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<F5>` | Save and Run Code (`M.run`) |
| `n` | `<C-F5>` | Save and Run File (`M.run`) |
| `n` | `<leader>rc` | Run Code (same as `<F5>`) |
| `n` | `<leader>rf` | Run File (same as `<C-F5>`) |
| `n` | `<S-F5>` / `<leader>rx` | Stop / Close Runner |
| `n` | `<leader>rp` | Run Project (`M.run_project`) |

---

## Cargo Integration (Optimized)

```lua
-- Caches Cargo.toml parsing
local _cargo_toml_cache = {}

function read_cargo_toml(cargo_toml) ... end
function find_cargo_bin_name(cargo_toml, file_path) ... end
function find_package_name(cargo_toml) ... end
function cargo_project_command() ... end
```

- Parses `Cargo.toml` for `[[bin]]` or infers from `src/main.rs`
- Sync I/O (`vim.uv.fs_*`) for zero-callback overhead

---

## Terminal Execution

```lua
local function execute_cmd(cmd)
  vim.cmd('silent! write')
  local snacks = require('snacks')
  active_term = snacks.terminal.open(cmd, {
    win = { position = 'float', width = 0.8, height = 0.6 },
    interactive = true,
  })
  -- Pause on exit (platform-specific)
  -- <Esc><Esc> to exit terminal mode
end
```

---

## OS Detection & Compiler Helpers

```lua
local function get_c_mode()
  if C_BUILD_TYPE == 1 then
    -- Release: GCC -O2
  else
    -- Debug: Clang -g -fsanitize=address,undefined
  end
end
```

- Cached at first call
- Supports custom flags via `C_EXTRA_FLAGS` / `CPP_EXTRA_FLAGS`

---

## Setup

```lua
function M.setup()
  local map = vim.keymap.set
  map('n', { '<F5>', '<leader>rc' }, M.run, { desc = 'Save and Run Code' })
  map('n', { '<C-F5>', '<leader>rf' }, M.run, { desc = 'Save and Run File' })
  map('n', { '<S-F5>', '<leader>rx' }, M.close, { desc = 'Stop / Close Runner' })
  map('n', '<leader>rp', M.run_project, { desc = 'Run Project' })
end
```

---

## Related Files

- `lua/config/keymaps.lua` — Keymap registration
- `lua/plugins/snacks/terminal.lua` — Terminal config

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Per-filetype commands | Simple, explicit, cached |
| Project detection | Covers 90% of common project types |
| Snacks terminal | Consistent UI, float window, pause on exit |
| User config via `vim.g` | No setup() args needed, override anytime |
| Sync I/O for Cargo | Simpler than async, fast enough |

---

## Limitations

- **No build configs** — Single command per filetype
- **No test integration** — Run tests via project command or REPL
- **No DAP integration** — Use `<leader>dc` for debugging
- **No Windows Go detection** — Only `go run` for single file
