# Neovim Configuration — AI Development Guidelines

> **Purpose:** the hard rules for editing this config. Read it, then read
> the source — the source wins.
> **Target:** Neovim **0.13+** (`vim.pack` + `vim.async`), plugins lazy-loaded
> repo url [Stellar:Vim](https://github.com/Imngzx/stellar-vim).

---

## 1. Project structure

| Path | Role |
|---|---|
| `init.lua` | `custom.startup` → `config` → `config.resonance`, in that order |
| `lua/custom/startup.lua` | `vim.loader.enable()`, disabled built-ins, `libs.power` picker switch, session setup |
| `lua/config/` | Options, keymaps, autocmds; `resonance.lua` bootstraps resonance and loads every plugin config |
| `lua/plugins/` | One resonance spec per file, auto-imported in VeryLazy by `resonance.import('plugins')` (`heirline/` is a directory) |
| `lua/plugins/core/` | Theme + core UI specs, imported at startup by `priority` (`snacks/` is a directory) |
| `lua/custom/` | Self-written feature modules (session, workspace, coderunner, repl, …) |
| `lua/libs/` | Shared helpers: `utils` (safe_load/safe_setup, OS checks), `power`, `bpm`, `git`, `icons`, `spell` |
| `lua/lsp/servers.lua` | **Single registry** for LSP servers, formatters, linters, Mason tools. Spec format is documented in its header comment. |
| `lua/lsp/servers/*.lua` | Per-server config modules referenced from the registry |
| `note/knowledge/` | Per-module docs — update the matching file when you change a module |
| `tests/` | `strict_boot.lua`, `smoke.lua` |

Installed plugins (read their README/doc before configuring — the source
wins over memory):

```text
~/.local/share/nvim/site/pack/core/opt/<plugin>/
```

resonance.nvim's own copy lives there too and is auto-managed; edit it
only in its own repo.

**Tools:** `rg` and `fd` over `grep`/`find`; `nvim --headless` for testing;
`lua-language-server --check=FILE` for diagnostics.

---

## 2. Red lines — violating these causes bugs

1. **Load configs through `libs.utils.safe_load` / `safe_setup`,** never a
   bare `require` in `config/resonance.lua`. One failing plugin must not
   take down the rest of startup; `NVIM_CONFIG_STRICT=1` turns these into
   hard errors for the tests. Note `safe_setup('x', require('x').setup)`
   evaluates the `require` *before* `safe_setup` runs, so a require error
   escapes it — wrap it: `safe_setup('x', function() require('x').setup() end)`.
2. **Theme first.** `plugins.core.catppuccin` (`priority = 1000`) loads before any UI plugin, or
   the UI flickers.
3. **Non-core plugin configs are required inside the `User VeryLazy`
   autocmd** in `config/resonance.lua` (via `import('plugins')`). Requiring
   them at top level makes LuaJIT parse every config file at startup. VeryLazy
   fires on its own and resonance replays read events for open buffers —
   no `trigger_verylazy()` call.
4. **Every plugin spec needs a lazy trigger** (`event`, `cmd`, `keys`,
   `ft`) unless it is genuinely core UI.
5. **Never write state into an unwritable or arbitrary cwd.** Paths derived
   from the workspace root (e.g. `custom/session.lua`) must fall back to
   `stdpath('state')` — nvim is launched from `/etc` and the like.
6. **Read the plugin's docs before setting options it manages** (e.g.
   nvim-ufo owns folding: do not set `foldmethod`/`foldexpr`).

---

## 3. Code style — match the surrounding code

- Module shape: `local M = {}` … `return M`, with `M.setup()` for init.
- **Localize what the module uses, at the top** (`local api = vim.api`,
  `local nvim_buf_get_name = api.nvim_buf_get_name`, `local uv_fs_stat =
  vim.uv.fs_stat`). No unused aliases.
- Lazy-require heavy deps: `package.loaded['snacks'] or require('snacks')`.
- **Arrays → numeric `for i = 1, #t`. Dictionaries → `pairs()`.**
- **AoS by default; SoA only for large numeric hot loops** (jump labels,
  highlight/match coordinates). LuaJIT stores numbers inline in array
  slots, so numeric SoA is contiguous and JIT-friendly; for small lists
  AoS is clearer and sorts in place. In SoA, never store `nil` — a hole
  makes `#t` undefined — keep an explicit count `n` or use `false`.
- `vim.uv` sync calls / `vim.system` over `vim.fn` in hot paths; no
  allocations or `pcall` per iteration in hot loops.
- OS checks via `libs.utils` (`is_penguin()`, `is_mac()`, `is_windows()`),
  not inline `jit.os`.
- Early returns, flat conditionals, comments only for *why*.

---

## 4. Development loop

### Test (mandatory for config changes)

```bash
# Strict boot: clean -u NONE process, safe_load/safe_setup errors are fatal
nvim --headless -u NONE -c "luafile ~/.config/nvim/tests/strict_boot.lua" -c "qall"

# Integration smoke: plugins, modules, LSP registry, session, git, UI, reload
nvim --headless -c "luafile ~/.config/nvim/tests/smoke.lua" -c "qall"
```

Exit code 0 = pass. If a test already fails before your change, say so —
confirm by re-running against `git show HEAD:<file>`.

### Benchmark (performance changes only)

```bash
nvim --headless -c "lua local t=vim.uv.hrtime(); require('custom.startup'); print('startup:', (vim.uv.hrtime()-t)/1e6, 'ms')" -c "qall"
```

No startup regression allowed.

---

## 5. Plugins

Plugin specs are **auto-imported** by `resonance.import()` (called from
`config/resonance.lua`); nothing is listed by hand there. Full details:
`note/knowledge/resonance.md`.

| Folder | Imported | Use for |
|---|---|---|
| `lua/plugins/core/` | at startup, highest `priority` first | theme (`catppuccin`, `priority = 1000`), core UI that must exist before VeryLazy |
| `lua/plugins/` | in `User VeryLazy`, sorted by name | everything else (the default) |

**Add a plugin** — create `lua/plugins/<name>.lua` that **returns** its
spec (or a list of specs). Do not call `require('resonance').load()` in the
file: a returned spec is the convention and the only form `priority` applies to.

```lua
return {
  'https://github.com/<author>/<plugin>',          -- full URL, not 'author/plugin'
  dependencies = 'https://github.com/<author>/<dep>',
  event = { 'BufReadPost', 'BufNewFile' },        -- and/or cmd / keys / ft (§2.4)
  keys = { { 'n', '<leader>xx', '<cmd>Foo<cr>', { desc = 'Foo' } } },
  build = 'make',                                 -- if the plugin needs one
  cond = require('libs.power').is_ac,             -- optional; false = disabled
  config = function() require('<plugin>').setup({}) end,
}
```

Spec fields resonance accepts: `src`/`url`/`[1]`, `name`, `version`,
`dependencies`, `event`, `cmd`, `keys`, `ft`, `lazy`, `cond`, `build`,
`config`/`setup`. `priority` belongs to `import()` (stripped before
`resonance.load`) and only matters inside `core/`. `lazy = false` means
"load on VimEnter" and cannot be combined with `event`/`cmd`/`ft`.

Rules:

- **The spec must be recognizable.** `import()` only registers a table whose
  `[1]` is a full URL or that has `src`/`url`/`plugin`; anything else is
  ignored silently.
- **One top-level file or folder per plugin group.** Split a big config into
  `lua/plugins/<name>/init.lua` + helpers (`heirline/`); helper files under it
  are never imported on their own.
- **Startup-critical goes in `core/`**, everything else in `lua/plugins/` —
  putting a plugin in `core/` costs startup time (§4 benchmark).
- **Disable** with `cond = false`, not by deleting or renaming the file.
- Moving a file between `plugins/` and `core/` changes its module path
  (`plugins.x` → `plugins.core.x`); update any `require` of it.
- Installed plugins land in `~/.local/share/nvim/site/pack/core/opt/<name>/`;
  pinned revisions in `nvim-pack-lock.json` (user-owned, see §8).

## 6. Common tasks

**Add a custom module** — `lua/custom/<name>.lua` per §3, wire it via
`safe_setup` in `config/resonance.lua`, add `note/knowledge/<name>.md`,
keymaps in `config/keymaps.lua`.

**Add an LSP server / formatter / linter / Mason tool** — edit only
`lua/lsp/servers.lua` (`M.servers`, `M.linters`, `M.tools`). Mason
binaries need absolute paths (`stdpath('data') .. '/mason/bin/<bin>'`) and
often `--stdio`; check the filetype with `vim.filetype.match()`.

**Statusline** — `lua/plugins/heirline/` (`statusline.lua`, `colors.lua`).
**Picker** — `lua/plugins/core/snacks/picker.lua`; gate expensive features on
`require('libs.power').is_ac()`.

---

## 7. System dependencies

User-facing install list: `README.md` → *Installation*. Keep both in sync
when a feature starts or stops shelling out to a tool. Guard optional tools
with `vim.fn.executable()` and degrade quietly — never error at startup
because a tool is missing.

| Tool | Needed by | Required? |
|---|---|---|
| Neovim 0.13 nightly | everything (`vim.pack`, `vim.async`) | yes |
| `git` | `vim.pack`, `libs/git.lua`, neogit, snacks git | yes |
| `gcc`/`cc`, `make` | treesitter parsers, flash-any | yes |
| `tree-sitter-cli` | nvim-treesitter (main) parser builds | yes |
| `rg`, `fd` | snacks/fzf pickers, `custom/zettel` | yes |
| `curl`, `unzip`, `tar`, `gzip` | Mason installs | yes |
| `node` + `npm` | Mason JS servers, telegram.nvim `build = 'npm i'` | yes |
| `python` | python LSP/venv-selector, `scripts.py` | for Python |
| `yarn` | markdown-preview `build = 'cd app && yarn install'` | for md preview |
| `wl-clipboard` | clipboard on Wayland Linux | Linux |
| `fcitx5` / `im-select` | `custom/language-switcher` | Linux / WSL |
| `lazygit`, `yazi` | snacks lazygit key, `custom/yazi` | optional |
| `pandoc` | `custom/md-paste` rich-text paste (`<leader>cp`) | optional |
| `gpg` | neogit commit verification | optional |
| `tdlib`, `kitty`/`ghostty` | telegram.nvim; snacks image | optional |
| `tectonic` | LaTeX rendering | optional |
| `clice` | C/C++ LSP (not from Mason) | for C/C++ |
| `fish`/`zsh`/`pwsh` | terminal shell pick in `config/keymaps.lua` | optional |
| `inotify-tools` | file watching on Linux | Linux |
| `vim-startuptime` | startup profiling | optional |

On Windows, `libs.utils.is_windows()` sets `CC=gcc`/`CXX=g++` for parser
builds (`plugins/treesitter.lua`).

---

## 8. Committing

Commit only when asked. Stage specific files, never `git add -A` — the
tree often holds unrelated user work (`nvim-pack-lock.json`, notes).
Conventional subjects: `feat(session): …`, `fix(lsp): …`.
