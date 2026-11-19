-- [Treesitter Context]
return {
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
  -- 在打开文件时自动加载
  event = { 'BufReadPost', 'BufNewFile' },
  config = function()
    require('treesitter-context').setup({
      enable = true, -- 启用插件
      max_lines = 5, -- 吸顶框最多显示几行（设为 0 则没有限制）
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 20, -- 单个上下文块最大行数
      trim_scope = 'outer', -- 当超出 max_lines 时，丢弃外层（outer）还是内层（inner）上下文
      mode = 'cursor', -- 计算上下文的基准点：'cursor' (光标所在) 或 'topline' (屏幕顶部)
      separator = nil, -- 吸顶框和正文的分割线，比如可以填 '-' 或 '─'
      zindex = 20, -- 浮动窗口层级
    })

    -- 按下[c 可以快速让光标向上跳跃到当前吸顶的上下文函数头部
    vim.keymap.set('n', '[c', function()
      require('treesitter-context').go_to_context(vim.v.count1)
    end, { silent = true, desc = 'Jump to upper context' })
  end
}
