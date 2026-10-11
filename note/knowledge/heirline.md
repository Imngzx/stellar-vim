# Heirline Documentation

## Overview

Provides the statusline, tabline, and winbar through `heirline.nvim`. The plugin loads after the first file buffer is opened.

## Configuration

- `lua/plugins/heirline/init.lua`: Registers Heirline and bpm with resonance, loads colors, refreshes colors on `ColorScheme`, and suppresses the winbar for floating and special buffers.
- `lua/plugins/heirline/colors.lua`: Builds the active palette from highlight groups and maps Neovim modes to labels and colors.
- `lua/plugins/heirline/statusline.lua`: Renders mode, diagnostics, Git summary, active LSP clients, Python virtual environment, cursor location, and clock.
- `lua/plugins/heirline/tabline.lua`: Renders buffers and tabpages with cached buffer state and scheduled redraws.
- `lua/plugins/heirline/winbar.lua`: Renders file path and Tree-sitter breadcrumbs with per-window and per-buffer caches.

## Refresh Behavior

- The statusline clock keeps its displayed string cached and refreshes on minute boundaries through `vim.async`.
- LSP client labels are invalidated on `LspAttach` and `LspDetach`.
- Tabline redraws are scheduled for buffer, tabpage, and diagnostic changes.
- Winbar caches are cleared when their window or buffer is deleted.

## Integration

- `libs.git` supplies `vim.b.my_git_branch` for the statusline.
- `minidiff` supplies `vim.b.minidiff_summary`.
- `snacks` supplies icons, buffer deletion, and Git-root lookup.
- `bpm` supplies attached buffers and workspace-tab names when available.
