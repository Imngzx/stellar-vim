require('resonance').load({
  'https://github.com/ChuYanLon/telegram.nvim',

  build = 'npm i',
  cond = not require('libs.utils').is_windows(),

  cmd = { 'Tg', 'TgLogout', 'TgSend', 'TgPr' },
  keys = {
    { 'n', '<leader>Tg', '<cmd>Tg<CR>', { desc = 'Open Telegram' } },
    { 'n', '<leader>TL', '<cmd>TgLogout<CR>', { desc = 'Logout Telegram' } },
  },
  config = function()
    require('telegram').setup({})
  end
})
