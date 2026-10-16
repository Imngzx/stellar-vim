# word-jump.lua — DIY Flash-Style Jump Navigation

> **Purpose**: Flash.nvim-like jump navigation with hierarchical labels, zero-GC hot path, and custom highlight groups.
> **Location**: `lua/custom/word-jump.lua`
> **Trigger**: `f` (normal, visual, operator-pending modes)

---

## Overview

Minimal Flash.nvim alternative built for:

- **Zero GC in hot path** — cached labels, cached C-API, byte operations
- **Hierarchical labels** — Single char → Double letter → Digit+letter (962 max)
- **Zero external deps** — Pure Lua + Neovim API

---

## Label Hierarchy (962 max)

```text
1-26:       a, b, c, ... z                    (single lowercase)
27-702:     aA, aB, ... zZ                   (lower + upper = 26*26)
703-962:    1a, 1b, ... 9z, 0a, ... 0z       (digit + lower = 10*26)
```

Total capacity: **962** unique jump targets per screen.

---

## Core Architecture

### Cached C-API (Hot Path Optimization)

```lua
local set_extmark = api.nvim_buf_set_extmark
local clear_namespace = api.nvim_buf_clear_namespace
local ns_id = api.nvim_create_namespace('flash_diy')
```

- Bypasses metatable lookups in jump loop
- Namespace reused, not recreated

### Pre-split Character Pools

```lua
local lower_chars, upper_chars, digit_chars = {}, {}, {}
for i = 1, 26 do lower_chars[i] = lower:sub(i, i) end
-- Avoids runtime string slicing in jump loop
```

### Byte-Based UTF-8 Navigation

```lua
local function get_utf8_len(line, col)
  local b = line:byte(col)
  if b < 0x80 then return 1 end
  if b < 0xE0 then return 2 end
  if b < 0xF0 then return 3 end
  return 4
end
```

- Zero string allocation
- Uses cached byte constants (`BYTE_0`...`BYTE_Z_LOWER`)

---

## Jump Flow

1. **`M.jump()`** called via `f` keymap
2. **Collect matches** — Scan visible window lines for alphanumeric positions
3. **Generate labels** — Hierarchical (single → double → digit+letter)
4. **Place extmarks** — Highlight labels with `FlashDiyMatch`/`FlashDiyLabel`
5. **Wait for input** — `vim.fn.getchar()` captures keystroke
6. **Match label → position** — Jump cursor, cleanup extmarks

---

## Highlight Groups

| Group | Purpose | Colors |
|-------|---------|--------|
| `FlashDiyBackdrop` | Dimmed background | `#545c7e` |
| `FlashDiyMatch` | Match highlight | `#c0caf5` on `#3d59a1` bold |
| `FlashDiyLabel` | Label highlight | `#15161e` on `#ff007c` bold |

---

## Keymappings

| Mode | Key | Action |
|------|-----|--------|
| `n`, `x`, `o` | `f` | `M.jump()` — DIY Flash Jump |

---

## Performance Characteristics

| Metric | Value |
|--------|-------|
| Max labels | 962 |
| GC in hot path | Zero (cached labels, byte ops) |
| C-API lookups | Cached at module load |
| String ops in loop | Zero (byte ops, pre-split pools) |

---

## Related Files

- `lua/config/keymaps.lua` — `f` keymap registration
- `lua/plugins/flash.lua` — Flash.nvim (alternative, not used)

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Hierarchical labels | Scales to 962 without multi-char input delay |
| Byte operations | Zero allocation, LuaJIT-friendly |
| Cached C-API | Avoids metatable overhead in jump loop |
| No external deps | Flash.nvim is 2k+ lines; this is ~200 |
| `f` key | Muscle memory compatible with Flash |
