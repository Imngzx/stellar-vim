# pairs.lua — Zero-GC Auto-Pairs with Smart Backspace/CR/Quote Handling

> **Purpose**: Minimal auto-pairs implementation with smart backspace, auto-indent on CR, and triple-quote expansion. Zero GC in hot path via byte operations.
> **Location**: `lua/custom/pairs.lua`
> **Triggers**: Typing `(`, `[`, `{`, `"`, `'`, `` ` ``, `)`, `]`, `}`, `Backspace`, `CR`

---

## Overview

Minimal auto-pairs (~140 lines) featuring:
- **Zero GC in hot path** — cached byte constants, byte-based checks
- **Smart backspace** — Deletes pair if cursor between matching pair
- **Auto-indent on CR** — Expands `{<CR>}` to `{<CR>  <CR>}`
- **Triple-quote expansion** — `"""` → `""""""` with cursor in middle
- **Quote skipping** — Types closing quote only if next char isn't same

---

## Supported Pairs

```lua
local open_pairs = { ['('] = ')', ['['] = ']', ['{'] = '}' }
local close_pairs = { [')'] = true, [']'] = true, ['}'] = true }
local quotes = { ['"'] = true, ["'"] = true, ['`'] = true }
```

---

## Cached Byte Constants (Zero Allocation)

```lua
local BYTE_0 = str_byte('0')
local BYTE_9 = str_byte('9')
local BYTE_A_UPPER = str_byte('A')
local BYTE_Z_UPPER = str_byte('Z')
local BYTE_A_LOWER = str_byte('a')
local BYTE_Z_LOWER = str_byte('z')

local function is_alphanumeric(char)
  if not char or char == '' then return false end
  local b = str_byte(char)
  return (b >= BYTE_0 and b <= BYTE_9)
      or (b >= BYTE_A_UPPER and b <= BYTE_Z_UPPER)
      or (b >= BYTE_A_LOWER and b <= BYTE_Z_LOWER)
end
```

- Pre-computed ASCII boundaries
- Single `str_byte()` call per check
- No string allocation, no pattern matching

---

## Core Handlers (Factory Pattern)

### Open Handler — `(`, `[`, `{`

```lua
local function make_open_handler(key, mode)
  local insert_str = key .. open_pairs[key] .. '<Left>'
  return function() api.nvim_feedkeys(insert_str, mode, false) end
end
```

- Inserts pair + moves cursor left
- Works in insert/replace modes

### Close Handler — `)`, `]`, `}`

```lua
local function make_close_handler(key, mode)
  return function()
    local left, right, line, col = get_context(mode)
    if right == key then
      -- Cursor at closing bracket → skip over
      return api.nvim_replace_termcodes('<Right>', true, false, true)
    else
      -- Normal insert
      return key
    end
  end
end
```

- **Smart skip**: If next char is matching close, move right instead of inserting
- Prevents double `))`

### Quote Handler — `"`, `'`, `` ` ``

```lua
local function make_quote_handler(key, mode)
  local double_key = key .. key
  local triple_quotes = { ['"'] = '"""', ["'"] = "'''", ['`'] = '```' }
  
  return function()
    local left, right, line, col = get_context(mode)
    
    -- Skip if next char is same quote
    if right == key then return '<Right>' end
    
    -- Triple-quote expansion
    if left == key and line:sub(col - 2, col) == double_key then
      return triple_quotes[key] .. '<Left><Left>'
    end
    
    -- Normal pair
    return key .. key .. '<Left>'
  end
end
```

**Behaviors:**
| Context | Input | Result |
|---------|-------|--------|
| `""` (cursor between) | `"` | Skip right |
| `"""` | `"` | Expand to `""""""` |
| Start of line | `"` | `""` + cursor inside |

### Backspace Handler

```lua
local function make_bs_handler(mode)
  return function()
    local left, right, line, col = get_context(mode)
    
    -- Delete pair if cursor between matching brackets
    if open_pairs[left] and open_pairs[left] == right then
      return '<BS><Del>'
    end
    
    -- Handle triple-quote backspace
    if triple_quotes[left] and line:sub(col - 2, col + 1) == triple_quotes[left] then
      return '<BS><Del><Del>'
    end
    
    return '<BS>'
  end
end
```

**Behaviors:**
| Context | Backspace | Result |
|---------|-----------|--------|
| `(|)` (cursor between) | `<BS>` | Deletes both |
| `"""|"""` | `<BS>` | Deletes 3 quotes each side |
| Normal | `<BS>` | Standard backspace |

### CR Handler — Auto-Indent

```lua
local function make_cr_handler(mode)
  return function()
    local left, right, line, col = get_context(mode)
    
    -- Auto-indent: {<CR>} → {<CR>  <CR>}
    if open_pairs[left] and open_pairs[left] == right then
      return '<CR><Esc>O'
    end
    
    return '<CR>'
  end
end
```

---

## Context Detection (Unified)

```lua
local function get_context(mode)
  local line, col
  if mode == 'i' then
    local cursor = get_cursor()
    line = get_line()
    col = cursor[2]
  else
    line = get_line()
    col = #line
  end
  return str_sub(line, col, col), str_sub(line, col + 1, col + 1), line, col
end
```

- Single function for all handlers
- Works in insert/replace/command modes
- Returns: `left_char`, `right_char`, `full_line`, `cursor_col`

---

## Setup & Configuration

```lua
M.config = {
  enable_cmdline = true,  -- Also work in command mode
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  
  local bind = vim.keymap.set
  
  for key in pairs(open_pairs) do
    bind('i', key, make_open_handler(key, 'i'))
    bind('i', open_pairs[key], make_close_handler(open_pairs[key], 'i'))
  end
  
  for key in pairs(quotes) do
    bind('i', key, make_quote_handler(key, 'i'))
  end
  
  bind('i', '<BS>', make_bs_handler('i'))
  bind('i', '<CR>', make_cr_handler('i'))
  
  if M.config.enable_cmdline then
    -- Repeat for 'c' (command) mode
  end
end
```

---

## Keymappings (Auto-Registered)

| Mode | Key | Action |
|------|-----|--------|
| `i` | `(`, `[`, `{` | Insert pair + move left |
| `i` | `)`, `]`, `}` | Smart skip or insert |
| `i` | `"`, `'`, `` ` `` | Pair + skip / triple-quote |
| `i` | `<BS>` | Delete pair / triple-quote |
| `i` | `<CR>` | Auto-indent on `{<CR>}` |

---

## Performance

| Technique | Benefit |
|-----------|---------|
| Cached byte constants | No ASCII recalculation |
| `str_byte()` + `str_sub()` | Zero allocation |
| Factory closures | No conditionals in hot path |
| Single `get_context()` | Shared logic, no duplication |

---

## Configuration

```lua
require('custom.pairs').setup({
  enable_cmdline = true,  -- default: true
})
```

---

## Related Files

- `lua/config/keymaps.lua` — Optional additional keymaps
- `lua/plugins/pairs.lua` — nvim-autopairs (not used)

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Factory closures | Handlers pre-bound, no conditionals per keystroke |
| Byte constants | ASCII checks without string allocation |
| Triple-quote expansion | Python/docstring workflow |
| Skip-on-match | Prevents `))`, `""` double-typing |
| Context unification | Single source of truth for cursor state |