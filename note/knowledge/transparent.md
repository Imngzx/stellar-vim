# transparent.lua — Background Transparency Toggle

> **Purpose**: Toggle Neovim background transparency with persistent state, highlight group management, and async caching.
> **Location**: `lua/custom/transparent.lua`
> **Triggers**: `<leader>ut` (toggle), `:TransparentEnable`, `:TransparentDisable`, `:TransparentToggle`

---

## Overview

Feature-complete transparency manager (~220 lines) with:
- **Persistent state** — Async cache to `~/.local/state/nvim/transparent_state`
- **Highlight group management** — Clears `bg` from configurable groups
- **Autocmd integration** — Re-applies on `ColorScheme`, `VimEnter`, `WinEnter`
- **Async I/O** — Uses `vim.async` for non-blocking cache reads/writes
- **Exclusion list** — Protects specific highlight groups (floats, statusline, etc.)

---

## Core State

| Variable | Type | Purpose |
|----------|------|---------|
| `vim.g.bg_transparent` | boolean | Current transparency state |
| `ORIGINAL_HL_CACHE` | table | Original highlight definitions for restore |
| `exclude_set` | table | Groups to never clear (O(1) lookup) |

---

## Configuration

```lua
local config = {
  enabled = false,                    -- Default off
  auto_enable = false,                -- Auto-enable on startup
  exclude_groups = {
    'NormalFloat', 'FloatBorder',     -- Floating windows
    'StatusLine', 'StatusLineNC',     -- Statuslines
    'TabLine', 'TabLineFill',         -- Tabline
    'WinBar', 'WinBarNC',             -- Winbar
    'Pmenu', 'PmenuSel', 'PmenuSbar', 'PmenuThumb', -- Popups
    'WhichKeyFloat',                  -- Which-key
    'SnacksPicker*',                  -- Snacks pickers
    'FlashDiy*',                      -- Word jump
    'Ufo*',                           -- UFO folds
    'RenderMarkdown*',                -- Markdown render
  },
  on_enable = function() end,         -- Hook
  on_disable = function() end,        -- Hook
  on_clear = function() end,          -- Hook
}
```

---

## Cache Persistence (Async)

### Read Cache
```lua
local function cache_read()
  local task = async.run(function()
    local fd = uv.fs_open(cache_path, 'r', 438)
    if not fd then return false end
    local stat = uv.fs_fstat(fd)
    local data = uv.fs_read(fd, stat.size, 0)
    uv.fs_close(fd)
    return data == '1'
  end)
  return task:pwait()
end
```

### Write Cache
```lua
local function cache_write()
  return async.run(function()
    local fd = uv.fs_open(cache_path, 'w', 438)
    if not fd then return end
    uv.fs_write(fd, vim.g.bg_transparent and '1' or '0', -1)
    uv.fs_close(fd)
  end):pwait()
end
```

- Uses `vim.async` for non-blocking I/O
- Single byte (`1`/`0`) for minimal I/O
- `pwait()` blocks until complete (setup phase)

---

## Highlight Management

### Clear Background
```lua
local function clear_group(group)
  local list = type(group) == 'string' and { group } or group
  for _, g in ipairs(list) do
    if not exclude_set[g] then
      -- Cache original if not already cached
      if not ORIGINAL_HL_CACHE[g] then
        ORIGINAL_HL_CACHE[g] = api.nvim_get_hl(0, { name = g, link = false })
      end
      -- Clear bg
      api.nvim_set_hl(0, g, { bg = 'NONE' })
    end
  end
end
```

### Restore Background
```lua
-- In M.disable():
for group, hl in pairs(ORIGINAL_HL_CACHE) do
  api.nvim_set_hl(0, group, hl)
end
```

---

## Core Functions

| Function | Command | Description |
|----------|---------|-------------|
| `M.enable()` | `TransparentEnable` | Enable transparency, cache state, clear highlights |
| `M.disable()` | `TransparentDisable` | Disable, restore highlights, cache state |
| `M.toggle(opt)` | `TransparentToggle` | Toggle or set explicit state |
| `M.clear()` | — | Apply transparency to current highlights |
| `M.setup(opts)` | — | Configure and register autocmds |

---

## Autocmd Integration

```lua
-- Re-apply on colorscheme change
api.nvim_create_autocmd('ColorScheme', {
  callback = function() M.clear() end,
})

-- Re-apply on window/tab enter
api.nvim_create_autocmd({ 'VimEnter', 'WinEnter', 'TabEnter' }, {
  callback = function() M.clear() end,
})

-- Auto-enable if configured
if config.auto_enable then M.enable() end
```

---

## Public Commands

| Command | Description |
|---------|-------------|
| `:TransparentEnable` | Enable transparency |
| `:TransparentDisable` | Disable transparency |
| `:TransparentToggle` | Toggle (or `:TransparentToggle true/false`) |

---

## Keymappings

| Key | Action |
|-----|--------|
| `<leader>ut` | Toggle transparency |

---

## State Flow

```
M.enable() → vim.g.bg_transparent = true → cache_write() → M.clear() → cache original HLs → set bg=NONE
    ↓
M.disable() → vim.g.bg_transparent = false → cache_write() → restore original HLs → redraw
    ↓
M.toggle() → reads vim.g.bg_transparent → calls enable/disable
```

---

## Performance

| Aspect | Implementation |
|--------|----------------|
| Cache I/O | Async (`vim.async`) — non-blocking |
| Exclusion check | O(1) set lookup (`exclude_set`) |
| Highlight cache | Only caches on first clear |
| Redraw | Only on disable (`vim.cmd('redraw!')`) |

---

## Hooks

| Hook | Called |
|------|--------|
| `config.on_enable()` | After enable + clear |
| `config.on_disable()` | After disable + restore |
| `config.on_clear()` | After each clear |

---

## Setup Example

```lua
require('custom.transparent').setup({
  auto_enable = false,
  exclude_groups = { 'MyCustomGroup' },
  on_enable = function() vim.notify('Transparency ON') end,
  on_disable = function() vim.notify('Transparency OFF') end,
})
```

---

## Related Files

- `lua/config/keymaps.lua` — `<leader>ut` keymap
- `lua/plugins/transparent.lua` — Alternative (not used)

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Async cache I/O | Non-blocking startup, no UI freeze |
| Exclusion set | Protects floats, statusline, popups from looking broken |
| Original HL cache | Perfect restore on disable |
| Autocmd re-apply | Handles colorscheme changes, new windows |
| Single-byte cache | Minimal I/O, atomic write |