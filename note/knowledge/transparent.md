# transparent.lua — Background Transparency Toggle

> **Purpose**: Toggle background transparency by stripping `bg`/`ctermbg` from highlight groups, with the state saved across sessions.
> **Location**: `lua/custom/transparent.lua`
> **Loaded by**: `config/resonance.lua` → `safe_setup('custom.transparent', require('custom.transparent').setup, { auto_enable = false })` (inside the `User VeryLazy` block). The commands and keymap are created at module load.

---

## Public API

| Function | Description |
|----------|-------------|
| `M.setup(opts?)` | Merge options, read the saved state, apply it (scheduled), register the `ColorScheme` re-apply autocmd |
| `M.enable()` | Set `vim.g.bg_transparent = true`, save the state, `M.clear()` |
| `M.disable()` | Set it to false, save the state, stop pending timers, restore saved highlights, `redraw!` |
| `M.toggle(opt?)` | Set state to `opt` when given, otherwise flip it, then call `enable`/`disable` |
| `M.clear()` | If enabled: strip backgrounds now and again after 800 ms, fire `User TransparentClear`, call `on_clear()` |

## Commands & Keymaps

| Command / Key | Action |
|---------------|--------|
| `:TransparentEnable` | `M.enable()` |
| `:TransparentDisable` | `M.disable()` |
| `:TransparentToggle` | `M.toggle(...)` (takes no arguments) |
| `<leader>ut` (n) | `M.toggle()` |

## Options (`setup`)

| Option | Default | Description |
|--------|---------|-------------|
| `groups` | `Normal`, `NormalNC`, `SignColumn`, `LineNr`, syntax groups, … | Core groups to clear (replaced, not merged, if passed) |
| `extra_groups` | Snacks picker, floats, Blink.cmp, WinBar, DropBar, … | Additional groups to clear |
| `exclude_groups` | `{}` | Groups never to clear (see gotchas) |
| `on_clear` | no-op | Called after every `M.clear()` |
| `auto_enable` | `nil` | `true`/`false` overrides the saved state at setup and writes it back |

`vim.g.transparent_groups` (a table) adds more groups at clear time.

## State & Behavior

- State lives in `vim.g.bg_transparent` and is saved as `true`/`false` in `stdpath('data')/transparent_state`. Reads and writes use `vim.async` but are awaited with `pwait()`, so they block.
- Only non-linked groups are touched. A group's original definition is cached on first clear and restored by `disable()`.
- The 800 ms second pass catches plugins that set highlights late. `ColorScheme` drops the highlight cache and re-clears when enabled.
- `M.clear()`/`M.disable()` call `require('snacks').util.stop` for the timers.

## Gotchas

- `config/resonance.lua` passes `auto_enable = false`, so every startup forces transparency off and overwrites the saved state. In practice the state does not persist.
- `exclude_set` is built from the default `exclude_groups` at module load, so `exclude_groups` passed to `setup()` has no effect.
- `:TransparentToggle` passes the command's args table to `M.toggle(opt)`. `opt` is non-nil, so the command always enables and never toggles off. Use `<leader>ut` instead.
