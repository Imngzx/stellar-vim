# yazi.lua — Yazi Terminal File Manager Integration

> **Purpose**: Open Yazi in a Snacks float and edit the file(s) chosen in it, using Yazi's `--chooser-file`.
> **Location**: `lua/custom/yazi.lua`
> **Loaded by**: on demand from the `<leader>fy` keymap in `lua/config/keymaps.lua`

---

## Prerequisites

- `yazi` in `PATH` (otherwise `M.open()` shows an error notification titled `Stellar:Yazi`)
- `snacks.nvim` (`require('snacks').win`)

## Public API

| Function | Description |
|----------|-------------|
| `M.open()` | Open Yazi in a float (80% × 80%, rounded border, backdrop 60, zindex 45), start in terminal-insert mode |

## Keymaps

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<leader>fy` | `M.open()` (desc: Find via Yazi) |

Buffer-local terminal mappings in the Yazi window:

| Key | Action |
|-----|--------|
| `<Esc><Esc>` | Sent through to Yazi. Overrides the global `t` mapping `<Esc><Esc>` → `<C-\><C-n>` |
| `<C-\><C-n>` | Disabled (`<NOP>`), so you cannot leave terminal mode by accident |

---

## Flow

1. `os.tmpname()` creates a temp file, and Yazi runs as `yazi --chooser-file="<tmp>"` via `jobstart(..., { term = true })`.
2. When Yazi exits, the float closes. On exit code 0, the first chosen path is opened with `:edit` and the rest are added with `:badd`.
3. The temp file is removed after it is read.

## Gotchas

- The temp file is only removed on exit code 0 when it can be opened. A non-zero exit leaves it in the temp directory.
