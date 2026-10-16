# cheatsheet.lua — Dynamic Keymap Reference

> **Purpose**: Auto-generated, searchable cheatsheet of all keymaps grouped by category, with live highlighting and fuzzy search.
> **Location**: `lua/custom/cheatsheet.lua`
> **Trigger**: `<leader>ch` (toggle)

---

## Overview

Dynamic cheatsheet (~280 lines) featuring:

- **Auto-discovery** — Scans all keymaps from `nvim_get_keymap()` and `nvim_buf_get_keymap()`
- **Smart categorization** — Regex-based grouping (LSP, Git, UI, etc.)
- **Live highlighting** — Extmark-based key/lhs/rhs/desc coloring
- **Fuzzy search** — Snacks.picker integration
- **Cache** — Rebuilds on window resize only

---

## Group Rules (Priority Order)

```lua
local group_rules = {
  { p = '^<leader>l',  n = '󰋚 LSP',        hl = 'Title' },
  { p = '^<leader>g',  n = '󰊢 Git',        hl = 'Title' },
  { p = '^<leader>f',  n = '󰍉 Find',       hl = 'Title' },
  { p = '^<leader>b',  n = '󰓩 Buffer',     hl = 'Title' },
  { p = '^<leader>w',  n = '󰖲 Window',     hl = 'Title' },
  { p = '^<leader>t',  n = '󰈙 Toggle/Tree',hl = 'Title' },
  { p = '^<leader>c',  n = '󰘦 Code',       hl = 'Title' },
  { p = '^<leader>s',  n = '󰛔 Search',     hl = 'Title' },
  { p = '^<leader>u',  n = '󰒓 UI',         hl = 'Title' },
  { p = '^<leader>d',  n = '󰃤 Debug',      hl = 'Title' },
  { p = '^<leader>p',  n = '󰏗 Plugin/Pkg', hl = 'Title' },
  { p = '^<leader><tab>', n = '󰓩 Workspace', hl = 'Title' },
  { p = '^<leader>',   n = ' General',    hl = 'Title' },
  { p = '^g',          n = '󰑑 Go/Nav',     hl = 'Title' },
  { p = '^]',          n = '󰑑 Next/Prev',  hl = 'Title' },
  { p = '^z',          n = '󰘸 Fold',       hl = 'Title' },
  { p = '^<c-',        n = '󰘴 Ctrl',       hl = 'Title' },
  { p = '^<a-',        n = '󰘵 Alt',        hl = 'Title' },
  { p = '^<s-',        n = '󰘶 Shift',      hl = 'Title' },
}
```

- **Priority** = array order (first match wins)
- **Pattern** = Lua pattern matching on `lhs`
- **Other** = Fallback group for unmatched keymaps

---

## Data Structures

```lua
-- Raw keymaps (cached)
_maps_dict = {}   -- lhs -> keymap info
_maps_list = {}   -- Array of all keymaps

-- Column rendering data
_cols_data = {}    -- Column content per group
_cols_count = {}   -- Key count per group
_lines = {}        -- Rendered lines
_line_parts = {}   -- {text, hl} per line for extmarks
_groups = {}       -- Group metadata {name, hl, keys, count}
_other_group = { name = ' General / Others', hl = 'Title', keys = {}, count = 0 }
```

---

## Build Process

```lua
local function build_data()
  if cache_lines then return end  -- Already built
  
  -- 1. Collect all keymaps
  for _, mode in ipairs({ 'n', 'v', 'x', 's', 'o', 'i', 'c', 't' }) do
    for _, kmap in ipairs(api.nvim_get_keymap(mode)) do
      _maps_dict[kmap.lhs] = kmap
      table.insert(_maps_list, kmap)
    end
  end
  
  -- 2. Buffer-local keymaps
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(buf) then
      for _, mode in ipairs({ 'n', 'v', 'x', 's', 'o', 'i', 'c', 't' }) do
        for _, kmap in ipairs(api.nvim_buf_get_keymap(buf, mode)) do
          -- Skip duplicates
        end
      end
    end
  end
  
  -- 3. Categorize
  for _, kmap in ipairs(_maps_list) do
    local lhs = format_lhs(kmap.lhs)
    for _, rule in ipairs(group_rules) do
      if lhs:match(rule.p) then
        -- Assign to group
        break
      end
    end
  end
  
  -- 3. Build columns (balanced)
  -- 4. Format lines with extmark highlights
end
```

---

## Highlighting (Extmark-Based)

```lua
-- Per-character highlighting via extmarks
cache_em_row, cache_em_col, cache_em_end, cache_em_hl = {}, {}, {}, {}

-- Highlight groups:
-- - Key:     Key label (lhs)
-- - Desc:    Description
-- - Sep:     Separator
-- - KeySeq:  Key sequence
```

- **Extmarks** — Per-character, no syntax overhead
- **Cached** — Rebuilt only on resize

---

## Display (Snacks.picker)

```lua
function M.toggle()
  if active_win and active_win:valid() then
    active_win:close()
    return
  end
  
  build_data()
  
  local win = require('snacks').win({
    position = 'float',
    width = 0.9,
    height = 0.9,
    border = 'rounded',
    backdrop = 60,
    title = ' 󰌌 Cheatsheet ',
    title_pos = 'center',
    zindex = 50,
  })
  
  -- Set buffer lines + extmarks
  vim.bo[buf].modifiable = false
end
```

---

## Keymappings

| Key | Action |
|-----|--------|
| `<leader>ch` | Toggle cheatsheet |

---

## Group Categories

| Prefix | Group | Icon |
|--------|-------|------|
| `<leader>l` | LSP | 󰋚 |
| `<leader>g` | Git | 󰊢 |
| `<leader>f` | Find | 󰍉 |
| `<leader>b` | Buffer | 󰓩 |
| `<leader>w` | Window | 󰖲 |
| `<leader>t` | Toggle/Tree | 󰈙 |
| `<leader>c` | Code | 󰘦 |
| `<leader>s` | Search | 󰛔 |
| `<leader>u` | UI | 󰒓 |
| `<leader>d` | Debug | 󰃤 |
| `<leader>p` | Plugin/Pkg | 󰏗 |
| `<leader><tab>` | Workspace | 󰓩 |
| `<leader>` | General |  |
| `g` | Go/Nav | 󰑑 |
| `]` | Next/Prev | 󰑑 |
| `z` | Fold | 󰘸 |
| `<c-` | Ctrl | 󰘴 |
| `<a-` | Alt | 󰘵 |
| `<s-` | Shift | 󰘶 |

---

## Cache Invalidation

```lua
api.nvim_create_autocmd('VimResized', {
  callback = function()
    cache_lines = nil  -- Force rebuild on resize
  end,
})
```

- **Rebuilds** only on window resize
- **Instant toggle** — cached data reused

---

## Related Files

- `lua/config/keymaps.lua` — Keymap definitions
- `lua/plugins/snacks/keys.lua` — Additional keymaps
- `lua/plugins/which-key.lua` — Alternative keymap help

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Auto-discovery | No manual maintenance, always current |
| Regex grouping | Flexible, priority-based |
| Snacks.picker float | Consistent UI, built-in search |
| Extmark highlights | Per-character, no syntax overhead |
| Resize-only rebuild | Balance freshness vs performance |
| Buffer-local keymaps | Includes ftplugin/buffer-specific maps |

---

## Related Files

- `lua/config/keymaps.lua` — Primary keymap source
- `lua/plugins/snacks/picker.lua` — Picker config
- `lua/plugins/which-key.lua` — Alternative help
