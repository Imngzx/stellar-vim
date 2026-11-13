local M = {}

function M.setup(opts)
  opts = opts or {}
  require('custom.autopairs.pairs').setup(opts.pairs)
  require('custom.autopairs.surround').setup(opts.surround)
  require('custom.autopairs.tabout').setup(opts.tabout)
end

return M
