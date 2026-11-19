local api = vim.api
local create_autocmd = api.nvim_create_autocmd
local create_augroup = api.nvim_create_augroup
local cmd = vim.cmd

-- [CSV View]
return {
  'https://github.com/hat0uma/csvview.nvim',
  cmd = { 'CsvViewEnable', 'CsvViewDisable', 'CsvViewToggle' },
  ft = { 'csv', 'tsv' },
  config = function()
    require('csvview').setup({
      view = {
        display_mode = 'border',
      },
      parser = { comments = { '#', '//' } },
      keymaps = {
        textobject_field_inner = { 'if', mode = { 'o', 'x' } },
        textobject_field_outer = { 'af', mode = { 'o', 'x' } },
        jump_next_field_end = { '<Tab>', mode = { 'n', 'v' } },
        jump_prev_field_end = { '<S-Tab>', mode = { 'n', 'v' } },
        jump_next_row = { '<Enter>', mode = { 'n', 'v' } },
        jump_prev_row = { '<S-Enter>', mode = { 'n', 'v' } },
      },
    })
  end,

  -- uses csvview plugin as soon as opening a csv file
  create_autocmd('BufReadPost', {
    group = create_augroup('CsvViewAutoEnable', { clear = true }),
    pattern = '*.csv',
    callback = function()
      cmd([[CsvViewEnable delimiter=, display_mode=border header_lnum=1]])
    end,
  })
}
