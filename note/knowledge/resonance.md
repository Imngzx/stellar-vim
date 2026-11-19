# config/resonance.lua + config/scan.lua — plugin import

## Layout

```
lua/plugins/core/   -- import('plugins.core') at top level of resonance.lua
  catppuccin.lua    --   priority = 1000 (theme before any UI plugin)
  snacks/           --   priority = 900
  cmdline.lua discord.lua tool.lua ui.lua
lua/plugins/*.lua   -- import('plugins') inside the VeryLazy autocmd
```

The folder decides *when*: core specs are required at startup, everything
else only in VeryLazy, so LuaJIT doesn't parse every spec file at startup
(a lazy.nvim-style `lazy = false` scan of all files measured ~+9 ms).
Order inside VeryLazy: `custom.workspace`, then `import('plugins')`, then
the `custom.*` modules (explicit, they take opts).

## import(mod) — lazy.nvim style

1. `safe_load` every module from `scan(mod)`.
2. Collect what they return: a spec (`[1]` is a URL, or `src`/`url`/
   `plugin` field) or a list of specs. Anything else is ignored: `nil` (the
   file called `require('resonance').load()` itself — the old style) or a
   helper table (`lsp.lua` returns `H`).
3. Sort the collected specs by `priority` (default 0, highest first; ties
   keep file order), strip `priority` (resonance doesn't know it), and
   `resonance.load()` each under `safe_setup`.

```lua
-- lua/plugins/jisho.lua
return {
  'https://github.com/Imngzx/jisho.nvim',
  cmd = { 'Jisho' },
  config = function() require('jisho').setup({}) end,
}
```

One broken file or spec is reported and the rest still load. Disable a
plugin with resonance's `cond` (`cond = false` / a function returning false).

## scan(mod)

- `vim.uv.fs_scandir` on `stdpath('config')/lua/<mod>`, **top level only**.
- `foo.lua` → `foo`; a directory counts only if it has `init.lua`
  (`heirline/`, `core/snacks/`). `core/` has no `init.lua`, which is why
  `import('plugins')` never reaches it.
- Sorted, so load order doesn't depend on the filesystem.

## Gotchas

- `priority` only orders **returned** specs. An old-style file registers the
  moment it is required, before the sort — core files must use `return`.
- `lazy = false` in resonance means "load on VimEnter"; headless checks must
  wait for VimEnter before looking at `colors_name` / `Snacks`.
- Any new top-level file in `lua/plugins/` auto-loads in VeryLazy; one in
  `lua/plugins/core/` auto-loads at startup.
- snacks submodules are `plugins.core.snacks.*`.
