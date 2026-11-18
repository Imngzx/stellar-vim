# multicursor.lua — Built-in Multicursor (Neovim 0.13+) Wrapper

> **Purpose**: Ergonomic `<leader>j` keymaps over Neovim's built-in multicursor (`zq`, `Q`, `q=`, `vim._core.mcursor`).
> **Location**: `lua/custom/multicursor.lua`
> **Loaded by**: `config/resonance.lua` → `safe_setup('custom.multicursor', require('custom.multicursor').setup)` (inside the `User VeryLazy` block)
> **Dependency**: Neovim 0.13+ (`vim._core.mcursor`, no external plugins)

---

## Public API

| Function | Description |
|----------|-------------|
| `M.setup()` | Gets the `nvim.multicursor` namespace, requires `vim._core.mcursor`, registers keymaps |

Everything else is module-local. The built-in functions actually used are `mcursor.active()`, `mcursor.restore()`, `mcursor.jump(forward, count)` and `mcursor.number(start, step, format)`.

---

## Key Mappings

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>j*` | Cursor at every match of `<cword>` (sets `/` to `\V<word>`, enables `hlsearch`, runs `zqgn`) |
| `n` | `<leader>j/` | Cursor at every match of the current search pattern (`zqgn`); warns if there are no matches |
| `n` | `<leader>jn` / `<leader>jN` | `zqgn` / `zqgN` |
| `n` | `<leader>jl` | `Vzqj` (desc: each line in current paragraph) |
| `n` | `<leader>jL` | `Vzqj` (same as `<leader>jl`, desc: each line in visual selection) |
| `x` | `<leader>j` | `zq` — cursors at the following motion within the selection |
| `x` | `<leader>jl` | `vQ` (desc: each line in selection) |
| `x` | `<leader>j*` | `zqgn` within the selection |
| `n` | `<leader>jc` | Clear all cursors (clears the `nvim.multicursor` extmark namespace) |
| `n` | `<leader>jQ` | Restore the previous session's cursors (`mcursor.restore()`) |
| `n` | `<leader>jt` | Toggle follow mode (`q=`), then notify the buffer-local `'follow'` state |
| `n` | `<leader>ji` | Insert ascending numbers at cursors: `1, 2, 3…` |
| `n` | `<leader>jI` | Insert zero-padded numbers: `001, 002…` |
| `n` | `]c` / `[p` | Jump to next / previous cursor (`[count]` supported) |
| `n` | `]C` / `[C` | Jump to next / previous cursor, then `Q` to remove the cursor there |

Jump, number, and clear mappings do nothing (or warn) when no multicursor session is active.

---

## Gotchas

- `]c` overrides Vim's built-in diff-mode `]c`; `]C`/`[C` override the built-in mcursor jumps (which also work without an active session).
- `<leader>jc` clears the extmarks directly instead of using the built-in `gQ`, so it does not save the snapshot that `mcursor.restore()` (`<leader>jQ`) reads.
- `vim._core.mcursor` is an internal module and may change.
- Built-in reference: `:help zq`, `:help Q`, `:help q=`, `:help 'follow'`.
