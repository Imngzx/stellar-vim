if vim.b.gitcommit_loaded then return end
vim.b.gitcommit_loaded = true

require('libs.spell').setup()
