local is_ac = require('libs.power').is_ac()
local Snacks = require('snacks')
local zettel = require('custom.zettel')

local keys = {}

local function bind(mappings)
  local n = #keys
  for i = 1, #mappings do
    n = n + 1
    keys[n] = mappings[i]
  end
end

-- ==========================================
-- 📂 [ Explorer & Dashboard ]
-- ==========================================
bind({
  { '<leader>e', function() Snacks.explorer() end, desc = 'File Explorer' },
  { '<leader>H', function() Snacks.dashboard() end, desc = 'Open Dashboard (Home)' },
})

-- ==========================================
-- 🔍 [ Pickers: Find & Grep ]
-- ==========================================
if is_ac then
  bind({
    { '<leader><leader>', function() Snacks.picker.smart() end, desc = 'Smart find' },
    { '<leader>/', function() Snacks.picker.grep() end, desc = 'Grep' },
    { '<leader>fc', function() Snacks.picker.files({ cwd = vim.fn.stdpath('config') }) end, desc = 'Find Neovim Config' },
    { '<leader>fC', function() Snacks.picker.grep({ cwd = vim.fn.stdpath('config') }) end, desc = 'Grep Neovim Config' },
    { '<leader>ff', function() Snacks.picker.git_files() end, desc = 'Find git files' },
    { '<leader>fp', function() Snacks.picker.projects() end, desc = 'Projects' },
    { '<leader>fz', function() Snacks.picker.zoxide() end, desc = 'Zoxide (Recent Dirs)' },
    { '<leader>fl', function() Snacks.picker.lines({ matcher = { sort_empty = false } }) end, desc = 'Buffer lines' },
    { '<leader>fB', function() Snacks.picker.grep_buffers() end, desc = 'Grep open buffers' },
    { '<leader>fw', function() Snacks.picker.grep_word() end, desc = 'Visual selection or word', mode = { 'n', 'x' } },
  })
end

-- ==========================================
-- 📜 [ Pickers: History, System & Registers ]
-- ==========================================
if is_ac then
  bind({
    { '<leader>fb', function() Snacks.picker.buffers() end, desc = 'Buffers' },
    { '<leader>fr', function() Snacks.picker.registers() end, desc = 'Registers' },
    { '<leader>sc', function() Snacks.picker.command_history() end, desc = 'Command history' },
    { '<leader>s/', function() Snacks.picker.search_history() end, desc = 'Search history' },
    { '<leader>fa', function() Snacks.picker.autocmds() end, desc = 'Autocmds' },
    { '<leader>sC', function() Snacks.picker.commands() end, desc = 'Commands' },
    { '<leader>sh', function() Snacks.picker.help() end, desc = 'Help pages' },
    { '<leader>sH', function() Snacks.picker.highlights() end, desc = 'Highlights' },
    { '<leader>fk', function() Snacks.picker.keymaps() end, desc = 'Find Keymaps' },
    { '<leader>sm', function() Snacks.picker.marks() end, desc = 'Marks' },
  })
end

bind({
  { '<leader>sn', function() Snacks.picker.notifications() end, desc = 'Notification history' },
  { '<leader>si', function() Snacks.picker.icons() end, desc = 'Icons' },
  { '<leader>su', function() Snacks.picker.undo() end, desc = 'Undo history' },
})

-- ==========================================
-- 🐙 [ Git ]
-- ==========================================
bind({
  { '<leader>gl', function() Snacks.lazygit.log_file() end, desc = 'Lazygit File Log' },
  { '<leader>gL', function() Snacks.gitbrowse() end, desc = 'Git browse link', mode = { 'n', 'v' } },
  { '<leader>gb', function() Snacks.git.blame_line() end, desc = 'Git blame line' },
  { '<leader>gg', function() Snacks.lazygit() end, desc = 'Lazygit' },
  { '<leader>gD', function() Snacks.picker.git_diff() end, desc = 'Git diff (hunks)' },
  { '<leader>ub', function() require('custom.git-blame').toggle() end, desc = 'Toggle Git Blame' },
})

if is_ac then
  bind({
    { '<leader>gB', function() Snacks.picker.git_branches() end, desc = 'Git branches' },
    { '<leader>gs', function() Snacks.picker.git_status() end, desc = 'Git status' },
    { '<leader>gS', function() Snacks.picker.git_stash() end, desc = 'Git stash' },
  })
end

-- ==========================================
-- 💡 [ LSP & Diagnostics ]
-- ==========================================
bind({
  { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Next reference', mode = { 'n', 't' } },
  { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Prev reference', mode = { 'n', 't' } },
})

if is_ac then
  bind({
    { '<leader>co', function() Snacks.picker.lsp_symbols({ matcher = { sort_empty = false } }) end, desc = 'LSP symbols' },
    { '<leader>cD', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics' },
    { '<leader>cd', function() Snacks.picker.diagnostics_buffer({ matcher = { sort_empty = false } }) end, desc = 'Buffer diagnostics' },
    { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto definition' },
    { 'gD', function() Snacks.picker.lsp_declarations() end, desc = 'Goto declaration' },
    { 'gr', function() Snacks.picker.lsp_references() end, nowait = true, desc = 'References' },
    { 'gI', function() Snacks.picker.lsp_implementations() end, desc = 'Goto implementation' },
    { 'gy', function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto type definition' },
  })
end

-- ==========================================
-- 🪟 [ Buffer & Window Management ]
-- ==========================================
bind({
  {
    '<leader>bd',
    function()
      local ok, bpm = pcall(require, 'bpm')
      if ok then bpm.detach() else Snacks.bufdelete(0, { wipe = true }) end
    end,
    desc = 'Detach / Wipeout buffer'
  },
  {
    '<leader>bo',
    function()
      local ok, bpm = pcall(require, 'bpm')
      if ok then
        local current_buf = vim.api.nvim_get_current_buf()
        local tab_bufs = bpm.get_attached_buf(0)
        for i = 1, #tab_bufs do
          local buf = tab_bufs[i]
          if buf ~= current_buf then bpm.detach(buf) end
        end
      else
        Snacks.bufdelete.other({ wipe = true })
      end
    end,
    desc = 'Detach other buffers in Workspace'
  },
  {
    '<leader>bD',
    function()
      local ok, bpm = pcall(require, 'bpm')
      if ok then bpm.evict() else Snacks.bufdelete(0, { wipe = true }) end
    end,
    desc = 'Evict buffer from ALL Workspaces'
  },
})

-- ==========================================
-- 🏢 [ Workspace Picker & Color Picker ]
-- ==========================================
bind({
  { '<leader>ft', function() require('custom.workspace').picker() end, desc = 'Find Workspace (Tab)' },
  {
    '<leader>up',
    function()
      require('config.color_picker'); vim.cmd('PickColor')
    end,
    desc = 'Pick Vibe Color'
  },
  { '<leader>br', function() Snacks.rename.rename_file() end, desc = 'Rename file' },
  { '<leader>bs', function() Snacks.scratch() end, desc = 'Toggle scratch buffer' },
})

-- ==========================================
-- 🛠️ [ Utility & Toggles ]
-- ==========================================
bind({
  { '<leader>st', function() require('custom.todo').search() end, desc = 'Search TODOs' },
  { '<leader>pT', function() Snacks.terminal() end, desc = '[Panel] Toggle half terminal' },
  { '<leader>uz', function() Snacks.zen() end, desc = 'Toggle zen mode' },
  { '<leader>uZ', function() Snacks.zen.zoom() end, desc = 'Toggle Zoom (Maximize window)' },
  { '<leader>spp', function() Snacks.profiler.toggle() end, desc = 'Toggle Profiler' },
  { '<leader>sps', function() Snacks.profiler.scratch() end, desc = 'Profiler Scratch Buffer' },
  {
    '<leader>pN',
    desc = '[Float] Neovim News',
    function()
      Snacks.win({
        file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1],
        width = 0.8,
        height = 0.8,
        border = 'rounded',
        backdrop = 60,
        title = ' 📰 News ',
        title_pos = 'center',
        wo = { spell = false, wrap = false, signcolumn = 'yes', statuscolumn = ' ', conceallevel = 3 },
      })
    end,
  },
})

-- ==========================================
-- 📔 [ Zettelkasten ]
-- ==========================================
bind({
  { '<leader>zn', function() zettel.new_card() end, desc = 'Zettel: New Card' },
  { '<leader>zI', function() zettel.init_workspace() end, desc = 'Zettel: Initialize Zettelkasten Workspace' },
  { '<leader>zi', function() zettel.new_inbox_note() end, desc = 'Zettel: New Inbox Note' },
  { '<leader>zb', function() zettel.backlinks() end, desc = 'Zettel: Find Backlinks' },
  { '<leader>zg', function() zettel.generate_graph() end, desc = 'Zettel: Generate graph' },
})

return keys
