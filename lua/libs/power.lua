local M = {}

local api = vim.api
local async = vim.async
local fn = vim.fn
local pcall = pcall
local schedule = vim.schedule
local uv = vim.uv

local fs_close = async.wrap(2, uv.fs_close)
local fs_open = async.wrap(4, uv.fs_open)
local fs_read = async.wrap(4, uv.fs_read)
local fs_write = async.wrap(4, uv.fs_write)
local system = async.wrap(3, vim.system)

M.config = {
  enable_auto_switch = true,
  default_to_ac = true,
}

local _is_ac = M.config.default_to_ac
local windows_ffi
local windows_status
local cache_path

local function get_cache_path()
  if not cache_path then
    cache_path = fn.stdpath('state') .. '/power_state.cache'
  end
  return cache_path
end

local function read_cache_fast()
  local path = get_cache_path()
  local fd = uv.fs_open(path, 'r', 438)
  if not fd then return end

  local data = uv.fs_read(fd, 2, 0)
  uv.fs_close(fd)
  if data then _is_ac = data:byte(1) == 49 end
end

---@async
local function read_power_file(path)
  local open_err, fd = fs_open(path, 'r', 438)
  if open_err or not fd then return end

  local read_err, data = fs_read(fd, 2, 0)
  fs_close(fd)
  if read_err then return end
  return data
end

local function write_cache(actual_ac)
  async.run('power-cache-write', function()
    local open_err, fd = fs_open(cache_path, 'w', 438)
    if open_err or not fd then return end

    fs_write(fd, actual_ac and '1' or '0', -1)
    fs_close(fd)
  end):raise_on_error()
end

local function verify_and_notify(actual_ac)
  if actual_ac == _is_ac then return end

  _is_ac = actual_ac
  write_cache(actual_ac)

  local msg = actual_ac
    and '🔌 [Power] AC detected. Restart Neovim to initialize High-Perf Pickers (Snacks).'
    or '🔋 [Power] Battery detected. Restart Neovim to initialize Low-Power Pickers (Fzf-lua).'

  schedule(function()
    vim.notify(msg, vim.log.levels.WARN, { title = 'Engine Switch' })
  end)
end

local function check_linux()
  async.run('power-linux-check', function()
    local data = read_power_file('/sys/class/power_supply/AC/online')
      or read_power_file('/sys/class/power_supply/ACAD/online')
    if data then verify_and_notify(data:byte(1) == 49) end
  end):raise_on_error()
end

local function get_windows_status()
  if windows_status then return windows_ffi, windows_status end

  local ok, ffi = pcall(require, 'ffi')
  if not ok then return end

  if not pcall(ffi.typeof, 'SYSTEM_POWER_STATUS') then
    local declared = pcall(ffi.cdef, [[
      typedef struct _SYSTEM_POWER_STATUS {
        unsigned char ACLineStatus;
        unsigned char BatteryFlag;
        unsigned char BatteryLifePercent;
        unsigned char SystemStatusFlag;
        unsigned long BatteryLifeTime;
        unsigned long BatteryFullLifeTime;
      } SYSTEM_POWER_STATUS;
      bool GetSystemPowerStatus(SYSTEM_POWER_STATUS *lpSystemPowerStatus);
    ]])
    if not declared then return end
  end

  local allocated, status = pcall(ffi.new, 'SYSTEM_POWER_STATUS')
  if not allocated then return end

  windows_ffi = ffi
  windows_status = status
  return windows_ffi, windows_status
end

local function check_windows()
  async.run('power-windows-check', function()
    local ffi, status = get_windows_status()
    if not ffi then return end

    local ok, powered = pcall(ffi.C.GetSystemPowerStatus, status)
    if not ok or not powered then return end

    ---@diagnostic disable-next-line: undefined-field
    local ac = status.ACLineStatus
    verify_and_notify(ac == 1 or ac == 255)
  end):raise_on_error()
end

local function check_mac()
  async.run('power-macos-check', function()
    local result = system({ 'pmset', '-g', 'batt' }, { text = true })
    if result and result.code == 0 and result.stdout then
      verify_and_notify(result.stdout:find('AC Power', 1, true) ~= nil)
    end
  end):raise_on_error()
end

function M.is_ac()
  if not M.config.enable_auto_switch then return M.config.default_to_ac end
  return _is_ac
end

function M.setup(opts)
  if opts then
    for key, value in pairs(opts) do
      M.config[key] = value
    end
  end
  if not M.config.enable_auto_switch then return end

  read_cache_fast()

  local utils = require('libs.utils')
  local checker = utils.is_penguin() and check_linux
    or utils.is_windows() and check_windows
    or utils.is_mac() and check_mac or function() end

  checker()

  api.nvim_create_autocmd('FocusGained', {
    group = api.nvim_create_augroup('LibPowerStateCheck', { clear = true }),
    callback = checker,
  })
end

return M
