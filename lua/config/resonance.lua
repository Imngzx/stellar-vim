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
    keys = {
      close = { 'q', '<Esc>' },
      toggle_details = '<CR>',
      resonate = 'r',
      update = 'u',
      update_all = 'U',
      skip = 's',
      uninstall = 'dd',
      search = 'S',
      open_dir = 'D',
      review = 'C',
      checkout = 'c',
      dag = 'A',
    },
  },
})

local utils = require('libs.utils')
local safe_load = utils.safe_load
local safe_setup = utils.safe_setup
-- resonance.import() pcalls every spec file itself and reports a broken one
-- through this, so one bad file never stops the rest -- no safe_setup needed.
-- NVIM_CONFIG_STRICT=1 (tests) makes it fatal.
local import_opts = {
  on_error = function(mod, err)
    local msg = '[config] Failed to load ' .. mod .. ': ' .. tostring(err)
    if vim.env.NVIM_CONFIG_STRICT == '1' then error(msg, 0) end
    vim.notify(msg, vim.log.levels.ERROR)
  end,
}

--plugins
resonance.import('plugins.core', import_opts)

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

    -- every top-level lua/plugins/* spec (core/ is skipped: imported above)
    -- (Mason's PATH is set by plugins.lsp, see lsp.add_mason_to_path)
    resonance.import('plugins', import_opts)

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
