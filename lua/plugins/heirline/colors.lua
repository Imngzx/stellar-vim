local utils = require('heirline.utils')
local M = {}
local active_colors = {}

function M.setup_colors()
  local statusline = utils.get_highlight('StatusLine')
  local diagnostic_info = utils.get_highlight('DiagnosticInfo')
  local error = utils.get_highlight('Error')
  local match_paren = utils.get_highlight('MatchParen')
  local cursor_line = utils.get_highlight('CursorLine')

  local palette = {
    bg = statusline.bg or '#1e1e2e',
    fg = statusline.fg or '#cdd6f4',

    -- bright_bg = utils.get_highlight('Folded').bg or '#45475a',
    -- section_bg = utils.get_highlight('CursorLine').bg or '#313244',
    bright_bg = '#45475a',
    section_bg = '#313244',

    normal = utils.get_highlight('Directory').fg or '#89b4fa',
    insert = utils.get_highlight('String').fg or '#a6e3a1',
    visual = utils.get_highlight('Statement').fg or '#cba6f7',
    replace = error.fg or '#f38ba8',
    command = match_paren.fg or '#fab387',
    terminal = utils.get_highlight('WarningMsg').fg or '#f9e2af',
    diag_error = utils.get_highlight('DiagnosticError').fg,
    diag_warn = utils.get_highlight('DiagnosticWarn').fg,
    diag_info = diagnostic_info.fg,
    diag_hint = utils.get_highlight('DiagnosticHint').fg,
    git_add = utils.get_highlight('MiniDiffSignAdd').fg or '#a6e3a1',
    git_change = utils.get_highlight('MiniDiffSignChange').fg or '#f9e2af',
    git_del = utils.get_highlight('MiniDiffSignDelete').fg or '#f38ba8',

    lsp_name = diagnostic_info.fg,
    venv_name = utils.get_highlight('Type').fg,

    tab_mod = match_paren.fg,
    tab_cross_bg = error.fg,
    tab_num = diagnostic_info.fg,
    tab_num_unfocus = utils.get_highlight('Comment').fg,
    tab_cross_fg = cursor_line.bg,
  }

  active_colors = palette
  return palette
end
M.mode_names = {
  n = 'NORMAL',
  no = 'OP-PENDING',
  nov = 'OP-PENDING',
  noV = 'OP-PENDING',
  ['no\22'] = 'OP-PENDING',
  niI = 'NORMAL',
  niR = 'NORMAL',
  niV = 'NORMAL',
  nt = 'NORMAL',
  ntT = 'NORMAL',
  v = 'VISUAL',
  vs = 'VISUAL',
  V = 'V-LINE',
  Vs = 'V-LINE',
  ['\22'] = 'V-BLOCK',
  ['\22s'] = 'V-BLOCK',
  s = 'SELECT',
  S = 'S-LINE',
  ['\19'] = 'S-BLOCK',
  i = 'INSERT',
  ic = 'INSERT',
  ix = 'INSERT',
  R = 'REPLACE',
  Rc = 'REPLACE',
  Rx = 'REPLACE',
  Rv = 'V-REPLACE',
  Rvc = 'V-REPLACE',
  Rvx = 'V-REPLACE',
  c = 'COMMAND',
  cv = 'EX',
  ce = 'EX',
  r = 'PROMPT',
  rm = 'MORE',
  ['r?'] = 'CONFIRM',
  x = 'CONFIRM',
  ['!'] = 'SHELL',
  t = 'TERMINAL',
}

M.mode_colors = {
  n = 'normal',
  no = 'replace',
  nov = 'replace',
  noV = 'replace',
  ['no\22'] = 'replace',
  niI = 'normal',
  niR = 'normal',
  niV = 'normal',
  nt = 'normal',
  ntT = 'normal',
  v = 'visual',
  vs = 'visual',
  V = 'visual',
  Vs = 'visual',
  ['\22'] = 'visual',
  ['\22s'] = 'visual',
  s = 'visual',
  S = 'visual',
  ['\19'] = 'visual',
  i = 'insert',
  ic = 'insert',
  ix = 'insert',
  R = 'replace',
  Rc = 'replace',
  Rx = 'replace',
  Rv = 'replace',
  Rvc = 'replace',
  Rvx = 'replace',
  c = 'command',
  cv = 'command',
  ce = 'command',
  r = 'replace',
  rm = 'replace',
  ['r?'] = 'replace',
  x = 'replace',
  ['!'] = 'command',
  t = 'terminal',
}

function M.get_mode_color(mode)
  local color_name = M.mode_colors[mode] or 'normal'
  return active_colors[color_name] or active_colors.normal or '#89b4fa'
end

return M
