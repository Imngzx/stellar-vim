---@type vim.lsp.Config

local capabilities = vim.lsp.protocol.make_client_capabilities()

-- Enforce UTF-16 offset encoding as the primary option
capabilities = vim.tbl_deep_extend('force', capabilities, {
  offsetEncoding = { 'utf-16' },
  general = {
    positionEncodings = { 'utf-16' },
  },
})

return {
  ruff = {
    cmd = { 'ruff', 'server' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
    capabilities = capabilities,
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
    capabilities = capabilities,
  },

  ty = {
    -- NOTE: uv tool install ty
    cmd = { 'ty', 'server' },
    filetypes = { 'python' },
    root_markers = { 'ty.toml', 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
    capabilities = capabilities,
  },

  pyrefly = {
    cmd = { 'pyrefly', 'lsp' },
    filetypes = { 'python' },
    capabilities = capabilities,
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
