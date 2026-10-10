---@type vim.lsp.Config

return {
  mason = true,

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
