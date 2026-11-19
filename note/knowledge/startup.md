# startup.lua Documentation

## Overview

First module loaded by `init.lua`. Enables the bytecode cache, disables unused built-ins, and initializes UI, power detection, and session persistence before editor options and plugins load.

## Execution Order (`init.lua`)

```lua
require('custom.startup')   -- this module
require('config')           -- core editor options, keymaps, autocmds
require('config.resonance') -- plugin manager bootstrap + plugin configs
```

## What startup.lua Does (in order)

1. Sets globals `_G.start_time` (`vim.uv.hrtime()` at boot) and `_G.I` (`libs.icons`).
2. Enables `vim.loader` bytecode cache.
3. Sets `vim.g.markdown_recommended_style = 0`.
4. Disables built-ins by setting `vim.g.loaded_<name> = 1` for: `fzf`, `gzip`, `matchit`, `netrwPlugin`, `netrwSettings`, `netrwFileHandlers`, `matchparen`, `tarPlugin`, `tutor`, `zipPlugin`, `tohtml`.
5. `require('custom.ui2').setup()` — enables ui2 (`targets = 'msg'`) and titles the msg window " Messages " from a `FileType msg` autocmd (ui2 has no title option).
6. Startup profiler: if `$PROF` is set, `packadd snacks.nvim` and start `snacks.profiler` with `startup.event = 'VimEnter'`.
7. `require('libs.power').setup({ enable_auto_switch = true })`.
8. `require('custom.session').setup()` — workspace persistence (see `session.md`).
9. If `vim.g.neovide`, loads `config.neovide`.

## Power Management (`libs.power`)

Selects pickers/features by power source: fzf-lua on battery, Snacks on AC. Battery mode also disables `Snacks.animate`, parts of `Snacks.picker`, `Snacks.image`, and `render-markdown.nvim`.

- At startup it reads the cached state from `stdpath('state')/power_state.cache` (synchronous, fast), then verifies asynchronously: Linux reads `/sys/class/power_supply/AC/online` (or `ACAD/online`), Windows uses `GetSystemPowerStatus` via FFI, macOS runs `pmset -g batt`. It re-checks on `FocusGained`.
- A detected change updates the cache and notifies you to restart Neovim; pickers are not switched live.

## Gotchas

- `custom.session` is set up here, before `config/options.lua`, so options set there (e.g. `undofile`, Windows `shadafile`) override session persistence settings.
