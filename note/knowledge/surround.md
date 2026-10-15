# surround.lua — Zero-GC Surround Text Objects

> **Purpose**: Minimal surround.nvim alternative with zero-GC hot path, bracket-aware pairs, and VS Code-style visual auto-wrap.
> **Location**: `lua/custom/surround.lua`
> **Triggers**: `sa` (add), `sd` (delete), `sr` (replace), visual `s` (auto-wrap)

---

## Overview

Minimal surround.nvim alternative (~200 lines) featuring:
- **Zero GC in hot path** — cached byte values, byte-based navigation
- **Bracket-aware pairs** — `()[]{}` auto-handle nesting
- **VS Code-style visual auto-wrap** — Type `s` in visual mode to wrap selection
- **UTF-8 safe** — Byte-length calculation without string allocation

---

## Supported Pairs

```lua
local surrounds = {
  ['('] = ')', [')'] = '(',  -- parentheses
  ['['] = ']', [']'] = '[',  -- brackets
  ['{'] = '}', ['}'] = '{',  -- braces
  ['<'] = '>', ['>'] = '<',  -- angle brackets
  ['"'] = '"', ["'"] = "'",  -- quotes
  ['`'] = '`',               -- backticks
}
```

Each pair cached with:
- `l_byte` / `r_byte` — First byte for O(1) comparison
- `is_bracket` — `true` for `()[]{}<>`, `false` for quotes

---

## Core Functions

| Function | Trigger | Description |
|----------|---------|-------------|
| `M.add_normal()` | `sa` | Add surround in normal mode (prompts for char) |
| `M.add_visual_interactive()` | Visual `s` + char | Wrap visual selection interactively |
| `M.delete()` | `sd` | Delete surround (prompts for char) |
| `M.replace()` | `sr` | Replace surround (prompts old → new) |
| `make_visual_handler()` | Visual `s` + char | VS Code-style auto-wrap |

---

## Zero-GC Hot Path Techniques

### Cached Byte Values

```lua
for _, pair in pairs(surrounds) do
  pair.l_byte = str_byte(pair[1])  -- First byte cached
  pair.r_byte = str_byte(pair[2])
  pair.is_bracket = pair[1] ~= pair[2]
end
```

### UTF-8 Byte Length (Zero Allocation)

```lua
local function get_utf8_len(line, col)
  if col >= #line then return 0 end
  local b = line:byte(col)
  if b < 0x80 then return 1 end
  if b < 0xE0 then return 2 end
  if b < 0xF0 then return 3 end
  return 4
end
```

- Uses `line:byte(col)` — no substring
- Cached byte constants (0x80, 0xE0, 0xF0)

### Bracket-Aware Matching

```lua
if pair.is_bracket then
  -- Handle nesting: count opening/closing brackets
  -- Skips matched pairs to find true boundary
end
```

---

## Visual Auto-Wrap (VS Code Style)

```lua
-- In visual mode, press 's' then surround char
-- Wraps selection with pair
vim.keymap.set('x', 's', function()
  local char = get_char('Surround with: ')
  local pair = surrounds[char]
  apply_visual_surround(pair[1], pair[2])
end)
```

---

## Keymappings

| Mode | Key | Action |
|------|-----|--------|
| `n` | `sa` | Add surround (prompts char) |
| `x` | `s` | Visual auto-wrap (prompts char) |
| `n` | `sd` | Delete surround (prompts char) |
| `n` | `sr` | Replace surround (prompts old→new) |

---

## UTF-8 Safety

| Operation | Method |
|-----------|--------|
| Cursor position | `api.nvim_win_get_cursor()` → 1-indexed → convert to 0-indexed |
| Character insertion | `api.nvim_buf_set_text()` with byte offsets |
| Deletion | `api.nvim_buf_set_text()` with empty table `{}`
| Byte offsets | `str_byte()` + `get_utf8_len()` for multi-byte chars |

---

## Related Files

- `lua/config/keymaps.lua` — Keymap registration
- `lua/plugins/surround.lua` — surround.nvim (not used)

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Byte-based navigation | Zero allocation, LuaJIT-friendly |
| Cached byte values | O(1) pair lookup in hot path |
| Bracket nesting logic | Correctly handles `(foo(bar))` |
| Visual `s` key | VS Code muscle memory |
| No external deps | surround.nvim is 800+ lines; this is ~200 |