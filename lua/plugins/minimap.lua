-- lua/plugins/neominimap.lua
vim.g.neominimap = {
  -- loaded on a key press: auto-enabling would make the first Toggle turn it off
  auto_enable = false,
  layout = 'float',
  float = {
    minimap_width = 20,
    margin = {
      right = 0, ---@type integer
      top = 2, ---@type integer
      bottom = 15, ---@type integer
    },
    z_index = 1,
    window_border = 'rounded',
  },
  click = { enabled = true },
  diagnostic = { enabled = true, mode = 'line' },
  mini_diff = { enabled = true },
  git = { enabled = true, mode = 'sign' },
  treesitter = { enabled = true },
  notification_level = vim.log.levels.OFF,
}

-- The float covers the right edge of the window, so the plugin's README
-- wants nowrap + a wide sidescrolloff. Applied only while the minimap is
-- on, and put back after.
local saved_opts

local function sync_opts()
  local enabled = require('neominimap.api').enabled()
  if enabled and not saved_opts then
    saved_opts = { wrap = vim.o.wrap, sidescrolloff = vim.o.sidescrolloff }
    vim.opt.wrap = false
    vim.opt.sidescrolloff = 36
  elseif not enabled and saved_opts then
    vim.opt.wrap = saved_opts.wrap
    vim.opt.sidescrolloff = saved_opts.sidescrolloff
    saved_opts = nil
  end
end

local function minimap(action)
  return function()
    vim.cmd('Neominimap ' .. action)
    sync_opts()
  end
end

local function set_hl()
  vim.api.nvim_set_hl(0, 'NeominimapBackground', { bg = 'NONE' })
  local block_color = require('snacks').util.color('Visual', 'bg') or '#45475a'
  vim.api.nvim_set_hl(0, 'NeominimapCursorLine', { bg = block_color })
end

return {
  'https://github.com/Isrothy/neominimap.nvim',

  keys = {
    { 'n', '<leader>nm', minimap('Toggle'), { desc = 'Toggle minimap' } },
    { 'n', '<leader>ns', '<cmd>Neominimap ToggleFocus<cr>', { desc = 'Focus minimap' } },
    { 'n', '<leader>no', minimap('Enable'), { desc = 'Open minimap' } },
    { 'n', '<leader>nc', minimap('Disable'), { desc = 'Close minimap' } },
    { 'n', '<leader>nr', '<cmd>Neominimap Refresh<cr>', { desc = 'Refresh minimap' } },
  },
  config = function()
    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('NeominimapHL', { clear = true }),
      callback = set_hl,
    })
    set_hl()
  end
}
