local utils = require('heirline.utils')

-- =========================================================
-- ⚡ 1. 赋值优化法 (Localize C-API for extreme performance)
-- =========================================================
local api = vim.api
local schedule = vim.schedule
local math_min = math.min
local table_concat = table.concat
local str_sub = string.sub

local buf_get_name = api.nvim_buf_get_name
local get_opt = api.nvim_get_option_value
local set_current_buf = api.nvim_set_current_buf
local get_current_buf = api.nvim_get_current_buf
local list_bufs = api.nvim_list_bufs
local nvim_strwidth = api.nvim_strwidth
local fs_basename = vim.fs.basename
local str_byteindex = vim.str_byteindex
local str_utfindex = vim.str_utfindex

local diag_count = vim.diagnostic.count
local severity = vim.diagnostic.severity
local list_tabpages = api.nvim_list_tabpages

local _opt_args = { buf = 0 }
local function get_opt_fast(name, bufnr)
  _opt_args.buf = bufnr
  return api.nvim_get_option_value(name, _opt_args)
end

local _bpm, _snacks
local function get_bpm()
  if not _bpm then pcall(function() _bpm = require('bpm') end) end
  return _bpm
end

local function get_snacks()
  if not _snacks then pcall(function() _snacks = require('snacks') end) end
  return _snacks
end

-- =========================================================
-- 🎮 2. 游戏级优化 (GC Reduction & Table Pooling)
-- =========================================================
local function clear_table(t)
  for i = 1, #t do t[i] = nil end
end

local function num_len(n)
  if n < 10 then return 1 end
  if n < 100 then return 2 end
  if n < 1000 then return 3 end
  return 4
end

local function truncate_buf_name(name)
  if #name <= 20 or str_utfindex(name, 'utf-32') <= 20 then return name end
  return str_sub(name, 1, str_byteindex(name, 'utf-32', 19, false)) .. '…'
end

local _buf_pool = {}
local _state_pool = {}

-- =========================================================
-- ⚙️ 3. 数据驱动层 (SoA 架构思想)
-- =========================================================
local function get_bufs()
  local bpm = get_bpm()
  if bpm then return bpm.get_attached_buf(0) end

  clear_table(_buf_pool)
  local all_bufs = list_bufs()
  local idx = 1
  for i = 1, #all_bufs do
    local b = all_bufs[i]
    if get_opt('buflisted', { buf = b }) then
      _buf_pool[idx] = b
      idx = idx + 1
    end
  end
  return _buf_pool
end

local function get_buf_state(bufnr)
  local state = _state_pool[bufnr]
  if not state then
    state = {}
    _state_pool[bufnr] = state
  end

  local name
  local bpm = get_bpm()
  if bpm then
    name = bpm.resolve_bufname(bufnr)
    if require('libs.utils').is_windows() then name = fs_basename(buf_get_name(bufnr)) end
  else
    name = fs_basename(buf_get_name(bufnr))
  end
  if name == '' then name = '[No Name]' end

  name = truncate_buf_name(name)
  state.safe_name = name

  local diags = diag_count(bufnr)
  state.errors = diags[severity.ERROR] or 0
  state.warns = diags[severity.WARN] or 0

  state.is_modified = get_opt_fast('modified', bufnr)
  local icon, hl = get_snacks().util.icon(buf_get_name(bufnr), 'file')
  state.icon = icon
  state.icon_hl = hl

  local w = 7
  w = w + (state.icon and nvim_strwidth(state.icon .. ' ') or 2)
  w = w + nvim_strwidth(state.safe_name)
  if state.errors > 0 then w = w + 3 + num_len(state.errors) end
  if state.warns > 0 then w = w + 3 + num_len(state.warns) end

  state.width = w
  return state
end

-- =========================================================
-- 🔄 4. 自动刷新钩子
-- =========================================================
local aug = api.nvim_create_augroup('Heirline_Tabline_Redraw', { clear = true })
api.nvim_create_autocmd(
  { 'VimEnter', 'UIEnter', 'BufAdd', 'BufDelete', 'BufWipeout', 'BufEnter', 'TabEnter', 'TabClosed',
    'DiagnosticChanged' }, {
    group = aug,
    callback = function(args)
      if args.event == 'BufDelete' or args.event == 'BufWipeout' then
        _state_pool[args.buf] = nil
      end

      schedule(function() vim.cmd('redrawtabline') end)
    end
  })

-- =========================================================
-- 📁 5. 核心 Buffer 渲染块 (数据消费端)
-- =========================================================
local TablineFileNameBlock = {
  hl = function(self) return self.is_active and 'TabLineSel' or 'TabLine' end,

  on_click = {
    callback = function(_, minwid, _, button)
      if button == 'm' or button == 'r' then
        local bpm = get_bpm()
        if bpm then bpm.detach(minwid) else get_snacks().bufdelete(minwid, { wipe = true }) end
      else
        set_current_buf(minwid)
      end
    end,
    minwid = function(self) return self.bufnr end,
    name = 'heirline_tabline_buffer_click',
  },

  { provider = '  ' },

  {
    provider = function(self)
      return self.state.icon and (self.state.icon .. ' ') or
        I.basic.file
    end,
    hl = function(self)
      return (self.is_active and self.state.icon_hl) and self.state.icon_hl or
        'Comment'
    end,
  },

  {
    provider = function(self) return self.state.safe_name end,
    hl = function(self) return { bold = self.is_active, italic = false } end,
  },

  {
    condition = function(self) return self.state.errors > 0 end,
    provider = function(self) return '  ' .. self.state.errors end,
    hl = { fg = 'diag_error' },
  },
  {
    condition = function(self) return self.state.warns > 0 end,
    provider = function(self) return '  ' .. self.state.warns end,
    hl = { fg = 'diag_warn' },
  },

  {
    provider = function(self)
      return self.state.is_modified and I.basic.modify or
        I.basic.close
    end,
    hl = function(self)
      if self.state.is_modified then return { fg = 'command' } end
      return { fg = self.is_active and 'tab_cross_bg' or 'tab_num_unfocus' }
    end,
    on_click = {
      callback = function(_, minwid)
        local bpm = get_bpm()
        if bpm then bpm.detach(minwid) else get_snacks().bufdelete(minwid, { wipe = true }) end
      end,
      minwid = function(self) return self.bufnr end,
      name = 'heirline_tabline_close_btn',
    },
  },
  { provider = ' ' },
}

local TablineBufferBlock = {
  TablineFileNameBlock,
  { provider = '|', hl = 'TabLine' },
}

-- =========================================================
-- 🏢 6. 顶层 Workspace Tab 渲染 (右侧区域)
-- =========================================================
local Tabpage = {
  provider = function(self)
    local bpm = get_bpm()
    local name = bpm and bpm.resolve_tabname(self.tabpage) or tostring(self.tabnr)
    return '%' .. self.tabnr .. 'T  ' .. name .. '  %T'
  end,
  hl = function(self)
    if self.is_active then
      return { fg = 'tab_num', bg = utils.get_highlight('TabLineSel').bg, bold = true }
    else
      return { fg = 'tab_num_unfocus', bg = utils.get_highlight('TabLine').bg, italic = false }
    end
  end,
}

local TabPages = {
  utils.make_tablist(Tabpage),
  {
    provider = '%999X 󰅖 %X',
    hl = function() return { fg = 'tab_cross_fg', bg = 'tab_cross_bg' } end,
  }
}

-- =========================================================
-- 🚀 7. 终极装配 (带 %= 弹性空间 & Pull Back)
-- =========================================================
local function get_right_padding()
  local tabs = list_tabpages()
  local bpm = get_bpm()
  local w = 0
  for i = 1, #tabs do
    local tab = tabs[i]
    local name = bpm and bpm.resolve_tabname(tab) or tostring(i)
    w = w + nvim_strwidth(name) + 4
  end
  return w + 5 -- 关闭按钮(3) + 防边缘换行安全区(2)
end

local function make_perfect_buflist(child_template, left_trunc, right_trunc, get_bufs_fn)
  return {
    init = function(self)
      local bufs = get_bufs_fn()
      local current_buf = get_current_buf()

      self._offset = self._offset or 1
      local total_width = 0
      local active_idx = 1
      local bufs_len = #bufs

      for i = 1, bufs_len do
        local bufnr = bufs[i]
        if bufnr == current_buf then active_idx = i end
        local state = get_buf_state(bufnr)
        total_width = total_width + state.width
      end

      local available_width = vim.o.columns - get_right_padding()

      if total_width <= available_width then
        self._offset = 1
      else
        local pre_active_width = 0
        for i = 1, active_idx - 1 do
          pre_active_width = pre_active_width + _state_pool[bufs[i]]
            .width
        end

        local active_width = _state_pool[bufs[active_idx]].width
        local current_scroll = 0
        for i = 1, self._offset - 1 do current_scroll = current_scroll + _state_pool[bufs[i]].width end

        if pre_active_width < current_scroll then
          self._offset = active_idx
        elseif pre_active_width + active_width > current_scroll + available_width then
          local temp_w = 0
          self._offset = 1
          for i = active_idx, 1, -1 do
            temp_w = temp_w + _state_pool[bufs[i]].width
            local req_w = temp_w + (i > 1 and 3 or 0)
            if req_w > available_width then
              self._offset = math_min(i + 1, active_idx)
              break
            end
          end
        end

        local width_from_offset = 0
        for i = self._offset, bufs_len do
          width_from_offset = width_from_offset +
            _state_pool[bufs[i]].width
        end

        if width_from_offset + (self._offset > 1 and 3 or 0) < available_width and self._offset > 1 then
          local temp_w = 0
          self._offset = 1
          for i = bufs_len, 1, -1 do
            temp_w = temp_w + _state_pool[bufs[i]].width
            local req_w = temp_w + (i > 1 and 3 or 0)
            if req_w > available_width then
              self._offset = i + 1
              break
            end
          end
        end
      end

      self._children = self._children or {}
      clear_table(self._children)

      local current_w = 0
      local child_idx = 1

      if self._offset > 1 then
        self._children[child_idx] = self:new(left_trunc, 1)
        current_w = current_w + 3
        child_idx = child_idx + 1
      end

      for i = self._offset, bufs_len do
        local bufnr = bufs[i]
        local w = _state_pool[bufnr].width
        if current_w + w > available_width then
          self._children[child_idx] = self:new(right_trunc, 1)
          break
        end

        local child = self:new(child_template, i)
        child.bufnr = bufnr
        child.is_active = (bufnr == current_buf)
        child.state = _state_pool[bufnr] -- 直接投喂预计算好的状态，Zero Double Work！

        self._children[child_idx] = child
        current_w = current_w + w
        child_idx = child_idx + 1
      end
    end,

    provider = function(self)
      local out = {}
      for i = 1, #self._children do out[i] = self._children[i]:eval() end
      return table_concat(out, '')
    end
  }
end

local BufferLine = make_perfect_buflist(
  TablineBufferBlock,
  { provider = '  ', hl = 'TabLine' },
  { provider = '  ', hl = 'TabLine' },
  get_bufs
)

local TabLine = {
  BufferLine,
  { provider = '%=', hl = 'TabLineFill' },
  TabPages,
}

return TabLine
