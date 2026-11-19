-- =====================================================================
-- 🎵 Install Resonance.nvim
-- =====================================================================
vim.pack.add({ 'https://github.com/Imngzx/resonance.nvim' })
-- vim.pack installs and manages resonance itself; resonance.load() is for
-- every other plugin. Pin a branch or tag here if you want one, e.g.
-- { src = 'https://github.com/Imngzx/resonance.nvim', version = 'main' }.

-- =====================================================================
-- 🚀 Configuration
-- =====================================================================
-- setup() runs before any resonance.load() below, so its options apply to
-- every plugin from the first one.
local resonance = require('resonance')
vim.keymap.set('n', '<leader>pL', '<cmd>Resonance<cr>', { desc = '[Float] Resonance UI' })
resonance.setup({
  ui = {
    border = 'rounded',
    width = 0.65,
    height = 0.75,
  },
})

local utils = require('libs.utils')
local safe_load = utils.safe_load
local safe_setup = utils.safe_setup
local scan = require('config.scan')

--plugins
safe_setup('config.scan', function()
  scan.import('plugins.core')
end)

-- [Core] lua/plugins/core/: theme + core UI, loaded now, highest `priority`
-- first (catppuccin = 1000, so the theme lands before any UI plugin)

-- NOTE: the specs in lua/plugins/ are imported in VeryLazy, not here.
-- Requiring a spec file runs it -- Lua parses it and builds its tables and
-- closures -- even though the plugin it describes stays lazy. Importing
-- them all at startup would cost that time before the first screen.
-- Resonance still lazy-loads the plugins themselves either way.

vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  callback = function()
    -- restore session
    safe_setup('custom.workspace')

    -- every top-level lua/plugins/* spec (core/ is skipped, see config/scan.lua)
    -- (Mason's PATH is set by plugins.lsp, see lsp.add_mason_to_path)
    safe_setup('config.scan', function() scan.import('plugins') end)

    -- coding
    safe_setup('custom.autopairs')
    safe_load('custom.word-jump')

    -- UI
    safe_setup('custom.incline')
    safe_setup('custom.lsp-loading')
    safe_setup('custom.transparent', { auto_enable = false })
    safe_setup('custom.multicursor')

    -- Util
    safe_setup('custom.coderunner')
    safe_setup('custom.repl')
    safe_setup('custom.language-switcher')
    safe_setup('custom.todo')
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
  end
})

-- VeryLazy fires on its own (resonance.setup()/load() arm it), and right
-- after the VeryLazy handlers above have run, Resonance replays the read
-- events for every open file. So the UI plugins registered during VeryLazy
-- (heirline, bpm, treesitter, lsp, ...) still load for `nvim <file>`.
-- No trigger_verylazy() or replay loop needed. To turn the replay off:
-- resonance.setup({ replay = false })
