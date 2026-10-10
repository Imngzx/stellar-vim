local M = {}

local api = vim.api
local nvim_buf_get_name = api.nvim_buf_get_name

M.config = {
  stage_action = nil,
  get_git_root = nil
}

local function get_file_status(git_root, rel_path)
  local obj = vim.system({
    'git', '-C', git_root, 'status', '--porcelain=v1', '--', rel_path
  }, { text = true }):wait()

  if obj.code ~= 0 or not obj.stdout or obj.stdout == '' then return nil end
  return obj.stdout:sub(1, 2)
end

local function make_item(git_root, rel_path, status)
  return {
    cwd = git_root,
    status = status,
    file = rel_path,
  }
end

function M.toggle_stage()
  local bufname = nvim_buf_get_name(0)
  if bufname == '' then
    vim.notify('Current buffer has no associated file', vim.log.levels.ERROR)
    return
  end

  local git_root = M.config.get_git_root(bufname)
  if not git_root then
    vim.notify('Not inside a Git repository', vim.log.levels.ERROR)
    return
  end

  local rel_path = vim.fs.relpath(git_root, bufname) or bufname
  local status = get_file_status(git_root, rel_path)
  if not status then
    vim.notify('File is not tracked by Git', vim.log.levels.ERROR)
    return
  end

  local picker = {
    selected = function(_, _)
      return { make_item(git_root, rel_path, status) }
    end,
    refresh = function()
      local action = status:sub(2, 2) == ' ' and 'unstaged' or 'staged'
      vim.notify(string.format('File %s %s', rel_path, action), vim.log.levels.INFO)
    end,
  }

  M.config.stage_action(picker)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  if not M.config.stage_action then
    M.config.stage_action = require('snacks.picker').actions.git_stage
  end
  if not M.config.get_git_root then
    M.config.get_git_root = require('snacks.git').get_root
  end

  vim.keymap.set('n', '<leader>ga', M.toggle_stage, { desc = 'Toggle git stage' })
end

return M