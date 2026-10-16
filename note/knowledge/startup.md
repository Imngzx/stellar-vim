# startup.lua Documentation

## Overview

Initializes key Neovim configurations and optimizes startup performance. Entry point for the entire config.

## Key Configurations

### 1. Bytecode Cache

- Enables bytecode loading with `vim.loader.enable()` for faster startup

### 2. Disabled Built-ins

Clobbers unwanted built-in plugins:

```lua
local disabled_built_ins = {
  'fzf',
  'gzip',
  'matchit',
  'netrwPlugin',
  'netrwSettings',
  'netrwFileHandlers',
  'matchparen',
  'tarPlugin',
  'tutor',
  'zipPlugin',
  'tohtml',
}
for i = 1, #disabled_built_ins do
  vim.g['loaded_' .. disabled_built_ins[i]] = 1
end
```

### 3. UI Setup

- Loads custom UI configurations via `require('custom.ui2').setup()`

### 4. Markdown Style

- Disables recommended markdown style: `vim.g.markdown_recommended_style = 0`

## Performance Optimization

### 1. Startup Profiler

When `PROF` environment variable is set:

- Uses `snacks.profiler` to track startup events
- Hooks into `VimEnter` event for performance analysis

```lua
if vim.env.PROF then
  vim.cmd('packadd snacks.nvim')
  require('snacks.profiler').startup({
    startup = { event = 'VimEnter' },
  })
end
```

### 2. Power Management

Automatically switches components based on power source via `libs.power`:

- Battery mode: Uses FZF for performance
- Wall power: Uses Snacks components
- Disables resource-intensive features in battery mode:
  - `Snacks.animate`, `Snacks.picker`, `Snacks.image`
  - `render-markdown.nvim`

```lua
require('libs.power').setup({ enable_auto_switch = true })
```

## Conditional Logic

- Environment variable `PROF` controls profiler activation
- Power source detection through `libs.power` setup (checks `/sys/class/power_supply/AC/online` on Linux)

## Execution Order (in init.lua)

```lua
-- 1. Bytecode cache + disable built-ins + UI init + power-aware picker
require('custom.startup')

-- 2. Core editor options
require('config')

-- 3. Plugin manager bootstrap + all plugin configs
require('config.resonance')
```

## Example Benchmark Commands

```bash
# Baseline (no config)
nvim --headless -u NONE -c "luafile ~/.config/nvim/init.lua" -c "qall"

# With resonance
nvim --headless -u NONE -c "luafile ~/.config/nvim/init.lua" -c "lua require('custom.startup')" -c "qall"

# Direct module timing
nvim --headless -c "lua local t=vim.uv.hrtime(); require('custom.startup'); print('startup:', (vim.uv.hrtime()-t)/1e6, 'ms')" -c "qall"
```

This module ensures optimized Neovim startup while maintaining necessary functionality through selective plugin loading and power-aware configurations.
