---@type vim.lsp.Config

return {
  ruff = {
    root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
    capabilities = {
      general = {
        positionEncodings = { 'utf-16' },
      },
    },
    cmd_env = { RUFF_TRACE = 'messages' },
    init_options = {
      settings = {
        logLevel = 'error',
      },
    },
  },

  basedpyright = {

    ---@type lspconfig.settings.basedpyright
    settings = {
      basedpyright = {
        analysis = {
          diagnosticSeverityOverrides = {
            reportUnknownMemberType = 'none',
            reportUnknownArgumentType = 'none',
          },
          typeCheckingMode = 'basic',
          diagnosticMode = 'openFilesOnly',
          useLibraryCodeForTypes = true,
          inlayHints = {
            variableTypes = true,
            functionReturnTypes = true,
            callArgumentNames = true,
            pytestParameters = true,
          },
        },
      },
    },
    capabilities = {
      offsetEncoding = { 'utf-16' },
    },
  },
  ty = {
    -- NOTE: uv tool install ty
    mason = false,
    root_markers = { 'ty.toml', 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
    cmd = { 'ty', 'server' },
    capabilities = {
      offsetEncoding = { 'utf-16' },
    },
  }
}
