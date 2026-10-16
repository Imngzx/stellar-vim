local M = {}

-- [LSP]
M.lsp = {
  error = ' ',
  warn = ' ',
  hint = ' ',
  info = ' ',
}

M.basic = {
  dir = '󰉋',
  dir_open = '󰉖',
  file = ' ',
  modify = ' ● ',
  close = ' 󰅖 ',
  indent = '│'
}

M.git = {
  commit = '󰜘',
  branch = '󰘬',
  staged = '',
  added = '',
  deleted = '',
  ignored = '',
  modified = '',
  renamed = '',
  unmerged = '',
  untracked = '󰊠',
}

return M
