local H = {}

-- calls the second init in this config
local lsp_manager = require('lsp.init')
lsp_manager.setup()

H.conform = {
  python = function(bufnr)
    if require('conform').get_formatter_info('ruff_format', bufnr).available then
      return { 'ruff_format' }
    else
      return { 'isort', 'black' }
    end
  end,
  javascript = { 'prettierd', 'prettier', stop_after_first = true },
  html = { 'prettierd', 'prettier', stop_after_first = true },
  css = { 'prettierd', 'prettier', stop_after_first = true },
  rust = { 'rustfmt' },
  c = { 'clang_format' },
  cpp = { 'clang_format' },
  sh = { 'shfmt' },
  bash = { 'shfmt' },
  toml = { 'taplo' },
  cmake = { 'cmake_format' },
  json = { 'jq' },
  zig = { 'zigfmt' },
  markdown = { 'rumdl' }
}

vim.g.markdown_fenced_languages = {
  'sh', 'bash=sh', 'python', 'py=python', 'javascript', 'js=javascript',
  'typescript', 'ts=typescript', 'html', 'css', 'json', 'lua', 'vim',
}

-- [Dependencies] Mason auto install once you open the Mason panel
require('resonance').load({
  {
    'https://github.com/mason-org/mason.nvim',
    cmd = { 'Mason', 'MasonInstall', 'MasonUninstall', 'MasonLog', 'MasonUpdate' },
    keys = {
      { 'n', '<leader>pm', function()
        vim.cmd('Mason')
        local registry = require('mason-registry')
        registry.refresh(function()
          local tools = lsp_manager.mason_tools
          for i = 1, #tools do
            local pkg_name = tools[i]
            local ok, pkg = pcall(registry.get_package, pkg_name)
            if ok and not pkg:is_installed() then
              vim.schedule(function()
                pkg:install()
                vim.notify('[Mason] Auto installing ' .. pkg_name, vim.log.levels.INFO)
              end)
            end
          end
        end)
      end, { desc = '[Panel] Mason' } }
    },
    setup = function()
      require('mason').setup({
        ui = { icons = { package_installed = '✓', package_pending = '➜', package_uninstalled = '✗' } },
      })
    end,
  },

  {
    'https://github.com/neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    setup = function()
      -- using the lsp or tools that listed inside the init that located inside "lsp" directory
      vim.lsp.enable(lsp_manager.enabled_servers)
    end
  },

  {
    'https://github.com/stevearc/conform.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    keys = {
      { 'n', '<leader>cf', function()
        require('conform').format({ async = true, lsp_format = 'fallback' })
      end, { desc = 'Format file' } }
    },
    setup = function()
      require('conform').setup({
        formatters_by_ft = H.conform,
        format_on_save = {
          timeout_ms = 800,
          lsp_format = 'fallback',
        },
      })
    end
  },

  {
    'https://github.com/mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    setup = function()
      local lint = require('lint')

      lint.linters_by_ft = {
        html = { 'htmlhint' },
        cmake = { 'cmakelint' },
      }

      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = vim.api.nvim_create_augroup('DIY_Linting', { clear = true }),
        callback = function()
          vim.schedule(function()
            lint.try_lint()
          end)
        end,
      })
    end
  },

  {
    'https://github.com/folke/lazydev.nvim',
    ft = 'lua',
    setup = function()
      -- finds types.yazi
      local utils = require('libs.utils')

      -- Yazi
      local homedir = vim.uv.os_homedir()
      local yazi_path = utils.is_windows()
        and (homedir .. '~/AppData/Roaming/yazi/config/plugins/types.yazi')
        or (homedir .. '~/.config/yazi/plugins/types.yazi')

      -- Hypr
      local hyprland_stubs = '/usr/share/hypr/stubs'

      require('lazydev').setup({
        library = {
          'nvim-lspconfig',
          vim.fn.stdpath('data') .. '/site/pack/core/opt/*',
          vim.fn.stdpath('config') .. '/lua',
          {
            path = yazi_path,
            words = { 'ya', 'cx' }
          },
          {
            path = hyprland_stubs,
            words = { 'hl', }
          }
        },
      })
    end
  },

  {
    plugin = {
      { src = 'https://github.com/Saghen/blink.cmp', version = vim.version.range('1') },
    },
    dependencies = {
      'https://github.com/rafamadriz/friendly-snippets',
      'https://github.com/huijiro/blink-cmp-supermaven',
    },
    event = { 'InsertEnter', 'CmdlineEnter' },
    setup = function()
      require('blink.cmp').setup({

        enabled = function()
          local bo = vim.bo
          if bo.buftype == 'prompt' or bo.filetype == 'snacks_picker_input' then
            return false
          end

          -- 2. only detect if you're in the "comment state" during insert mode
          local mode = vim.fn.mode
          if mode():sub(1, 1) == 'i' then
            local cursor = vim.api.nvim_win_get_cursor(0)
            local row, col = cursor[1], cursor[2]

            local ok, node = pcall(vim.treesitter.get_node, {
              bufnr = 0,
              pos = { row - 1, math.max(0, col - 1) },
            })
            if ok and node and node.type and node:type():find('comment') then
              return false
            end
          end

          return true
        end,

        keymap = { preset = 'enter' },
        appearance = { nerd_font_variant = 'mono' },

        signature = {
          window = {
            border = { 'rounded' },
          },
        },

        completion = {
          ghost_text = {
            enabled = true,
          },
          documentation = {
            auto_show = true,
            window = {
              border = 'rounded',
              winhighlight =
              'Normal:Normal,FloatBorder:FloatBorder,CursorLine:BlinkCmpDocCursorLine,Search:None',
            }
          },
          menu = {
            winhighlight =
            'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None',
            scrollbar = true,
            auto_show_delay_ms = 200,
            border = 'rounded',
            draw = {
              align_to = 'cursor',
              columns = { { 'kind_icon' }, { 'label', gap = 1 }, { 'menu', gap = 1 } },
              components = {
                label = {
                  text = function(ctx)
                    return require('colorful-menu').blink_components_text(ctx)
                  end,
                  highlight = function(ctx)
                    return require('colorful-menu').blink_components_highlight(ctx)
                  end,
                },
                menu = {
                  text = function(ctx)
                    local menu_labels = {
                      lsp = '[LSP]',
                      buffer = '[Buffer]',
                      snippets = '[LuaSnip]',
                      path = '[Path]',
                      lazydev = '[LazyDev]',
                      telegram = '[Telegram]',
                      supermaven = '[Supermaven]',
                    }
                    return menu_labels[ctx.source_name] or ('[' .. ctx.source_name .. ']')
                  end,
                  highlight = 'Comment',
                },
              },
            },
          },
        },

        cmdline = {
          enabled = true,
          keymap = {
            preset = 'enter',
            ['<C-y>'] = { 'select_and_accept' },
          },
          completion = {
            list = { selection = { preselect = false } },
            menu = {
              auto_show = true,
            },
            ghost_text = {
              enabled = true,
            },
          },
        },

        sources = {
          default = function()
            if vim.bo.filetype == 'lua' then
              return { 'lazydev', 'lsp', 'supermaven', 'path', 'snippets', 'buffer' }
            end
            if vim.bo.filetype == 'telegram' then
              return { 'telegram', 'lsp', 'supermaven', 'snippets', 'path' }
            end
            return { 'lsp', 'supermaven', 'path', 'snippets', 'buffer' }
          end,
          providers = {
            lazydev = {
              name = 'LazyDev',
              module = 'lazydev.integrations.blink',
              score_offset = 100,
            },
            snippets = {
              opts = {
                friendly_snippets = true,
              }
            },
            telegram = {
              module = 'telegram.blink'
            },
            supermaven = {
              name = 'Supermaven',
              module = 'blink-cmp-supermaven',
              async = true,
            },
          },
        },

        fuzzy = { implementation = 'prefer_rust_with_warning' },
      })
    end
  },

  -- [Diagnostic] Load after LSP attaches
  -- https://github.com/rachartier/tiny-inline-diagnostic.nvim/issues/112#issuecomment-2784644922
  {
    'https://github.com/rachartier/tiny-inline-diagnostic.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    setup = function()
      require('tiny-inline-diagnostic').setup({
        preset = 'modern',
        signs = { diag = '  ' },
        transparent_cursorline = true,
        options = {
          virt_texts = {
            priority = 2048,
          },
          show_source = {
            enabled = true,
          },
        },
      })
      vim.diagnostic.config({
        virtual_text = false, --leave this with false when you using this plugin
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = 'rounded',
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = I.lsp.error,
            [vim.diagnostic.severity.WARN] = I.lsp.warn,
            [vim.diagnostic.severity.HINT] = I.lsp.hint,
            [vim.diagnostic.severity.INFO] = I.lsp.info,
          },
        },
      })

      -- Keymap
      local diagnostic_goto = function(next, severity)
        return function()
          vim.diagnostic.jump({
            count = (next and 1 or -1) * vim.v.count1,
            severity = severity and vim.diagnostic.severity[severity] or nil,
            on_jump = function()
              vim.diagnostic.open_float()
            end,
          })
        end
      end
      vim.keymap.set('n', '<leader>cl', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
      vim.keymap.set('n', ']d', diagnostic_goto(true), { desc = 'Next Diagnostic' })
      vim.keymap.set('n', '[d', diagnostic_goto(false), { desc = 'Prev Diagnostic' })
      vim.keymap.set('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Next Error' })
      vim.keymap.set('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Prev Error' })
      vim.keymap.set('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Next Warning' })
      vim.keymap.set('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Prev Warning' })
    end
  }
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('LspKepmap', {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(
        not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
        { bufnr = ev.buf }
      )
    end
    -- LSP keymaps
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buf = ev.buf, desc = 'LSP hover' })
    vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, { buf = ev.buf, desc = 'Rename symbol' })
    vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action,
      { buf = ev.buf, desc = 'Code action' })
    vim.keymap.set('i', '<c-k>', vim.lsp.buf.signature_help,
      { buf = ev.buf, desc = 'Signature help' })
    vim.keymap.set('n', '<leader>pl', '<cmd>checkhealth vim.lsp<cr>', { desc = '[Panel] Lsp info' })
  end,
})
