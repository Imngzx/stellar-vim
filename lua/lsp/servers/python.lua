---@type vim.lsp.Config


-- Enforce UTF-16 offset encoding as the primary option
vim.lsp.config('*', {
  capabilities = {
    offsetEncoding = { 'utf-16' },
    general = {
      positionEncodings = { 'utf-16' },
    },
  },
})

return {
  ruff = {
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
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
  },

  ty = {
    -- NOTE: uv tool install ty
    filetypes = { 'python' },
    root_markers = { 'ty.toml', 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
    cmd = { 'ty', 'server' },
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
