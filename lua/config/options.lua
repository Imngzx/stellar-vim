local opt = vim.opt
local o = vim.o

-- [Appearance]
opt.signcolumn = 'yes' -- always show sign column
opt.winborder = 'rounded'
opt.showmode = false -- Hide mode status

-- Line edit
opt.fillchars = {
  eob = ' ',
  vert = '│',
  horiz = '─',
  verthoriz = '┼',
  vertleft = '┤',
  vertright = '├',
  horizup = '┴',
  horizdown = '┬',
  fold = ' ',
  foldopen = '',
  foldclose = '',
  foldsep = ' ',
}
opt.list = true
opt.listchars = {
  tab = '  ',
  trail = '·',
  nbsp = '␣',
  extends = '›',
  precedes = '‹',
}
opt.cursorline = true -- highlight current line
opt.scrolloff = 4 -- keep 4 lines visible around cursor
opt.scrolloffpad = 1 -- cursor position stays at middle when you go to eob
opt.sidescrolloff = 8 -- keep 8 columns visible horizontally

-- Line number
opt.number = true
opt.relativenumber = true
opt.numberwidth = 4

-- Indent
opt.expandtab = true -- use spaces instead of tabs
opt.shiftwidth = 2 -- indent size
opt.tabstop = 2 -- tab character width
opt.shiftround = true -- round indent to nearest multiple of shiftwidth
opt.smartindent = true -- auto-indent new lines intelligently

-- Wrap
opt.wrap = true -- default line wrap
opt.linebreak = true -- wrap at word boundary if wrap
opt.breakindent = true -- maintain indent on wrap

-- Others
opt.winminwidth = 5 -- prevent tiny splits
opt.undofile = true
if require('libs.utils').is_windows() then opt.shadafile = 'NONE' end
o.sessionoptions = 'buffers,curdir,tabpages,winsize,help,skiprtp,folds'
opt.jumpoptions = 'view' -- restore view after jump
opt.virtualedit = 'block' -- allow cursor past EOL in block mode
opt.updatetime = 250 -- reduce execution time takes from cursorhold

-- [Editor]
opt.cmdheight = 0
opt.fileformat = 'unix'
opt.ruler = false
opt.confirm = true -- confirm before quitting unsaved changes
o.autoread = true

-- Case
opt.ignorecase = true -- case-insensitive by default
opt.incsearch = true -- show search results while typing
opt.smartcase = true -- but smart if uppercase is used

-- Split
opt.splitbelow = true -- horizontal splits below
opt.splitright = true -- vertical splits to the right
opt.splitkeep = 'screen' -- preserve layout when splitting

-- Format
opt.formatoptions = 'jcroqlnt' -- keep comments, wrap text, autoformat when possible

-- Command
opt.inccommand = 'nosplit' -- live preview for :substitute
opt.wildmode = 'longest:full,full' -- enhanced command completion

vim.o.foldcolumn = '1'
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
-- vim.o.foldmethod = 'expr'
-- vim.o.foldexpr = 'v:lua.require"ufo".foldexpr()'

-- Check spelling
opt.spell = false
opt.spellsuggest = 'best,5' -- show only first best 5
opt.spelloptions = 'camel' -- support CamelCase

-- lsp checkhealth warning removal
vim.filetype.add({
  extension = {
    mdx = 'markdown.mdx',
    dox = 'c.doxygen',
    doxy = 'cpp.doxygen',
    gotmpl = 'gotmpl'
  }
})
