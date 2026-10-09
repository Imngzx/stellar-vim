---@type vim.lsp.Config

return {
  ruff = {
    filetypes = { 'python' },
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
    filetypes = { 'python' },
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
    mason = true,
    filetypes = { 'python' },
    root_markers = { 'ty.toml', 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
    cmd = { 'ty', 'server' },
    capabilities = {
      offsetEncoding = { 'utf-16' },
    },
  },

  pyrefly = {
    cmd = { 'pyrefly', 'lsp' },
    filetypes = { 'python' },
    root_markers = {
      'pyrefly.toml',
      'pyproject.toml',
      'setup.py',
      'setup.cfg',
      'requirements.txt',
      'Pipfile',
      '.git',
    },
  }
}
