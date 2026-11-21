if vim.b.typst_loaded then return end
vim.b.typst_loaded = true

require('libs.spell').setup()
