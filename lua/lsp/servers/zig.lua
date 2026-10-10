---@type vim.lsp.Config

return {
  cmd = { 'zls' },
  filetypes = { 'zig', 'zir' },

  settings = {
    zls = {
      -- clean useless imports
      enable_autofix = true,
      warn_style = true,
    }
  }
}
