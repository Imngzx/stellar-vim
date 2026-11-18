# cheatsheet.lua — Dynamic Keymap Reference

> **Purpose**: Floating, read-only cheatsheet of every keymap that has a `desc`, grouped by prefix and laid out in balanced columns.
> **Location**: `lua/custom/cheatsheet.lua`
> **Loaded**: on demand via the `<leader>ch` keymap (`lua/config/keymaps.lua`); no `setup()`.

---

## Public API

| Function | Description |
|----------|-------------|
| `M.toggle()` | Closes the cheatsheet if open; otherwise builds (or reuses) the layout and opens it in a `Snacks.win` float (80%×80%, rounded, title ` 🚀 Cheatsheet `, filetype `nvcheatsheet`). |

## Keymaps

| Key | Where | Action |
|-----|-------|--------|
| `<leader>ch` | `lua/config/keymaps.lua` | `require('custom.cheatsheet').toggle()` |
| `q` / `<Esc>` | inside the float | close |

---

## Collection

- Modes `n`, `v`, `i` only: global maps (`nvim_get_keymap`) plus the **current buffer's** local maps (`nvim_buf_get_keymap(0, ...)`).
- Maps without a `desc` are skipped.
- Entries are merged by `lhs`; the badge `[NVI]` shows which modes have the map. A buffer-local map replaces the global entry's desc/modes.
- Display: leading space (leader) becomes `<Space> + `; descriptions longer than the column are cut off with `...`.

## Grouping

`group_rules` are **plain prefix matches** on the raw `lhs`, first match wins; unmatched maps go to ` General / Others`. Leader maps appear as `' a'`, `' b'`, … because `mapleader = ' '`, so the rules depend on a space leader.

| Prefix | Group |
|--------|-------|
| `<leader>a` `b` `c` `d` `f` `g` `n` `p` `r` `s` `t` `T` `u` `z` `<Tab>` | AI, Buffer/Workspace, Code/LSP, Debug, Find, Git, Minimap, Panel/Tools, Code Runner, Search Meta, Translate, Telegram, UI & Toggles, Zettelkasten, Workspace/Tabs |
| `g`, `[`, `]`, `s`, `z` | Goto/LSP, Prev, Next, Surround, Fold/UFO |
| `<C-`, `<A-`, `<S-` | Ctrl/Window, Alt/Move, Shift/Buffer |

Keys within a group are sorted by `lhs`. Each group goes into whichever column is currently shortest. The number of columns is `floor((columns * 0.8 - 4) / 52)` (at least 1).

---

## Caching

The rendered lines and extmark highlights are cached. The cache is cleared on `VimResized` or when `toggle()` is called from a different buffer than last time.

## Gotchas

- Keymaps defined after the first build (e.g., by lazily loaded plugins) don't appear until the cache is cleared (resize, or open from another buffer).
- Adding a new `<leader>` prefix group means adding a rule to `group_rules`; otherwise its maps go into General / Others.
