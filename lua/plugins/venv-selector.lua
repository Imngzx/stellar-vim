-- [Python Venv Selector]
return {
  'https://github.com/linux-cultist/venv-selector.nvim',
  -- 只有在打开 Python 文件时，或者手动输入命令时才加载，极致优化启动速度
  ft = 'python',
  cmd = { 'VenvSelect', 'VenvSelectCached' },
  keys = {
    { 'n', '<leader>cv', function() vim.cmd('VenvSelect') end, { desc = 'Select Python Venv' } },
  },
  config = function()
    -- line below used to remove useless warnings
    ---@diagnostic disable-next-line: missing-fields
    require('venv-selector').setup({
      settings = {
        options = {
          notify_user_on_venv_activation = true,
        },
      },
    })
  end
}
