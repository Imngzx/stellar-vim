-- neovide will have fonts issues with nvim 0.12,
-- please use neovide-git instead if you want to use neovide
local o = vim.o
local opt = vim.opt
local g = vim.g

if g.neovide then
  o.guifont = 'Maple Mono NF CN:h13'
  -- vim.g.neovide_window_blurred = true
  -- vim.g.neovide_opacity = 0.93
  g.neovide_floating_blur_amount_x = 3.0
  g.neovide_floating_blur_amount_y = 3.0
  g.neovide_refresh_rate = 60

  g.neovide_cursor_antialiasing = true
  g.neovide_cursor_smooth_blink = true
  opt.guicursor:append('a:blinkwait700-blinkon475-blinkoff475')

  g.neovide_hide_titlebar = true
  g.neovide_padding_bottom = 0
  g.neovide_floating_shadow = false
  g.neovide_window_blurred = true
  -- vim.g.neovide_opacity = 0.8
  -- vim.g.neovide_normal_opacity = 0.8
  -- Running in Neovide → disable snacks scroll
  g.snacks_scroll = false
else
  -- Running in terminal → enable snacks scroll & ui2
  g.snacks_scroll = require('libs.power').is_ac()
end
