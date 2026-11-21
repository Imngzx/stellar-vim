--- Strict configuration boot test.
--- Run: nvim --headless -u NONE -c "luafile ~/.config/nvim/tests/strict_boot.lua" -c "qall!"
--- Exit code 0 = pass, non-zero = failure.

local config_root = vim.fn.stdpath('config')
vim.env.NVIM_CONFIG_STRICT = '1'
vim.opt.rtp:prepend(config_root)

-- resonance pcalls every plugin's config() and only reports a failure, and
-- once snacks is up it reports through Snacks.notifier, not vim.notify.
-- Collect error-level notifications from both so they fail the test.
local errors = {}
local ERROR = vim.log.levels.ERROR
local function watch(tbl, key)
  local notify = tbl[key]
  tbl[key] = function(msg, level, opts)
    if level == ERROR then errors[#errors + 1] = tostring(msg) end
    return notify(msg, level, opts)
  end
end
watch(vim, 'notify')

dofile(vim.fs.joinpath(config_root, 'init.lua'))

-- `-c luafile` runs before VimEnter and `-c qall` quits before it fires, so
-- the `lazy = false` core specs (catppuccin, snacks) would never load.
vim.api.nvim_exec_autocmds('VimEnter', { modeline = false })
assert(vim.g.colors_name, 'colorscheme not loaded on VimEnter')
assert(package.loaded['snacks'], 'snacks not loaded on VimEnter')
-- snacks replaces vim.notify
watch(vim, 'notify')
watch(require('snacks').notifier, 'notify')

vim.api.nvim_exec_autocmds('User', { pattern = 'VeryLazy' })
vim.wait(200)

local function assert_map(mode, lhs)
  assert(vim.fn.maparg(lhs, mode) ~= '', 'Missing ' .. mode .. ' mapping: ' .. lhs)
end

assert_map('i', '<Tab>')
assert_map('i', '<S-Tab>')
assert_map('n', 'sa')
assert_map('n', 'sd')
assert_map('n', 'sr')
assert_map('x', '(')

assert(#errors == 0, 'Errors reported during boot:\n' .. table.concat(errors, '\n'))

print('[SUCCESS] Strict configuration boot passed')
