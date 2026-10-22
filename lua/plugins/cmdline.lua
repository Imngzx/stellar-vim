local row = 0.25

require('resonance').load({
  'https://github.com/aurora0x27/popup.nvim',

  lazy = true,

  config = function()
    require('popup').setup({
      cursor_hack = vim.g.neovide,
      enable_ui2 = true,
      views = {
        cmdline = {
          width = 0.45,
          col = 0.5,
          row = row,
          relative = 'editor',
        },
        input = {
          width = 0.55,
          col = 0.5,
          row = row,
          relative = 'editor',
        },
        lsp_rename = {
          width = 0.20,
          col = 1,
          row = 1,
          relative = 'cursor',
        },
      },

      routes = {
        {
          match = { firstc = '/' },
          prefix = ' ',
          title = 'Search',
          hl = 'CmdlineSearchDown',
          ft = 'regex',
          view = 'cmdline',
        },
        {
          match = { firstc = '?' },
          prefix = ' ',
          title = 'Search',
          hl = 'CmdlineSearchUp',
          ft = 'regex',
          view = 'cmdline',
        },
        {
          match = { firstc = ':', pattern = '%s*he?l?p?%s+' },
          prefix = '?',
          title = 'Help',
          hl = 'CmdlineHelp',
          view = 'cmdline',
        },
        {
          match = { firstc = ':', pattern = '%s*lua%s+' },
          prefix = ' ',
          title = 'Lua',
          hl = 'CmdlineLua',
          ft = 'lua',
          view = 'cmdline',
        },
        {
          match = { firstc = ':', pattern = '%s*%!' },
          prefix = '$',
          title = 'Filter',
          hl = 'CmdlineFilter',
          ft = 'bash',
          view = 'cmdline',
        },
        {
          match = { firstc = '', prompt = 'New Name' },
          prefix = '󰥻 ',
          hl = 'LspRenameInput',
          view = 'lsp_rename',
        },
        {
          match = { firstc = ':' },
          prefix = '',
          hl = 'CmdlineDefault',
          title = 'Cmdline',
          ft = 'vim',
          view = 'cmdline',
        },
        {
          match = { firstc = '' },
          prefix = '󰥻 ',
          hl = 'CmdlineInput',
          view = 'input',
        },
      },
    })
  end
})
