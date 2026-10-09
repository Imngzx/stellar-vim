return {
  enabled = true,
  preset = {
    header = require('plugins.snacks_config.logo_names').StellarVim_default,
    keys = {
      { icon = '󰱼 ', key = 'f', desc = 'Find File', action = ":lua Snacks.dashboard.pick('files')" },
      { icon = '󰝒 ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
      { icon = '󰷾 ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
      { icon = '󰋚 ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
      { icon = '󰥨 ', key = 'z', desc = 'Zoxide Dirs', action = ':lua Snacks.picker.zoxide()' },
      { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
      { icon = '󰁯 ', key = 's', desc = 'Restore Session', action = ":lua require('custom.session').load(false)" },
      { icon = '󱑽 ', key = 'l', desc = 'Resonance', action = ":lua require('resonance').open_ui()" },
      { icon = '󰈆 ', key = 'q', desc = 'Quit', action = ':qa' },
    },
  },
  sections = {
    { section = 'header' },
    { section = 'keys',  gap = 1, padding = 1 },
    function()
      local stats = require('resonance').stats()
      local ms = string.format('%.2f ms', stats.startuptime)
      return {
        align = 'center',
        text = {
          { '󱐋 ', hl = 'Special' },
          { stats.loaded .. ' / ' .. stats.count, hl = 'Special' },
          { ' plugins loaded in ', hl = 'Comment' },
          { ms, hl = 'Special' },
        },
        padding = 1,
      }
    end,

    function()
      local is_ac = require('libs.power').is_ac()
      local power_icon = is_ac and '⚡' or '🔋'
      local power_mode = is_ac and '[High Performance]' or '[Ascetic Mode]'
      local power_hl = is_ac and 'DiagnosticOk' or 'DiagnosticWarn'
      local version = vim.version()
      local nvim_ver = string.format('NVIM v%d.%d.%d', version.major, version.minor, version.patch)
      return {
        align = 'center',
        text = {
          { power_icon .. ' ', hl = power_hl },
          { power_mode, hl = 'Comment' },
          { '  •  ', hl = 'Comment' },
          { '✨ ', hl = 'Special' },
          { nvim_ver, hl = 'Comment' },
        },
        padding = 1,
      }
    end,
  },
}
