# session.lua Documentation

## Overview

Manages workspace-local Neovim state and git-branch-aware sessions.

## Persistence Layout

State is stored below `<workspace>/.cache/nvim/`:

| Path | Purpose |
|---|---|
| `sessions/` | Session files and bpm.nvim buffer-pool JSON |
| `undo/` | Persistent undo history |
| `shada/main.shada` | Marks, registers, and command history |
| `swap/` | Swap files |

`bpm.nvim` serializes tab names, per-tab buffer membership, and buffer ordering to an adjacent JSON file. It is restored after the Vim session.

## Configuration

Set `vim.g.session_persistence` before `User VeryLazy` to override defaults:

```lua
vim.g.session_persistence = {
  dir = '.cache/nvim', -- workspace-relative
  session = true,
  undo = true,
  shada = true,
  swap = true,
}
```

All modes default to `true`. Set an individual mode to `false` to disable it. On Windows, an existing `shadafile=NONE` is preserved.

## Core Functions

- `M.save()`: Saves the current session and bpm.nvim state.
- `M.load(last)`: Restores the current session; `last=true` chooses the newest workspace session.
- `M.setup()`: Configures persistence once and registers automatic saving.

## Commands

- `:RestoreSession` – restore the session for the current branch/workspace.
- `:RestoreLastSession` – restore the newest session in the workspace.
- `:StopSession` – disable session saving for the current Neovim instance.

## Lifecycle

The module saves on `VimLeavePre`. It skips empty instances until a session has been restored.

`M.save()` and `M.load()` initialize persistence when invoked before `User VeryLazy`, so the dashboard restore action is safe during startup.
