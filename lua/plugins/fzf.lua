require('resonance').load({
  'https://github.com/ibhagwan/fzf-lua',
  cond = function() return not require('libs.power').is_ac() end,
  cmd = 'FzfLua',
  keys = {
    { 'n', '<leader><leader>', function() require('fzf-lua').files() end, { desc = 'Smart find' } },
    { 'n', '<leader>/', function() require('fzf-lua').live_grep() end, { desc = 'Grep' } },
    { 'n', '<leader>fc', function() require('fzf-lua').files({ cwd = vim.fn.stdpath('config') }) end, { desc = 'Find Neovim Config' } },
    { 'n', '<leader>fC', function() require('fzf-lua').live_grep({ cwd = vim.fn.stdpath('config') }) end, { desc = 'Grep Neovim Config' } },
    { 'n', '<leader>ff', function() require('fzf-lua').git_files() end, { desc = 'Find git files' } },
    { 'n', '<leader>fp', function() require('fzf-lua').oldfiles() end, { desc = 'Projects / Recent' } },
    { 'n', '<leader>fz', function() require('fzf-lua').oldfiles() end, { desc = 'Zoxide (Recent Dirs)' } },
    { 'n', '<leader>fl', function() require('fzf-lua').blines() end, { desc = 'Buffer lines' } },
    { 'n', '<leader>fB', function() require('fzf-lua').lines() end, { desc = 'Grep open buffers' } },
    { { 'n', 'x' }, '<leader>fw', function() require('fzf-lua').grep_cword() end, { desc = 'Visual selection or word' } },

    { 'n', '<leader>fb', function() require('fzf-lua').buffers() end, { desc = 'Buffers' } },
    { 'n', '<leader>fr', function() require('fzf-lua').registers() end, { desc = 'Registers' } },
    { 'n', '<leader>sc', function() require('fzf-lua').command_history() end, { desc = 'Command history' } },
    { 'n', '<leader>s/', function() require('fzf-lua').search_history() end, { desc = 'Search history' } },
    { 'n', '<leader>fa', function() require('fzf-lua').autocmds() end, { desc = 'Autocmds' } },
    { 'n', '<leader>sC', function() require('fzf-lua').commands() end, { desc = 'Commands' } },
    { 'n', '<leader>sh', function() require('fzf-lua').help_tags() end, { desc = 'Help pages' } },
    { 'n', '<leader>sH', function() require('fzf-lua').highlights() end, { desc = 'Highlights' } },
    { 'n', '<leader>fk', function() require('fzf-lua').keymaps() end, { desc = 'Find Keymaps' } },
    { 'n', '<leader>sm', function() require('fzf-lua').marks() end, { desc = 'Marks' } },

    { 'n', '<leader>gB', function() require('fzf-lua').git_branches() end, { desc = 'Git branches' } },
    { 'n', '<leader>gs', function() require('fzf-lua').git_status() end, { desc = 'Git status' } },
    { 'n', '<leader>gS', function() require('fzf-lua').git_stash() end, { desc = 'Git stash' } },

    { 'n', '<leader>co', function() require('fzf-lua').lsp_document_symbols() end, { desc = 'LSP symbols' } },
    { 'n', '<leader>cD', function() require('fzf-lua').lsp_workspace_diagnostics() end, { desc = 'Diagnostics' } },
    { 'n', '<leader>cd', function() require('fzf-lua').lsp_document_diagnostics() end, { desc = 'Buffer diagnostics' } },

    { 'n', 'gd', function() require('fzf-lua').lsp_definitions() end, { desc = 'Goto definition' } },
    { 'n', 'gD', function() require('fzf-lua').lsp_declarations() end, { desc = 'Goto declaration' } },
    { 'n', 'gr', function() require('fzf-lua').lsp_references() end, { nowait = true, desc = 'References' } },
    { 'n', 'gI', function() require('fzf-lua').lsp_implementations() end, { desc = 'Goto implementation' } },
    { 'n', 'gy', function() require('fzf-lua').lsp_typedefs() end, { desc = 'Goto type definition' } },
  },
  config = function()
    require('fzf-lua').setup({
      'default',
      formatter = 'path.dirname_first',
      fzf_colors = true,
      winopts = {
        border = 'rounded',
        preview = { border = 'border', scrollbar = 'float' },
      },
      keymap = {
        builtin = { ['<Esc>'] = 'hide' },
        fzf = { ['esc'] = 'abort' }
      }
    })
  end
})
