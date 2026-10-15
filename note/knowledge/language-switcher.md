# language-switcher.lua — Cross-Platform IME Auto-Switch

> **Purpose**: Automatic Input Method Editor (IME) switching to English on mode exit/buffer leave, with platform-specific implementations for Linux (fcitx5), WSL (im-select), and native Windows (Imm32).
> **Location**: `lua/custom/language-switcher.lua`
> **Triggers**: Auto on `InsertLeave`, `BufLeave`, `FocusLost`, `CmdlineEnter`

---

## Overview

Cross-platform IME manager (~250 lines) with platform-specific backends:

- **Linux**: `fcitx5-remote` CLI
- **WSL**: `im-select.exe` via WSL interop
- **Windows**: Win32 API via `ffi` (Imm32/user32)

Automatically switches to English (US) layout on:

- `InsertLeave` (exit insert mode)
- `BufLeave` (leave buffer)
- `FocusLost` (leave Neovim)
- `CmdlineEnter` (enter command line)

---

## Platform Detection

```lua
local is_wsl = vim.uv.os_uname().release:lower():find('microsoft') ~= nil
local is_windows = util.is_windows() and not is_wsl
```

| Platform | Detection | Backend |
|----------|-----------|---------|
| Linux | `not is_windows and not is_wsl` | `fcitx5-remote` |
| WSL | `is_wsl` | `im-select.exe` (WSL interop) |
| Windows | `is_windows` | Win32 API (Imm32/user32) |

---

## Shared Abstraction: `setup_cli_ime(opts)`

```lua
---@class CliImeOpts
---@field name string              -- Augroup name
---@field cmd_get table            -- Command to get current IME status
---@field cmd_off table            -- Command to switch to English
---@field get_cmd_on fun(target): table|nil  -- Command to restore previous
---@field sync_off_on_enter boolean -- Sync off on Enter/Focus

local function setup_cli_ime(opts)
  local aug = create_augroup(opts.name, { clear = true })
  
  -- Save current IME on InsertEnter
  create_autocmd('InsertEnter', {
    group = aug,
    callback = function()
      local out = vim.system(opts.cmd_get, { text = true }):wait()
      if out.code == 0 then
        vim.b[opts.name .. '_saved'] = trim(out.stdout)
      end
    end,
  })
  
  -- Restore on InsertLeave
  create_autocmd('InsertLeave', {
    group = aug,
    callback = function()
      local saved = vim.b[opts.name .. '_saved']
      if saved then
        local cmd = opts.get_cmd_on(saved)
        if cmd then vim.system(cmd):wait() end
      end
    end,
  })
  
  -- Force English on BufLeave/FocusLost/CmdlineEnter
  create_autocmd({ 'BufLeave', 'FocusLost', 'CmdlineEnter' }, {
    group = aug,
    callback = function()
      vim.system(opts.cmd_off):wait()
    end,
  })
end
```

---

## Linux: fcitx5-remote

```lua
local FCITX5_REMOTE = executable('fcitx5-remote') == 1 and 'fcitx5-remote' or nil

function M.fcitx()
  if not FCITX5_REMOTE then return end
  setup_cli_ime({
    name = 'fcitx5_ime',
    cmd_get = { FCITX5_REMOTE },           -- Get current layout
    cmd_off = { FCITX5_REMOTE, '-c' },     -- Switch to English (clear)
    get_cmd_on = function(target)
      return target and { FCITX5_REMOTE, '-s', target } or nil
    end,
    sync_off_on_enter = false,
  })
end
```

| Command | Purpose |
|---------|---------|
| `fcitx5-remote` | Get current layout |
| `fcitx5-remote -c` | Switch to English (clear) |
| `fcitx5-remote -s <layout>` | Switch to specific layout |

---

## WSL: im-select.exe (WSL Interop)

```lua
local IM_SELECT_EXE = '/mnt/c/Users/*/scoop/apps/im-select/current/im-select.exe'

function M.wsl_ime()
  if executable(IM_SELECT_EXE) ~= 1 then return end
  setup_cli_ime({
    name = 'wsl_ime',
    cmd_get = { IM_SELECT_EXE },              -- Get current layout
    cmd_off = { IM_SELECT_EXE, '1033' },      -- Switch to English (1033 = en-US)
    get_cmd_on = function(target)
      return target and { IM_SELECT_EXE, target } or nil
    end,
    sync_off_on_enter = true,  -- Sync off on enter for WSL
  })
end
```

| Command | Purpose |
|---------|---------|
| `im-select.exe` | Get current layout ID |
| `im-select.exe 1033` | Switch to English (1033 = en-US) |
| `im-select.exe <id>` | Switch to specific layout |

> **Note**: Path must be updated to match your `im-select.exe` installation location.

---

## Native Windows: Win32 API (FFI)

```lua
local ffi = require('ffi')
local user32, imm32

ffi.cdef[[
  HWND GetForegroundWindow();
  HWND GetFocus();
  LRESULT PostMessageW(HWND, UINT, WPARAM, LPARAM);
  HKL GetKeyboardLayout(DWORD);
  BOOL PostThreadMessageW(DWORD, UINT, WPARAM, LPARAM);
  DWORD GetWindowThreadProcessId(HWND, LPDWORD);
  HWND ImmGetDefaultIMEWnd(HWND);
  LRESULT SendMessageW(HWND, UINT, WPARAM, LPARAM);
]]

local WM_INPUTLANGCHANGEREQUEST = 0x0050
local ENGLISH_US_LAYOUT_ID = 0x04090409
local WM_IME_CONTROL = 0x0283
local IMC_GETOPENSTATUS = 0x0005
local IMC_SETOPENSTATUS = 0x0006
```

### IME Status Functions

```lua
local function get_ime_status(hWnd)
  local imeWnd = imm32.ImmGetDefaultIMEWnd(hWnd)
  if imeWnd == ffi.NULL then return nil end
  local result = user32.SendMessageW(imeWnd, WM_IME_CONTROL, IMC_GETOPENSTATUS, 0)
  return result ~= 0
end

local function set_ime_status(hWnd, open)
  local imeWnd = imm32.ImmGetDefaultIMEWnd(hWnd)
  if imeWnd == ffi.NULL then return false end
  user32.SendMessageW(imeWnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, open and 1 or 0)
  return true
end
```

### Force Switch to English

```lua
function M.force_switch_to_english()
  local hWnd = user32.GetForegroundWindow()
  user32.PostMessageW(hWnd, WM_INPUTLANGCHANGEREQUEST, 0, ENGLISH_US_LAYOUT_ID)
end
```

### Auto-Switch Logic

```lua
function M.auto_switch_ime()
  create_autocmd('InsertLeave', {
    callback = function()
      local hWnd = user32.GetForegroundWindow()
      if get_ime_status(hWnd) then
        set_ime_status(hWnd, false)  -- Close IME
      end
    end,
  })
  -- Also on BufLeave, FocusLost, CmdlineEnter
end
```

---

## Setup Dispatch

```lua
function M.setup()
  if is_wsl then
    M.wsl_ime()
  elseif is_windows then
    M.auto_switch_ime()
  else
    M.fcitx()
  end
end
```

---

## Keymappings (Manual)

| Command | Function |
|---------|----------|
| `:lua require('custom.language-switcher').force_switch_to_english()` | Force English layout |

---

## Requirements

| Platform | Requirement |
|----------|-------------|
| Linux | `fcitx5-remote` in PATH |
| WSL | `im-select.exe` installed via Scoop (`scoop install im-select`) |
| Windows | None (built-in Win32 API) |

---

## Configuration

```lua
-- Update im-select path for your system
local IM_SELECT_EXE = '/mnt/c/Users/*/scoop/apps/im-select/current/im-select.exe'

-- Or override fcitx5-remote if not in PATH
local FCITX5_REMOTE = '/usr/bin/fcitx5-remote'
```

---

## Autocmd Groups Created

| Group | Events | Purpose |
|-------|--------|---------|
| `fcitx5_ime` | `InsertEnter`, `InsertLeave`, `BufLeave`, `FocusLost`, `CmdlineEnter` | Linux fcitx5 |
| `wsl_ime` | Same | WSL im-select |
| `win32_ime` | `InsertLeave`, `BufLeave`, `FocusLost`, `CmdlineEnter` | Windows Win32 |

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Shared `setup_cli_ime` | DRY for CLI-based backends (Linux/WSL) |
| FFI for Windows | No external deps, native performance |
| `im-select.exe` for WSL | Best Windows IME control via interop |
| `fcitx5-remote` for Linux | Standard fcitx5 CLI |
| Buffer-local saved layout | Per-buffer IME state restoration |
| Force English on `BufLeave`/`FocusLost` | Prevents IME leakage to other apps |

---

## Related Files

- `lua/config/keymaps.lua` — Optional manual keymap
- `lua/libs/utils.lua` — `is_windows()`, `is_wsl()`

---

## Limitations

- **fcitx5 only** — No ibus/rime support
- **WSL path hardcoded** — Must update `IM_SELECT_EXE` path
- **Windows FFI** — Requires LuaJIT with FFI enabled
- **No Wayland native** — fcitx5 works on Wayland but via CLI
- **No per-filetype config** — Global only
