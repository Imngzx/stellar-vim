if vim.b.plaintex_loaded then return end
vim.b.plaintex_loaded = true

require('libs.spell').setup()
