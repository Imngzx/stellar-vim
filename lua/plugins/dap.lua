-- [Debugger] Nvim-DAP
require('resonance').load({
  plugin = {
    'https://github.com/mfussenegger/nvim-dap',
    'https://github.com/rcarriga/nvim-dap-ui',
    'https://github.com/theHamsta/nvim-dap-virtual-text',
    'https://github.com/mfussenegger/nvim-dap-python',
    'https://github.com/leoluz/nvim-dap-go',
  },
  dependencies = { 'https://github.com/nvim-neotest/nvim-nio' },
  keys = {
    -- 📺 DAP UI
    { 'n', '<leader>du', function() require('dapui').toggle() end, { desc = 'Toggle Dap UI' } },

    -- 🐍 DAP Python
    { 'n', '<localleader>dT', function() require('dap-python').test_method() end, { desc = 'Debug Method (Python)' } },
    { 'n', '<localleader>dC', function() require('dap-python').test_class() end, { desc = 'Debug Class (Python)' } },

    -- ⚙️ DAP Core
    { 'n', '<leader>dB', function()
      require('dap').set_breakpoint(vim.fn.input(
        'Breakpoint condition: '))
    end, { desc = 'Breakpoint condition' } },
    { 'n', '<leader>db', function() require('dap').toggle_breakpoint() end, { desc = 'Toggle breakpoint' } },
    { 'n', '<leader>dc', function() require('dap').continue() end, { desc = 'Continue' } },
    { 'n', '<leader>dC', function() require('dap').run_to_cursor() end, { desc = 'Run to cursor' } },
    { 'n', '<leader>dg', function() require('dap').goto_() end, { desc = 'Go to line (no execute)' } },
    { 'n', '<leader>di', function() require('dap').step_into() end, { desc = 'Step into' } },
    { 'n', '<leader>dj', function() require('dap').down() end, { desc = 'Down' } },
    { 'n', '<leader>dk', function() require('dap').up() end, { desc = 'Up' } },
    { 'n', '<leader>dl', function() require('dap').run_last() end, { desc = 'Run last' } },
    { 'n', '<leader>do', function() require('dap').step_out() end, { desc = 'Step out' } },
    { 'n', '<leader>dO', function() require('dap').step_over() end, { desc = 'Step over' } },
    { 'n', '<leader>dp', function() require('dap').pause() end, { desc = 'Pause' } },
    { 'n', '<leader>dr', function() require('dap').repl.toggle() end, { desc = 'Toggle REPL' } },
    { 'n', '<leader>ds', function() require('dap').session() end, { desc = 'Session' } },
    { 'n', '<leader>dt', function() require('dap').terminate() end, { desc = 'Terminate' } },
    { 'n', '<leader>dw', function() require('dap.ui.widgets').hover() end, { desc = 'Widgets' } },
  },
  config = function()
    -- 🎨 custom dap icons
    vim.fn.sign_define('DapBreakpoint',
      { text = ' ', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition',
      { text = ' ', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapLogPoint',
      { text = ' ', texthl = 'DapLogPoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapStopped',
      { text = ' ', texthl = 'DapBreakpointStopped', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointRejected',
      { text = ' ', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })

    -- 🔌 starts dependent plugins
    local dapui = require('dapui')
    dapui.setup()
    require('nvim-dap-virtual-text').setup({})
    require('dap-python').setup('python3', {})
    require('dap-go').setup({})

    local dap = require('dap')

    dap.listeners.after.event_initialized['dapui-auto-open'] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated['dapui-auto-close'] = function() dapui.close() end
    dap.listeners.before.event_exited['dapui-auto-close'] = function() dapui.close() end

    local mason_bin = vim.fn.stdpath('data') .. '/mason/bin/'
    -- windows compability
    local codelldb_cmd = require('libs.utils').is_windows() and mason_bin .. 'codelldb.cmd' or
      mason_bin .. 'codelldb'

    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        -- 👇 修复：使用 Mason 里的绝对路径
        command = codelldb_cmd,
        args = { '--port', '${port}' },
      },
    }

    dap.configurations.zig = {
      {
        type = 'codelldb',
        request = 'launch',
        name = 'Launch Zig',
        program = function()
          return vim.fn.input('Path to executable: ', vim.uv.cwd() .. '/zig-out/bin/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = true,
        args = {},
      },
    }

    dap.configurations.cpp = {
      {
        name = 'Launch file',
        type = 'codelldb',
        request = 'launch',
        program = function()
          -- 按下继续后，会要求你输入编译好的可执行文件路径 (例如: ./out/main)
          return vim.fn.input('Path to executable: ', vim.uv.cwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},
      },
    }

    dap.configurations.c = dap.configurations.cpp
    dap.configurations.rust = dap.configurations.cpp
    -- Go uses nvim-dap-go adapter (configured via dap-go.setup)
  end
})
