# Heirline Documentation

## Overview

Provides the statusline, tabline, and winbar through `heirline.nvim`. Auto-imported in the `User VeryLazy` block by `resonance.import('plugins')` (`lua/plugins/heirline/init.lua` returns the spec); the plugin itself triggers on `BufReadPost`, `BufNewFile`, or `BufEnter` (resonance replays these for buffers opened before VeryLazy). `bpm.nvim` is registered in the same file and triggers on `BufReadPost`/`BufNewFile`.

## Files

- `init.lua`: Registers Heirline and bpm with resonance, loads colors, refreshes them on `ColorScheme`, sets up `libs.git` (git root via Snacks), and defines `disable_winbar_cb`.
- `colors.lua`: `setup_colors()` builds the palette from highlight groups (with Catppuccin Mocha fallbacks); `mode_names`, `mode_colors`, and `get_mode_color(mode)` map modes to labels/colors.
- `statusline.lua`: Mode, diagnostics, git branch + mini.diff summary, Python venv (only if `venv-selector` is loaded), active LSP clients (at most 2 names, then `(+N)`), cursor `line:col`, and a 12-hour clock. Empty on `snacks_dashboard`.
- `tabline.lua`: Buffer list on the left, tabpages and a close-tab button on the right. Scrolls horizontally to keep the current buffer visible, with truncation markers; buffer names truncated to 20 characters.
- `winbar.lua`: File path plus Tree-sitter breadcrumbs (max 5 levels, `⋯` when deeper); a separate winbar for terminal buffers.

## Mouse

- Tabline buffer: left click switches to it; middle/right click (or clicking the close icon) detaches it from the tab with bpm, or wipes it with `Snacks.bufdelete` when bpm is unavailable.
- Tabline tabpage: click to switch; the `󰅖` button closes the current tab.
- Winbar breadcrumb: click to jump the cursor to the start of that scope.

## Winbar Visibility

Disabled for floating windows, unnamed unmodified normal buffers, `buftype` `nofile`/`prompt`/`help`, `snacks_dashboard`, and `snacks_picker*` filetypes. The file path is flexible: full path → abbreviated directories → file name only, with `$HOME` shown as `~`.

## Refresh Behavior

- The clock string is cached and refreshed at each minute boundary by a `vim.async` loop.
- Mode is cached and updated on `ModeChanged`.
- LSP client labels are cached per buffer and invalidated on `LspAttach`/`LspDetach`.
- Tabline redraws are scheduled on buffer add/delete/enter, tab enter/close, `DiagnosticChanged`, `VimEnter`, and `UIEnter`. Per-buffer state tables are reused but recomputed on every render.
- Winbar breadcrumbs are cached per window (keyed by buffer, changedtick, and enclosing scope node); the window cache is cleared on `WinClosed`, file-path and node-name caches on `BufDelete`/`BufWipeout`.

## Integration

- `libs.git` supplies `vim.b.my_git_branch`; `mini.diff` supplies `vim.b.minidiff_summary`.
- `snacks` supplies icons, buffer deletion, and git-root lookup.
- `bpm` supplies per-tab attached buffers, buffer names, and tab names when available (on Windows, the tabline uses the file basename instead of bpm's buffer name).
