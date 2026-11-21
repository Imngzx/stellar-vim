local M = {}
local api, fn = vim.api, vim.fn
local ORIGINAL_HL_CACHE = {}

M._timers = {}
local async = vim.async

-- Config Module
local config = {
  groups = {
    'Normal', 'NormalNC', 'SignColumn', 'EndOfBuffer',
    'LineNr', 'CursorLineNr', 'NonText',
    'Comment', 'Constant', 'Special', 'Identifier', 'Statement',
    'PreProc', 'Type', 'Underlined', 'Todo', 'String', 'Function',
    'Conditional', 'Repeat', 'Operator', 'Structure',
  },

  extra_groups = {
    'SnacksPickerInput', 'SnacksPickerInputBorder',
    'SnacksPickerList', 'SnacksPickerListBorder',
    'SnacksBackdrop', 'SnacksNormal',
    'NormalFloat', 'FloatBorder', 'FloatTitle', 'FloatFooter',
    'BlinkCmpMenu', 'BlinkCmpMenuBorder',
    'BlinkCmpDoc', 'BlinkCmpDocBorder',
    'BlinkCmpSignatureHelp', 'BlinkCmpSignatureHelpBorder',
    'LspInfoBorder', 'WhichKeyFloat',
    'WinBar', 'WinBarNC',
    'DropBarMenuNormalFloat', 'DropBarMenuBorder',
  },

  exclude_groups = {},
  on_clear = function() end,
}

local exclude_set = {}

local cache_path = fn.stdpath('data') .. package.config:sub(1, 1) .. 'transparent_state'

---@return boolean
local function cache_read()
  ---@type vim.async.Task<boolean>
  local task = async.run(function()
    ---@type boolean, string?, vim.uv.fs_stat_t?
    local ok, err, stat = async.pawait(2, vim.uv.fs_stat, cache_path)
    if ok and not err and stat then
      ---@type boolean, string?, integer?
      local ok, err, fd = async.pawait(4, vim.uv.fs_open, cache_path, 'r', 438)
      if ok and not err and fd then
        ---@type boolean, string?, string?
        local ok, err, data = async.pawait(4, vim.uv.fs_read, fd, stat.size, 0)
        async.pawait(2, vim.uv.fs_close, fd)
        if ok and not err and data then
          ---@cast data string
          return (data:match('true') ~= nil)
        end
      end
    end
    return false
  end)
  local ok, result = task:pwait()
  if ok then return result end
  return false
end

---@return vim.async.Task
local function cache_write()
  return async.run(function()
    local dir = vim.fs.dirname(cache_path)
    ---@type boolean, string?, vim.uv.fs_stat_t?
    local ok, err, stat = async.pawait(2, vim.uv.fs_stat, dir)
    if not ok or err or not stat then
      async.await(3, vim.uv.fs_mkdir, dir, { parents = true })
    end
    ---@type boolean, string?, integer?
    local ok, err, fd = async.pawait(4, vim.uv.fs_open, cache_path, 'w', 438)
    if ok and not err and fd then
      async.await(4, vim.uv.fs_write, fd, tostring(vim.g.bg_transparent), -1)
      async.await(2, vim.uv.fs_close, fd)
    end
  end)
end

local function clear_group(group)
  local list = type(group) == 'string' and { group } or group

  for i = 1, #list do
    local g = list[i]
    if not exclude_set[g] then
      local def = api.nvim_get_hl(0, { name = g, link = true })

      if def and not def.link then
        if ORIGINAL_HL_CACHE[g] == nil then
          ORIGINAL_HL_CACHE[g] = vim.deepcopy(def)
        end

        if def.bg or def.ctermbg then
          def.bg = nil
          def.ctermbg = nil
          api.nvim_set_hl(0, g, def)
        end
      end
    end
  end
end

local function do_clear()
  if not vim.g.bg_transparent then return end
  clear_group(config.groups)
  clear_group(config.extra_groups)
  if type(vim.g.transparent_groups) == 'table' then clear_group(vim.g.transparent_groups) end
end

function M.clear()
  if not vim.g.bg_transparent then return end

  for i = 1, #M._timers do
    require('snacks').util.stop(M._timers[i])
  end
  M._timers = {}

  do_clear()

  local timer = vim.uv.new_timer()
  if timer then
    timer:start(800, 0, vim.schedule_wrap(function()
      do_clear()
      require('snacks').util.stop(timer)
    end))
    table.insert(M._timers, timer)
  end

  api.nvim_exec_autocmds('User', { pattern = 'TransparentClear', modeline = false })
  config.on_clear()
end

function M.enable()
  vim.g.bg_transparent = true
  cache_write():pwait()
  M.clear()
end

function M.disable()
  vim.g.bg_transparent = false
  cache_write():pwait()

  for i = 1, #M._timers do
    require('snacks').util.stop(M._timers[i])
  end
  M._timers = {}

  for group, attrs in pairs(ORIGINAL_HL_CACHE) do
    api.nvim_set_hl(0, group, attrs)
  end

  ORIGINAL_HL_CACHE = {}

  vim.cmd('redraw!')
end

function M.toggle(opt)
  if opt ~= nil then
    vim.g.bg_transparent = opt
  else
    vim.g.bg_transparent = not vim.g.bg_transparent
  end

  if vim.g.bg_transparent then
    M.enable()
  else
    M.disable()
  end
end

function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_extend('force', config, opts)

  exclude_set = {}
  local exclude_groups = config.exclude_groups
  for i = 1, #exclude_groups do
    exclude_set[exclude_groups[i]] = true
  end

  vim.g.bg_transparent = cache_read()

  if opts.auto_enable ~= nil then
    if opts.auto_enable then
      vim.g.bg_transparent = true
    else
      vim.g.bg_transparent = false
    end
    cache_write():pwait()
  end

  vim.schedule(function()
    if vim.g.bg_transparent then
      M.clear()
    else
      M.disable()
    end
  end)

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('TransparentThemeSync', { clear = true }),
    callback = function()
      if vim.g.bg_transparent then
        ORIGINAL_HL_CACHE = {}
        M.clear()
      else
        ORIGINAL_HL_CACHE = {}
      end
    end,
  })
end

-- Wrapped: a command callback receives its args table, which toggle() would
-- take as the state to set.
vim.api.nvim_create_user_command('TransparentEnable', function() M.enable() end,
  { desc = 'Enable background transparency' })
vim.api.nvim_create_user_command('TransparentDisable', function() M.disable() end,
  { desc = 'Disable background transparency' })
vim.api.nvim_create_user_command('TransparentToggle', function() M.toggle() end,
  { desc = 'Toggle background transparency' })
vim.keymap.set('n', '<leader>ut', function() M.toggle() end,
  { desc = 'Toggle transparent background' })

return M
