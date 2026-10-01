local api = vim.api
local o = vim.o
local opt = vim.opt
local create_autocmd = api.nvim_create_autocmd
-- local write = io.write
local create_augroup = api.nvim_create_augroup
local schedule = vim.schedule
local ui_group = create_augroup('AutoUIVisibility', { clear = true })
local map = vim.keymap.set
local user_command = vim.api.nvim_create_user_command
-- local bg_sync_group = vim.api.nvim_create_augroup('TerminalBgSync', { clear = true })

local function augroup(name)
  return create_augroup('cameron_' .. name, { clear = true })
end

-- no commenting on next line when o or O in normal mode
create_autocmd('FileType', {
  group = create_augroup('DisableAutoComment', { clear = true }),
  pattern = '*',
  callback = function(event)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(event.buf) then
        vim.bo[event.buf].formatoptions = vim.bo[event.buf].formatoptions:gsub('[cro]', '')
      end
    end)
  end,
})

-- [Autocmd] Highlight on yank and paste
create_autocmd({ 'TextYankPost', 'TextPutPost' }, {
  group = create_augroup('HighlightOnYankAndPaste', { clear = true }),
  callback = function() vim.hl.hl_op() end,
  desc = 'Highlight text when yank and paste',
})

-- [Autocmd] Change EOL format to unix on save
create_autocmd('BufWritePre', {
  callback = function(args)
    local buf = args.buf
    local get_opt = vim.api.nvim_get_option_value
    if get_opt('readonly', { buf = buf })
      or get_opt('buftype', { buf = buf }) ~= ''
      or get_opt('binary', { buf = buf }) then
      return
    end
    vim.api.nvim_set_option_value('fileformat', 'unix', { buf = buf })
  end,
})

-- [Autocmd] Auto set root
create_autocmd('BufEnter', {
  group = create_augroup('AutoSetRoot', { clear = true }),
  callback = function(args)
    if vim.g.SessionLoad or vim.bo[args.buf].buftype ~= '' then return end
    local root = vim.fs.root(args.buf, { '.git', 'Makefile', '.jj' })
    if root then api.nvim_set_current_dir(root) end
  end,
  desc = 'Find root and change current directory',
})

-- close some filetypes with <q>
create_autocmd('FileType', {
  group = augroup('close_with_q'),
  pattern = {
    'PlenaryTestPopup', 'checkhealth', 'dap-float', 'dbout', 'gitsigns-blame',
    'grug-far', 'help', 'lspinfo', 'neotest-output', 'neotest-output-panel',
    'neotest-summary', 'notify', 'qf', 'spectre_panel', 'startuptime',
    'tsplayground', 'msg', 'pager', 'dialog',
  },
  callback = function(event)
    local buf = event.buf
    vim.bo[buf].buflisted = false
    schedule(function()
      if not api.nvim_buf_is_valid(buf) then return end
      map('n', 'q', function()
        pcall(vim.api.nvim_win_close, 0, false)
        pcall(api.nvim_buf_delete, buf, { force = true })
      end, { buf = buf, silent = true, desc = 'Quit buffer' })
    end)
  end,
})

create_autocmd({ 'BufEnter', 'BufAdd', 'BufDelete' }, {
  group = ui_group,
  callback = function()
    local has_real_file = false

    local list_bufs = api.nvim_list_bufs
    local buf_is_valid = api.nvim_buf_is_valid
    local buf_is_loaded = api.nvim_buf_is_loaded
    local buf_get_name = api.nvim_buf_get_name

    local bufs = list_bufs()

    for i = 1, #bufs do
      local buf = bufs[i]
      if buf_is_valid(buf) and buf_is_loaded(buf) and api.nvim_get_option_value('buflisted', { buf = buf }) then
        local ft = api.nvim_get_option_value('filetype', { buf = buf })
        local bt = api.nvim_get_option_value('buftype', { buf = buf })
        local modified = api.nvim_get_option_value('modified', { buf = buf })
        local name = buf_get_name(buf)

        if ft ~= 'snacks_dashboard' and not ft:match('^snacks_picker') then
          if name ~= '' or modified or bt == 'terminal' then
            has_real_file = true
            break
          end
        end
      end
    end

    if has_real_file then
      if o.showtabline ~= 2 then opt.showtabline = 2 end
      if o.laststatus ~= 3 then opt.laststatus = 3 end
    else
      if o.showtabline ~= 0 then opt.showtabline = 1 end
      if o.laststatus ~= 0 then opt.laststatus = 0 end
    end
  end,
})

user_command('ZettelInit', function()
  require('custom.zettel').init_workspace()
end, { desc = 'Initialize Zettelkasten Workspace' })

-- create_autocmd({ 'VimEnter', 'ColorScheme' }, {
--   group = bg_sync_group,
--   callback = function()
--     local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
--     if normal and normal.bg then
--       local hex = string.format('#%06x', normal.bg)
--
--       if os.getenv('TMUX') then
--         write(string.format('\027Ptmux;\027\027]11;%s\007\027\\', hex))
--       else
--         -- Native Kitty sequence
--         write(string.format('\027]11;%s\007', hex))
--       end
--     end
--   end,
-- })
--
-- create_autocmd('VimLeavePre', {
--   group = bg_sync_group,
--   callback = function()
--     if os.getenv('TMUX') then
--       write('\027Ptmux;\027\027]111\007\027\\')
--     else
--       write('\027]111\007')
--     end
--   end,
-- })
