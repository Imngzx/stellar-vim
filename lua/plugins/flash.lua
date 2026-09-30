require('resonance').load({
  'https://github.com/folke/flash.nvim',
  keys = {
    { { 'n', 'x', 'o' }, '<CR>', function() require('flash').jump() end, { desc = 'Flash' } },
    { { 'n', 'x', 'o' }, '<S-CR>', function() require('flash').treesitter() end, { desc = 'Flash treesitter' } },
    { 'o', 'r', function() require('flash').remote() end, { desc = 'Remote flash' } },
    { { 'o', 'x' }, 'R', function() require('flash').treesitter_search() end, { desc = 'Treesitter search' } },
    { { 'c' }, '<c-s>', function() require('flash').toggle() end, { desc = 'Toggle flash search' } }
  },
  config = function()
    require('flash').setup({
      modes = {
        char = {
          enabled = false,
        }
      }
    })
  end
})
