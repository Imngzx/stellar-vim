local M = {}

local api = vim.api
local fn = vim.fn
local uv = vim.uv
local fs = vim.fs
local bpm = require('libs.bpm')
local nvim_list_bufs = api.nvim_list_bufs
local nvim_buf_is_loaded = api.nvim_buf_is_loaded
local nvim_buf_get_name = api.nvim_buf_get_name
local nvim_buf_delete = api.nvim_buf_delete
local nvim_get_option_value = api.nvim_get_option_value
local nvim_create_user_command = api.nvim_create_user_command
local nvim_create_augroup = api.nvim_create_augroup
local nvim_create_autocmd = api.nvim_create_autocmd

local fs_stat = uv.fs_stat
local fs_scandir = uv.fs_scandir
local fs_scandir_next = uv.fs_scandir_next
local fs_open = uv.fs_open
local fs_read = uv.fs_read
local fs_write = uv.fs_write
local fs_close = uv.fs_close
local fs_fstat = uv.fs_fstat
local cwd = uv.cwd
local TITLE = 'Stellar:Session'

local DEFAULT_PERSISTENCE = {
  dir = '.cache/nvim',
  session = true,
  undo = true,
  shada = true,
  swap = true,
}

local persistence
local setup_persistence

local function ensure_dir(path)
  if not fs_stat(path) then vim.fs.mkdir(path, { parents = true }) end
end

local function get_git_branch(root)
  local head_path = root .. '/.git/HEAD'
  local fd = fs_open(head_path, 'r', 438)
  if not fd then return '' end

  local stat = fs_fstat(fd)
  if not stat then
    fs_close(fd)
    return ''
  end

  local data = fs_read(fd, stat.size, 0)
  fs_close(fd)

  if not data or data == '' then return '' end

  local branch = data:match('ref: refs/heads/([^\n\r]+)')
  if branch then return branch end

  return data:sub(1, 7)
end

local function get_workspace_root()
  local current_cwd = fs.normalize(cwd() or '')
  return fs.normalize(fs.root(current_cwd, { '.git' }) or current_cwd)
end

local function get_session_name()
  local root = persistence.root
  local branch = get_git_branch(root)
  if branch ~= '' then branch = '@@' .. branch:gsub('[/:]', '%%') end

  local name = root:gsub('[/:]', '%%') .. branch
  return fs.joinpath(persistence.session_dir, name .. '.vim')
end

function M.save()
  if not persistence then setup_persistence() end

  if not persistence.session then return end

  if vim.g.session_stopped then return end

  local has_real_file = false
  local bufs = nvim_list_bufs()

  for i = 1, #bufs do
    local buf = bufs[i]
    if nvim_buf_is_loaded(buf) and nvim_get_option_value('buflisted', { buf = buf }) then
      if nvim_buf_get_name(buf) ~= '' and nvim_get_option_value('buftype', { buf = buf }) == '' then
        has_real_file = true
        break
      end
    end
  end

  if not vim.g.session_loaded and not has_real_file then
    return
  end

  vim.o.sessionoptions = 'buffers,curdir,tabpages,winsize,help,skiprtp,folds'

  vim.cmd('silent! cclose')
  vim.cmd('silent! lclose')

  local bpm_data = bpm.call('to_json')

  local session_name = get_session_name()

  vim.cmd('silent! mksession! ' .. fn.fnameescape(session_name))

  if bpm_data then
    local json_path = session_name:gsub('%.vim$', '.json')
    local fd = fs_open(json_path, 'w', 438)
    if fd then
      fs_write(fd, bpm_data, -1)
      fs_close(fd)
    end
  end
end

function M.load(last)
  if not persistence then setup_persistence() end

  if not persistence.session then return end

  local target_file = get_session_name()

  if last then
    local max_time = 0
    local latest_file = nil

    local req = fs_scandir(persistence.session_dir)
    if req then
      while true do
        local name, type = fs_scandir_next(req)
        if not name then break end

        if type == 'file' and name:sub(-4) == '.vim' then
          local path = fs.joinpath(persistence.session_dir, name)
          local stat = fs_stat(path)
          if stat and stat.mtime.sec > max_time then
            max_time = stat.mtime.sec
            latest_file = path
          end
        end
      end
    end

    if latest_file then target_file = latest_file end
  end

  if fs_stat(target_file) then
    local bufs = nvim_list_bufs()
    for i = 1, #bufs do
      local buf = bufs[i]
      local bt = nvim_get_option_value('buftype', { buf = buf })
      local ft = nvim_get_option_value('filetype', { buf = buf })
      if ft == 'snacks_dashboard' or bt == 'nofile' or bt == 'terminal' then
        pcall(nvim_buf_delete, buf, { force = true })
      end
    end

    vim.cmd('silent! source ' .. fn.fnameescape(target_file))

    if bpm.is_available() then
      local bpm_path = target_file:gsub('%.vim$', '.json')
      local bpm_stat = fs_stat(bpm_path)
      if bpm_stat then
        local fd = fs_open(bpm_path, 'r', 438)
        if fd then
          local data = fs_read(fd, bpm_stat.size, 0)
          fs_close(fd)

          if data and data ~= '' then
            bpm.get().from_json(data)

            local after_bufs = nvim_list_bufs()
            for i = 1, #after_bufs do
              local bufnr = after_bufs[i]
              if api.nvim_buf_is_valid(bufnr) then
                api.nvim_set_option_value('buflisted', false, { buf = bufnr })
              end
            end
            pcall(api.nvim_exec_autocmds, 'TabEnter', { group = 'BufferPoolManager' })
          end
        end
      end
    end

    vim.g.session_loaded = true
    vim.notify('Session & Workspace Restored', vim.log.levels.INFO, { title = TITLE })
  else
    vim.notify('No Session Found for current branch/dir', vim.log.levels.WARN, { title = TITLE })
  end
end

setup_persistence = function()
  local config = vim.tbl_extend('force', DEFAULT_PERSISTENCE, vim.g.session_persistence or {})
  local root = get_workspace_root()
  local base_dir = fs.joinpath(root, config.dir)
  local session_dir = fs.joinpath(base_dir, 'sessions')

  persistence = {
    root = root,
    session = config.session,
    session_dir = session_dir,
  }

  if config.session then ensure_dir(session_dir) end

  vim.o.undofile = config.undo
  if config.undo then
    local undo_dir = fs.joinpath(base_dir, 'undo')
    ensure_dir(undo_dir)
    vim.o.undodir = undo_dir
  end

  if config.shada and vim.o.shadafile ~= 'NONE' then
    local shada_dir = fs.joinpath(base_dir, 'shada')
    ensure_dir(shada_dir)
    vim.o.shadafile = fs.joinpath(shada_dir, 'main.shada')
  elseif not config.shada then
    vim.o.shada = ''
  end

  vim.o.swapfile = config.swap
  if config.swap then
    local swap_dir = fs.joinpath(base_dir, 'swap')
    ensure_dir(swap_dir)
    vim.o.directory = swap_dir .. '//'
  end
end

local initialized = false

function M.setup()
  if not persistence then setup_persistence() end

  if initialized then return end

  setup_persistence()
  nvim_create_autocmd('VimLeavePre', {
    group = nvim_create_augroup('Session', { clear = true }),
    callback = M.save,
  })

  nvim_create_user_command('RestoreSession', function() M.load(false) end, {})
  nvim_create_user_command('RestoreLastSession', function() M.load(true) end, {})
  nvim_create_user_command('StopSession', function()
    vim.g.session_stopped = true
    vim.notify('Session saving disabled for this instance', vim.log.levels.WARN, { title = TITLE })
  end, {})

  initialized = true
end

return M
