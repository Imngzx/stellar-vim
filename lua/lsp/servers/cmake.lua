---@type vim.lsp.Config
return {
  cmd = { 'neocmakelsp', 'stdio' },
  filetypes = { 'cmake' },
  root_markers = { '.neocmake.toml', '.git', 'build', 'cmake' },

  init_options = {
    format = {
      enable = true
    }
  }

}
