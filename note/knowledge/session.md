# session.lua Documentation

## Overview

Manages workspace-local Neovim state and git-branch-aware sessions.

## Persistence Layout

The workspace root is the nearest ancestor of the cwd containing `.git`, or the cwd itself. State is stored below `<workspace root>/.cache/nvim/` (the `dir` option):

| Path | Purpose |
|---|---|
| `sessions/` | Session files and bpm.nvim buffer-pool JSON |
| `undo/` | Persistent undo history |
| `shada/main.shada` | Marks, registers, and command history |
| `swap/` | Swap files |

**Fallback:** if `<workspace root>/.cache/nvim` cannot be created (e.g. Neovim launched from an unwritable directory such as `/etc`), the same layout is created under `stdpath('state')/persistence` instead. Session file names embed the full root path, so sessions from different fallback workspaces don't collide.

Session files are named `<root>@@<branch>.vim`, with `/` and `:` in the root and branch replaced by `%`. The branch is read from `.git/HEAD`; a detached HEAD uses the first 7 characters of the commit hash, and a non-git root has no `@@` suffix.

`bpm.nvim` serializes tab names, per-tab buffer membership, and buffer ordering to an adjacent `.json` file (same name as the session). It is restored after the Vim session.

## Configuration

Set `vim.g.session_persistence` before `custom.startup` runs (top of `init.lua`), since `M.setup()` is called from `custom/startup.lua`:

```lua
vim.g.session_persistence = {
  dir = '.cache/nvim', -- workspace-relative
  session = true,
  undo = true,
  shada = true,
  swap = true,
}
```

All modes default to `true`. Set an individual mode to `false` to disable it (`shada = false` sets `shada=''`). An existing `shadafile=NONE` is left untouched.

Gotcha: `config/options.lua` runs after `M.setup()`, sets `undofile = true` unconditionally, and on Windows sets `shadafile = 'NONE'` — so `undo = false` is overridden and workspace ShaDa is not used on Windows.

## Core Functions

- `M.save()`: Closes quickfix/location lists, then writes the session (`mksession!`) and bpm.nvim state for the current workspace/branch.
- `M.load(last)`: Restores the current workspace/branch session; `last=true` picks the most recently modified `.vim` in the session directory. Before sourcing, it wipes dashboard, `nofile`, and `terminal` buffers. After a bpm restore, all buffers are unlisted (bpm manages visibility).
- `M.setup()`: Configures persistence once and registers the `VimLeavePre` autosave and user commands.

## Commands

- `:RestoreSession` – restore the session for the current branch/workspace.
- `:RestoreLastSession` – restore the newest session in the session directory.
- `:StopSession` – disable session saving for the current Neovim instance.

## Lifecycle

The module saves on `VimLeavePre`. It skips saving when no listed, named, normal buffer is loaded, unless a session was restored in this instance.

`M.save()` and `M.load()` initialize persistence if it has not been set up yet.

With the fallback directory, all fallback workspaces share one `sessions/` directory, so `:RestoreLastSession` may pick a session from a different workspace.
