# startup.lua Documentation

## Overview

Initializes key Neovim configurations and optimizes startup performance.

## Key Configurations

### 1. Bytecode Cache

- Enables bytecode loading with `vim.loader.enable()` for faster startup

### 2. Disabled Built-ins

Clobbers unwanted built-in plugins:

- `fzf`, `gzip`, `matchit`, `netrw*`, `matchparen`, `tarPlugin`, `tutor`, `zipPlugin`, `tohtml`

### 3. UI Setup

- Loads custom UI configurations via `custom.ui2.setup()`

## Performance Optimization

### 1. Startup Profiler

- When `PROF` environment variable is set:
  - Uses `snacks.profiler` to track startup events
  - Hooks into `VimEnter` event for performance analysis

### 2. Power Management

- Automatically switches components based on power source:
  - Battery mode: Uses FZF for performance
  - Wall power: Uses Snacks components
- Disables resource-intensive features in battery mode:
  - `Snacks.animate`, `Snacks.picker`, `Snacks.image`
  - `render-markdown.nvim`

## Conditional Logic

- Environment variable `PROF` controls profiler activation
- Power source detection through `libs.power` setup

## Example Configuration Impact

```lua
-- Disable unwanted built-ins
for i, plugin in ipairs({'fzf', 'gzip', 'matchit'}) do
  vim.g['loaded_'..plugin] = 1
end

-- Enable bytecode caching
vim.loader.enable()
```

This module ensures optimized Neovim startup while maintaining necessary functionality through selective plugin loading and power-aware configurations.
