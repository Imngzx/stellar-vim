-- =====================================================================
-- 🎵 Install Resonance.nvim
-- =====================================================================
vim.pack.add({ 'https://github.com/Imngzx/resonance.nvim' })

-- =====================================================================
-- 🚀 Configuration
-- =====================================================================
local resonance = require('resonance')
resonance.load({
  'https://github.com/Imngzx/resonance.nvim',
  version = 'main',
  lazy = false,
  keys = {
    { 'n', '<leader>pL', '<cmd>Resonance<cr>', { desc = '[Float] Resonance UI' } },
  },
  config = function()
    resonance.setup({
      ui = {
        border = 'rounded',
        width = 0.65,
        height = 0.75,
      }
    })
  end
})

local utils = require('libs.utils')
local safe_load = utils.safe_load
local safe_setup = utils.safe_setup

--plugins

-- [Theme]
-- load theme first to avoid flickering
safe_load('plugins.catppuccin')

-- load core ui elements at the same time
safe_load('plugins.snacks')
safe_load('plugins.cmdline')
safe_load('plugins.ui')

safe_load('plugins.tool')

-- idk why it wont load if it's inside the block ((
safe_load('plugins.discord')

-- NOTE: the reson I wrap my plugins with this block is because the mechanics of luajit
-- although resonance.nvim will blocks luajit to require the plugin until resonance sends it to rtp
-- but luajit will still read the config file (not the plugin)
-- this will cause some slow startup time
-- It doesnt meant that resonance is not lazy-loading

vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  callback = function()
    -- restore session
    safe_setup('custom.workspace', require('custom.workspace').setup)
    safe_load('plugins.fzf')

    -- coding
    local fn, env = vim.fn, vim.env
    local mason_bin = vim.fs.joinpath(fn.stdpath('data'), 'mason', 'bin')
    local is_windows = utils.is_windows()
    if is_windows then mason_bin = mason_bin:gsub('/', '\\') end
    if not env.PATH:find(mason_bin, 1, true) then
      local sep = is_windows and ';' or ':'
      env.PATH = mason_bin .. sep .. env.PATH
    end
    safe_load('plugins.treesitter')
    safe_load('plugins.lsp')
    safe_load('plugins.treesitter-context')
    safe_load('plugins.colorful-lsp-menu')
    safe_load('plugins.ufo')
    safe_setup('custom.autopairs', require('custom.autopairs').setup)
    safe_load('custom.word-jump')

    -- UI
    safe_load('plugins.heirline')
    safe_setup('custom.incline', require('custom.incline').setup)
    safe_setup('custom.lsp-loading', require('custom.lsp-loading').setup)
    safe_setup('custom.transparent', require('custom.transparent').setup, { auto_enable = false })
    safe_setup('custom.multicursor', require('custom.multicursor').setup)
    safe_load('plugins.minimap')
    safe_load('plugins.mini-hipatterns')
    safe_load('plugins.markdown')
    safe_load('plugins.csvview')

    -- Util
    safe_setup('custom.coderunner', require('custom.coderunner').setup)
    safe_setup('custom.repl', require('custom.repl').setup)
    safe_load('plugins.venv-selector')
    safe_load('plugins.dap')
    safe_load('plugins.jisho')
    safe_load('plugins.AI')
    safe_load('plugins.atone')
    safe_setup('custom.language-switcher', require('custom.language-switcher').setup)
    safe_setup('custom.todo', require('custom.todo').setup)
    safe_load('custom.sudo')


    -- [git]
    safe_setup('custom.git', function(opts)
      require('custom.git').setup(opts)
    end, {
      stage_action = function(picker) require('snacks').picker.actions.git_stage(picker) end,
      get_git_root = function(filepath) return require('snacks').git.get_root(filepath) end
    })
    safe_setup('custom.git-blame', function(opts)
      require('custom.git-blame').setup(opts)
    end, {
      enabled = true,
      message_template = '  󰈔 <summary>,  <author> (<date>)',
      date_format = '%r',
      delay = 1000,
      max_summary_length = 30,
      get_git_root = function(filepath) return require('snacks').git.get_root(filepath) end
    })

    safe_load('plugins.telegram')
  end
})

-- The replay lives in its OWN autocmd, registered after the VeryLazy one, so
-- it runs after every trigger has been registered but is NOT aborted when a
-- plugin's setup() raises (popup.nvim raises on this neovim build).
--
-- `replay_for_buffer` fires only the trigger groups that have not yet run
-- for the buffer, so the UI plugins (heirline, bpm, treesitter, lsp, ...)
-- register their triggers during VeryLazy -- AFTER BufReadPost/BufEnter
-- already fired -- and still get their chance to load.
vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  callback = function()
    -- Synchronous on purpose: a scheduled callback runs after this callback
    -- returns, by which point the `once = true` triggers have already been
    -- consumed and the replay fires into nothing.
    local api = vim.api
    local bufs = api.nvim_list_bufs()
    for i = 1, #bufs do
      local buf = bufs[i]
      if api.nvim_buf_is_loaded(buf) and api.nvim_buf_get_name(buf) ~= '' then
        pcall(resonance.replay_for_buffer, buf)
      end
    end
  end,
})


-- NOTE: must put this at the end of your init.lua!
resonance.trigger_verylazy()
