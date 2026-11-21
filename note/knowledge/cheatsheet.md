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

- Modes `n`, `v`, `i`, `o`, `t`: global maps (`nvim_get_keymap`) plus the **current buffer's** local maps (`nvim_buf_get_keymap(0, ...)`). Buffer maps are only read when the buffer is a real file (`buftype == ''`), so the dashboard's one-letter actions stay out.
- Hidden: `<Plug>` maps and Neovim's own defaults (desc starting with `:help ` or `vim.`).
- Maps without a `desc` are skipped.
- Global and buffer-local maps are separate entries (a buffer map never hides a global one with the same `lhs`); within each, entries are merged by `lhs` and the badge `[NVIOT]` shows which modes have the map. Buffer-local descriptions start with `󰈙`.
- Display: only the leading space (leader) becomes `<Space> + `, other spaces become `<Space>`; there is always at least one space before the description, which is cut off with `...` to fit the column.

## Grouping

`group_rules` are **plain prefix matches** on the raw `lhs`, first match wins; unmatched maps go to ` General / Others`. Leader maps appear as `' a'`, `' b'`, … because `mapleader = ' '`, so the rules depend on a space leader.

| Prefix | Group |
|--------|-------|
| `<leader>a` `b` `c` `d` `f` `g` `j` `n` `p` `q` `r` `s` `t` `T` `u` `w` `z` `<Tab>` | AI, Buffer/Workspace, Code/LSP, Debug, Find, Git, Multicursor, Minimap, Panel/Tools, Quit/Restart, Code Runner, Search Meta, Translate, Telegram, UI & Toggles, Write/Save, Zettelkasten, Workspace/Tabs |
| `g`, `[`, `]`, `s`, `z` | Goto/LSP, Prev, Next, Surround, Fold/UFO |
| `<C-`, `<A-`, `<S-` | Ctrl/Window, Alt/Move, Shift/Buffer |

Keys within a group are sorted by `lhs`. Each group goes into whichever column is currently shortest. The number of columns is `floor((columns * 0.8 - 4) / 54)` (at least 1).

---

## Caching

The rendered lines and extmark highlights are cached. The cache is cleared on `VimResized` or when `toggle()` is called from a different buffer than last time.

## Gotchas

- Keymaps defined after the first build (e.g., by lazily loaded plugins) don't appear until the cache is cleared (resize, or open from another buffer).
- Adding a new `<leader>` prefix group means adding a rule to `group_rules`; otherwise its maps go into General / Others.
