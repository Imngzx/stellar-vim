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

-- ============================================================
-- Linux: fcitx5-remote
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
-- Windows: IME control via Imm32 / user32
-- ============================================================
local IME_AVAILABLE = false
local user32, imm32

if util.is_windows() then
  -- Pre-declare all FFI definitions at module load
  pcall(function()
    ffi.cdef [[
      typedef unsigned long DWORD;
      typedef void* HANDLE;
      typedef HANDLE HWND;
      typedef unsigned int UINT;
      typedef uintptr_t WPARAM;
      typedef intptr_t LPARAM;
      typedef int BOOL;
      typedef long LONG;

      HWND GetForegroundWindow(void);
      DWORD GetWindowThreadProcessId(HWND hWnd, DWORD* lpdwProcessId);
      HKL GetKeyboardLayout(DWORD idThread);
      BOOL PostMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
    ]]

    -- Load DLLs
    user32 = ffi.load('user32')
    imm32 = ffi.load('imm32')

    -- Verify functions exist
    if user32.GetForegroundWindow and user32.GetWindowThreadProcessId and user32.GetKeyboardLayout and user32.PostMessageW then
      IME_AVAILABLE = true
    end
  end)
end

local WM_INPUTLANGCHANGEREQUEST = 0x0050
local ENGLISH_US_LAYOUT_ID = 0x04090409

--- Get IME open status for a window
---@param hWnd HWND
---@return boolean|nil
local function get_ime_status(hWnd)
  if not IME_AVAILABLE or hWnd == nil or hWnd == ffi.NULL then return nil end

  -- Use ImmGetOpenStatus via imm32
  if imm32.ImmGetOpenStatus then
    local hIMC = imm32.ImmGetContext(hWnd)
    if hIMC ~= ffi.NULL then
      local status = imm32.ImmGetOpenStatus(hIMC)
      imm32.ImmReleaseContext(hWnd, hIMC)
      return status ~= 0
    end
  end
  return nil
end

--- Set IME open status for a window
---@param hWnd HWND
---@param open boolean
---@return boolean
local function set_ime_status(hWnd, open)
  if not IME_AVAILABLE or hWnd == nil or hWnd == ffi.NULL then return false end

  if imm32.ImmSetOpenStatus then
    local hIMC = imm32.ImmGetContext(hWnd)
    if hIMC ~= ffi.NULL then
      local ok = imm32.ImmSetOpenStatus(hIMC, open and 1 or 0)
      imm32.ImmReleaseContext(hWnd, hIMC)
      return ok ~= 0
    end
  end
  return false
end

--- Force switch to English (US) keyboard layout
function M.force_switch_to_english()
  if not IME_AVAILABLE then return end

  local hWnd = user32.GetForegroundWindow()
  if hWnd == nil or hWnd == ffi.NULL then return end

  -- 1. Turn off IME
  set_ime_status(hWnd, false)

  -- 2. Switch to English layout via PostMessageW
  -- WM_INPUTLANGCHANGEREQUEST with HKL for US English
  user32.PostMessageW(hWnd, WM_INPUTLANGCHANGEREQUEST, 0, ENGLISH_US_LAYOUT_ID)
end

--- Auto-switch IME on mode change (Insert <-> Normal)
function M.auto_switch_ime()
  if not IME_AVAILABLE then return end

  local aug = create_augroup('DIY_WindowsIME', { clear = true })

  create_autocmd('InsertLeave', {
    group = aug,
    callback = function()
      local hWnd = user32.GetForegroundWindow()
      if hWnd ~= nil and hWnd ~= ffi.NULL then
        -- Save IME state per buffer
        local status = get_ime_status(hWnd)
        vim.b.saved_ime_status = status
        -- Turn off IME
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
  if util.is_windows() then
    -- Native Windows or WSL: use Windows IME APIs
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
