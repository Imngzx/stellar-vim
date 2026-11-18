# word-jump.lua — DIY Flash-Style Jump Navigation

> **Purpose**: Flash.nvim-like character jump: type a character, then a label, to jump to any visible occurrence.
> **Location**: `lua/custom/word-jump.lua`
> **Loaded by**: `config/resonance.lua` → `safe_load('custom.word-jump')` inside the `User VeryLazy` block. The keymap is set at module load (no `setup()`).

---

## Public API

| Function | Description |
|----------|-------------|
| `M.jump()` | Prompt for a target character, label every visible occurrence, then jump to the chosen label |

## Keymaps

| Mode | Key | Action |
|------|-----|--------|
| `n`, `x`, `o` | `f` | `M.jump()` — replaces the built-in `f` |

---

## Jump Flow

1. Prompt `⚡ Flash ❯` and read one character (`getcharstr`); `<Esc>` or an empty read cancels.
2. Find every literal (plain `string.find`) occurrence of that character in lines `w0`..`w$`, up to 962 matches.
3. 0 matches → nothing happens; 1 match → jump immediately.
4. Otherwise dim the visible range and draw a label next to each match.
5. Read a label key. A single-key label jumps; a prefix key (uppercase or digit) redraws only the labels with that prefix and reads a second key.

## Label Hierarchy (962 max)

Labels are generated in order, with only as many tiers as the match count needs:

1. Lowercase singles, in home-row order `asdfghjklqwertyuiopzxcvbnm` (26)
2. Uppercase singles `A S D F …` (up to 26). Each two-key prefix needed takes one uppercase letter, starting from the end of the list (`M`, `N`, `B`, …).
3. Uppercase prefix + lowercase, e.g. `Ma`, `Ms` (26 per prefix)
4. Digit prefix + lowercase, `1a` … `0z` (only above 702 matches)

## Highlight Groups

Redefined on every `ColorScheme` (augroup `FlashDiyHL`).

| Group | Purpose | Colors |
|-------|---------|--------|
| `FlashDiyBackdrop` | Dims the visible range | fg `#545c7e` |
| `FlashDiyMatch` | The matched character | `#c0caf5` on `#3d59a1`, bold |
| `FlashDiyLabel` | Label overlay | `#15161e` on `#ff007c`, bold |

Extmarks live in the `flash_diy` namespace.

---

## Gotchas

- Overriding `f` removes built-in `f` behavior, including `;`/`,` repeat. The jump uses `nvim_win_set_cursor`, so in operator-pending mode the motion is not inclusive like the built-in `f` (`df<char>` does not delete the target character).
- The label is drawn as an overlay on the column *after* the match, so it covers the next character instead of the match.
- Matches past 962 are dropped silently.
