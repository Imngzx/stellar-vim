_G.I = require('libs.icons')

local vim_g = vim.g
local loader = vim.loader

-- Bytecode cache
if loader then
  loader.enable()
end

vim_g.markdown_recommended_style = 0

local disabled_built_ins = {
  'fzf',
  'gzip',
  'matchit',
  'netrwPlugin',
  'netrwSettings',
  'netrwFileHandlers',
  'matchparen',
  'tarPlugin',
  'tutor',
  'zipPlugin',
  'tohtml',
}
for i = 1, #disabled_built_ins do
  vim_g['loaded_' .. disabled_built_ins[i]] = 1
end

require('custom.ui2').setup()

--[Startup Profiler]
if vim.env.PROF then
  vim.cmd('packadd snacks.nvim')
  require('snacks.profiler').startup({
    startup = {
      event = 'VimEnter',
    },
  })
end

-- PERF: changing picker due to powermode
-- fzf during battery mode
-- snacks during wall power mode
require('libs.power').setup({ enable_auto_switch = true })

-- NOTE: list of disabled plugin during battery mode
-- Snacks.animate, partial Snacks.picker, Snacks.image
-- render-markdown.nvim
