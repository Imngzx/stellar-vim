# custom.autopairs — Pair Editing Package

> **Purpose**: Native pair insertion, surround editing, and tab-out behavior.
> **Location**: `lua/custom/autopairs/`
> **Loader**: `custom.autopairs.setup()` from `config/resonance.lua`

## Modules

| Module | Responsibility |
|---|---|
| `spec.lua` | Shared delimiter metadata and aliases |
| `pairs.lua` | Automatic insertion, closing, backspace, enter, and command-line pairs |
| `surround.lua` | `sa`, `sd`, `sr`, and VS Code-style visual wrapping |
| `tabout.lua` | Insert-mode `<Tab>` and `<S-Tab>` movement across pairs |
| `init.lua` | Calls each module's setup function |

## Shared Pair Contract

- Automatic pairs: `()`, `[]`, `{}`, quotes, and backticks.
- Surround aliases: adds `b` for parentheses and `<`/`>` for angle brackets.
- Tabout pairs: `()`, `[]`, `{}`, quotes, and backticks.
- Angle brackets remain surround-only because `<` and `>` are common operators.

## Keymaps

| Mode | Key | Action |
|---|---|---|
| Insert | Pair characters | Insert or skip matching pairs |
| Insert | `<BS>` | Remove an empty matching pair |
| Insert | `<CR>` | Expand a matching pair onto separate lines |
| Insert | `<Tab>` | Tab out of a pair or fall back |
| Insert | `<S-Tab>` | Tab backwards out of a pair or fall back |
| Normal | `sa` | Surround a motion |
| Visual | `sa` | Interactively surround a selection |
| Visual | `(` `[` `{` `"` `'` `` ` `` | VS Code-style auto-wrap |
| Normal | `sd` | Delete a surround |
| Normal | `sr` | Replace a surround |

## Performance

- Delimiter bytes are cached in `spec.lua`.
- Tabout matching scans bytes and uses depth counters for nested brackets.
- Surround insertion uses byte offsets and allocation-free UTF-8 length checks.
- Existing per-key closures remain local to insertion and visual-wrap handlers.
- Setup is centralized without adding runtime indirection to hot paths.
