local map = vim.keymap.set
local cmd = vim.cmd

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- [Basic]
-- Quit & Save
map('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit all' })
map('n', '<leader>qr', '<cmd>restart!<cr>', { desc = 'Restart' })
map('n', '<leader>ww', '<cmd>w<cr>', { desc = 'Save file' })
map('n', '<leader>wq', '<cmd>wq<cr>', { desc = 'Save and quit' })

-- [View]
map('n', '<leader>us', '<cmd>setlocal spell! spell?<cr>', { desc = 'Toggle spelling' })
map('n', '<leader>uw', '<cmd>setlocal wrap! wrap?<cr>', { desc = 'Toggle wrap' })

-- [Edit]
-- Indent
map({ 'n', 'v' }, 'j', 'gj')
map({ 'n', 'v' }, 'k', 'gk')
map('x', '<', '<gv')
map('x', '>', '>gv')

-- Comment
map('n', 'gco', 'o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add comment below' })
map('n', 'gcO', 'O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add comment above' })

-- Move lines
map('n', '<a-k>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = 'Move up' })
map('n', '<a-j>', "<cmd>execute 'move .+' . v:count1<cr>==", { desc = 'Move down' })
map('i', '<a-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move up' })
map('i', '<a-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move down' })
map('v', '<a-k>', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = 'Move up' })
map('v', '<a-j>', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = 'Move down' })

-- Spelling
map('n', '<leader>cs', 'z=', { desc = 'Spelling suggestions' })

-- [Buffer]
map('n', '<s-h>', '<cmd>bprevious<cr>', { desc = 'Prev buffer' })
map('n', '<s-l>', '<cmd>bnext<cr>', { desc = 'Next buffer' })
map('n', '<leader>bn', function()
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
end, { desc = 'New file' })

-- [Window]
map('n', '<leader>pd', '<c-w>c', { desc = 'Delete window', remap = true })
map('n', '<leader>ps', '<c-w>s', { desc = '[Panel] Split window below', remap = true })
map('n', '<leader>pv', '<c-w>v', { desc = '[Panel] Split window right', remap = true })

-- Move between windows
map('n', '<c-h>', '<c-w>h', { desc = 'Move to left window' })
map('n', '<c-j>', '<c-w>j', { desc = 'Move to below window' })
map('n', '<c-k>', '<c-w>k', { desc = 'Move to above window' })
map('n', '<c-l>', '<c-w>l', { desc = 'Move to right window' })

-- Resize splits
map('n', '<c-left>', function() vim.cmd('vertical resize -' .. vim.v.count1) end,
  { desc = 'Decrease window width' })
map('n', '<c-right>', function() vim.cmd('vertical resize +' .. vim.v.count1) end,
  { desc = 'Increase window width' })
map('n', '<c-down>', function() vim.cmd('resize -' .. vim.v.count1) end,
  { desc = 'Decrease window height' })
map('n', '<c-up>', function() vim.cmd('resize +' .. vim.v.count1) end,
  { desc = 'Increase window height' })

-- Terminal
map('n', '<leader>pt', function()
  local shell = ''
  local fn = vim.fn

  if require('libs.utils').is_windows() then
    if fn.executable('pwsh') == 1 then
      shell = 'pwsh'
    elseif fn.executable('powershell') == 1 then
      shell = 'powershell'
    else
      shell = 'cmd'
    end
  else
    if fn.executable('fish') == 1 then
      shell = 'fish'
    elseif fn.executable('zsh') == 1 then
      shell = 'zsh'
    else
      shell = vim.env.SHELL or 'bash'
    end
  end

  cmd('term ' .. shell)
  cmd('startinsert')
end, { desc = '[Panel] Open Smart Terminal' })

map('n', 'mdd', function() vim.cmd("delm!") end, { expr = true, desc = 'Delete all markers' })

-- Search (Better n/N behavior)
map('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next search result' })
map('x', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
map('o', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result' })
map('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev search result' })
map('x', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })
map('o', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result' })

-- ==========================================
-- 🏢 [ Workspace / Tabs (Powered by BPM) ]
-- ==========================================
map('n', '<leader><tab>n', '<cmd>tabnew<cr>', { desc = 'New Workspace' })
map('n', '<leader><tab>N', function()
  vim.ui.input({ prompt = 'Workspace Name: ' }, function(name)
    if not name then return end
    vim.api.nvim_command('tabnew')
    if name ~= '' then
      local ok, bpm = pcall(require, 'bpm')
      if ok then bpm.rename_tab(vim.api.nvim_get_current_tabpage(), name) end
    else
      vim.notify('Warn: Workspace name not assigned, opening an anonymous buffer',
        vim.log.levels.WARN)
    end
  end)
end, { silent = true, desc = 'New Workspace with name' })
map('n', '<leader><tab>d', '<cmd>tabclose<cr>', { desc = 'Close Workspace' })
map('n', '<leader><tab>r', function()
  vim.ui.input({ prompt = 'Workspace Name: ' }, function(name)
    if not name or name == '' then return end
    local ok, bpm = pcall(require, 'bpm')
    if ok then bpm.rename_tab(vim.api.nvim_get_current_tabpage(), name) end
  end)
end, { desc = 'Rename Workspace' })

-- Clear search and stop snippet on escape
map({ 'i', 'n', 's' }, '<esc>', function()
  vim.v.hlsearch = 0
  return '<esc>'
end, { expr = true, desc = 'Escape and clear hlsearch' })

-- Yazi integration
map('n', '<leader>fy', function() require('custom.yazi').open() end, { desc = 'Find via Yazi' })

-- Showkeys toggle
map('n', '<leader>sK', '<cmd>ShowkeysToggle<cr>', { desc = 'Toggle Showkeys' })

-- Package update
map('n', '<leader>pu', function() vim.pack.update() end, { desc = '[Panel] Update plugins' })

map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

map('n', '<leader>ch', function() require('custom.cheatsheet').toggle() end,
  { desc = 'Toggle Cheatsheet' })
