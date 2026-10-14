# vim.async — Structured Concurrency for Neovim Lua

> **Source**: Neovim 0.13+ runtime documentation (`:h vim.async`, `lua-async.txt`)
> **Available**: Nightly/0.13+ — Lua coroutine-based async workflows
> **Config Usage**: `libs/power.lua` uses `vim.async` for power state polling

---

## Overview

`vim.async` lets Lua code wait for timers, callbacks, and other tasks without blocking Nvim's event loop. Async work runs inside **tasks**, which can pause at checkpoints and manage child tasks.

**Key distinction**: Your config uses `vim.system` (subprocess spawning) — different API. `vim.async` is for Lua coroutine-based async.

---

## Core Functions

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

---

## Task API

Created via `vim.async.run()`. Methods:

| Method | Purpose |
|--------|---------|
| `task:wait(timeout?)` | Sync wait (pumps event loop); raises on timeout/error |
| `task:pwait(timeout?)` | Protected wait → `ok, ...` |
| `task:close(callback?)` | Request cooperative close for task + children |
| `task:detach()` | Fire-and-forget; becomes top-level, parent no longer waits |
| `task:on_complete(fn)` | Observe completion without blocking |
| `task:status()` | `"running" \| "awaiting" \| "normal" \| "completed"` |
| `task:completed()` | Boolean |
| `task:raise_on_error()` | Raise error for detached/fire-and-forget tasks |
| `task:traceback(msg?, level?)` | Get traceback when not active |

---

## Key Semantics

### Task Tree

- Tasks form a tree: child tasks attached to parent
- Parent waits for children at checkpoints
- Child created while parent running → attached, runs at parent's next checkpoint

### Checkpoints (Where Task Can Pause)

Inside a task, these are checkpoints:

- `vim.async.await(...)`
- `vim.async.pawait(...)`
- `vim.async.checkpoint()`
- `vim.async.sleep(...)` (internally calls checkpoint)
- Successful return from task function (final checkpoint)

### Cooperative Cancellation

- `task:close()` marks task as closing
- Task observes at next checkpoint
- If suspended on closable operation (timer, child), that operation closed first
- Use `vim.async.is_closing()` in loops for cleanup

### Detached Tasks

- `task:detach()` → fire-and-forget background work
- Becomes top-level; original parent no longer waits/closes
- Errors don't propagate automatically → use `task:on_complete()` or `task:raise_on_error()`

---

## Usage Patterns

### Basic Async Work

```lua
local async = vim.async

async.run(function()
  vim.notify('waiting...')
  async.sleep(1000)
  vim.notify('done')
end)
```

### Await Callback-Style API

```lua
local async = vim.async

async.run(function()
  local err, stat = async.await(2, vim.uv.fs_stat, 'notes.txt')
  if err then error(err, 0) end
  print(('notes.txt is %d bytes'):format(stat.size))
end)
```

### Await with Closable Handle (Cancellation Support)

```lua
local async = vim.async

async.run(function()
  local lines = async.await(function(done)
    return start_read_lines('notes.txt', done)  -- returns closable
  end)
  render(lines)
end)
```

### Protected Await (Recoverable Failures)

```lua
local async = vim.async

async.run(function()
  local ok, text_or_err = async.pawait(async.run(read_file, 'notes.txt'))
  if not ok then text_or_err = '' end
  show_buffer(text_or_err)
end)
```

### Semaphore for Concurrency Control

```lua
local async = vim.async

async.run(function()
  local limit = async.semaphore(4)
  local tasks = {}

  for _, path in ipairs(paths) do
    table_insert(tasks, async.run(function()
      return limit:with(function()
        return read_file(path)
      end)
    end))
  end

  local next_task = async.iter(tasks)
  while true do
    local task = next_task()
    if task == nil then break end
    async.await(task)
  end
end)
```

### Timeout

```lua
local async = vim.async

async.run(function()
  local task = async.run(read_file, 'notes.txt')
  local text = async.timeout(5000, task)  -- raises "timeout" if deadline wins
  show_buffer(text)
end)
```

### Wrap Callback APIs Reusably

```lua
local async = vim.async
local fs_stat = async.wrap(2, vim.uv.fs_stat)  -- callback at arg 2

async.run(function()
  local err, stat = fs_stat(vim.api.nvim_buf_get_name(0))
  if not err and stat then print(stat.size) end
end)
```

### From Sync Code: Wait for Task

```lua
local task = vim.async.run(function()
  vim.async.sleep(100)
  return 'done'
end)

print(task:wait())  -- blocks, pumps event loop
```

---

## Task Status Values

| Status | Meaning |
|--------|---------|
| `"running"` | Task currently executing Lua code |
| `"normal"` | Task active but another coroutine running |
| `"awaiting"` | Task suspended at checkpoint or waiting for children |
| `"completed"` | Task and all attached children finished |

---

## Differences from vim.system

| Aspect | `vim.async` | `vim.system` |
|--------|-------------|--------------|
| **Purpose** | Lua coroutine async | Subprocess spawning |
| **Blocking** | Never blocks event loop | Can block if `:wait()` used |
| **Cancellation** | Cooperative (checkpoints) | Process kill |
| **Use Case** | Timers, callbacks, I/O, coordination | External commands, LSP, formatters |

---

## In This Config

**`lua/libs/power.lua`** uses `vim.async` for power state polling:

```lua
local async = vim.async
local fs_open = async.wrap(4, uv.fs_open)
local fs_read = async.wrap(4, uv.fs_read)
local fs_write = async.wrap(4, uv.fs_write)
local fs_close = async.wrap(2, uv.fs_close)
local system = async.wrap(3, vim.system)

-- Async tasks for Linux/Windows/macOS power detection
async.run('power-linux-check', function() ... end):raise_on_error()
```

**Note**: This config also uses `vim.system` directly in `zettel/init.lua` for graph generation — different API.

---

## Common Pitfalls

1. **Forgetting checkpoints** — long-running sync code never yields; use `vim.async.checkpoint()`
2. **Blocking in task** — don't use `task:wait()` inside a task; use `await(task)`
3. **Unobserved detached errors** — call `task:raise_on_error()` or `task:on_complete()`
4. **Assuming preemption** — scheduling is cooperative; sync code runs to checkpoint
5. **Confusing with vim.system** — different APIs for different purposes

---

## Reference Links

- `:h vim.async` — Full API documentation
- `:h lua-async` — Module overview
- `lua-async.txt` in runtime docs
