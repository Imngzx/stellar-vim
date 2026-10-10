---@type vim.lsp.Config

return {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },

  ---@type lspconfig.settings.rust_analyzer
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
        buildScripts = {
          enable = true,
        },
      },
      checkOnSave = true,
      check = {
        allFeatures = true,
        command = 'clippy',
        -- extraArgs = { '--no-deps' },
      },
      procMacro = {
        enable = true,
        ignored = {
          ['napi-derive'] = { 'napi' },
          ['async-recursion'] = { 'async_recursion' },
        },
      },
      diagnostics = {
        enable = true,
        experimental = {
          enable = true,
        },
      },
    },
  },
}
