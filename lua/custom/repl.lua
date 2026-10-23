local M = {}
local LOG_TITLE = 'Repl'

local api = vim.api
local pcall, xpcall, load, type, select = pcall, xpcall, load, type, select
local setmetatable, setfenv = setmetatable, setfenv
local table_concat = table.concat
local debug_traceback = debug.traceback
local nvim_buf_get_text = api.nvim_buf_get_text
local nvim_buf_set_lines = api.nvim_buf_set_lines
local nvim_buf_get_mark = api.nvim_buf_get_mark
local nvim_get_current_buf = api.nvim_get_current_buf
local nvim_feedkeys = api.nvim_feedkeys
local nvim_replace_termcodes = api.nvim_replace_termcodes
local nvim_get_mode = api.nvim_get_mode
local schedule = vim.schedule
local inspect = vim.inspect

local CurrCtx = nil

local function new_env()
  return setmetatable({}, { __index = _G })
end

local function ensure_ctx()
  if not CurrCtx then CurrCtx = { env = new_env() } end
  return CurrCtx
end

function M.reset_current_ctx()
  CurrCtx = { env = new_env() }
end

local function repl_impl(lines)
  local out = {}

  local function on_error(err)
    table.insert(out, '[ERROR]')
    if err then
      table.insert(out, err)
    end
    local trace_back = debug_traceback()
    vim.list_extend(out, vim.split(trace_back, '\n', { plain = true }))
  end

  local function on_print(...)
    local args = { ... }
    local parts = {}
    for i = 1, select('#', ...) do
      local v = args[i]
      parts[i] = type(v) == 'string' and v or inspect(v)
    end
    local str = table_concat(parts, ' ')
    local output_lines = vim.split(str, '\n', { plain = true })
    vim.list_extend(out, output_lines)
  end

  local source_code = table_concat(lines, '\n')
  local chunk, err = load(source_code, 'main@repl')

  if not chunk then
    on_error(err)
    return out
  end

  local env = ensure_ctx().env
  setfenv(chunk, env)
  env.print = on_print

  local results = { xpcall(chunk, on_error) }
  local ok = table.remove(results, 1)

  if ok then
    local vals = vim.tbl_map(inspect, results)

    if #vals > 0 then
      local ret = '=> ' .. vals[1]
      local ret_lines = vim.split(ret, '\n', { plain = true })
      vim.list_extend(out, ret_lines)

      for i = 2, #vals do
        table.insert(out, ',')
        local val = vals[i]
        if type(val) == 'string' then
          vim.list_extend(out, vim.split(val, '\n', { plain = true }))
        else
          vim.list_extend(out, { tostring(val) })
        end
      end
    end
  end

  return out
end

local function get_lines(bufnr, from, to)
  local ok, ret = pcall(nvim_buf_get_text, bufnr, from[1], from[2], to[1], to[2])
  if not ok then
    vim.notify(
      string.format('Cannot get text of buffer %d, [%d:%d]-[%d:%d] because `%s`', bufnr, from[1],
        from[2], to[1], to[2], ret),
      vim.log.levels.ERROR,
      { title = LOG_TITLE }
    )
    return nil
  end
  return ret
end

function M.exec(bufnr, from, to)
  local lines = get_lines(bufnr, from, to)
  if not lines or #lines == 0 then return end
  local out = repl_impl(lines)
  if #out > 0 then
    local line_to_insert = to[1]
    nvim_buf_set_lines(bufnr, line_to_insert + 1, line_to_insert + 1, false, out)
  end
end

function M.eval(bufnr, from, to)
  local lines = get_lines(bufnr, from, to)
  if not lines or #lines == 0 then return end
  lines[#lines] = 'return ' .. lines[#lines]
  local out = repl_impl(lines)
  if #out > 0 then
    local line_to_insert = to[1]
    nvim_buf_set_lines(bufnr, line_to_insert + 1, line_to_insert + 1, false, out)
  end
end

local function change_mode(mode_key)
  -- 修复点：将 'n' 换成 'x'，同步执行按键事件，确保在获取标记（mark）前彻底退出 Visual 模式
  nvim_feedkeys(nvim_replace_termcodes(mode_key, true, false, true), 'x', false)
end

local function exec_wrapper(fn)
  local buf = nvim_get_current_buf()
  local from = nvim_buf_get_mark(buf, '<')
  local to = nvim_buf_get_mark(buf, '>')

  from[1] = from[1] - 1
  to[1] = to[1] - 1
  to[2] = to[2] + 1

  fn(buf, from, to)
end

local function visual_wrapper(fn)
  local mode = nvim_get_mode().mode
  if mode ~= 'v' and mode ~= 'V' and mode ~= '\22' then
    vim.notify('Unsupported mode: start repl on modes `v`, `V` or `C-v`', vim.log.levels.ERROR,
      { title = LOG_TITLE })
    return
  end

  change_mode('<Esc>')
  schedule(function() exec_wrapper(fn) end)
end

function M.setup()
  local map = vim.keymap.set

  api.nvim_create_user_command('ReplExec', function() exec_wrapper(M.exec) end, { range = true })
  api.nvim_create_user_command('ReplEval', function() exec_wrapper(M.eval) end, { range = true })

  map('v', '<leader>rr', function() visual_wrapper(M.exec) end,
    { silent = true, desc = 'Exec selected code' })
  map('v', '<leader>re', function() visual_wrapper(M.eval) end,
    { silent = true, desc = 'Eval selected code' })
end

return M
