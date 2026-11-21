if vim.b.text_loaded then return end
vim.b.text_loaded = true

require('libs.spell').setup()
