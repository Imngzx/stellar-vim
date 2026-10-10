---@type vim.lsp.Config

return {
  cmd = { vim.fn.stdpath('data') .. '/mason/bin/luau-lsp', 'lsp', '--stdio' },
  filetypes = { 'luau' },
  root_markers = { '.git', 'selene.toml', 'selene.yml' },
  settings = {
    luau = {
      completion = {
        imports = {
          enabled = true,
        },
      },
      diagnostics = {
        globals = { 'game', 'workspace', 'script', 'print', 'warn', 'error' },
      },
      sourcemap = {
        enabled = true,
        autoreload = true,
      },
    },
  },
}
