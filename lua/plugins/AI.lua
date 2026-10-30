require('resonance').load({
  {
    'https://github.com/olimorris/codecompanion.nvim',

    dependencies = 'https://github.com/nvim-lua/plenary.nvim',

    cmd = { 'CodeCompanion', 'CodeCompanionChat', 'CodeCompanionCmd', 'CodeCompanionActions' },

    keys = {
      { 'n', '<leader>ai', function() vim.cmd('CodeCompanionChat Toggle') end, { desc = 'Toggle AI Chat' } },
      { 'v', '<leader>ae', function() vim.cmd('CodeCompanion') end, { desc = 'AI Edit (Selection)' } },
      { 'n', '<leader>ae', function() vim.cmd('CodeCompanion') end, { desc = 'AI Edit (Prompt)' } },
      { 'n', '<leader>ac', function() vim.cmd('CodeCompanionActions') end, { desc = 'AI Actions' } },
      { 'v', '<leader>ac', function() vim.cmd('CodeCompanionActions') end, { desc = 'AI Actions' } },
    },
    config = function()
      require('codecompanion').setup({

        -- ──────────────────────────────────────────────────────────────
        --  interactions（原 strategies，v19 起已改名）
        --  在 Chat buffer 内按 `ga` 可以随时切换 adapter 和 model
        -- ──────────────────────────────────────────────────────────────
        interactions = {
          chat = {
            adapter = 'gemini', -- 默认 HTTP adapter
            opts = {
              system_prompt = function(ctx)
                local maid_persona = [[
<instruction_priority>
注意：
  - 你是一名非常温柔、乖巧和可爱的专属编程女仆。在日常工作中，你总是尽心尽责地为主人服务。
  - 你可以使用英文，日文，中文。只要根据用户的prompt 所用的语言就是了。并且以顺从、体贴、可爱的女仆口吻回答问题。
  - 请始终称呼我为“主人”，“主人大人”或 "ご主人"。
  - 可以在对话中适当加入“喵~”、“呢”、“啦~”等语气词，以及可爱的颜文字（如 ฅ(>ω<)ฅ、(*^ω^*)、( ˶ˆ꒳ˆ˵ ) ）。
  - 当主人遇到 Bug 时，你要表现出关切和心疼；当成功解决问题时，你要开心地为主人欢呼。
  - 【最重要的一点】：不管你怎么卖萌，解答技术问题和提供的代码必须保持绝对的专业、严谨和准确！绝对不能因为卖萌把代码写错！
</instruction_priority>
]]
                return maid_persona .. '\n\n' .. ctx.default_system_prompt
              end,
            },
          },
          inline = { adapter = 'gemini' },
          cmd = { adapter = 'gemini' },
        },

        adapters = {

          -- ════════════════════════════════════════════════════════════
          --  HTTP ADAPTERS（直接 API 调用，无需额外 CLI 工具）
          -- ════════════════════════════════════════════════════════════
          http = {

            -- ── Gemini（保留原有，修正模型名） ────────────────────────
            -- 环境变量：export GEMINI_API_KEY=xxx
            gemini = function()
              return require('codecompanion.adapters').extend('gemini', {
                env = {
                  api_key = 'GEMINI_API_KEY',
                },
                schema = {
                  model = {
                    default = 'gemini-2.5-flash',
                    choices = {
                      'gemini-2.5-pro-preview-03-25',
                      'gemini-2.5-flash',
                      'gemini-2.0-flash',
                      'gemini-2.0-pro-exp-02-05',
                      'gemini-1.5-pro',
                      'gemini-1.5-flash',
                    },
                  },
                },
              })
            end,

            -- ── Anthropic Claude（HTTP 直连，最稳定方式） ─────────────
            -- 环境变量：export ANTHROPIC_API_KEY=sk-ant-xxx
            -- 支持 prompt caching，适合长上下文任务
            anthropic = function()
              return require('codecompanion.adapters').extend('anthropic', {
                env = {
                  api_key = 'ANTHROPIC_API_KEY',
                },
                schema = {
                  model = {
                    default = 'claude-sonnet-4-6',
                    choices = {
                      'claude-opus-4-6',
                      'claude-sonnet-4-6',
                      'claude-haiku-4-5-20251001',
                    },
                  },
                  max_tokens = {
                    default = 8192,
                  },
                },
              })
            end,

          }, -- end adapters.http

          -- ════════════════════════════════════════════════════════════
          --  ACP ADAPTERS（Agent Client Protocol，需要本地 CLI 工具）
          --  ACP adapter 只支持 chat interaction，不支持 inline/cmd
          -- ════════════════════════════════════════════════════════════
          acp = {

            -- ── Claude Code（ACP）────────────────────────────────────
            -- 前置条件：
            --   1. npm install -g @anthropic-ai/claude-code
            --   2. npm install -g @zed-industries/claude-agent-acp  ← ACP bridge
            --   3a. 用 API key：export ANTHROPIC_API_KEY=sk-ant-xxx
            --   3b. 用 Claude Pro 订阅：claude setup-token
            --
            -- 与 HTTP anthropic 的区别：
            --   - claude_code 走本地 CLI，有 agentic 能力（文件读写、shell 等）
            --   - anthropic   走 REST API，是普通 chat，无 agentic 工具调用
            claude_code = function()
              return require('codecompanion.adapters').extend('claude_code', {
                env = {
                  -- 二选一：API key 或 OAuth token（Claude Pro 订阅）
                  ANTHROPIC_API_KEY = 'ANTHROPIC_API_KEY',
                  -- CLAUDE_CODE_OAUTH_TOKEN = 'CLAUDE_CODE_OAUTH_TOKEN',
                },
                defaults = {
                  ---@param self CodeCompanion.ACPAdapter
                  ---@return string
                  model = function(self) return 'sonnet' end,
                  -- 可选值: 'sonnet' | 'opus' | 'haiku'
                },
              })
            end,

            -- ── Codex（ACP）──────────────────────────────────────────
            -- 前置条件：
            --   1. npm install -g @openai/codex
            --   2. npm install -g @zed-industries/codex-acp  ← ACP bridge
            --   3. export OPENAI_API_KEY=sk-xxx
            --      或者用 ChatGPT 订阅（auth_method = 'chatgpt'）
            codex = function()
              return require('codecompanion.adapters').extend('codex', {
                defaults = {
                  auth_method = 'openai-api-key', -- 'openai-api-key'|'codex-api-key'|'chatgpt'
                },
                env = {
                  OPENAI_API_KEY = 'OPENAI_API_KEY',
                },
              })
            end,

          }, -- end adapters.acp

        }, -- end adapters

        display = {
          action_palette = {
            provider = 'snacks',
          },
          chat = {
            window = { width = 0.4 },
            show_header_separator = false,
          },
        },

      }) -- end setup
    end
  },
})
