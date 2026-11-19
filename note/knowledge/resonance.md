# config/resonance.lua + config/scan.lua — plugin discovery

## How specs are loaded

1. **Eager** (top level, fixed order): `catppuccin` → `snacks`, `cmdline`,
   `ui`, `tool`, `discord`. Listed explicitly in `resonance.lua` and in the `EAGER` set in `scan.lua`.
2. **VeryLazy**: `custom.workspace` first, then every other spec found by
   `require('config.scan').scan_plugins()`, then the `custom.*` modules (explicit, they take opts).

## scan_plugins() (`lua/config/scan.lua`)

- `vim.uv.fs_scandir` on `stdpath('config')/lua/plugins`, **top level only**.
- `foo.lua` → `plugins.foo`; a directory counts only if it has `init.lua`
  (`heirline/`, `snacks/`). Subfiles like `heirline/statusline.lua` or
  `snacks/logos/*` are components and are never loaded directly.
- Names in `EAGER` (in `scan.lua`) are excluded; the rest are `table.sort`ed so
  load order doesn't depend on the filesystem.

## Gotchas

- Any new top-level file in `lua/plugins/` auto-loads in VeryLazy. Park WIP
  files elsewhere, or disable a plugin with resonance's `cond` in its spec
  (`cond = false` / a function returning false).
- Spec files register themselves via `require('resonance').load(...)`; they
  don't need to `return` anything.
- A plugin that must load before VeryLazy goes in the eager block **and**
  in `EAGER`. Adding it to `EAGER` alone means it never loads.
