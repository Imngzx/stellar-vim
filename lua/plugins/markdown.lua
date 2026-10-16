require('resonance').load({
  {
    'https://github.com/MeanderingProgrammer/render-markdown.nvim',
    -- cmd = { 'Tg', 'TgLogout', 'TgSend', 'TgPr' },
    ft = { 'markdown', 'norg', 'rmd', 'org', 'codecompanion', 'telegram' },
    config = function()
      local render_markdown = require('render-markdown')
      render_markdown.setup({
        file_types = { 'markdown', 'norg', 'rmd', 'org', 'codecompanion', 'telegram' },

        code = {
          sign = true,
          width = 'block',
          right_pad = 1,
        },
        heading = {
          sign = true,
          icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
          width = 'block',
          left_pad = 2,
          right_pad = 4,
        },
        checkbox = {
          enabled = true,
        },
        quote = {
          enabled = true,
        },
        latex = {
          enabled = true,
          render_modes = false,
          converter = { 'utftex', 'latex2text' },
          highlight = 'RenderMarkdownMath',
          position = 'center',
          top_pad = 0,
          bottom_pad = 0,
        },
        completions = { lsp = { enabled = false } },
      })

      vim.schedule(function()
        vim.cmd('doautocmd FileType ' .. vim.bo.filetype)
      end)

      local ok, snacks = pcall(require, 'snacks')
      if ok then
        snacks.toggle({
          name = 'Render Markdown',
          get = function()
            return require('render-markdown.state').enabled
          end,
          set = function(enabled)
            if enabled then
              render_markdown.enable()
            else
              render_markdown.disable()
            end
          end,
        }):map('<leader>um')
      end
      if not require('libs.power').is_ac() then
        require('render-markdown').disable()
      end
      -- mpls markdown preview keymap
      if ok then
        snacks.keymap.set('n', '<localleader>cz', function()
          -- Use current buffer for root_dir detection
          local buf = vim.api.nvim_get_current_buf()
          vim.lsp.start({
            name = 'mpls',
            cmd = {
              'mpls',
              '--theme',
              'dark',
              '--enable-emoji',
              '--enable-footnotes',
            },
            root_dir = vim.fs.root(buf, { '.marksman.toml', '.git' })
              or vim.fn.getcwd(),
            filetypes = { 'markdown' },
          })
        end, {
          ft = 'markdown',
          desc = '[LSP] Preview file',
        })
      end
    end,
  },
  {
    'https://github.com/aurora0x27/markdown-preview2.nvim',
    keys = {
      { 'n', '<leader>cb', '<cmd>MarkdownPreviewToggle<cr>', { desc = 'Toggle MarkdownPreview' } },
    },
    -- cmd = { 'MarkdownPreview', 'MarkdownPreviewStop', 'MarkdownPreviewToggle' },
    build = 'cd app && yarn install',
    config = function()
      require('mkdp').setup()
    end,
  }
})
