# session.lua Documentation

## Overview

Manages Neovim session persistence with automatic saving and loading capabilities.

## Core Functions

- `M.save()`: Saves the current session
- `M.load()`: Loads a session (with optional `last` parameter)
- `M.setup()`: Initializes session management with autocmd hook

## Session Management

- **Session Directory**: Stored in `state/sessions/` directory
- **Git Integration**: Automatically detects Git branch for session naming
- **Automatic Saving**: Hooks into `VimLeavePre` event to save on exit

## Key Commands

- `:SessionSave` – Manually save session
- `:SessionLoad` – Load saved session

## Configuration

- Checks for existing session directory, creates if missing
- Uses `snacks.git` for Git branch detection when available
- Handles session file naming based on Git branch or default name

## Example Usage

```lua
-- Save current session
:SessionSave

-- Load last session
:SessionLoad
```

This module provides robust session management for Neovim, ensuring workspace state persistence across sessions.
