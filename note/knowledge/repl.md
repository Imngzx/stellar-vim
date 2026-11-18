# repl.lua — In-Buffer Lua Evaluation

> **Purpose**: Run a visual selection of Lua code inside Neovim and insert the output into the buffer below the selection.
> **Location**: `lua/custom/repl.lua`
> **Loaded**: `safe_setup('custom.repl', ...)` inside the `User VeryLazy` block of `lua/config/resonance.lua`

---

## Public API

| Function | Description |
|----------|-------------|
| `M.exec(bufnr, from, to)` | Runs the text in the 0-indexed `{row, col}` range `from`–`to` (end-exclusive col) as a chunk. |
| `M.eval(bufnr, from, to)` | Same, but prefixes the **last line** with `return ` so its value is shown. |
| `M.reset_current_ctx()` | Discards the REPL environment (no keymap/command bound). |
| `M.setup()` | Registers the commands and keymaps below. |

Output (inserted as lines after the last selected line):

- `print(...)` inside the chunk is redirected into the output (non-strings via `vim.inspect`).
- Return values: first as `=> <inspect>`, further values each preceded by a `,` line. `exec` shows them too if the chunk itself `return`s.
- Errors: `[ERROR]`, the message, then a `debug.traceback()`; compile errors produce the same block.

---

## Commands & Keymaps

| Key / Command | Mode | Action |
|---------------|------|--------|
| `<leader>rr` | `v` | Exec selection |
| `<leader>re` | `v` | Eval selection |
| `:ReplExec` | — | Exec the range between the `'<` / `'>` marks |
| `:ReplEval` | — | Eval the range between the `'<` / `'>` marks |

The keymaps error with a notification if not in `v`, `V`, or `<C-v>` mode.

---

## Environment

- Chunks run with `setfenv` in a table whose `__index` is `_G`: plain globals assigned in the REPL stay in that table, while `vim`, `require`, etc. resolve through `_G`.
- One environment is shared across all buffers and persists until `M.reset_current_ctx()`.
- Lua only.

---

## Gotchas

- Visual keymaps feed `<Esc>` with `nvim_feedkeys(..., 'x')` (synchronous) and then `vim.schedule` the run, so the `'<`/`'>` marks reflect the current selection rather than the previous one.
- The commands accept a range (`range = true`) but ignore it and always read the `'<`/`'>` marks, so `:10,20ReplExec` runs the last visual selection, not lines 10–20.
- `eval` only prepends `return ` to the last line; it fails if the last line is a statement or only part of a multi-line expression.
