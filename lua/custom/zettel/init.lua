local M = {}

local api = vim.api
local fn = vim.fn
local uv = vim.uv
local fs = vim.fs

local fs_stat = uv.fs_stat
local fs_open = uv.fs_open
local fs_write = uv.fs_write
local fs_close = uv.fs_close
local fs_normalize = fs.normalize
local os_homedir = uv.os_homedir
local json_encode = vim.json.encode

local string_match = string.match
local string_gmatch = string.gmatch
local fn_substitute = fn.substitute
local string_gsub = string.gsub
local string_lower = string.lower
local fn_fnamemodify = fn.fnamemodify
local fn_fnameescape = fn.fnameescape
local fn_executable = fn.executable
local os_execute = os.execute
local os_date = os.date
local pcall = pcall
local tostring = tostring
local system = vim.system
local schedule = vim.schedule
local cwd = uv.cwd
local contents = require('custom.zettel.contents')


local function get_workspace_root()
  local buf = api.nvim_get_current_buf()
  local root = fs.root(buf, { '.marksman.toml', '.git', 'Makefile', '.jj' }) or cwd() or '.'
  return fs_normalize(root)
end

local function get_target_filepath(title, sub_dir, exact_name)
  local step1 = string_lower(string_gsub(title, '%s+', '-'))
  local safe_title = fn_substitute(step1, '\\v[^a-z0-9_.\\-一-龥ぁ-んァ-ヶ가-힣]', '', 'g')
  local filename = exact_name and (safe_title .. '.md') or
    (tostring(os_date('%Y%m%d%H%M')) .. '-' .. safe_title .. '.md')
  local root = get_workspace_root()
  local target_dir = fs_normalize(root .. '/' .. sub_dir)
  if not fs_stat(target_dir) then
    vim.fs.mkdir(target_dir, { parents = true })
  end
  return target_dir .. '/' .. filename
end

local function createbuf_and_curpos(filepath, lines, cursor_pos)
  local bufnr = api.nvim_create_buf(true, false)
  api.nvim_buf_set_name(bufnr, filepath)
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  api.nvim_set_option_value('filetype', 'markdown', { buf = bufnr })
  api.nvim_set_current_buf(bufnr)
  api.nvim_win_set_cursor(0, cursor_pos)
  -- uncomment this if you want insert mode after zettel init
  -- vim.cmd('startinsert')
end

function M.init_workspace()
  local default_path = get_workspace_root()
  vim.ui.input({ prompt = ' 🚀 Init Zettel workspace in: ', default = default_path }, function(path)
    if not path or path == '' then return end
    schedule(function()
      local home = os_homedir()
      if home and path:sub(1, 1) == '~' then
        path = home .. path:sub(2)
      end
      path = fs_normalize(path)
      local dirs = {
        path,
        path .. '/.meta',
        path .. '/Inbox',
        path .. '/Inbox/Daily',
        path .. '/Inbox/Meetings',
        path .. '/Inbox/Idea',
        path .. '/Inbox/Snippet',
        path .. '/Inbox/Projects',
        path .. '/Inbox/People',
        path .. '/Cards',
        path .. '/Cards/Examples',
        path .. '/Assets'
      }
      for i = 1, #dirs do
        local dir = dirs[i]
        if not fs_stat(dir) then
          vim.fs.mkdir(dir, { parents = true })
        end
      end
      local function write_file(filepath, content)
        fs_stat(filepath, function(_, stat)
          if not stat then
            fs_open(filepath, 'w', 438, function(_, fd)
              if fd then
                fs_write(fd, content, -1, function()
                  fs_close(fd)
                end)
              end
            end)
          end
        end)
      end
      write_file(path .. '/.marksman.toml', contents.TOML_CONTENT)
      write_file(path .. '/.markdownlint.json', contents.JSON_CONTENT)
      write_file(path .. '/.editorconfig', contents.EDITORCONFIG)
      write_file(path .. '/.gitignore', contents.GITIGNORE)
      write_file(path .. '/.rumdl.toml', contents.RUMDL)
      write_file(path .. '/.moxide.toml', contents.MD_OXIDE)
      write_file(path .. '/index.md', contents.INDEX_CONTENT)
      write_file(path .. '/Cards/Examples/example-card.md', contents.EXAMPLE_CARD_CONTENT)
      write_file(path .. '/Cards/Examples/example-tag.md', contents.EXAMPLE_TAG_CONTENT)
      write_file(path .. '/Cards/Examples/example-usage.md', contents.EXAMPLE_USAGE_CONTENT)
      write_file(path .. '/.meta/user.md', contents.USER_META_CONTENT)
      write_file(path .. '/.meta/agent_rules.md', contents.AGENT_META_CONTENT)
      vim.notify('[Zettel] Workspace initialized successfully at:\n' .. path, vim.log.levels.INFO)
      vim.cmd('edit ' .. fn_fnameescape(path .. '/index.md'))
    end)
  end)
end

function M.new_card()
  vim.ui.input({ prompt = ' 󰎚 Card Title (Enter for Quick Note): ' }, function(title)
    if title == nil then return end
    schedule(function()
      local safe_input = vim.trim(title)
      local is_empty = (safe_input == '')
      local timestamp = tostring(os_date('%Y%m%d%H%M'))
      local filename_seed = is_empty and timestamp or title
      local final_title = is_empty and 'Untitled' or title
      local filepath = get_target_filepath(filename_seed, 'Cards', true)
      local lines = {
        '---',
        'title: ' .. final_title,
        'date: ' .. tostring(os.date('%Y-%m-%d %H:%M:%S')),
        'tags: []',
        '---',
        '',
        '# ' .. final_title,
        '',
        'Links: [[index]]',
        -- 'Tags Guide: [[example-tag]]',
      }
      createbuf_and_curpos(filepath, lines, { 7, 2 })
    end)
  end)
end

function M.new_inbox_note()
  local scenarios = {
    { name = '📝 Daily (日记/工作日志)', folder = 'Daily' },
    { name = '🤝 Meetings (会议记录)', folder = 'Meetings' },
    { name = '💡 Idea (灵感/随便写写)', folder = 'Idea' },
    { name = '✂️ Snippet (代码片段)', folder = 'Snippet' },
    { name = '📥 Root (直接扔进 Inbox 根目录)', folder = '' },
    { name = '📔 Projects (项目)', folder = 'Projects' },
    { name = '👀 People (关于人的)', folder = 'People' },
  }
  vim.ui.select(scenarios, {
    prompt = ' 📂 Select Scenario: ',
    format_item = function(item) return item.name end,
  }, function(choice)
    if not choice then return end
    local is_daily = (choice.folder == 'Daily')
    local default_title = is_daily and tostring(os.date('%Y-%m-%d')) or ''

    schedule(function()
      vim.ui.input({ prompt = ' 󰎚 Note Title: ', default = default_title }, function(title)
        if not title or vim.trim(title) == '' then return end
        schedule(function()
          local subfolder = choice.folder == '' and 'Inbox' or ('Inbox/' .. choice.folder)
          local filepath = get_target_filepath(title, subfolder, is_daily)
          if is_daily and fs_stat(filepath) then
            vim.cmd('edit ' .. fn_fnameescape(filepath))
            vim.notify('󰎚 Daily note already exists. Opened.', vim.log.levels.INFO)
            return
          end
          local lines = {
            '---',
            'title: ' .. title,
            'date: ' .. tostring(os.date('%Y-%m-%d %H:%M:%S')),
            'scenario: ' .. (choice.folder == '' and 'Inbox' or choice.folder),
            '---',
            '',
            '# ' .. title,
            '',
          }
          createbuf_and_curpos(filepath, lines, { 7, 2 })
        end)
      end)
    end)
  end)
end

function M.backlinks()
  local ok, snacks = pcall(require, 'snacks')
  if not ok then return end
  local current_file = fn.expand('%:t:r')
  if current_file == '' then
    vim.notify('No file to find backlinks for!', vim.log.levels.WARN)
    return
  end
  local search_pattern = '\\[\\[' .. current_file .. '\\]\\]'
  snacks.picker.grep({
    title = ' 🔗 Backlinks (' .. current_file .. ') ',
    prompt = ' 󰌹  ',
    search = search_pattern,
    regex = true,
  })
end

local auto_graph_setup = false
--- @param silent boolean?
function M.generate_graph(silent)
  local root = get_workspace_root()
  if fn_executable('rg') == 0 then
    if not silent then
      vim.notify('[Zettel] "rg" (ripgrep) is required for graph view!',
        vim.log.levels.ERROR)
    end
    return
  end

  if not auto_graph_setup then
    auto_graph_setup = true
    api.nvim_create_autocmd('BufWritePost', {
      group = api.nvim_create_augroup('ZettelAutoGraph', { clear = true }),
      pattern = '*.md',
      callback = function(args)
        local file_path = api.nvim_buf_get_name(args.buf)
        if file_path:find(root, 1, true) then
          M.generate_graph(true) -- Silent update!
        end
      end
    })
  end

  local cmd = {
    'rg', '-o', '\\[\\[([^\\]]+)\\]\\]',
    '--vimgrep', '--no-heading',
    '-g', '*.md', '-g', '!{.meta,Assets,.*}/*',
    root
  }

  system(cmd, { text = true }, function(obj)
    schedule(function()
      if obj.code ~= 0 and obj.code ~= 1 then
        if not silent then
          vim.notify('[Zettel] Graph gen failed: ' .. (obj.stderr or 'error'),
            vim.log.levels.ERROR)
        end
        return
      end

      local output = obj.stdout or ''
      local nodes_map = {}
      local edge_map = {}
      local nodes = {}
      local links = {}
      local node_cnt = 0
      local link_cnt = 0

      for line in string_gmatch(output, '[^\r\n]+') do
        local file, target = string_match(line, '^(.-):%d+:%d+:%[%[(.-)%]%]$')
        if file and target then
          local source = fn_fnamemodify(file, ':t:r')
          if not nodes_map[source] then
            nodes_map[source] = true
            node_cnt = node_cnt + 1
            nodes[node_cnt] = { name = source, id = source }
          end
          if not nodes_map[target] then
            nodes_map[target] = true
            node_cnt = node_cnt + 1
            nodes[node_cnt] = { name = target, id = target }
          end
          local edge_key = source .. '\0' .. target
          if not edge_map[edge_key] then
            edge_map[edge_key] = true
            link_cnt = link_cnt + 1
            links[link_cnt] = { source = source, target = target }
          end
        end
      end

      local ok, json_str = pcall(json_encode, { nodes = nodes, links = links })
      if not ok then return end
      local html = contents.GRAPH_TEMPLATE_HEAD .. json_str .. contents.GRAPH_TEMPLATE_TAIL
      local html_path = root .. '/.meta/graph.html'
      fs_open(html_path, 'w', 438, function(_, fd)
        if fd then
          fs_write(fd, html, -1, function()
            fs_close(fd)
            if silent then return end
            schedule(function()
              if vim.ui.open then
                vim.ui.open(html_path)
              else
                local utils = require('libs.utils')
                local open_cmd = utils.is_mac() and 'open' or
                  (utils.is_windows() and 'start' or 'xdg-open')
                os_execute(open_cmd .. ' ' .. fn_fnameescape(html_path))
              end
              vim.notify(
                '🌌 Zettel Graph generated! (' ..
                node_cnt ..
                ' nodes)\n⚡ Auto-update enabled: Hit F5 in browser after saving your notes!',
                vim.log.levels.INFO)
            end)
          end)
        else
          if not silent then
            schedule(function()
              vim.notify('[Zettel] Failed to open graph HTML for writing', vim.log.levels.ERROR)
            end)
          end
        end
      end)
    end)
  end)
end

return M
