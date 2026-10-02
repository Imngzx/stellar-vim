local M = {}

local api = vim.api
local uv = vim.uv
local fs = vim.fs
local fn = vim.fn

local utils = require('libs.utils')

-- Hoist frequently used functions to locals (luajit optimization)
local nvim_buf_get_name = api.nvim_buf_get_name
local nvim_bo = vim.bo
local nvim_notify = vim.notify
local nvim_cmd = vim.cmd
local uv_fs_stat = uv.fs_stat
local uv_fs_read = uv.fs_read
local uv_fs_open = uv.fs_open
local uv_fs_close = uv.fs_close
local fs_normalize = fs.normalize
local fs_dirname = fs.dirname
local fs_basename = fs.basename
local fs_find = fs.find
local shellescape = fn.shellescape
local uv_cwd = uv.cwd
local table_concat = table.concat

-- ====================================================================
-- USER CONFIGURATION (overridable via vim.g.coderunner)
-- ====================================================================

local cfg = vim.g.coderunner or {}

-- Build types: 1 = Release, 2 = Debug (sanitizers)
local C_BUILD_TYPE = cfg.c_build_type or 2
local CPP_BUILD_TYPE = cfg.cpp_build_type or 2

-- Custom compiler flags (overrides defaults)
local C_EXTRA_FLAGS = cfg.c_extra_flags or ''
local CPP_EXTRA_FLAGS = cfg.cpp_extra_flags or ''

-- Custom project commands
local PROJECT_COMMANDS = cfg.project_commands or {}

-- ====================================================================
-- COMPILER HELPERS (lazy-evaluated, cached)
-- ====================================================================

local _c_mode_cache
local function get_c_mode()
  if _c_mode_cache then return _c_mode_cache end
  if C_BUILD_TYPE == 1 then
    -- Release Build (GCC -O2)
    _c_mode_cache = {
      'cd $dir &&',
      'mkdir -p out &&',
      'gcc -Wall -Wextra -O2' .. C_EXTRA_FLAGS .. ' -o out/$fileNameWithoutExt $fileName -lm &&',
      './out/$fileNameWithoutExt',
    }
  else
    -- Debug Build (Clang -g -fsanitize)
    _c_mode_cache = {
      'cd $dir &&',
      'mkdir -p out &&',
      'clang -Wall -Wextra -g -fsanitize=address,undefined' .. C_EXTRA_FLAGS .. ' -o out/$fileNameWithoutExt $fileName -lm &&',
      './out/$fileNameWithoutExt',
    }
  end
  return _c_mode_cache
end

local _cpp_mode_cache
local function get_cpp_mode()
  if _cpp_mode_cache then return _cpp_mode_cache end
  if CPP_BUILD_TYPE == 1 then
    -- Release Build (G++ -O2)
    _cpp_mode_cache = {
      'cd $dir &&',
      'mkdir -p out &&',
      'g++ -std=c++23 -Wall -Wextra -O2' .. CPP_EXTRA_FLAGS .. ' -o out/$fileNameWithoutExt $fileName &&',
      './out/$fileNameWithoutExt',
    }
  else
    -- Debug Build (Clang++ -g -fsanitize)
    _cpp_mode_cache = {
      'cd $dir &&',
      'mkdir -p out &&',
      'clang++ -std=c++23 -Wall -Wextra -g -fsanitize=address,undefined' .. CPP_EXTRA_FLAGS .. ' -o out/$fileNameWithoutExt $fileName -lm &&',
      './out/$fileNameWithoutExt',
    }
  end
  return _cpp_mode_cache
end

-- ====================================================================
-- OS DETECTION AND FILETYPE CONFIG (cached)
-- ====================================================================

local _filetype_cmds_cache
local function get_filetype_cmds()
  if _filetype_cmds_cache then return _filetype_cmds_cache end

  if utils.is_windows() then
    _filetype_cmds_cache = {
      cpp = { 'cd $dir && cl /utf-8 /nologo /EHsc /O2 /std:c++latest /Zc:__cplusplus $fileName /Fe:$fileNameWithoutExt.exe && $fileNameWithoutExt.exe' },
      c = { 'cd $dir && cl /utf-8 /nologo /O2 $fileName /Fe:$fileNameWithoutExt.exe && $fileNameWithoutExt.exe' },
      python = { 'cd $dir &&', 'python -u $fileName' },
      java = { 'cd $dir; javac $fileName; java $fileNameWithoutExt' },
      rust = { 'cd $dir; rustc $fileName; .\\$fileNameWithoutExt.exe' },
      typescript = { 'deno run $fileName' },
      zig = { 'cd $dir &&', 'zig build run' },
    }
  else
    _filetype_cmds_cache = {
      c = get_c_mode(),
      cpp = get_cpp_mode(),
      python = { 'cd $dir &&', 'python3 -u $fileName' },
      java = { 'cd $dir &&', 'javac $fileName &&', 'java $fileNameWithoutExt' },
      rust = { 'cd $dir &&', 'rustc $fileName &&', './$fileNameWithoutExt' },
      typescript = { 'deno run $fileName' },
      zig = { 'cd $dir &&', 'zig build run' },
    }
  end

  -- Merge user-defined commands
  for ft, cmd in pairs(PROJECT_COMMANDS) do
    _filetype_cmds_cache[ft] = cmd
  end

  return _filetype_cmds_cache
end

-- ====================================================================
-- UTILITY FUNCTIONS
-- ====================================================================

local function normalize_path(path)
  return fs_normalize(path):gsub('\\', '/'):gsub('/$', '')
end

local function find_upward(name, start_dir)
  local matches = fs_find(name, { path = start_dir, upward = true })
  return matches[1]
end

local function relative_path(root, path)
  local normalized_root = normalize_path(root)
  local normalized_path = normalize_path(path)
  local prefix = normalized_root .. '/'
  if normalized_path:sub(1, #prefix) == prefix then
    return normalized_path:sub(#prefix + 1)
  end
end

-- ====================================================================
-- CARGO PROJECT DETECTION (optimized with vim.uv sync I/O)
-- ====================================================================

local _cargo_toml_cache = {}

local function read_cargo_toml(cargo_toml)
  local cached = _cargo_toml_cache[cargo_toml]
  if cached then return cached end

  local fd = uv_fs_open(cargo_toml, 'r', 438)
  if not fd then return nil end

  local stat = uv.fs_fstat(fd)
  if not stat then
    uv_fs_close(fd)
    return nil
  end

  local data = uv_fs_read(fd, stat.size, 0)
  uv_fs_close(fd)

  if not data then return nil end

  -- Parse TOML once, cache results
  local lines = {}
  for line in data:gmatch('[^\r\n]+') do
    lines[#lines + 1] = line
  end

  local result = { lines = lines }
  _cargo_toml_cache[cargo_toml] = result
  return result
end

local function find_cargo_bin_name(cargo_toml, file_path)
  local root = fs_dirname(cargo_toml)
  local rel = relative_path(root, file_path)
  if not rel then return nil end

  local parsed = read_cargo_toml(cargo_toml)
  if not parsed then return nil end

  local block_name, block_path = nil, nil

  for _, line in ipairs(parsed.lines) do
    local inline_name, inline_path = line:match('name%s*=%s*"([^"]+)".-path%s*=%s*"([^"]+)"')
    if not inline_name then
      inline_path, inline_name = line:match('path%s*=%s*"([^"]+)".-name%s*=%s*"([^"]+)"')
    end

    if inline_name and inline_path == rel then
      return inline_name
    end

    if line:match('^%s*%[%[') then
      block_name, block_path = nil, nil
    end

    block_name = line:match('^%s*name%s*=%s*"([^"]+)"') or block_name
    block_path = line:match('^%s*path%s*=%s*"([^"]+)"') or block_path

    if block_name and block_path == rel then
      return block_name
    end
  end
end

local function find_package_name(cargo_toml)
  local parsed = read_cargo_toml(cargo_toml)
  if not parsed then return nil end

  local in_package = false
  for _, line in ipairs(parsed.lines) do
    if line:match('^%s*%[package%]%s*$') then
      in_package = true
    elseif line:match('^%s*%[') then
      in_package = false
    elseif in_package then
      local name = line:match('^%s*name%s*=%s*"([^"]+)"')
      if name then return name end
    end
  end
end

local function infer_cargo_bin_name(cargo_toml, file_path)
  local root = fs_dirname(cargo_toml)
  local rel = relative_path(root, file_path)
  if not rel then return nil end

  local bin_name = rel:match('^src/bin/([^/]+)%.rs$')
    or rel:match('^src/bin/([^/]+)/main%.rs$')
  if bin_name then return bin_name end

  if rel == 'src/main.rs' then return find_package_name(cargo_toml) end
end

local function cargo_project_command()
  local file_path = nvim_buf_get_name(0)
  if file_path == '' then return nil end

  local start_dir = fs_dirname(file_path)
  local cargo_toml = find_upward('Cargo.toml', start_dir)
  if not cargo_toml then return nil end

  local root = fs_dirname(cargo_toml)

  if nvim_bo.filetype ~= 'rust' then
    return 'cd ' .. shellescape(root) .. ' && cargo run'
  end

  local bin_name = find_cargo_bin_name(cargo_toml, file_path)
    or infer_cargo_bin_name(cargo_toml, file_path)

  if bin_name then
    return 'cd ' .. shellescape(root) .. ' && cargo run --bin ' .. shellescape(bin_name)
  end

  return 'cd ' .. shellescape(root) .. ' && cargo run'
end

-- ====================================================================
-- TERMINAL EXECUTION (using Snacks.terminal)
-- ====================================================================

local active_term = nil

function M.close()
  if active_term and active_term.valid then
    active_term:close()
    active_term = nil
  end
end

local function build_pause_cmd()
  if utils.is_windows() then
    if vim.o.shell:match('pwsh') or vim.o.shell:match('powershell') then
      return ' ; pause'
    else
      return ' & pause'
    end
  else
    return ' ; echo ""; bash -c \'read -n 1 -s -r -p "Press any key to continue..."\' 2>/dev/null || read -p "Press ENTER to continue..."'
  end
end

local _pause_cmd_cache
local function get_pause_cmd()
  if _pause_cmd_cache then return _pause_cmd_cache end
  _pause_cmd_cache = build_pause_cmd()
  return _pause_cmd_cache
end

local function execute_cmd(cmd)
  nvim_cmd('silent! write')
  M.close()

  local final_cmd = cmd .. get_pause_cmd()

  local win_opts = {
    position = 'float',
    width = 0.8,
    height = 0.8,
    border = 'rounded',
    backdrop = 60,
    title = ' Code Runner ',
    title_pos = 'center',
    zindex = 45,
  }

  active_term = require('snacks').terminal(final_cmd, {
    win = win_opts,
    enter = true,
  })

  nvim_cmd('startinsert')
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { buf = active_term.buf, nowait = true })
end

-- ====================================================================
-- PUBLIC API
-- ====================================================================

function M.build_run_command()
  local ft = nvim_bo.filetype
  local filetype_cmds = get_filetype_cmds()
  local cmd_template = filetype_cmds[ft]

  if not cmd_template then
    nvim_notify('No runner config for filetype: ' .. ft, vim.log.levels.WARN)
    return nil
  end

  if ft == 'rust' then
    local cargo_cmd = cargo_project_command()
    if cargo_cmd then return cargo_cmd end
  end

  local path = nvim_buf_get_name(0)
  if path == '' then
    nvim_notify('Buffer has no associated file', vim.log.levels.WARN)
    return nil
  end

  local dir = fs_dirname(path)
  local fileName = fs_basename(path)
  local fileNameWithoutExt = fileName:match('(.+)%..+') or fileName

  local cmd = type(cmd_template) == 'table' and table_concat(cmd_template, ' ') or cmd_template
  cmd = cmd:gsub('%$dir', dir)
  cmd = cmd:gsub('%$fileNameWithoutExt', fileNameWithoutExt)
  cmd = cmd:gsub('%$fileName', fileName)

  return cmd
end

function M.run()
  local cmd = M.build_run_command()
  if not cmd then return end
  execute_cmd(cmd)
end

function M.build_project_command()
  local cargo_cmd = cargo_project_command()
  if cargo_cmd then return cargo_cmd end

  local path = nvim_buf_get_name(0)
  local cwd = path ~= '' and fs_dirname(path) or uv_cwd()

  if uv_fs_stat(cwd .. '/Makefile') then return 'make' end
  if uv_fs_stat(cwd .. '/build.zig') then return 'zig build run' end
  if uv_fs_stat(cwd .. '/package.json') then return 'npm start' end

  nvim_notify('No project config found (Makefile/Cargo.toml/etc.)', vim.log.levels.WARN)
end

function M.run_project()
  local cmd = M.build_project_command()
  if not cmd then return end
  execute_cmd(cmd)
end

function M.setup()
  local map = vim.keymap.set
  map('n', { '<F5>', '<leader>rc' }, M.run, { desc = 'Save and Run Code' })
  map('n', { '<C-F5>', '<leader>rf' }, M.run, { desc = 'Save and Run File' })
  map('n', { '<S-F5>', '<leader>rx' }, M.close, { desc = 'Stop / Close Runner' })
  map('n', '<leader>rp', M.run_project, { desc = 'Run Project' })
end

return M