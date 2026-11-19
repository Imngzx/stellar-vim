return {
  'https://github.com/Imngzx/jisho.nvim',

  dependencies = { 'https://github.com/atusy/budoux.lua', },

  cmd = { 'Jisho' },

  keys = {
    { { 'n', 'x' }, '<leader>tj', '<Cmd>Jisho<CR>', { desc = 'Jisho' } },
  },

  config = function()
    require('jisho').setup({
      use_budoux = true,
      layout = 'spacious',
      window = {
        width = 0.6,
        height = 0.9,
      }
    })
  end,
}
