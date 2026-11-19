return {
  'https://github.com/Imngzx/jisho.nvim',

  dependencies = { 'https://github.com/atusy/budoux.lua', },

  cmd = { 'Jisho' },

  keys = {
    { 'n', '<leader>tj', function() require('jisho').search() end, { desc = 'Jisho (Word under cursor)' } },
    { 'v', '<leader>tj', function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
      vim.schedule(function()
        local s = vim.api.nvim_buf_get_mark(0, '<')
        local e = vim.api.nvim_buf_get_mark(0, '>')
        local lines = vim.fn.getregion({ 0, s[1], s[2] + 1, 0 }, { 0, e[1], e[2] + 1, 0 })
        require('jisho').search(table.concat(lines, ' '))
      end)
    end, { desc = 'Jisho (Selection)' } },
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
