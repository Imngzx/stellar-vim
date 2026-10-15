# multicursor.lua — Built-in Multicursor (Neovim 0.13+) Wrapper

> **Purpose**: Thin wrapper around Neovim's built-in `vim._core.mcursor` with ergonomic keymaps and match management.
> **Location**: `lua/custom/multicursor.lua`
> **Dependency**: Neovim 0.13+ (built-in multicursor API)

---

## Overview

Thin wrapper (~140 lines) around `vim._core.mcursor` providing:
- **Word/all-matches cursors** — `mcA` / `mcw`
- **Visual multicursor** — `mcV`
- **Numbered cursors** — `mcN` / `mcP` (padded)
- **Navigation** — `mcj` / `mck` (next/prev), with remove variants
- **Follow mode** — `mcF` toggle
- **Numbers** — `mc#` (1,2,3...) / `mc#p` (001,002...)

---

## Requirements

- **Neovim 0.13+** — Built-in `vim._core.mcursor` module
- No external plugins needed

---

## Core Functions

| Function | Trigger | Description |
|----------|---------|-------------|
| `multicursor_all_matches()` | `mcA` | All matches of current search |
| `multicursor_word_under_cursor()` | `mcw` | Word under cursor |
| `multicursor_visual_matches()` | `mcV` | Visual selection matches |
| `clear_multicursors()` | `mcc` | Clear all cursors |
| `restore_multicursors()` | `mcr` | Restore previous cursors |
| `multicursor_numbers()` | `mc#` | Number cursors 1,2,3... |
| `multicursor_numbers_padded()` | `mc#p` | Number cursors 001,002... |
| `follow_mode_state()` | `mcF` | Toggle follow mode |
| `jump_next_cursor()` | `mcj` | Jump to next cursor |
| `jump_prev_cursor()` | `mck` | Jump to prev cursor |
| `jump_next_cursor(true)` | `mcJ` | Jump next + remove |
| `jump_prev_cursor(true)` | `mcK` | Jump prev + remove |

---

## Key Mappings

| Mode | Key | Action |
|------|-----|--------|
| `n`, `x` | `mcA` | All matches of search |
| `n` | `mcw` | Word under cursor |
| `x` | `mcV` | Visual selection matches |
| `n` | `mcc` | Clear all cursors |
| `n` | `mcr` | Restore cursors |
| `n` | `mc#` | Number cursors (1,2,3) |
| `n` | `mc#p` | Number cursors (001,002) |
| `n` | `mcF` | Toggle follow mode |
| `n` | `mcj` | Jump to next cursor |
| `n` | `mck` | Jump to prev cursor |
| `n` | `mcJ` | Jump next + remove cursor |
| `n` | `mcK` | Jump prev + remove cursor |

---

## Internal API Usage

```lua
local mcursor = require('vim._core.mcursor')

-- Check active
mcursor.active()

-- Create cursors
mcursor.add()           -- Add cursor at cursor
mcursor.add_all()       -- All matches
mcursor.add_word()      -- Word under cursor
mcursor.add_visual()    -- Visual selection

-- Navigation
mcursor.jump_next()
mcursor.jump_prev()
mcursor.jump_next_remove()
mcursor.jump_prev_remove()

-- Numbers
mcursor.number(start, step, format)  -- format: '%d' or '%03d'

-- State
mcursor.follow  -- boolean, follow mode
mcursor.restore()  -- Restore saved cursors
mcursor.clear()    -- Clear all
```

---

## Search Integration

```lua
local function get_matches()
  local total = vim.fn.searchcount({ maxcount = 0 }).total
  return { total = total }
end

local function escape_search(word)
  return vim.fn.escape(word, '\\')
end
```

- Uses `vim.fn.searchcount()` for match counting
- Escapes regex special chars for word search

---

## Setup Function

```lua
function M.setup()
  ns_mc = api.nvim_create_namespace('nvim.multicursor')
  mcursor = require('vim._core.mcursor')
  setup_keymaps()
end
```

- Creates dedicated namespace
- Loads built-in multicursor module
- Registers all keymaps

---

## Visual Mode Behavior

| Mapping | Behavior |
|---------|----------|
| `mcV` | Creates cursors at each line of visual selection |
| `mcA` | Uses current search register (`/`) for all matches |
| `mcw` | Uses `<cword>` for word under cursor |

---

## Follow Mode

```lua
local function follow_mode_state()
  local state = vim.bo.follow and 'ON' or 'OFF'
  vim.notify('Follow mode is ' .. state, vim.log.levels.INFO)
end
```

- Toggles `vim.bo.follow`
- Shows notification with current state

---

## Related Files

- `lua/config/keymaps.lua` — Keymap registration
- `:help vim._core.mcursor` — Built-in API docs

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Wrapper not replacement | Uses Neovim's built-in (stable, maintained) |
| Minimal API surface | Only exposes useful keymaps |
| `vim._core.mcursor` | Official internal API (stable in 0.13+) |
| No external deps | Zero dependencies |
- `vim._core.mcursor` is internal — subject to change (low risk in 0.13+)
- No undo integration for multicursor operations
- No column-block editing (line-based only)