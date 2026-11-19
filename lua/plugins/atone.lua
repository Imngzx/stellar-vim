return {
  'https://github.com/XXiaoA/atone.nvim',
  cmd = { 'Atone' },
  keys = {
    { 'n', '<leader>uu', '<cmd>Atone toggle<cr>', { desc = 'Toggle Undo Tree (Atone)' } },
  },
  config = function()
    require('atone').setup({
      layout = {
        direction = 'left',
        width = 0.25,
      },
      diff_cur_node = {
        enabled = true,
        split_percent = 0.3,
      },
      marks = {
        persist = true,
      },
      ui = {
        border = 'rounded',
        compact = true,
        node_label = {
          custom = true,
        },
      }
    })
  end
}
