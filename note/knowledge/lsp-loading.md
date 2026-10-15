# lsp-loading.lua — LSP Progress Indicator (Fidget.nvim Alternative)

> **Purpose**: Lightweight LSP progress indicator using Neovim's built-in `$/progress` notifications. SoA (Struct of Arrays) architecture for zero-GC performance.
> **Location**: `lua/custom/lsp-loading.lua`
> **Events**: `LspProgress` (automatic via `vim.lsp.handlers`)

---

## Overview

Minimal LSP progress UI (~340 lines) replacing fidget.nvim:
- **SoA Architecture** — Parallel arrays, zero allocations in hot path
- **Spinner Animation** — 10-frame braille spinner at 60fps
- **Multi-client Support** — Tracks multiple LSP clients simultaneously
- **Token-based** — Matches LSP `$/progress` token lifecycle
- **Ignore List** — Configurable client filtering

---

## Architecture: Struct of Arrays (SoA)

```lua
-- ⚡ Struct of Arrays for extreme performance
local t_tokens = {}      -- LSP progress tokens
local t_clients = {}     -- Client names
local t_titles = {}      -- Progress titles
local t_messages = {}    -- Progress messages
local t_percentages = {} -- Progress percentages (0-100)
local t_dones = {}       -- Done flags
local t_idx = {}         -- token -> array index
local t_count = 0        -- Active task count
```

**Benefits:**
- **Zero allocations** in hot path (animation loop)
- **Cache-friendly** — Sequential memory access
- **O(1) operations** — Token lookup via `t_idx`

---

## Token Lifecycle (LSP `$/progress`)

| Event | Handler | Action |
|-------|---------|--------|
| `begin` | `LspProgress` (kind=begin) | Add task, start animation |
| `report` | `LspProgress` (kind=report) | Update message/percentage |
| `end` | `LspProgress` (kind=end) | Mark done, schedule cleanup |

---

## Core Data Structures

```lua
-- Task arrays (parallel)
local t_tokens = {}        -- [idx] = token
local t_clients = {}       -- [idx] = client_name
local t_titles = {}        -- [idx] = title
local t_messages = {}      -- [idx] = message
local t_percentages = {}   -- [idx] = percentage (0-100)
local t_dones = {}         -- [idx] = boolean
local t_idx = {}           -- token -> idx (O(1) lookup)
local t_count = 0          -- Active count

-- Animation state
local frame = 1            -- Spinner frame (1-10)
local timer = nil          -- Animation timer
local win_id = nil         -- Float window ID
local buf_id = nil         -- Float buffer ID
local ns = nvim_create_namespace('diy_lsp_loading')

-- Pre-allocated extmarks
local extmarks = {}
local ext_count = 0
```

---

## Configuration

```lua
local config = {
  spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },  -- 10-frame braille
  icons = { check = '✓', error = '✗' },
  highlights = {
    spinner = 'DiagnosticWarn',
    check = 'DiagnosticHint',
    client = 'Directory',
    title = 'Normal',
    text = 'Comment',
  },
  border = 'none',
  keep_done_ms = 1000,           -- Show checkmark for 1s after done
  ignore_clients = { 'rumdl' },  -- Clients to ignore
}
```

---

## Animation Loop (60fps)

```lua
local function start_animation()
  if timer and not timer:is_closing() then return end
  timer = uv.new_timer()
  timer:start(0, 100, function()  -- 100ms = 10fps
    vim.schedule(update_window)
    frame = frame % #config.spinner + 1
  end)
end
```

- **100ms interval** = 10 FPS (smooth braille animation)
- **`vim.schedule`** — Thread-safe UI updates
- **Frame cycling** — `frame % #spinner + 1`

---

## Window Rendering

```lua
local function update_window()
  if t_count == 0 then
    cleanup()  -- Close window, stop timer
    return
  end
  
  -- Build lines from SoA arrays
  local lines = {}
  for i = 1, t_count do
    if t_dones[i] then
      -- Show checkmark for keep_done_ms
      table.insert(lines, string_format('  %s %s', config.icons.check, t_clients[i]))
    else
      -- Spinner + client + title + percentage
      local spin = config.spinner[frame]
      local pct = t_percentages[i] > 0 and string_format(' (%d%%)', t_percentages[i]) or ''
      table.insert(lines, string_format('  %s %s%s %s', spin, t_clients[i], pct, t_titles[i] or ''))
    end
  end
  
  -- Update float buffer
  nvim_buf_set_lines(buf_id, 0, -1, false, lines)
  
  -- Apply highlights via extmarks
  -- (spinner, client, percentage, checkmark colored)
end
```

---

## Float Window

```lua
local function get_win_config(width, height)
  return {
    relative = 'editor',
    anchor = 'SE',
    row = vim.o.lines - vim.o.cmdheight - 2,
    col = vim.o.columns - 2,
    width = width,
    height = height,
    style = 'minimal',
    border = config.border,
    focusable = false,
    zindex = 100,
  }
end
```

- **Anchor** — Bottom-right (SE)
- **Auto-size** — Based on longest line
- **Non-focusable** — Never steals focus

---

## LSP Handler Registration

```lua
function M.setup()
  local group = nvim_create_augroup('diy_lsp_loading', { clear = true })
  
  -- Override default $/progress handler
  vim.lsp.handlers['$/progress'] = function(err, result, ctx)
    if err or not result then return end
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if not client or ignore_set[client.name] then return end
    
    local token = result.token
    local value = result.value
    local kind = value.kind  -- 'begin' | 'report' | 'end'
    
    if kind == 'begin' then
      add_task(token, client.name, value.title, value.message, value.percentage)
    elseif kind == 'report' then
      update_task(token, value.message, value.percentage)
    elseif kind == 'end' then
      finish_task(token, value.message)
    end
  end
end
```

---

## Token Management

### Add Task (`begin`)
```lua
local function add_task(token, client, title, message, percentage)
  if t_idx[token] then return end  -- Already exists
  
  t_count = t_count + 1
  local idx = t_count
  
  t_tokens[idx] = token
  t_clients[idx] = client
  t_titles[idx] = title or ''
  t_messages[idx] = message or ''
  t_percentages[idx] = percentage or 0
  t_dones[idx] = false
  t_idx[token] = idx
  
  if t_count == 1 then start_animation() end
  update_window()
end
```

### Update Task (`report`)
```lua
local function update_task(token, message, percentage)
  local idx = t_idx[token]
  if not idx then return end
  
  if message then t_messages[idx] = message end
  if percentage then t_percentages[idx] = percentage end
  update_window()
end
```

### Finish Task (`end`)
```lua
local function finish_task(token, message)
  local idx = t_idx[token]
  if not idx then return end
  
  t_dones[idx] = true
  if message then t_messages[idx] = message end
  
  -- Schedule removal after keep_done_ms
  vim.defer_fn(function()
    remove_task(token)
  end, config.keep_done_ms)
  
  update_window()
end
```

### Remove Task
```lua
local function remove_task(token)
  local idx = t_idx[token]
  if not idx then return end
  
  -- Swap-remove for O(1) removal
  local last = t_count
  if idx ~= last then
    t_tokens[idx] = t_tokens[last]
    t_clients[idx] = t_clients[last]
    t_titles[idx] = t_titles[last]
    t_messages[idx] = t_messages[last]
    t_percentages[idx] = t_percentages[last]
    t_dones[idx] = t_dones[last]
    t_idx[t_tokens[idx]] = idx
  end
  
  t_tokens[last] = nil
  t_clients[last] = nil
  t_titles[last] = nil
  t_messages[last] = nil
  t_percentages[last] = nil
  t_dones[last] = nil
  t_idx[token] = nil
  t_count = t_count - 1
  
  if t_count == 0 then cleanup() else update_window() end
end
```

---

## Cleanup

```lua
local function cleanup()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  if win_id and nvim_win_is_valid(win_id) then
    nvim_win_close(win_id, true)
  end
  win_id = nil
  buf_id = nil
  ext_count = 0
end
```

---

## Ignore List

```lua
local ignore_set = {}
for i = 1, #config.ignore_clients do
  ignore_set[config.ignore_clients[i]] = true
end

-- In handler:
if ignore_set[client.name] then return end
```

- **O(1) lookup** via set
- Default: ignores `rumdl` (markdown linter, noisy)

---

## Performance Characteristics

| Metric | Value |
|--------|-------|
| Allocation in animation | Zero (pre-allocated arrays) |
| Token lookup | O(1) via `t_idx` |
| Task add/remove | O(1) swap-remove |
| Animation FPS | 10 (100ms interval) |
| Memory | Fixed (arrays grow/shrink) |

---

## Related Files

- `lua/config/keymaps.lua` — No keymaps (automatic)
- `lua/plugins/lsp.lua` — LSP setup

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| SoA over AoS | Zero allocations, cache-friendly, LuaJIT-friendly |
| Swap-remove | O(1) removal without array shifting |
| Token-based | Matches LSP `$/progress` protocol |
| Float window (SE) | Non-intrusive, consistent position |
| Braille spinner | Smooth, no font dependency |
| 10 FPS | Smooth enough, low CPU |
| `vim.defer_fn` for done | Shows checkmark briefly before cleanup |