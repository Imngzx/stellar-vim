require('resonance').load({
  'https://github.com/vyfor/cord.nvim',

  cond = require('libs.power').is_ac(),
  lazy = true,

  config = function()
    local icon = require('cord.api.icon').get

    require('cord').setup({
      -- EDITOR: Your custom Discord app ID preserved
      editor = {
        client = '1552672873137569792',
        tooltip = 'Stellar:Vim • resonance.nvim',
        icon = nil,
      },

      -- DISPLAY: Catppuccin theme to match your colorscheme
      display = {
        theme = 'catppuccin',
        flavor = 'accent',
        view = 'full',
        swap_fields = true,
        swap_icons = false,
      },

      -- TIMESTAMP: Show session duration
      timestamp = {
        enabled = true,
        reset_on_idle = true,
        reset_on_change = false,
      },

      -- IDLE: Stellar-themed idle
      idle = {
        enabled = true,
        timeout = 180000,
        details = '💫 Stargazing...',
        state = 'AFK',
        tooltip = 'Stellar:Vim is resting',
        icon = icon('sleep', 'catppuccin', 'dark'),
      },

      -- TEXT: Every message branded with Stellar:Vim
      text = {
        workspace = function(opts)
          local branch = opts.git_branch and (' ⎇ ' .. opts.git_branch) or ''
          return '🌌 ' .. opts.workspace .. branch .. ' • Stellar:Vim'
        end,
        viewing = function(opts)
          return '🔭 Reading ' .. opts.filename
        end,
        editing = function(opts)
          return '✨ Editing ' .. opts.filename
        end,
        file_browser = function(opts)
          return '📁 Browsing ' .. opts.name
        end,
        plugin_manager = function(opts)
          return '📦 Managing plugins'
        end,
        lsp = function(opts)
          return '🔧 LSP: ' .. opts.name
        end,
        docs = function(opts)
          return '📖 Reading ' .. opts.name
        end,
        vcs = function(opts)
          return '📝 Committing in ' .. opts.name
        end,
        debug = function(opts)
          return '🐛 Debugging ' .. opts.name
        end,
        terminal = function(opts)
          return '💻 Terminal: ' .. opts.name
        end,
        dashboard = '🏠 Stellar:Vim Dashboard',
      },

      -- BUTTONS: Quick links to your repo
      buttons = {
        {
          label = 'View Config',
          url = 'https://github.com/Imngzx/stellar-vim',
        },
        {
          label = 'Stellar:Vim',
          url = 'https://github.com/Imngzx/stellar-vim',
        },
      },

      -- HOOKS: Ready notification only
      hooks = {
        ready = function()
          vim.notify('[[Stellar:Vim]]: presence connected ✨', vim.log.levels.INFO, { title = 'Cord' })
        end,
      },

      -- ADVANCED: Performance tuning
      advanced = {
        plugin = {
          debounce = {
            delay = 30,
            interval = 500,
          },
        },
        workspace = {
          root_markers = { '.git', 'Cargo.toml', 'go.mod', 'package.json', 'pyproject.toml' },
        },
      },
    })
  end
})
