# yazi.lua — Yazi Terminal File Manager Integration

> **Purpose**: Float-based Yazi file picker with chooser file support, using Snacks.nvim window.
> **Location**: `lua/custom/yazi.lua`
> **Trigger**: `<Leader>fy` (defined in keymaps)

---

## Overview

Lightweight Yazi.nvim alternative (~50 lines) using:
- **Snacks.nvim float window** — Consistent UI with other pickers
- **Yazi chooser file** — Native Yazi multi-select via `--chooser-file`
- **Non-blocking** — `vim.fn.jobstart` with async exit callback

---

## Prerequisites

- `yazi` binary in PATH
- `snacks.nvim` loaded (for float window)

---

## Core Function: `M.open()`

```lua
function M.open()
  -- 1. Check yazi executable
  if vim.fn.executable('yazi') == 0 then
    vim.notify('Yazi not installed!', vim.log.levels.ERROR)
    return
  end

  -- 2. Create temp file for chooser
  local tmpfile = os.tmpname()

  -- 3. Open Snacks float window
  local win = require('snacks').win({
    position = 'float',
    width = 0.8,
    height = 0.8,
    border = 'rounded',
    backdrop = 60,
    title = ' 󰇥 Yazi ',
    title_pos = 'center',
    zindex = 45,
    enter = true,
  })

  -- 4. Start Yazi with chooser file
  vim.fn.jobstart(string.format('yazi --chooser-file="%s"', tmpfile), {
    term = true,
    on_exit = function(_, code, _)
      vim.schedule(function()
        win:close()
        if code == 0 then
          -- Read selected files from chooser file
          local fd = io.open(tmpfile, 'r')
          if fd then
            local is_first = true
            for target_file in fd:lines() do
              if target_file and target_file ~= '' then
                if is_first then
                  vim.cmd.edit(target_file)  -- First file: edit
                  is_first = false
                else
                  vim.cmd.badd(target_file)  -- Rest: add to buffer list
                end
              end
            end
            fd:close()
            os.remove(tmpfile)
          end
        end
      end)
    end
  })

  vim.cmd('startinsert')

  -- Terminal exit mappings
  vim.keymap.set('t', '<Esc><Esc>', '<Esc><Esc>', { buf = win.buf, nowait = true })
  vim.keymap.set('t', '<C-\\><C-n>', '<NOP>', { buf = win.buf, nowait = true })
end
```

---

## Flow

1. **Validate** — Check `yazi` in PATH
2. **Temp file** — `os.tmpname()` for chooser output
3. **Float window** — Snacks.nvim float (80% size, centered)
4. **Launch Yazi** — `yazi --chooser-file=<tmpfile>` in terminal
5. **On exit** — Read chooser file, open files:
   - First file → `:edit`
   - Additional files → `:badd`
4. **Cleanup** — Close window, remove temp file

---

## Terminal Mappings (Inside Yazi)

| Key | Action |
|-----|--------|
| `<Esc><Esc>` | Exit terminal mode (pass through to Yazi) |
| `<C-\><C-n>` | Disabled (`<NOP>`) — prevents accidental exit |

---

## Keymappings

| Mode | Key | Action |
|------|-----|--------|
| `n` | `<Leader>fy` | `M.open()` — Open Yazi picker |

---

## Integration Points

| Module | Role |
|--------|------|
| `snacks.nvim` | Float window (`snacks.win`) |
| `keymaps.lua` | `<Leader>fy` registration |
| `yazi` (external) | File manager binary |

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Snacks float window | Consistent UI with other pickers |
| `--chooser-file` | Native Yazi multi-select, no plugin protocol |
| Temp file + jobstart | Non-blocking, async, no external deps |
| First file = edit, rest = badd | Standard buffer workflow |
| Terminal mappings | Prevent accidental exit, let Yazi handle keys |

---

## Related Files

- `lua/config/keymaps.lua` — `<Leader>fy` keymap
- `lua/plugins/snacks/init.lua` — Snacks window config