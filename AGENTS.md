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
| `lua/plugins/` | One resonance spec per file (`heirline/`, `snacks/` are directories) |
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
2. **Theme first.** `plugins.catppuccin` loads before any UI plugin, or
   the UI flickers.
3. **Non-core plugin configs are required inside the `User VeryLazy`
   autocmd** in `config/resonance.lua`. Requiring them at top level makes
   LuaJIT parse every config file at startup.
4. **`resonance.trigger_verylazy()` stays the last line** of
   `config/resonance.lua`. The buffer-replay autocmd above it must stay a
   *separate*, *synchronous* VeryLazy callback — see the comment there.
5. **Every plugin spec needs a lazy trigger** (`event`, `cmd`, `keys`,
   `ft`) unless it is genuinely core UI.
6. **Never write state into an unwritable or arbitrary cwd.** Paths derived
   from the workspace root (e.g. `custom/session.lua`) must fall back to
   `stdpath('state')` — nvim is launched from `/etc` and the like.
7. **Read the plugin's docs before setting options it manages** (e.g.
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

## 5. Common tasks

**Add a plugin** — create `lua/plugins/<name>.lua` with
`require('resonance').load({{ src = ..., event/cmd/keys/ft = ..., config = function() ... end }})`,
then `safe_load('plugins.<name>')` inside the VeryLazy block of
`config/resonance.lua`.

**Add a custom module** — `lua/custom/<name>.lua` per §3, wire it via
`safe_setup` in `config/resonance.lua`, add `note/knowledge/<name>.md`,
keymaps in `config/keymaps.lua`.

**Add an LSP server / formatter / linter / Mason tool** — edit only
`lua/lsp/servers.lua` (`M.servers`, `M.linters`, `M.tools`). Mason
binaries need absolute paths (`stdpath('data') .. '/mason/bin/<bin>'`) and
often `--stdio`; check the filetype with `vim.filetype.match()`.

**Statusline** — `lua/plugins/heirline/` (`statusline.lua`, `colors.lua`).
**Picker** — `lua/plugins/snacks/picker.lua`; gate expensive features on
`require('libs.power').is_ac()`.

---

## 6. Committing

Commit only when asked. Stage specific files, never `git add -A` — the
tree often holds unrelated user work (`nvim-pack-lock.json`, notes).
Conventional subjects: `feat(session): …`, `fix(lsp): …`.
