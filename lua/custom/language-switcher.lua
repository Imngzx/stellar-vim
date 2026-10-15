local M = {}

local api = vim.api
local fn = vim.fn
local system = vim.system
local schedule = vim.schedule
local trim = vim.trim
local executable = fn.executable
local create_augroup = api.nvim_create_augroup
local create_autocmd = api.nvim_create_autocmd
local ffi = require('ffi')
local util = require('libs.utils')

-- OS Detection
local is_wsl = vim.uv.os_uname().release:lower():find('microsoft') ~= nil
local is_windows = util.is_windows() and not is_wsl

-- ============================================================
-- Shared CLI IME Auto-Switching Logic (used by WSL & Linux)
-- ============================================================
---@class CliImeOpts
---@field name string Augroup name
---@field cmd_get table Command to get current status
---@field cmd_off table Command to turn off/switch to English
---@field get_cmd_on fun(target: string|nil): table|nil Returns the command to restore status
---@field sync_off_on_enter boolean Whether to run off command synchronously on enter/focus

---@param opts CliImeOpts
local function setup_cli_ime(opts)
  local aug = create_augroup(opts.name, { clear = true })

  create_autocmd('InsertLeave', {
    group = aug,
    callback = function()
      system(opts.cmd_get, { text = true }, function(obj)
        if obj.code == 0 and obj.stdout then
          schedule(function()
            vim.b.saved_im = trim(obj.stdout)
          end)
        end
      end)
      -- Force switch to English/Off
      system(opts.cmd_off)
    end,
  })

  create_autocmd('InsertEnter', {
    group = aug,
    callback = function()
      local cmd = opts.get_cmd_on(vim.b.saved_im)
      if cmd then
        system(cmd)
      end
    end,
  })

  create_autocmd({ 'VimEnter', 'FocusGained', 'CmdlineLeave' }, {
    group = aug,
    callback = function()
      if opts.sync_off_on_enter then
        system(opts.cmd_off, { text = true }):wait()
      else
        system(opts.cmd_off)
      end
    end,
  })
end

-- ============================================================
-- 1. Linux: fcitx5-remote
-- ============================================================
local FCITX5_REMOTE = executable('fcitx5-remote') == 1 and 'fcitx5-remote' or nil

function M.fcitx()
  if not FCITX5_REMOTE then return end
  local cmd_off = { FCITX5_REMOTE, '-c' }
  local cmd_on = { FCITX5_REMOTE, '-o' }

  setup_cli_ime({
    name = 'DIY_Fcitx5',
    cmd_get = { FCITX5_REMOTE },
    cmd_off = cmd_off,
    get_cmd_on = function(target) return target == '2' and cmd_on or nil end,
    sync_off_on_enter = true, -- original fcitx logic waited synchronously
  })
end

-- ============================================================
-- 2. WSL: im-select.exe (WSL Interop)
-- ============================================================
local IM_SELECT_EXE = nil

if is_wsl then
  if executable('im-select.exe') == 1 then
    IM_SELECT_EXE = 'im-select.exe'
  else
    local matches = fn.glob('/mnt/c/Users/*/scoop/apps/im-select/current/im-select.exe', true, true)
    if matches and #matches > 0 then
      IM_SELECT_EXE = matches[1]
    end
  end
end

function M.wsl_ime()
  if not IM_SELECT_EXE or executable(IM_SELECT_EXE) ~= 1 then
    vim.notify('im-select.exe not found in WSL. IME auto-switch disabled.', vim.log.levels.WARN)
    return
  end

  setup_cli_ime({
    name = 'DIY_WslIME',
    cmd_get = { IM_SELECT_EXE },
    cmd_off = { IM_SELECT_EXE, '1033' }, -- 1033 is the layout ID for English (US)
    get_cmd_on = function(target)
      return (target and target ~= '1033') and { IM_SELECT_EXE, target } or nil
    end,
    sync_off_on_enter = false,
  })
end

-- ============================================================
-- 3. Native Windows: IME control via Imm32 / user32
-- ============================================================
local IME_AVAILABLE = false
local user32, imm32

if is_windows then
  local ok, err = pcall(function()
    ffi.cdef [[
      typedef unsigned long DWORD;
      typedef void* HANDLE;
      typedef HANDLE HWND;
      typedef HANDLE HKL;
      typedef HANDLE HIMC;
      typedef unsigned int UINT;
      typedef uintptr_t WPARAM;
      typedef intptr_t LPARAM;
      typedef intptr_t LRESULT;
      typedef int BOOL;

      HWND GetForegroundWindow(void);
      HWND ImmGetDefaultIMEWnd(HWND hWnd);
      LRESULT SendMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
      BOOL PostMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
    ]]

    user32 = ffi.load('user32')
    imm32 = ffi.load('imm32')
  end)

  if ok and user32 and imm32 then
    IME_AVAILABLE = true
  else
    vim.notify('IME module FFI failed to load: ' .. tostring(err), vim.log.levels.WARN)
  end
end

local WM_INPUTLANGCHANGEREQUEST = 0x0050
local ENGLISH_US_LAYOUT_ID = 0x04090409

local WM_IME_CONTROL = 0x0283
local IMC_GETOPENSTATUS = 0x0005
local IMC_SETOPENSTATUS = 0x0006

---@param hWnd HWND
---@return boolean|nil
local function get_ime_status(hWnd)
  if not IME_AVAILABLE or hWnd == nil or hWnd == ffi.NULL then return nil end
  local ime_hWnd = imm32.ImmGetDefaultIMEWnd(hWnd)
  if ime_hWnd ~= ffi.NULL then
    local status = user32.SendMessageW(ime_hWnd, WM_IME_CONTROL, IMC_GETOPENSTATUS, 0)
    return status ~= 0
  end
  return nil
end

---@param hWnd HWND
---@param open boolean
---@return boolean
local function set_ime_status(hWnd, open)
  if not IME_AVAILABLE or hWnd == nil or hWnd == ffi.NULL then return false end
  local ime_hWnd = imm32.ImmGetDefaultIMEWnd(hWnd)
  if ime_hWnd ~= ffi.NULL then
    user32.SendMessageW(ime_hWnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, open and 1 or 0)
    return true
  end
  return false
end

function M.force_switch_to_english()
  if not IME_AVAILABLE then return end

  local hWnd = user32.GetForegroundWindow()
  if hWnd == nil or hWnd == ffi.NULL then return end

  set_ime_status(hWnd, false)
  user32.PostMessageW(hWnd, WM_INPUTLANGCHANGEREQUEST, 0, ENGLISH_US_LAYOUT_ID)
end

function M.auto_switch_ime()
  if not IME_AVAILABLE then return end

  local aug = create_augroup('DIY_WindowsIME', { clear = true })

  create_autocmd('InsertLeave', {
    group = aug,
    callback = function()
      local hWnd = user32.GetForegroundWindow()
      if hWnd ~= nil and hWnd ~= ffi.NULL then
        local status = get_ime_status(hWnd)
        vim.b.saved_ime_status = status
        set_ime_status(hWnd, false)
      end
    end,
  })

  create_autocmd('InsertEnter', {
    group = aug,
    callback = function()
      local hWnd = user32.GetForegroundWindow()
      if hWnd ~= nil and hWnd ~= ffi.NULL then
        local saved = vim.b.saved_ime_status
        if saved then
          set_ime_status(hWnd, true)
        end
      end
    end,
  })

  create_autocmd({ 'VimEnter', 'FocusGained', 'CmdlineLeave' }, {
    group = aug,
    callback = function()
      local hWnd = user32.GetForegroundWindow()
      if hWnd ~= nil and hWnd ~= ffi.NULL then
        set_ime_status(hWnd, false)
      end
    end,
  })
end

-- ============================================================
-- Setup: dispatch based on platform
-- ============================================================
M.setup = function()
  if is_wsl then
    -- WSL environment: Must use WSL Interop (.exe call)
    M.wsl_ime()
  elseif is_windows then
    -- Native Windows environment: use FFI APIs
    if IME_AVAILABLE then
      M.auto_switch_ime()
    end
  else
    -- Linux / macOS: use fcitx5-remote
    if FCITX5_REMOTE then
      M.fcitx()
    end
  end
end

return M
