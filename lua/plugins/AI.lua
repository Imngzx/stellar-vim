return {
  {
    'https://github.com/olimorris/codecompanion.nvim',

    dependencies = {
      'https://github.com/nvim-lua/plenary.nvim',
      'https://github.com/nvim-treesitter/nvim-treesitter',
    },

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

        interactions = {
          chat = {
            adapter = 'gemini',
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

          http = {

            gemini = function()
              return require('codecompanion.adapters').extend('gemini', {
                env = {
                  api_key = 'GEMINI_API_KEY',
                },
                schema = {
                  model = {
                    default = 'gemini-3.5-flash',
                    choices = {
                      'gemini-3.1-pro-preview',
                      'gemini-3.5-flash',
                      'gemini-3.1-flash-lite-preview',
                      'gemini-3-flash-preview',
                      'gemini-2.5-pro',
                      'gemini-2.5-flash',
                      'gemini-2.5-flash-lite',
                    },
                  },
                },
              })
            end,

            anthropic = function()
              return require('codecompanion.adapters').extend('anthropic', {
                env = {
                  api_key = 'ANTHROPIC_API_KEY',
                },
                schema = {
                  model = {
                    default = 'claude-sonnet-5',
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

          },

          acp = {

            claude_code = function()
              return require('codecompanion.adapters').extend('claude_code', {
                env = {
                  CLAUDE_CODE_OAUTH_TOKEN = 'CLAUDE_CODE_OAUTH_TOKEN',
                },
                defaults = {
                  session_config_options = {
                    model = function(self) return 'sonnet' end,
                  },
                },
              })
            end,

            codex = function()
              return require('codecompanion.adapters').extend('codex', {
                defaults = {
                  auth_method = 'api-key',
                },
                env = {
                  OPENAI_API_KEY = 'OPENAI_API_KEY',
                },
              })
            end,

          },

        },

        display = {
          action_palette = {
            provider = 'snacks',
          },
          chat = {
            window = { width = 0.4 },
          },
        },

      })
    end
  },
}
