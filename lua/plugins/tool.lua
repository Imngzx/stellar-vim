-- [Key note] Load on VeryLazy
require('resonance').load({
  {
    'https://github.com/folke/which-key.nvim',
    event = { 'User', pattern = 'VeryLazy' },
    config = function()
      local wk = require('which-key')

      wk.setup({
        preset = 'modern',               -- 可选: classic, modern, helix
        delay = function(ctx)
          return ctx.plugin and 0 or 250 -- 稍微延迟，避免快速盲打时屏幕闪烁
        end,
        win = {
          border = 'rounded', -- 与你全局的圆角风格统一
          padding = { 1, 2 }, -- 上下 1 行，左右 2 列的内边距，呼吸感更好
        },
      })

      -- 2. 🏷️ 注册你所有的快捷键前缀和精美图标
      wk.add({
        { '<leader>a', group = 'AI', icon = ' ' },
        { '<leader>b', group = 'Buffer', icon = '󰓩 ' },
        { '<leader>c', group = 'Code', icon = ' ' },
        { '<leader>d', group = 'Debug', icon = ' ' },
        { '<leader>e', group = 'Explorer', icon = '󰙅 ' },
        { '<leader>f', group = 'Find/File', icon = '󰈞 ' },
        { '<leader>g', group = 'Git', icon = '󰊢 ' },
        { '<leader>gp', group = 'Neogit Panel', icon = '󰊢 ' },
        { '<leader>H', group = 'Open Dahsboard (Home)', icon = ' ' },
        { '<leader>j', group = 'Multicursor', icon = '󰪥 ' },
        { '<leader>n', group = 'Minimap', icon = '🗺️ ' },
        { '<leader>p', group = 'Panel/Project', icon = '󰏖 ' },
        { '<leader>q', group = 'Quit', icon = '󰗼 ' },
        { '<leader>r', group = 'Run', icon = ' ' },
        { '<leader>s', group = 'Search', icon = ' ' },
        { '<leader>t', group = 'Translate', icon = ' ' },
        { '<leader>T', group = 'Telegram', icon = ' ' },
        { '<leader>u', group = 'UI/Toggles', icon = '󰙵 ' },
        { '<leader>w', group = 'Write/Quit', icon = ' / 󰩈 ' },
        { '<leader>z', group = 'Zettelkasten', icon = ' ' },

        { '<leader>/', group = 'Grep', icon = '󱎸 ' },

        { '[', group = 'Prev', icon = '󰒮 ' },
        { ']', group = 'Next', icon = '󰒭 ' },
        { 'g', group = 'Goto', icon = '󰜎 ' },
        { 's', group = 'Surround', icon = '󰑄 ' },
        { 'z', group = 'Fold', icon = '󱃅 ' },

        -- bpm tab
        { '<leader><tab>', group = 'Workspace/Tabs', icon = '󰓩 ' },
      })

      vim.keymap.set('n', '<leader>?',
        function() wk.show({ global = false }) end,
        { desc = 'Buffer local keymaps' }
      )
    end
  },

  {
    'https://github.com/nvim-mini/mini.diff',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      local mini_diff = require('mini.diff')

      mini_diff.setup({
        view = {
          style = 'sign',
          signs = { add = '│', change = '│', delete = '│' },
        },
        mappings = {
          -- Apply hunks inside a visual/operator region
          apply = '<leader>gh',

          -- Reset hunks inside a visual/operator region
          reset = '<leader>gH',

          -- Hunk range textobject to be used inside operator
          -- Works also in Visual mode if mapping differs from apply and reset
          textobject = '<leader>gh',

          -- Go to hunk range in corresponding direction
          goto_first = '[H',
          goto_prev = '[h',
          goto_next = ']h',
          goto_last = ']H',
        },
      })
      vim.keymap.set('n', '<leader>go', function()
        mini_diff.toggle_overlay(0)
      end, { desc = 'Toggle diff' })
    end
  },

  {
    'https://github.com/Imngzx/ascetic.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    -- event = { 'User', pattern = 'VeryLazy' },
    config = function()
      local Ascetic = require('ascetic')

      Ascetic.setup({
        enabled = true,
        smart_j_k = true,
        threshold = 10,
        timeout = 2000,
        message = function(key)
          local insults = {
            j = 'Down down down... use `C-d` bro!',
            k = 'Up up up... use `C-u` instead!',
          }
          return insults[key] or ('Stop pressing `%s`!'):format(key)
        end,
      })
      vim.keymap.set('n', '<leader>ua', Ascetic.toggle, { desc = 'Toggle Ascetic' })
    end
  },

  {
    'https://github.com/NeogitOrg/neogit',
    dependencies = 'https://github.com/nvim-lua/plenary.nvim',

    cmd = 'Neogit',
    keys = {
      { 'n', '<leader>gpt', function() require('neogit').open() end,                             { desc = 'Neogit (Tab)' } },
      { 'n', '<leader>gps', function() require('neogit').open({ kind = 'split_below_all' }) end, { desc = 'Neogit (Split Below)' } },
      { 'n', '<leader>gpv', function() require('neogit').open({ kind = 'vsplit' }) end,          { desc = 'Neogit (VSplit)' } },
    },

    setup = function()
      require('neogit').setup({
        disable_context_highlighting = true,
        disable_insert_on_commit = 'auto',

        filewatcher = {
          interval = 1000,
          enabled = true,
        },

        graph_style = 'unicode',
        process_spinner = false,
        kind = 'replace',

        floating = {
          relative = 'editor',
          width = 0.8,
          height = 0.8,
          style = 'minimal',
          border = 'rounded',
        },

        disable_line_numbers = true,
        disable_relative_line_numbers = true,
        console_timeout = 2000,
        auto_show_console = true,
        auto_close_console = true,
        notification_icon = '󰊢 ',

        status = {
          show_head_commit_hash = true,
          recent_commit_count = 10,
          HEAD_padding = 10,
          HEAD_folded = false,
          mode_padding = 3,
          mode_text = {
            M = 'modified',
            N = 'new file',
            A = 'added',
            D = 'deleted',
            C = 'copied',
            U = 'updated',
            R = 'renamed',
            T = 'changed',
            DD = 'unmerged',
            AU = 'unmerged',
            UD = 'unmerged',
            UA = 'unmerged',
            DU = 'unmerged',
            AA = 'unmerged',
            UU = 'unmerged',
            ['?'] = '',
          },
        },

        commit_editor = {
          kind = 'floating',
          show_staged_diff = true,
          staged_diff_split_kind = 'split',
          spell_check = false,
        },

        commit_select_view = { kind = 'tab' },
        commit_view = { kind = 'vsplit', verify_commit = vim.fn.executable('gpg') == 1 },
        log_view = { kind = 'tab' },
        rebase_editor = { kind = 'auto' },
        reflog_view = { kind = 'tab' },
        merge_editor = { kind = 'auto' },
        preview_buffer = { kind = 'floating_console' },
        popup = { kind = 'split', show_title = false },
        stash = { kind = 'tab' },
        refs_view = { kind = 'tab' },

        signs = {
          hunk = { '', '' },
          item = { '', '' },
          section = { '', '' },
        },

        integrations = {
          telescope = false,
          fzf_lua = false,
          mini_pick = false,
          snacks = true,
        },

        sections = {
          sequencer = { folded = false, hidden = false },
          untracked = { folded = false, hidden = false },
          unstaged = { folded = false, hidden = false },
          staged = { folded = false, hidden = false },
          stashes = { folded = true, hidden = false },
          recent = { folded = true, hidden = false },
          rebase = { folded = true, hidden = false },
        },

        mappings = {
          commit_editor = {
            ['q'] = 'Close', ['C'] = 'Submit', ['X'] = 'Abort',
          },
          status = {
            ['q'] = 'Close', ['s'] = 'Stage', ['u'] = 'Unstage',
          },
          popup = {
            ['c'] = 'CommitPopup', ['P'] = 'PushPopup', ['p'] = 'PullPopup',
          },
        },
      })
    end
  }
})
