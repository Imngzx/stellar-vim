# language-switcher.lua — Cross-Platform IME Auto-Switch

> **Purpose**: Turn the input method off (English) when leaving Insert mode and restore it on re-entering, with backends for Linux (fcitx5), WSL (im-select.exe), and native Windows (Imm32 via FFI).
> **Location**: `lua/custom/language-switcher.lua`
> **Loaded**: `safe_setup('custom.language-switcher', ...)` inside the `User VeryLazy` block of `lua/config/resonance.lua`. No keymaps or commands.

---

## Platform dispatch (`M.setup()`)

| Platform | Detection | Backend | Requirement |
|----------|-----------|---------|-------------|
| WSL | `uname().release` contains `microsoft` | `M.wsl_ime()` | `im-select.exe` on `PATH`, or at `/mnt/c/Users/*/scoop/apps/im-select/current/im-select.exe` |
| Windows | `libs.utils.is_windows()` and not WSL | `M.auto_switch_ime()` | LuaJIT FFI loading `user32` / `imm32` |
| Anything else (Linux/macOS) | fallback | `M.fcitx()` | `fcitx5-remote` on `PATH`; otherwise nothing happens |

Detection and binary lookup happen at module load (require time), not in `setup()`.

---

## Public API

| Function | Description |
|----------|-------------|
| `M.setup()` | Picks one backend as above. |
| `M.fcitx()` | fcitx5 autocmds (augroup `DIY_Fcitx5`). No-op without `fcitx5-remote`. |
| `M.wsl_ime()` | im-select autocmds (augroup `DIY_WslIME`). Warns and returns if `im-select.exe` isn't found. |
| `M.auto_switch_ime()` | Win32 autocmds (augroup `DIY_WindowsIME`). No-op if FFI failed. |
| `M.force_switch_to_english()` | Windows only: closes the IME and posts `WM_INPUTLANGCHANGEREQUEST` for en-US (`0x04090409`) to the foreground window. Not called anywhere in the config. |

---

## Behavior

All backends use the same three autocmds:

| Event | Action |
|-------|--------|
| `InsertLeave` | Save the current state in a buffer variable, then switch off |
| `InsertEnter` | Restore if the saved state was "on" |
| `VimEnter`, `FocusGained`, `CmdlineLeave` | Switch off |

| Backend | Read state | Off | Restore | Saved in |
|---------|-----------|-----|---------|----------|
| fcitx5 | `fcitx5-remote` (`2` = active) | `fcitx5-remote -c` | `fcitx5-remote -o` if saved `2` | `vim.b.saved_im` |
| WSL | `im-select.exe` (layout id) | `im-select.exe 1033` | `im-select.exe <id>` if saved id ≠ `1033` | `vim.b.saved_im` |
| Windows | `IMC_GETOPENSTATUS` via `ImmGetDefaultIMEWnd` | `IMC_SETOPENSTATUS 0` | `IMC_SETOPENSTATUS 1` | `vim.b.saved_ime_status` |

On fcitx5, the off command on `VimEnter`/`FocusGained`/`CmdlineLeave` runs synchronously (`:wait()`); on WSL it is async.

---

## Gotchas

- The setup runs on `User VeryLazy`, which resonance fires after `UIEnter`, so the `VimEnter` autocmd is registered too late and never fires at startup.
- CLI backends: on `InsertLeave` the "read state" and "off" commands are started async and at the same time, so the read can see the state after it was already switched off. When that happens, the IME won't be restored on the next `InsertEnter`.
- Only fcitx5 is supported on Linux (no ibus). macOS takes the fcitx5 path and does nothing without `fcitx5-remote`.
