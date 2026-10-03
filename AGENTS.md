# Neovim Configuration — AI Development Guidelines

> **Purpose**: Step-by-step reference for AI assistants working on this Neovim configuration.  
> **Audience**: Any AI agent editing `~/.config/nvim/`.  
> **Last Updated**: 2026-10-03

---

## 1. Repository Overview

| Aspect | Detail |
|--------|--------|
| **Type** | Personal Neovim configuration (modular, lazy-loaded via resonance.nvim) |
| **Entry Point** | `init.lua` → `require('custom.startup')` → `require('config.resonance')` |
| **Core Modules** | `lua/custom/` (24 modules), `lua/plugins/` (30+ plugin configs), `lua/config/` (7 configs), `lua/libs/` (5 utilities) |
| **Plugin Manager** | `resonance.nvim` (lazy-loader wrapper around `vim.pack`, Neovim 0.13+) |
| **Config Style** | Lazy specs with triggers: `event`, `cmd`, `keys`, `ft`, `User VeryLazy` |
| **Knowledge Base** | `note/knowledge/` — auto-generated module documentation |

---

## 2. Available Tools on This Machine

| Tool | Path | Purpose |
|------|------|---------|
| `nvim` | System `nvim` (0.13+) | Headless testing: `nvim --headless -c "..." -c "qall"` |
| `lua` | Embedded in `nvim` | All Lua execution via `nvim --headless -c "lua ..."` |
| `rg` (ripgrep) | System `rg` | Fast code search |
| `git` | System `git` | Version control, `git show HEAD:<file>` for original versions |
| `bash` / `fish` | Standard | Shell commands, pipelines |
| `python3` | System `python3` | `scripts.py` utility runner |
| `fzf` | System `fzf` | Fuzzy finder (used in picker configs) |
| `fd` | System `fd` | Fast file finder (used in picker configs) |
| `lua-language-server` | `/usr/bin/lua-language-server` (pacman) | LSP diagnostics: `lua-language-server --check=FILE` |

### Benchmark Command Template

```bash
# Startup benchmark (10 runs, 3 warmup, no user config)
nvim --headless -u NONE -c "luafile ~/.config/nvim/init.lua" -c "qall"  # baseline

# With resonance
nvim --headless -u NONE -c "luafile ~/.config/nvim/init.lua" -c "lua require('custom.startup')" -c "qall"

# Direct module timing
nvim --headless -c "lua local t=vim.uv.hrtime(); require('custom.startup'); print('startup:', (vim.uv.hrtime()-t)/1e6, 'ms')" -c "qall"
```

---

## 3. Key Architecture Patterns

### Startup Sequence (`init.lua`)

```lua
-- 1. Bytecode cache + disable built-ins + UI init + power-aware picker
require('custom.startup')

-- 2. Core editor options
require('config.options')
require('config.keymaps')
require('config.autocmds')

-- 3. Plugin manager bootstrap + all plugin configs
require('config.resonance')
```

### Module Pattern (`lua/custom/*.lua`, `lua/plugins/*.lua`)

```lua
local M = {}

-- Localize globals at top
local api = vim.api
local fn = vim.fn
local uv = vim.uv
local resonance = require('resonance')

-- Lazy-require heavy deps
local function get_snacks()
  return package.loaded['snacks'] or require('snacks')
end

function M.setup()
  -- Initialization logic
end

function M.core_function()
  -- Feature implementation
end

return M
```

### Plugin Spec (via resonance.nvim)

```lua
local resonance = require('resonance')

resonance.load({
  {
    src = "https://github.com/author/plugin",
    event = { "BufReadPost", "BufNewFile" },  -- or cmd, keys, ft
    dependencies = "https://github.com/author/dep",
    build = 'make',  -- or 'npm i', function() end
    config = function()
      local plugin = require('plugin')
      plugin.setup({ ... })
    end
  },
})
```

---

## 4. Development Workflow

### Step 1: Read & Understand

```bash
# Read core entry points
read ~/.config/nvim/init.lua
read ~/.config/nvim/lua/custom/startup.lua
read ~/.config/nvim/lua/config/resonance.lua

# Read key custom modules
read ~/.config/nvim/lua/custom/session.lua
read ~/.config/nvim/lua/custom/coderunner.lua
read ~/.config/nvim/lua/custom/workspace.lua

# Read plugin configs
read ~/.config/nvim/lua/plugins/heirline.lua
read ~/.config/nvim/lua/plugins/snacks.lua
read ~/.config/nvim/lua/plugins/lsp.lua
```

### Step 2: Test Current Behavior

```bash
# Quick smoke test (full config)
nvim --headless -c "luafile ~/.config/nvim/init.lua" -c "qall"

# Test specific module
nvim --headless -c "lua require('custom.session').save()" -c "qall"

# Test resonance plugin loading
nvim --headless -c "luafile ~/.config/nvim/init.lua" -c "lua print(vim.inspect(require('resonance').plugins))" -c "qall"

# Benchmark startup
for i in {1..10}; do nvim --headless -u NONE -c "luafile ~/.config/nvim/init.lua" -c "qall"; done 2>&1 | tail -5
```

### Step 3: Make Changes

- Edit files in **config root** (`~/.config/nvim/`)
- Test immediately with headless Neovim
- For plugin changes: edit `lua/plugins/*.lua` or `lua/plugins/*/config/*.lua`

### Step 4: Verify

```bash
# Functional tests
nvim --headless -c "luafile ~/.config/nvim/init.lua" -c "lua require('custom.session').save(); print('session saved')" -c "qall"
nvim --headless -c "luafile ~/.config/nvim/init.lua" -c "lua require('custom.workspace').open()" -c "qall"

# Startup regression check
nvim --headless -u NONE -c "luafile ~/.config/nvim/init.lua" -c "qall"  # must complete < 200ms

# Config reload test
nvim --headless -c "luafile ~/.config/nvim/init.lua" -c "lua dofile(vim.env.MYVIMRC)" -c "qall"
```

### Step 5: Commit

```bash
cd ~/.config/nvim
git add lua/custom/session.lua lua/plugins/heirline.lua
git commit -m "feat(session): add auto-save on focus lost"
```

---

## 5. Critical Patterns & Conventions

### resonance.nvim Integration Rules

1. **Always use lazy triggers** — `event`, `cmd`, `keys`, `ft`; avoid `config` without trigger
2. **Wrap plugin requires in `User VeryLazy` autocmd** — prevents luajit parsing at startup (see `config/resonance.lua:55-141`)
3. **Load theme first** — `require('plugins.catppuccin')` before UI plugins to avoid flicker
4. **Call `resonance.trigger_verylazy()` at end** — fires `User VeryLazy` for deferred configs

### Performance Rules

- **Bytecode cache first**: `if vim.loader then vim.loader.enable() end` (in `startup.lua:2-4`)
- **Disable unused built-ins** — 11 plugins disabled in `startup.lua:8-23`
- **Power-aware picker** — `libs.power` switches fzf (battery) vs snacks (AC) at `startup.lua:37-44`
- **Lazy-require heavy modules** — `package.loaded['x'] or require('x')`
- **Localize globals** — `local uv = vim.uv`, `local api = vim.api` at module top

### Lua Style (Project Conventions)

- Tables over multiple returns: `{name=..., path=..., loaded=...}`
- Early returns, flat conditionals
- Comments only for *why*, not *what*
- `vim.uv` / `vim.system` over `vim.fn` in hot paths
### LuaJIT/C API Performance Rules

- **Prefer `vim.uv` sync APIs** (`fs_stat`, `fs_read`, `fs_write`) over async callbacks for small I/O — avoids callback/closure allocation.
- **Hoist FFI `cdef` and `ffi.new` to module scope** — compile once, reuse struct instances; never allocate in hot paths.
- **Use `libs.utils` OS helpers** (`is_penguin()`, `is_windows()`, `is_mac()`) — they cache `jit.os` checks; avoid inline `jit.os` duplication.
- **Use byte operations** (`str:byte(i) == N`, `bit.band`) over string sub/compare — no intermediate string allocation.
- **Numeric `for i = 1, #tbl` loops** over `ipairs`/`pairs` — avoids iterator function call overhead; JIT compiles to tight loop.
- **Hoist C-API functions to local** at module scope (bypasses metatable lookups in hot paths):
  ```lua
  local api = vim.api
  local nvim_buf_is_loaded = api.nvim_buf_is_loaded
  local nvim_buf_get_name = api.nvim_buf_get_name
  local uv_fs_stat = vim.uv.fs_stat
  local str_byte = string.byte
  local str_sub = string.sub
  local math_max = math.max
  ```
- **SoA (Struct of Arrays) over AoS** for cache-friendly access in hot loops:
  ```lua
  -- Good: parallel arrays
  local match_rows, match_cols = {}, {}
  -- Bad: array of tables
  local matches = { {row=1, col=2}, ... }
  ```
- **Avoid allocations in hot paths**: reuse tables, use `table.clear()`, pre-allocate when size known.
- **`pcall`/`xpcall` are expensive** — don't wrap every C-API call; only where failure is expected/handled.
- **`vim.schedule`/`vim.schedule_wrap`** for deferring to event loop (avoids blocking UI).
- **`local x = M.x`** for module self-references in methods (avoids table lookup per call).
### vim.async (Neovim 0.13+) — Structured Concurrency

Available in nightly/0.13+. Use for Lua coroutine-based async workflows instead of callback chains.

| Function | Purpose |
|----------|---------|
| `vim.async.run(fn, ...)` | Create task (top-level or child), returns `Task` |
| `vim.async.await(awaitable)` | Suspend until task/callback completes; raises errors |
| `vim.async.pawait(awaitable)` | Protected await → returns `ok, ...` |
| `vim.async.sleep(ms)` | Async sleep without blocking event loop |
| `vim.async.timeout(ms, task)` | Await task with deadline |
| `vim.async.iter(tasks)` | Iterator yielding completed tasks in finish order |
| `vim.async.semaphore(n)` | Limit concurrent operations |
| `vim.async.wrap(argc, fn)` | Convert callback-style fn to async fn |
| `vim.async.checkpoint()` | Process pending children/cancellation |
| `vim.async.is_closing()` | Check if current task was closed |

**Task methods:** `wait()`, `pwait()`, `close()`, `detach()`, `on_complete()`, `status()`, `completed()`, `raise_on_error()`, `traceback()`.

**Key semantics:**
- Tasks form a tree (child tasks attached to parent, parent waits for children)
- Cooperative cancellation via checkpoints (`await`, `sleep`, `checkpoint`)
- `detach()` for fire-and-forget background work
- From sync code: `task:wait()` pumps event loop; inside task: prefer `await(task)`

**Note:** Your config uses `vim.system` (subprocess spawning) — different API. `vim.async` is for Lua coroutine-based async.

### Cross-Module Communication

```lua
-- Shared state via _G
_G.MyGlobalState = _G.MyGlobalState or {}

-- Event-driven
vim.api.nvim_create_autocmd('VimLeavePre', {
  pattern = '*',
  callback = function() M.save() end
})

-- Direct require (for lightweight modules)
local utils = require('libs.utils')
```

---

## 6. Common Tasks

### Add New Custom Module (`lua/custom/newmodule.lua`)

1. Create module following pattern in §3
2. Add `require('custom.newmodule')` to `config/resonance.lua` (after core UI, before `trigger_verylazy`)
3. Create `note/knowledge/newmodule.md` with purpose, functions, keymaps
4. Add keymaps in `config/keymaps.lua` if needed

### Add New Plugin (`lua/plugins/newplugin.lua`)

1. Create file with `resonance.load({{ src=..., event=..., config=... }})`
2. Add `require('plugins.newplugin')` to `config/resonance.lua`
3. For complex plugins: create `lua/plugins/newplugin_config/` with `init.lua`, `config.lua`, etc.
4. Follow lazy trigger conventions: `event` for filetypes, `keys` for keymaps, `cmd` for commands

### Modify Heirline Statusline

1. Edit `lua/plugins/heirline_config/statusline.lua` (components)
2. Edit `lua/plugins/heirline_config/colors.lua` (color palette)
3. Test: `nvim --headless -u NONE -c "luafile ~/.config/nvim/init.lua" -c "doautocmd User VeryLazy" -c "lua vim.cmd('redrawstatus'); vim.cmd('redrawtabline'); vim.cmd('colorscheme catppuccin')" -c "qall"`

### Modify Snacks Picker Config

1. Edit `lua/plugins/snacks_config/picker.lua` or `lua/plugins/snacks.lua`
2. Power-aware: check `require('libs.power').is_ac()` for conditional features

### Update Knowledge Base

```bash
# After modifying a custom module, update its docs
# Example: coderunner.lua → note/knowledge/coderunner.md

### Add New LSP Server

1. Create server config at `lua/lsp/servers/<name>.lua`:
   ```lua
   ---@module 'lspconfig'
   return {
     mason = true/false,           -- auto-install via Mason
     cmd = { 'binary', 'args' },   -- use full path for Mason bins:
                                   -- vim.fn.stdpath('data')..'/mason/bin/<binary>'
     filetypes = { 'ft1', 'ft2' },
     root_markers = { '.git', 'config.file' },
     settings = { ... },           -- server-specific settings
   }
   ```

2. Register in `lua/lsp/init.lua`:
   - Add to `custom_servers` metatable `__index`:

     ```lua
     if k == '<server_name>' then return require('lsp.servers.<name>') end
     ```

   - Add to `custom_server_keys` list:

     ```lua
     '<server_name>',
     ```

3. Test:

   ```bash
   nvim --headless -c "luafile ~/.config/nvim/init.lua" -c "lua require('custom.startup')" -c "lua require('config.resonance')" -c "lua require('lsp.init').setup()" -c "lua vim.lsp.enable(require('lsp.init').enabled_servers)" -c "edit test.<ft>" -c "lua vim.wait(2000)" -c "lua print(vim.inspect(vim.lsp.get_clients({name='<server_name>'})))" -c "qall"
   ```

### Add Mason-only Tool (formatter/linter/debugger)

Add to `M.mason_tools` in `lua/lsp/init.lua`:

```lua
M.mason_tools = {
  -- existing tools...
  'tool-name',  -- matches Mason package name
}
```

Then press `<leader>pm` to open Mason and auto-install.

### Key Gotchas for LSP

- **Use absolute path** for Mason binaries: `vim.fn.stdpath('data') .. '/mason/bin/<binary>'`
- **`--stdio` flag** often needed for LSP servers installed via Mason
- **Filetype must match** — check `vim.filetype.match({filename='test.xxx'})`

---

## 7. Debugging Checklist

| Symptom | Check |
|---------|-------|
| Slow startup | `vim.loader.enable()` called? Built-ins disabled? `vim-startuptime` output |
| Plugin not loading | Trigger registered? `:packadd` called? Check `resonance.plugins` |
| UI flicker on theme change | Theme loaded first? `catppuccin` before `snacks`/`heirline`? |
| Keymap not working | Defined in `config/keymaps.lua` or plugin `keys` spec? `which-key` conflict? |
| LSP not attaching | `lsp.lua` config? `vim.lsp.enable()` called? Check `:LspInfo` |
| Session not restoring | `session.lua` autocmds? `VimLeavePre` firing? Check `~/.local/state/nvim/sessions/` |
| Power mode not switching | `libs.power` setup called? `/sys/class/power_supply/AC/online` readable? |

---

## 8. Reference: resonance.nvim API Used

| Function | Purpose | Config Usage |
|----------|---------|--------------|
| `resonance.load(specs)` | Register plugins lazily | `config/resonance.lua:33-141`, all `plugins/*.lua` |
| `resonance.setup(opts)` | Configure loader | `config/resonance.lua:19-27` |
| `resonance.open_ui()` | Open plugin manager UI | `config/resonance.lua:30` keymap |
| `resonance.trigger_verylazy()` | Fire `User VeryLazy` | `config/resonance.lua:145` |
| `resonance.plugins` | Access plugin table | Debugging, inspection |

### `vim.pack` API (via resonance)

| Function | Purpose |
|----------|---------|
| `vim.pack.add(specs, {confirm=false, load=false})` | Install plugins |
| `vim.pack.get(names?, {info, offline})` | Query installed |
| `vim.pack.update(names?, {force, offline})` | Update plugins |
| `vim.pack.del(names, {force})` | Delete plugins |
| `PackChanged` event | Build hooks |

---

## 9. Sync Locations

| Source (Edit Here) | Runtime (Test Here) |
|--------------------|---------------------|
| `~/.config/nvim/lua/custom/` | Loaded directly from config |
| `~/.config/nvim/lua/plugins/` | Loaded directly from config |
| `~/.config/nvim/lua/config/` | Loaded directly from config |
| `~/.config/nvim/lua/libs/` | Loaded directly from config |
| `~/.local/share/nvim/site/pack/core/opt/resonance.nvim/` | resonance.nvim itself (auto-managed) |

**Always test in runtime** — that's what Neovim actually loads.

---

## 10. Emergency: Restore Original Files

```bash
# From git HEAD (config repo)
cd ~/.config/nvim
git show HEAD:lua/custom/session.lua > lua/custom/session.lua
git show HEAD:lua/plugins/heirline.lua > lua/plugins/heirline.lua

# Re-clone resonance.nvim if corrupted
rm -rf ~/.local/share/nvim/site/pack/core/opt/resonance.nvim
nvim --headless -c "luafile ~/.config/nvim/init.lua" -c "qall"  # auto-reclones
```

---

## 11. AI Workflow & Communication Patterns

### Todo System (Mandatory for Multi-Step Work)

**Initialize at start of any multi-step task:**

```lua
todo(i="Brief purpose", op="init", list=[{"phase": "PhaseName", "items": ["Task 1", "Task 2"]}])
```

**Update as work progresses:**

```lua
todo(i="Task description", op="start", task="Task 1", phase="PhaseName")
todo(i="Task description", op="done", task="Task 1", phase="PhaseName")
```

**Phase transitions are automatic** — earliest incomplete task in phase order becomes active.

### Code Editing Patterns

#### Use `edit` tool with anchored patches (not `write` for modifications)

```lua
edit(i="Purpose", input=[[
*** Begin Patch
[~/.config/nvim/lua/custom/session.lua#HASH]
PUT 69.=69:
+  vim.notify('Session saved to ' .. target_file)
PUT 185.=185:
+  nvim_create_autocmd('FocusLost', { callback = M.save })
*** End Patch
]])
```

#### For new files, use `write`

```lua
write(i="Create new module", path="~/.config/nvim/lua/custom/newmodule.lua", content=[[
local M = {}
local api = vim.api

function M.setup()
  -- init
end

return M
]])
```

#### Use `lsp` for cross-file renames/references

```lua
lsp(action="rename", file="~/.config/nvim/lua/custom/session.lua", line=69, symbol="save", new_name="persist", apply=true)
lsp(action="references", file="~/.config/nvim/lua/custom/session.lua", line=69, symbol="save")
```

---

## 12. Module Reference Quick Index

### Core Custom Modules (`lua/custom/`)

| Module | Purpose | Key Functions | Knowledge Doc |
|--------|---------|---------------|---------------|
| `startup.lua` | Boot sequence, bytecode cache, built-in disable, power-aware picker | — | — |
| `session.lua` | Workspace persistence (git-branch-aware) | `save()`, `load(last)`, `setup()` | `note/knowledge/session.md` |
| `coderunner.lua` | Build/run integration (C/C++/Rust/Go/Python) | `run_project()`, `build_run_command()` | `note/knowledge/coderunner.md` |
| `workspace.lua` | Project navigation | `open()`, `switch()` | `note/knowledge/workspace.md` |
| `transparent.lua` | Background transparency toggle | `toggle()`, `setup()` | `note/knowledge/transparent.md` |
| `zettel.lua` | Note-taking system | `new()`, `search()`, `link()` | `note/knowledge/zettel.md` |
| `git.lua` / `git-blame.lua` | Git workflow helpers | `blame()`, `diff()`, `status()` | — |
| `repl.lua` | Interactive REPL per filetype | `open()`, `send()` | — |
| `todo.lua` | Code annotation search (TODO/FIXME) | `search()`, `list()` | — |
| `ui2.lua` | UI enhancements | `setup()` | — |
| `word-jump.lua` | Navigation utilities | `jump()`, `setup()` | — |
| `cheatsheet.lua` | Quick reference system | `show()`, `build()` | — |
| `sudo.lua` | Elevated privilege commands | `write()`, `read()` | — |
| `language-switcher.lua` | Language toggling | `toggle()`, `setup()` | — |
| `pairs.lua` | Utility functions | various | — |
| `incline.lua` | LSP client management | `setup()` | — |
| `color-list.lua` | Color scheme tools | `list()`, `preview()` | — |
| `surround.lua` | Surround text objects | `setup()` | — |
| `lsp-loading.lua` | LSP progress UI | `setup()` | — |

### Key Plugin Configs (`lua/plugins/`)

| Config | Plugin | Trigger | Notes |
|--------|--------|---------|-------|
| `heirline.lua` | heirline.nvim | `BufReadPost`, `BufNewFile` | Statusline, tabline, winbar |
| `snacks.lua` | snacks.nvim | Various | Picker, explorer, profiler, image |
| `lsp.lua` | nvim-lspconfig + mason | `FileType` | LSP setup per language |
| `treesitter.lua` | nvim-treesitter | `BufReadPost` | Parsing, highlight, indent |
| `fzf.lua` | fzf-lua | `Cmd`/`Keys` | Fuzzy finder (battery mode) |
| `catppuccin.lua` | catppuccin | `VeryLazy` | Theme (load first) |
| `dap.lua` | nvim-dap | `Keys` | Debugging |
| `markdown.lua` | render-markdown | `FileType` | Markdown rendering |
| `cmdline.lua` | noice.nvim | `VeryLazy` | Command line UI |
| `ufo.lua` | nvim-ufo | `BufReadPost` | Folding |
| `csvview.lua` | csvview.nvim | `FileType` | CSV viewer |
| `telegram.lua` | telegram.nvim | `Cmd` | Telegram integration |

### Libraries (`lua/libs/`)

| Lib | Purpose |
|-----|---------|
| `power.lua` | AC/battery detection, auto-switch picker |
| `utils.lua` | OS detection, version checks |
| `git.lua` | Git root detection for heirline |
| `icons.lua` | Icon definitions |
| `spell.lua` | Spell check utilities |

---

*Generated 2026-08-16. Follows resonance.nvim AI_GUIDELINES.md pattern.*
