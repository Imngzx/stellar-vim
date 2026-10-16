# todo.lua — Project-wide TODO/FIXME Search

> **Purpose**: Search and navigate TODO/FIXME comments across the entire project using Snacks.nvim's grep engine.
> **Location**: `lua/custom/todo.lua`
> **Trigger**: `<Leader>st` (defined in keymaps)

---

## Overview

Minimal wrapper around `snacks.picker.grep` that searches for annotated comments using a pre-defined keyword list. No custom highlighting or parsing — delegates to `mini.hipatterns` for inline highlighting and Snacks for project-wide search.

---

## Keywords Tracked

```lua
local keywords = {
  'TODO',    -- Work to be done
  'FIXME',   -- Known bug/broken code
  'NOTE',    -- Important context
  'WARN',    -- Warning/potential issue
  'HACK',    -- Temporary workaround
  'PERF'     -- Performance optimization needed
}
```

---

## Core Functions

| Function | Purpose |
|----------|---------|
| `M.setup()` | No-op — highlights handled by `mini.hipatterns` |
| `M.search()` | Opens Snacks grep picker with regex for keywords |

---

## Search Implementation

```lua
function M.search()
  local search_pattern = '\\b(' .. table.concat(keywords, '|') .. '):'
  -- Results in regex: \b(TODO|FIXME|NOTE|WARN|HACK|PERF):
  
  snacks.picker.grep({
    title = 'Todo Comments',
    prompt = ' 󰄳  ',
    search = search_pattern,
    regex = true,
  })
end
```

- **`\b`** — Word boundary (matches `TODO:` but not `NOTTODO:`)
- **`:` suffix** — Matches annotated comments (`TODO: fix this`) not bare words
- **`regex = true`** — Enables ripgrep regex engine

---

## Integration Points

| Module | Role |
|--------|------|
| `mini.hipatterns` | Inline highlighting of keywords in buffers |
| `snacks.picker` | Project-wide grep with preview, filters, actions |
| `keymaps.lua` | `<Leader>st` → `require('custom.todo').search()` |

---

## Keybindings

| Key | Action |
|-----|--------|
| `<Leader>st` | Open project-wide TODO search |

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| No custom highlight engine | `mini.hipatterns` uses extmarks (modern, no screen residue bugs) |
| Delegates grep to Snacks | Ripgrep backend, preview, filters, actions built-in |
| Keywords as table | Easy to extend, single source of truth |
| Regex word boundary | Avoids false positives (`NOTTODO:`) |

---

## Related Files

- `lua/plugins/mini-hipatterns.lua` — Inline highlighting config
- `lua/plugins/snacks/keys.lua` — `<Leader>st` keymap
- `lua/config/keymaps.lua` — Keymap registration
