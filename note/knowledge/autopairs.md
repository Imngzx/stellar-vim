# custom.autopairs — Pair Editing Package

> **Purpose**: Native pair insertion, surround editing, and tab-out behavior.
> **Location**: `lua/custom/autopairs/`
> **Loader**: `safe_setup('custom.autopairs', require('custom.autopairs').setup)` inside the `User VeryLazy` autocmd in `config/resonance.lua`, so mappings do not exist until VeryLazy fires.

## Modules

| Module | Responsibility |
|---|---|
| `spec.lua` | Shared delimiter metadata (pair tables with cached bytes) and aliases |
| `pairs.lua` | Automatic insertion, closing, backspace, enter, and command-line pairs |
| `surround.lua` | `sa`, `sd`, `sr`, and VS Code-style visual wrapping |
| `tabout.lua` | Insert-mode `<Tab>` and `<S-Tab>` movement across pairs |
| `init.lua` | `setup(opts)` calls each module's setup with `opts.pairs`, `opts.surround`, `opts.tabout` |

## Configuration

Only `pairs` takes options:

```lua
require('custom.autopairs').setup({ pairs = { enable_cmdline = true } }) -- default
```

`enable_cmdline` also binds the pair keys and `<BS>` in command-line mode (`<CR>` is never bound there).

## Shared Pair Contract

- Automatic pairs: `()`, `[]`, `{}`, `""`, `''`, and backticks.
- Surround aliases: `b` for parentheses; `<`/`>` for angle brackets; open and close characters are interchangeable. Any other character surrounds with itself on both sides.
- Tabout pairs: `()`, `[]`, `{}`, quotes, and backticks.
- Angle brackets remain surround-only because `<` and `>` are common operators.

## Pair Behavior

- An opening bracket is not auto-closed when the next character is alphanumeric.
- A quote is not auto-closed when either neighbor is alphanumeric (so `don't` works); typing a third quote after `""` inserts a triple-quote pair.
- Typing a closer (or quote) right before the same character moves over it.
- `<BS>` between an empty pair (or empty triple-quote pair) deletes both sides.
- `<CR>` between brackets opens an indented empty line between them; it is passed through when the popup menu is visible.

## Keymaps

| Mode | Key | Action |
|---|---|---|
| Insert/Cmdline | Pair characters | Insert or skip matching pairs |
| Insert/Cmdline | `<BS>` | Remove an empty matching pair |
| Insert | `<CR>` | Expand a matching bracket pair onto separate lines |
| Insert | `<Tab>` | If the next character is a closer, or a quote closing an earlier quote on the line, move past it; otherwise a normal `<Tab>` (also when the popup menu is visible). See Gotchas for openers. |
| Insert | `<S-Tab>` | If the previous character is a closer, move back to just inside its matching opener; otherwise a normal `<S-Tab>` |
| Normal | `sa` | Surround: prompts for the character **first**, then takes a motion (`sa` `(` `iw`) |
| Visual | `sa` | Prompt for a character and surround the selection |
| Visual | `(` `[` `{` `"` `'` `` ` `` | VS Code-style wrap of the selection |
| Normal | `sd` | Delete a surround (prompts for the character) |
| Normal | `sr` | Replace a surround (prompts for old, then new character) |

Public functions: `surround.add_normal()`, `surround.add_visual_interactive()`, `surround.delete()`, `surround.replace()`, `tabout.tabout()`, `tabout.tabout_back()`.

## Gotchas

- `sd`/`sr` search only the current line, nesting-aware for brackets.
- The visual wrap mappings shadow built-in visual-mode keys: `"` (register prefix, e.g. `"+y`), `'`/`` ` `` (mark jumps), and `(`/`[`/`{` motions.
- `<Tab>` before an opening bracket (or an unmatched-before quote) is meant to jump past the matching closer, but `tabout()` is an expression mapping, so its `nvim_win_set_cursor` is undone and the key currently does nothing there.
- `<S-Tab>` must be a non-expression mapping because it moves the cursor directly (expression mappings restore cursor moves); `tests/smoke.lua` asserts this.
