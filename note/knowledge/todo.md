# todo.lua — Project-wide TODO/FIXME Search

> **Purpose**: Search annotated comments across the project with Snacks' grep picker.
> **Location**: `lua/custom/todo.lua`
> **Loaded**: `safe_setup('custom.todo', ...)` inside the `User VeryLazy` block of `lua/config/resonance.lua`

---

## Keywords

`TODO`, `FIXME`, `NOTE`, `WARN`, `HACK`, `PERF` (module-local `keywords` table).

The search regex is built as `\b(TODO|FIXME|NOTE|WARN|HACK|PERF):` — the word boundary avoids `NOTTODO:` and the trailing `:` limits hits to annotations rather than bare words.

---

## Public API

| Function | Purpose |
|----------|---------|
| `M.setup()` | No-op; kept so the loader call doesn't fail. Highlighting lives in `plugins/mini-hipatterns.lua`. |
| `M.search()` | Opens `snacks.picker.grep` (title `Todo Comments`, `regex = true`) with the pattern above. Silently returns if `snacks` can't be required. |

---

## Keymaps

| Key | Action | Defined in |
|-----|--------|------------|
| `<Leader>st` | `require('custom.todo').search()` | `lua/plugins/snacks/keys.lua` |

---

## Gotchas

- In-buffer keyword highlighting is done by `mini.hipatterns` (extmarks), which keeps its own keyword list in `lua/plugins/mini-hipatterns.lua`. Adding a keyword here does not highlight it, and vice versa — update both.
