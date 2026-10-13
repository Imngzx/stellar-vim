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
-- 1. Linux: fcitx5-remote
-- ============================================================
local FCITX5_REMOTE = executable('fcitx5-remote') == 1 and 'fcitx5-remote' or nil

local CMD_GET = { FCITX5_REMOTE }
local CMD_OFF = { FCITX5_REMOTE, '-c' }
local CMD_ON = { FCITX5_REMOTE, '-o' }

function M.fcitx()
  if not FCITX5_REMOTE then return end

  local aug = create_augroup('DIY_Fcitx5', { clear = true })

  create_autocmd('InsertLeave', {
    group = aug,
    callback = function()
      system(CMD_GET, { text = true }, function(obj)
        if obj.code == 0 and obj.stdout then
          schedule(function()
            vim.b.saved_im = trim(obj.stdout)
          end)
        end
      end)
      system(CMD_OFF)
    end,
  })

  create_autocmd('InsertEnter', {
    group = aug,
    callback = function()
      local target = vim.b.saved_im
      if target == '2' then
        system(CMD_ON)
      end
    end,
  })

  create_autocmd({ 'VimEnter', 'FocusGained', 'CmdlineLeave' }, {
    group = aug,
    callback = function()
      system(CMD_OFF, { text = true }):wait()
    end,
  })
end

-- ============================================================
-- 2. WSL: im-select.exe (WSL Interop)
-- ============================================================
-- Update this path to where scoop installed im-select.exe
local IM_SELECT_EXE = '/mnt/c/Users/Administrator/scoop/apps/im-select/current/im-select.exe'

function M.wsl_ime()
  if executable(IM_SELECT_EXE) ~= 1 then
    vim.notify('im-select.exe not found in WSL. IME auto-switch disabled.', vim.log.levels.WARN)
    return
  end

  local aug = create_augroup('DIY_WslIME', { clear = true })
  local WSL_CMD_GET = { IM_SELECT_EXE }
  local WSL_CMD_EN = { IM_SELECT_EXE, '1033' } -- 1033 is the layout ID for English (US)

  create_autocmd('InsertLeave', {
    group = aug,
    callback = function()
      system(WSL_CMD_GET, { text = true }, function(obj)
        if obj.code == 0 and obj.stdout then
          schedule(function()
            vim.b.saved_im = trim(obj.stdout)
          end)
        end
      end)
      -- Force switch to English
      system(WSL_CMD_EN)
    end,
  })

  create_autocmd('InsertEnter', {
    group = aug,
    callback = function()
      local target = vim.b.saved_im
      if target and target ~= '1033' then
        system({ IM_SELECT_EXE, target })
      end
    end,
  })

  create_autocmd({ 'VimEnter', 'FocusGained', 'CmdlineLeave' }, {
    group = aug,
    callback = function()
      system(WSL_CMD_EN)
    end,
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
