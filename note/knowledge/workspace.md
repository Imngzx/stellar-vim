# workspace.lua Documentation

## Overview

Manages workspace configuration and project picking with adaptive performance optimizations.

## Key Components

### 1. Workspace Detection

- Searches for `.nvim.lua` config files upward in directory tree
- Uses `vim.fs.find` with upward search for config discovery

### 2. Power-Aware Picker

- **AC Power**: Uses `Snacks.picker` for rich UI experience
- **Battery Power**: Uses `Fzf-lua` for better performance

## Core Functions

- `M.setup()`: Initializes workspace configuration
  - Detects local `.nvim.lua` config files
  - Reads and processes configuration content
- `M.picker()`: Selects workspace/project picker
  - Uses `bpm` (battery/power manager) for power state detection
  - Adapts picker based on power source
  - Supports both `Snacks.picker` and `Fzf-lua`

## Performance Considerations

- **Battery Mode**: Prioritizes performance with Fzf-lua
- **AC Mode**: Prioritizes UI experience with Snacks.picker
- **Cross-Platform**: Handles Windows path normalization

## Dependencies

- Requires `libs.utils` for utility functions
- Uses `libs.power` for power state detection
- Integrates with `bpm` (battery/power manager)

## Example Configuration Impact

```lua
-- Detect and load local .nvim.lua config
local matches = vim.fs.find('.nvim.lua', { path = vim.uv.cwd(), upward = true, limit = 1 })
if #matches > 0 then
  local config_path = matches[1]
  local config = vim.secure.read(config_path)
  -- process config content
end

-- Adaptive picker selection
if require('libs.power').is_ac() then
  require('snacks').picker({ /* UI options */ })
else
  require('fzf-lua').setup({ /* Performance options */ })
end
```

This module ensures optimal workspace management with intelligent adaptation to system power state and efficient project navigation.
