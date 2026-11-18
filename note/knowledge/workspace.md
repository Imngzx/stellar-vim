# workspace.lua Documentation

## Overview

Two independent features: loading a project-local `.nvim.lua`, and a power-aware picker for switching between tabpages ("workspaces").

## Core Functions

- `M.setup()`: Finds the nearest `.nvim.lua` searching upward from the cwd and executes it. Called from the `User VeryLazy` block in `config/resonance.lua`.
  - Read via `vim.secure.read()`, so untrusted files trigger Neovim's trust prompt; a denied/empty file is skipped.
  - Syntax and runtime errors are reported via `vim.notify` (with traceback) instead of raising.
  - On Windows the path is normalized with `vim.fs.normalize`.
- `M.picker()`: Lists all tabpages and switches to the selected one.
  - Each entry shows the tab name (bpm.nvim `resolve_tabname`, else `Tab <id>`), a buffer count (bpm.nvim attached buffers, else unique loaded buffers in the tab's windows), and the file name in the tab's focused window. The current tab is highlighted and marked `(Current)`.
  - AC power (`libs.power.is_ac()`): `Snacks.picker` with the `select` layout.
  - Battery: `fzf-lua` `fzf_exec`; force-loads fzf-lua through `resonance.loader` (falls back to `:packadd fzf-lua`).

## Keymaps

| Key | Action | Defined in |
|---|---|---|
| `<leader>ft` | `M.picker()` (Find Workspace (Tab)) | `lua/plugins/snacks/keys.lua` |

## Dependencies

- `libs.utils` (Windows detection), `libs.power` (AC/battery), `libs.bpm` (tab names and buffer membership; optional).
