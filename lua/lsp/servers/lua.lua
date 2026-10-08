---@module 'lspconfig'

return {
  lua_ls = {
    mason = true,
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },

    ---@type lspconfig.settings.lua_ls
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        codeLens = { enable = false },
        completion = { callSnippet = 'Replace' },
        doc = { privateName = { '^_' } },
        hint = { enable = true },
        diagnostics = {
          globals = {
            'vim',
            'Snacks',
            'MiniPairs',
            'SimpleTabline',
            'SimpleTablineSwitch',
            'SimpleTablineClose',
            'SimpleTablineScrollLeft',
            'SimpleTablineScrollRight',
            'hl',
          }
        }
      }
    }
  },

  emmylua_ls = {
    cmd = { 'emmylua_ls' },
    filetypes = { 'lua' },
    root_markers = {
      '.emmyrc.json',
      '.git',
    },
    workspace_required = false,
    settings = {
      emmylua = {
        diagnostics = {
          globals = { 'vim', 'Snacks', 'MiniPairs' },
          disable = { 'missing-return', 'invisible-return' }
        },
        workspace = {
          library = {
            vim.env.VIMRUNTIME .. '/lua',
            vim.fn.stdpath('data') .. '/site/pack/core/opt',
          },
          maxPreload = 100000,
          preloadFileSize = 10000,
        },
        completion = {
          autoRequire = false,
          callSnippet = true,
        },
      },
    },
  }
}
