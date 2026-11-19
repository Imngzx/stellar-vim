local progress = vim.defaulttable()
vim.api.nvim_create_autocmd('LspProgress', {
  group = vim.api.nvim_create_augroup('SnacksLspProgress', { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local value = ev.data.params.value
    if not client or type(value) ~= 'table' then return end

    local p = progress[client.id]

    for i = 1, #p do
      local v = p[i]
      if v.token == ev.data.params.token then
        p[i] = {
          token = ev.data.params.token,
          msg = ('[%3d%%] %s%s'):format(
            value.kind == 'end' and 100 or value.percentage or 100,
            value.title or '',
            value.message and (' %s'):format(value.message) or ''
          ),
          done = value.kind == 'end',
        }
        break
      end
    end

    if value.kind == 'begin' then
      table.insert(p, {
        token = ev.data.params.token,
        msg = ('[%3d%%] %s%s'):format(
          value.percentage or 0,
          value.title or '',
          value.message and (' %s'):format(value.message) or ''
        ),
        done = false,
      })
    end

    local msg = {}
    progress[client.id] = vim.tbl_filter(function(v)
      return table.insert(msg, v.msg) or not v.done
    end, p)

    local spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

    vim.notify(table.concat(msg, '\n'), vim.log.levels.INFO, {
      id = 'lsp_progress_' .. client.id,
      title = client.name,
      opts = function(notif)
        notif.icon = #progress[client.id] == 0 and ' '
          or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
      end,
    })
  end,
})
