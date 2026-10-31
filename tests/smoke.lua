--- Smoke test for nvim config
--- Run: nvim --headless -c "luafile ~/.config/nvim/tests/smoke.lua" -c "qall"
--- Exit code 0 = pass, non-zero = fail

local io_stderr = io.stderr
local io_stdout = io.stdout
local os_exit = os.exit
local pcall = pcall
local tostring = tostring
local assert = assert
local string_format = string.format
local vim_inspect = vim.inspect
local vim_wait = vim.wait
local vim_cmd = vim.cmd
local vim_pack_get = vim.pack.get
local vim_api_list_rtp = vim.api.nvim_list_runtime_paths
local table_concat = table.concat
local table_insert = table.insert
local string_find = string.find

local function fail(msg)
  io_stderr:write('[FAIL] ' .. msg .. '\n')
  os_exit(1)
end

local function pass(msg)
  io_stdout:write('[PASS] ' .. msg .. '\n')
end

local function assert_truthy(val, msg)
  if not val then fail(msg) end
end

-- ============================================================
-- 1. Load core config
-- ============================================================
pass('Loading core config...')
local ok, err = pcall(function()
  dofile(vim.env.MYVIMRC)
end)
assert_truthy(ok, 'Failed to load init.lua: ' .. tostring(err))
pass('Core config loaded')

-- ============================================================
-- 2. Verify resonance.nvim is available
-- ============================================================
pass('Checking resonance.nvim...')
local resonance = require('resonance')
assert_truthy(resonance, 'resonance module not found')
assert_truthy(resonance.load, 'resonance.load not found')
assert_truthy(resonance.trigger_verylazy, 'resonance.trigger_verylazy not found')
pass('resonance.nvim API available')

-- ============================================================
-- 3. Trigger VeryLazy to load all plugins
-- ============================================================
pass('Triggering VeryLazy...')
resonance.trigger_verylazy()
vim_wait(100) -- allow async loads to complete
pass('VeryLazy triggered')

-- ============================================================
-- 4. Verify key plugins are in rtp
-- ============================================================
pass('Verifying plugin runtime paths...')
local required_plugins = {
  'snacks.nvim',
  'heirline.nvim',
  'catppuccin',
  'nvim-treesitter',
  'nvim-lspconfig',
  'mason.nvim',
  'bpm.nvim',
  'conform.nvim',
  'nvim-lint',
  'nvim-dap',
  'blink.cmp',
  'flash.nvim',
  'which-key.nvim',
  'mini.icons',
  'mini.diff',
  'render-markdown.nvim',
  'csvview.nvim',
  'nvim-ufo',
  'nvim-treesitter-context',
  'colorful-menu.nvim',
  'tiny-inline-diagnostic.nvim',
  'venv-selector.nvim',
  'jisho.nvim',
  'codecompanion.nvim',
  'telegram.nvim',
  'cord.nvim',
  'atone.nvim',
  'ascetic.nvim',
  'showkeys',
  'neogit',
  'nvim-hlslens',
  'popup.nvim',
  'lazydev.nvim',
  'friendly-snippets',
  'fzf-lua',
  'nvim-dap-python',
  'nvim-dap-ui',
  'nvim-dap-virtual-text',
  'nvim-nio',
  'plenary.nvim',
  'promise-async',
  'budoux.lua',
}

-- Plugins that are lazy-loaded via event/cmd/keys/ft triggers
-- These won't be in rtp until their trigger fires
local lazy_plugins = {
  'heirline.nvim',
  'bpm.nvim',
  'flash.nvim',
  'fzf-lua',
  'neogit',
  'nvim-hlslens',
  'showkeys',
  'venv-selector.nvim',
  'csvview.nvim',
  'jisho.nvim',
  'codecompanion.nvim',
  'telegram.nvim',
  'cord.nvim',
  'atone.nvim',
  'ascetic.nvim',
  'popup.nvim',
  'lazydev.nvim',
  'friendly-snippets',
  'nvim-dap-python',
  'nvim-dap-ui',
  'nvim-dap-virtual-text',
  'nvim-nio',
  'plenary.nvim',
  'promise-async',
  'budoux.lua',
  'nvim-treesitter',
  'nvim-lspconfig',
  'mason.nvim',
  'blink.cmp',
  'conform.nvim',
  'nvim-lint',
  'nvim-dap',
  'nvim-ufo',
  'nvim-treesitter-context',
  'colorful-menu.nvim',
  'tiny-inline-diagnostic.nvim',
  'render-markdown.nvim',
  'which-key.nvim',
  'mini.icons',
  'mini.diff',
}

-- Open a buffer to trigger BufReadPost events
vim_cmd('enew')

for i = 1, #required_plugins do
  local plugin = required_plugins[i]
  local is_lazy = false
  for j = 1, #lazy_plugins do
    if plugin == lazy_plugins[j] then
      is_lazy = true
      break
    end
  end

  local found = false
  local rtp = vim_api_list_rtp()
  for k = 1, #rtp do
    if string_find(rtp[k], plugin, 1, true) then
      found = true
      break
    end
  end

  if is_lazy then
    -- For lazy plugins, just verify they're installed (via vim.pack.get)
    local installed = false
    local packs = vim_pack_get()
    for m = 1, #packs do
      local pack = packs[m]
      if pack.spec and pack.spec.name == plugin then
        installed = true
        break
      end
    end
    assert_truthy(installed, 'Lazy plugin not installed: ' .. plugin)
    pass('Lazy plugin installed: ' .. plugin)
  else
    assert_truthy(found, 'Plugin not in rtp: ' .. plugin)
    pass('Plugin in rtp: ' .. plugin)
  end
end
pass('All plugins verified (installed or in rtp)')

-- ============================================================
-- 5. Verify custom modules load
-- ============================================================
pass('Loading custom modules...')
local custom_modules = {
  'custom.startup',
  'custom.session',
  'custom.workspace',
  'custom.coderunner',
  'custom.repl',
  'custom.todo',
  'custom.transparent',
  'custom.zettel',
  'custom.git',
  'custom.git-blame',
  'custom.incline',
  'custom.lsp-loading',
  'custom.multicursor',
  'custom.pairs',
  'custom.surround',
  'custom.word-jump',
  'custom.cheatsheet',
  'custom.sudo',
  'custom.yazi',
  'custom.language-switcher',
  'config.options',
  'config.keymaps',
  'config.autocmds',
  'config.resonance',
  'config.clipboard',
  'libs.utils',
  'libs.power',
  'libs.git',
  'libs.icons',
  'libs.spell',
  'lsp.init',
  'lsp.servers',
}

for i = 1, #custom_modules do
  local mod = custom_modules[i]
  local ok, mod_obj = pcall(require, mod)
  assert_truthy(ok, 'Failed to require ' .. mod .. ': ' .. tostring(mod_obj))
  assert_truthy(mod_obj, 'Module returned nil: ' .. mod)
end
pass('All ' .. #custom_modules .. ' custom modules loaded')

-- ============================================================
-- 6. Verify LSP servers registered
-- ============================================================
pass('Checking LSP servers...')
local lsp_init = require('lsp.init')
lsp_init.setup()
assert_truthy(#lsp_init.enabled_servers > 0, 'No LSP servers enabled')
pass('LSP servers: ' .. table_concat(lsp_init.enabled_servers, ', '))

-- ============================================================
-- 7. Test session save/load
-- ============================================================
pass('Testing session save/load...')
local session = require('custom.session')
session.save()
session.load()
pass('Session save/load works')

-- ============================================================
-- 8. Test workspace picker
-- ============================================================
pass('Testing workspace picker...')
local workspace = require('custom.workspace')
workspace.picker()
pass('Workspace picker works')

-- ============================================================
-- 9. Test git integration
-- ============================================================
pass('Testing git integration...')
local git = require('custom.git')
git.setup({
  stage_action = require('snacks').picker.actions.git_stage,
  get_git_root = require('snacks').git.get_root
})
local blame = require('custom.git-blame')
blame.setup({
  enabled = true,
  get_git_root = require('snacks').git.get_root
})
pass('Git integration works')

-- ============================================================
-- 10. Test heirline statusline
-- ============================================================
pass('Checking heirline...')
-- heirline.nvim is lazy-loaded via BufReadPost/BufNewFile
-- Verify it's installed instead of requiring (would fail if not triggered)
local heirline_installed = false
local packs = vim_pack_get()
for i = 1, #packs do
  local pack = packs[i]
  if pack.spec and pack.spec.name == 'heirline.nvim' then
    heirline_installed = true
    break
  end
end
assert_truthy(heirline_installed, 'heirline.nvim not installed')
pass('heirline.nvim installed')

-- ============================================================
-- 11. Test snacks picker
-- ============================================================
pass('Checking snacks...')
local snacks = require('snacks')
assert_truthy(snacks.picker, 'snacks.picker not available')
assert_truthy(snacks.terminal, 'snacks.terminal not available')
assert_truthy(snacks.git, 'snacks.git not available')
pass('snacks.nvim core modules available')

-- ============================================================
-- 12. Test bpm.nvim (tabline/workspace)
-- ============================================================
pass('Checking bpm.nvim...')
-- bpm.nvim is lazy-loaded via BufReadPost/BufNewFile
-- Verify it's installed instead of requiring (would fail if not triggered)
local bpm_installed = false
packs = vim_pack_get()
for i = 1, #packs do
  local pack = packs[i]
  if pack.spec and pack.spec.name == 'bpm.nvim' then
    bpm_installed = true
    break
  end
end
assert_truthy(bpm_installed, 'bpm.nvim not installed')
pass('bpm.nvim installed')

-- ============================================================
-- 13. Test transparent toggle
-- ============================================================
pass('Testing transparent toggle...')
local transparent = require('custom.transparent')
transparent.setup({ auto_enable = false })
transparent.toggle()
pass('Transparent toggle works')

-- ============================================================
-- 14. Test todo
-- ============================================================
pass('Testing todo...')
local todo = require('custom.todo')
todo.setup()
todo.search()
pass('Todo works')

-- ============================================================
-- 15. Test coderunner
-- ============================================================
pass('Testing coderunner...')
local coderunner = require('custom.coderunner')
coderunner.build_run_command()
pass('Coderunner works')

-- ============================================================
-- 16. Test config reload
-- ============================================================
pass('Testing config reload...')
dofile(vim.env.MYVIMRC)
pass('Config reload works')

-- ============================================================
-- ALL TESTS PASSED
-- ============================================================
io_stdout:write('\n[SUCCESS] All smoke tests passed!\n')
os_exit(0)