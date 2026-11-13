--- Strict configuration boot test.
--- Run: nvim --headless -u NONE -c "luafile ~/.config/nvim/tests/strict_boot.lua" -c "qall!"
--- Exit code 0 = pass, non-zero = failure.

local config_root = vim.fn.stdpath('config')
vim.env.NVIM_CONFIG_STRICT = '1'
vim.opt.rtp:prepend(config_root)

dofile(vim.fs.joinpath(config_root, 'init.lua'))

local resonance = require('resonance')
vim.api.nvim_exec_autocmds('User', { pattern = 'VeryLazy' })
vim.wait(100)

local function assert_map(mode, lhs)
  assert(vim.fn.maparg(lhs, mode) ~= '', 'Missing ' .. mode .. ' mapping: ' .. lhs)
end

assert_map('i', '<Tab>')
assert_map('i', '<S-Tab>')
assert_map('n', 'sa')
assert_map('n', 'sd')
assert_map('n', 'sr')
assert_map('x', '(')

print('[SUCCESS] Strict configuration boot passed')
