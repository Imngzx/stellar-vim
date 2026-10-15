# repl.lua — VibeREPL: In-Buffer Code Evaluation

> **Purpose**: Interactive REPL for evaluating code selections in any language. Supports visual/normal modes with persistent environment per session.
> **Location**: `lua/custom/repl.lua`
> **Triggers**: `<Leader>re` (eval selection), `<Leader>rr` (exec selection)

---

## Overview

Minimal REPL (~170 lines) featuring:
- **Per-session environment** — Isolated `_G` per evaluation session
- **Visual/Normal mode** — Eval or exec selected code
- **Persistent context** — Variables persist across evaluations
- **Safe execution** — `pcall`/`xpcall` with traceback
- **Async-friendly** — `vim.schedule` for visual mode

---

## Core Architecture

### Persistent Context

```lua
local CurrCtx = nil

local function new_env()
  return setmetatable({}, { __index = _G })  -- Isolated env, falls back to _G
end

local function ensure_ctx()
  if not CurrCtx then CurrCtx = { env = new_env() } end
  return CurrCtx
end

function M.reset_current_ctx()
  CurrCtx = { env = new_env() }  -- Fresh environment
end
```

- Each REPL session gets isolated environment
- Inherits from `_G` (Neovim globals, stdlib)
- `M.reset_current_ctx()` clears state

---

## Core Functions

| Function | Trigger | Description |
|----------|---------|-------------|
| `M.exec(bufnr, from, to)` | `<Leader>rr` | Execute statements (no return values shown) |
| `M.eval(bufnr, from, to)` | `<Leader>re` | Evaluate expressions (shows return values) |
| `M.reset_current_ctx()` | — | Reset REPL environment |

---

## Evaluation Flow

### `repl_impl(lines)` — Core Evaluator

```lua
local function repl_impl(lines)
  local ctx = ensure_ctx()
  local chunk, err = load(table.concat(lines, '\n'), 'REPL', 't', ctx.env)
  if not chunk then return { err = err } end

  local results = { pcall(chunk) }
  local ok = table.remove(results, 1)
  if not ok then return { err = results[1] } end
  return results  -- Return values as array
end
```

- `load(..., 't', ctx.env)` — Compile with isolated env
- `pcall` — Safe execution, captures errors
- Returns array of results or `{ err = ... }`

### Line Extraction

```lua
local function get_lines(bufnr, from, to)
  local ok, ret = pcall(nvim_buf_get_text, bufnr, from[1], from[2], to[1], to[2])
  if not ok then return {} end
  return ret
end
```

- Supports both line-wise and character-wise ranges
- Handles visual/normal mode ranges

---

## Execution Modes

### Exec Wrapper (Normal Mode)

```lua
local function exec_wrapper(fn)
  local buf = nvim_get_current_buf()
  local from = { nvim_buf_get_mark(buf, '[') }
  local to = { nvim_buf_get_mark(buf, ']') }
  fn(buf, from, to)
end
```

- Uses `'[` and `']` marks (last visual selection or current line)
- Synchronous execution

### Visual Wrapper

```lua
local function visual_wrapper(fn)
  local mode = nvim_get_mode().mode
  if mode == 'v' or mode == 'V' or mode == '\22' then
    change_mode('x')  -- Exit visual mode first
  end
  schedule(function() exec_wrapper(fn) end)
end
```

- Exits visual mode before getting marks (`'x` feedkey)
- `vim.schedule` defers to next event loop tick

---

## Keymappings

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<Leader>rr` | Execute selection (statements) |
| `x` | `<Leader>rr` | Execute visual selection |
| `n` | `<Leader>re` | Evaluate selection (expressions) |
| `x` | `<Leader>re` | Evaluate visual selection |

---

## Output Handling

```lua
-- In M.exec / M.eval:
local results = repl_impl(lines)
if results.err then
  vim.notify('[VibeRepl] Error: ' .. results.err, vim.log.levels.ERROR)
else
  local output = vim.inspect(results)
  vim.notify('[VibeRepl] Result: ' .. output, vim.log.levels.INFO)
end
```

- Errors → `vim.notify` ERROR level
- Results → `vim.inspect` → `vim.notify` INFO level
- `vim.inspect` handles tables, functions, nil, etc.

---

## Visual Mode Fix

```lua
local function change_mode(mode_key)
  -- Fix: use 'x' not 'n' to synchronously exit Visual mode
  nvim_feedkeys(nvim_replace_termcodes(mode_key, true, false, true), 'x', false)
end
```

- **Problem**: `get_mark('[')` returns old position if still in visual mode
- **Fix**: Feed `'x` (exit visual) synchronously before reading marks

---

## Environment Isolation

```lua
local function new_env()
  return setmetatable({}, { __index = _G })
end
```

| Feature | Behavior |
|---------|----------|
| Variable assignment | Stays in REPL env (`CurrCtx.env`) |
| Global access | Falls back to `_G` (vim, require, etc.) |
| Module loading | `require` works via `_G` fallback |
| Reset | `M.reset_current_ctx()` creates fresh env |

---

## Keymappings (Registered in setup)

```lua
function M.setup()
  local map = vim.keymap.set
  map({ 'n', 'x' }, '<Leader>rr', visual_wrapper(M.exec), { silent = true, desc = 'Exec selected code' })
  map({ 'n', 'x' }, '<Leader>re', visual_wrapper(M.eval), { silent = true, desc = 'Eval selected code' })
end
```

| Key | Mode | Function |
|-----|------|----------|
| `<Leader>rr` | `n`, `x` | Execute (statements) |
| `<Leader>re` | `n`, `x` | Evaluate (expressions) |

---

## Use Cases

| Scenario | Command |
|----------|---------|
| Test Lua snippet | Select lines → `<Leader>re` |
| Run multiple statements | Select block → `<Leader>rr` |
| Inspect variable | `x = 1 + 1` → `<Leader>re` → shows `2` |
| Test function | Define fn → call it → `<Leader>re` |
| Reset state | `<Leader>rr` on `M.reset_current_ctx()` call |

---

## Related Files

- `lua/config/keymaps.lua` — Keymap registration
- `lua/plugins/repl.lua` — Alternative REPL plugins (not used)

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Isolated env per session | Prevents pollution, allows `reset_current_ctx()` |
| `load(..., 't', env)` | Text mode, custom env, no bytecode caching issues |
| `pcall` + `vim.inspect` | Safe, readable output for any Lua value |
| Visual mode → schedule | Avoids mark-capture race condition |
| `setmetatable({}, {__index=_G})` | Full stdlib access, isolated writes |

---

## Limitations

- **Lua only** — No polyglot support (unlike IPython/Jupyter)
- **No inline display** — Results via notify, not virtual text
- **No history** — No up/down for previous expressions
- **Single buffer** — All evals share same `CurrCtx`