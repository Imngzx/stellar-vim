---@module 'snacks'

local utils = require('libs.utils')
local power = require('libs.power')

-- 1. 加载核心插件
vim.pack.add({ 'https://github.com/folke/snacks.nvim' })
local Snacks = require('snacks')

-- 2. 组装化配置（加载刚刚拆分出来的文件！）
Snacks.setup({
  bigfile = {
    enabled = true,
    notify = true,
    size = 1.5 * 1024 * 1024, -- 1.5MB
    line_length = 1500,
  },
  explorer = { enabled = true },
  image = { enabled = power.is_ac() },
  indent = {
    enabled = true,
    indent = {
      hl = 'SnacksIndentInactive',
    },
    scope = {
      enabled = true,
      underline = false,
      hl = {
        'SnacksIndent1',
        'SnacksIndent2',
        'SnacksIndent3',
        'SnacksIndent4',
        'SnacksIndent5',
        'SnacksIndent6',
        'SnacksIndent7',
      },
    },
  },
  input = { enabled = false },
  profiler = { enabled = true },
  quickfile = { enabled = true },
  scope = { enabled = true },
  words = { enabled = true },
  styles = {},
  scroll = {
    enabled = power.is_ac(),
    animate = { duration = { step = 10, total = 50 }, easing = 'linear' },
  },
  statuscolumn = {
    enabled = true,
    folds = { open = true, git_hl = true },
  },
  notifier = {
    enabled = true,
    timeout = 3000,
    width = { min = 40, max = 0.4 },
    height = { min = 1, max = 0.1 },
    margin = { top = 1, right = 1, bottom = 1 },
    padding = true,
    sort = { 'level', 'added' },
    style = 'compact',
    top_down = true,
    date_format = '%R',
    refresh = 150,
  },

  dashboard = require('plugins.snacks.dashboard'),
  picker = require('plugins.snacks.picker'),
})

-- 3. 读取分离出去的按键配置
local key = require('plugins.snacks.keys')

local keymap_set = vim.keymap.set

local set_keys = function(keys)
  for i = 1, #keys do
    local k = keys[i]
    local lhs, rhs = k[1], k[2]

    if lhs and rhs then
      local opts = {}
      if k.desc then opts.desc = k.desc end
      if k.nowait ~= nil then opts.nowait = k.nowait end
      if k.silent ~= nil then opts.silent = k.silent end
      if k.expr ~= nil then opts.expr = k.expr end
      if k.buf ~= nil then opts.buf = k.buf end

      local mode = k.mode or 'n'
      if type(mode) == 'table' then
        for j = 1, #mode do
          keymap_set(mode[j], lhs, rhs, opts)
        end
      else
        keymap_set(mode, lhs, rhs, opts)
      end
    end
  end
end

-- 4. 依托你精湛的按需加载引擎
require('resonance').load({
  'https://github.com/folke/snacks.nvim',
  event = { 'User', pattern = 'VeryLazy' },
  config = function()
    set_keys(key)

    _G.dd = function(...) Snacks.debug.inspect(...) end

    -- NOTE: can enable this if you want snacks notifier shows lsp progress
    -- require('plugins.snacks.lsp_progress')

    if utils.is_compatible_version('0.11') then
      ---@diagnostic disable-next-line: duplicate-set-field
      vim._print = function(_, ...) dd(...) end
    else
      vim.print = _G.dd
    end

    -- 切换器快捷键保留
    Snacks.toggle.option('spell', { name = 'Spelling' }):map('<leader>us')
    Snacks.toggle.option('wrap', { name = 'Wrap' }):map('<leader>uw')
    Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map('<leader>uL')
    Snacks.toggle.diagnostics():map('<leader>ud')
    Snacks.toggle.line_number():map('<leader>ul')
    Snacks.toggle.option('conceallevel',
      { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map('<leader>uc')
    Snacks.toggle.treesitter():map('<leader>uT')
    Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map(
      '<leader>uB')
    Snacks.toggle.inlay_hints():map('<leader>uh')
    Snacks.toggle.indent():map('<leader>ug')
    Snacks.toggle.dim():map('<leader>uD')
  end
})

return Snacks
