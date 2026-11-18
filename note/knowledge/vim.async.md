# vim.async — Structured Concurrency for Neovim Lua

> **Source**: `$VIMRUNTIME/lua/vim/async.lua` (+ `lua/vim/async/_core.lua`, `_semaphore.lua`), `:h lua-async` (`doc/lua-async.txt`)
> **Available**: Nightly/0.13+ — Lua coroutine-based async workflows
> **Config Usage**: `libs/power.lua`, `custom/transparent.lua`, `custom/git-blame.lua`, `plugins/heirline/statusline.lua` (see below)

---

## Overview

`vim.async` lets Lua code wait for timers, callbacks, and other tasks without blocking Nvim's event loop. Async work runs inside **tasks**, which can pause at checkpoints and manage child tasks.

`vim.system()` is not an alternative to `vim.async` but composes with it: `SystemObj` implements `vim.async.Closable`,
so `async.await(3, vim.system, cmd, opts)` returns the result object and closing the awaiting task stops the process.

---

## Core Functions

| Function | Purpose |
|----------|---------|
| `vim.async.run([name,] fn, ...)` | Create task (top-level or child), returns `Task`; optional `name` string first |
| `vim.async.await(...)` | Suspend until done; forms: `await(task)`, `await(fn(cb))`, `await(argc, fn, ...)`; raises errors |
| `vim.async.pawait(...)` | Protected await (same forms) → returns `ok, ...` |
| `vim.async.sleep(ms)` | Async sleep without blocking event loop |
| `vim.async.timeout(ms, task)` | Await task with deadline; on expiry closes the task and raises `"timeout"` |
| `vim.async.iter(tasks)` | Iterator yielding completed task **handles** (not results) in finish order |
| `vim.async.semaphore(permits?)` | `Semaphore` (default 1 permit) with `:with(fn)`, `:acquire()`, `:release()` |
| `vim.async.wrap(argc, fn)` | Convert callback-style fn to async fn (callback at position `argc`) |
| `vim.async.checkpoint()` | Start pending children, deliver pending cancellation/failure; does **not** yield to the event loop |
| `vim.async.is_closing()` | Check if current task was closed |

---

## Task API

Created via `vim.async.run()`. Methods:

| Method | Purpose |
|--------|---------|
| `task:wait(timeout?)` | Sync wait (pumps event loop); raises `"timeout"` (task keeps running) or the task error; CTRL-C raises `"interrupted"` |
| `task:pwait(timeout?)` | `pcall(task.wait, task, timeout)` → `ok, ...` |
| `task:close(callback?)` | Request cooperative close for task + children |
| `task:detach()` | Fire-and-forget; becomes top-level, parent no longer waits; returns self |
| `task:on_complete(fn)` | Observe completion without blocking; `fn(err, ...)`; returns an unsubscribe function |
| `task:status()` | `"running" \| "awaiting" \| "normal" \| "completed"` |
| `task:completed()` | Boolean |
| `task:raise_on_error()` | Report the error (via scheduler) when an unobserved task fails; returns self |
| `task:traceback(msg?, level?)` | Get traceback when not active |

---

## Key Semantics

### Task Tree

- Tasks form a tree: child tasks attached to parent
- Parent waits for children at checkpoints
- Child created while parent running → attached, runs at parent's next checkpoint
- Unhandled child failure fails the parent, which closes the remaining children
- Awaiting a task only observes it; ownership is fixed at creation

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
- Dropping a task handle does **not** stop it; keep the handle and call `task:close()`

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

## In This Config

| File | Usage |
|------|-------|
| `lua/libs/power.lua` | `async.wrap` around `uv.fs_open/fs_read/fs_write/fs_close` and `vim.system`; named one-shot tasks (`power-linux-check`, `power-windows-check`, `power-macos-check`, `power-cache-write`) with `:raise_on_error()`, run at setup and on `FocusGained` (not polling) |
| `lua/custom/transparent.lua` | `async.pawait(argc, vim.uv.fs_*, ...)` for the state cache; `cache_read()` blocks on `task:pwait()` from sync code |
| `lua/custom/git-blame.lua` | Debounce: `task:close()` on the previous task cancels its `async.sleep(config.delay)`, then spawns `vim.system` with a plain callback (the job is killed separately) |
| `lua/plugins/heirline/statusline.lua` | `HeirlineClock` top-level task looping `async.sleep()` to the next minute boundary |

---

## Common Pitfalls

1. **Long sync loops** — nothing preempts Lua code; `checkpoint()` does not yield to the event loop, so to let the UI run use `async.sleep(0)` or `async.await(vim.schedule)`
2. **Blocking in task** — don't use `task:wait()` inside a task; use `await(task)`
3. **Unobserved detached errors** — call `task:raise_on_error()` or `task:on_complete()`
4. **Assuming preemption** — scheduling is cooperative; sync code runs to checkpoint
5. **PUC Lua 5.1 + `for task in async.iter(...)`** — the iterator may suspend; use the direct-call form if PUC Lua support matters (LuaJIT is fine)

---

## Reference Links

- `:h lua-async` / `:h vim.async` (`doc/lua-async.txt`) — full API and more examples (semaphore, timeout, pawait)
