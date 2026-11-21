# lsp-loading.lua — LSP Progress Indicator (Fidget.nvim Alternative)

> **Purpose**: Lightweight LSP progress indicator driven by Neovim's built-in `LspProgress` autocmd (`$/progress`).
> **Location**: `lua/custom/lsp-loading.lua`
> **Loaded**: `require('custom.lsp-loading').setup()` on `User VeryLazy` (`config/resonance.lua`)

## Public API

| Function | Description |
|----------|-------------|
| `setup()` | Creates augroup `diy_lsp_loading` with `LspProgress`, `LspDetach`, `VimResized` autocmds. Takes no options |

No keymaps or commands. It does **not** override `vim.lsp.handlers['$/progress']`; it only listens to `LspProgress`.

## Behavior

| Event | Action |
|-------|--------|
| `LspProgress` kind=`begin` | Append task (client name, title, message, percentage); start spinner timer |
| `LspProgress` kind=`report` | Update message/percentage (ignored once the task is done) |
| `LspProgress` kind=`end` | Mark done (check icon, message = server message or `Done`), remove after `keep_done_ms` |
| `LspDetach` | Remove all tasks whose client **name** matches the detached client |
| `VimResized` | Re-size/re-position the float |

- Each line renders as `<spinner|check> [client] title message  NN%`; message truncated to 40 chars; lines are
  right-aligned (left-padded) to the widest line.
- Float: bottom-right (`anchor = 'SE'`, editor-relative, above the statusline), non-focusable, `noautocmd`,
  `zindex = 40`, `winhl = 'Normal:NONE'`, scratch buffer with `bufhidden = wipe`. Highlights via extmarks in namespace
  `diy_lsp_loading`.
- Spinner timer ticks every **80 ms** (`vim.schedule_wrap`); window, buffer and timer are torn down when no tasks remain.
- State is kept as parallel arrays (`t_tokens`, `t_clients`, `t_titles`, `t_messages`, `t_percentages`, `t_dones`)
  plus `t_idx` (key → index, key = `client_id:token`). Removal shifts later entries down (O(n), n is small). The extmark spec table is reused
  across frames, but `update_window()` still allocates line/chunk tables on every tick.

## Configuration

Hard-coded in the local `config` table at the top of the file (edit the source to change):

| Key | Default |
|-----|---------|
| `spinner` | 10-frame braille spinner |
| `icons` | `check = '✓'`, `error = '✗'` (`error` is currently unused) |
| `highlights` | spinner `DiagnosticWarn`, check `DiagnosticHint`, client `Directory`, title `Normal`, text `Comment` |
| `border` | `'none'` |
| `keep_done_ms` | `1000` |
| `ignore_clients` | `{ 'rumdl' }` |

## Gotchas

- Tasks are keyed by `client_id .. ':' .. token`: LSP tokens are only unique per client.
- A `begin` for a key that is still shown (finished, waiting out `keep_done_ms`) replaces the old line. The delayed
  removal carries a serial (`t_end_serial`) and does nothing if the task was re-begun or removed in the meantime.
