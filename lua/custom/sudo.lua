-- Windows 系统直接退出，不加载此功能
if require('libs.utils').is_windows() then
  return
end
local SUDO_TITLE = 'Sudo'

local aug = vim.api.nvim_create_augroup('sudo_save_simple', { clear = true })

-- 检查当前文件或目录是否有写入权限
local function is_writable(path)
  if path == '' then return true end

  local stat = vim.uv.fs_stat(path)
  if stat then
    return vim.uv.fs_access(path, 'W')
  else
    local dir = vim.fs.dirname(path)
    return vim.uv.fs_access(dir, 'W')
  end
end

-- 核心保存逻辑
local function do_sudo_save(buf, path)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local data = table.concat(lines, '\n') .. '\n'

  -- 1. 先探测是否需要输入密码 (可能 sudo 缓存还在有效内)
  local check = vim.system({ 'sudo', '-n', 'true' }):wait()
  local stdin_data = data

  if check.code ~= 0 then
    -- 2. 需要密码时才弹出输入框
    local pwd = vim.fn.inputsecret('Sudo Password for ' .. vim.fs.basename(path) .. ': ')

    -- 取消或未输入
    if not pwd or pwd == '' then
      vim.notify('Canceled.', vim.log.levels.WARN, { title = SUDO_TITLE })
      return
    end
    -- 将密码和数据流合并，供 sudo -S 读取 (完美修复多出空行的 Bug)
    stdin_data = pwd .. '\n' .. data
  end

  -- 3. 使用 sudo tee 执行保存
  local obj = vim.system({ 'sh', '-c', 'sudo -S tee "$1" >/dev/null', '--', path }, {
    stdin = stdin_data
  }):wait()

  if obj.code == 0 then
    vim.bo[buf].modified = false
    vim.cmd('checktime ' .. buf)
    vim.notify('Successfully saved: ' .. path, vim.log.levels.INFO, { title = SUDO_TITLE })
  else
    vim.notify('Failed to save: ' .. (obj.stderr or ''), vim.log.levels.ERROR,
      { title = SUDO_TITLE })
  end
end

-- 拦截器：当读取或新建文件时，如果没权限，则挂载拦截钩子
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  group = aug,
  callback = function(args)
    local buf = args.buf
    local path = vim.api.nvim_buf_get_name(buf)

    -- 过滤掉悬浮窗、终端或无名 Buffer
    if vim.bo[buf].buftype ~= '' and vim.bo[buf].buftype ~= 'acwrite' then return end
    if path == '' or path:match('^[%w%+%.%-]+://') then return end

    -- 如果没有写权限
    if not is_writable(path) then
      -- 告诉 Neovim: "这个文件不可写，但我会手动接管保存过程，别乱报 ReadOnly 警告"
      vim.bo[buf].buftype = 'acwrite'

      -- 为这个 Buffer 专门设置一个监听器：只在敲下 `:w` 时触发
      vim.api.nvim_create_autocmd('BufWriteCmd', {
        group = aug,
        buf = buf,
        callback = function()
          do_sudo_save(buf, path)
        end
      })
    end
  end
})
