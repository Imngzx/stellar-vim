require('resonance').load({
  'https://github.com/kevinhwang91/nvim-ufo',
  dependencies = 'https://github.com/kevinhwang91/promise-async',
  event = { 'BufReadPost', 'BufNewFile' },
  keys = {
    { 'n', 'zR', function() require('ufo').openAllFolds() end, { desc = 'Open all folds' } },
    { 'n', 'zM', function() require('ufo').closeAllFolds() end, { desc = 'Close all folds' } },
    { 'n', 'zr', function() require('ufo').openFoldsExceptKinds() end, { desc = 'Fold less' } },
    { 'n', 'zm', function() require('ufo').closeFoldsWith() end, { desc = 'Fold more' } },
    { 'n', 'zp', function() require('ufo').peekFoldedLinesUnderCursor() end, { desc = 'Peek fold' } },
  },
  config = function()
    local function set_fold_hl()
      vim.api.nvim_set_hl(0, 'FoldText', {
        fg = require('custom.color-list').colors.toxic_matcha.hex,
        italic = true,
        bold = true
      })
    end

    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('UfoFoldColor', { clear = true }),
      callback = set_fold_hl,
    })
    set_fold_hl()

    local strwidth = vim.api.nvim_strwidth

    local handler = function(virtText, lnum, endLnum, width, truncate)
      local newVirtText = {}
      local new_idx = 1

      local foldedLines = endLnum - lnum
      local suffix = ('  ⋯  ↙ [%d lines folded]'):format(foldedLines)
      local sufWidth = strwidth(suffix)
      local targetWidth = width - sufWidth
      local curWidth = 0

      for i = 1, #virtText do
        local chunk = virtText[i]
        local chunkText = chunk[1]
        local chunkWidth = strwidth(chunkText)

        if targetWidth > curWidth + chunkWidth then
          newVirtText[new_idx] = chunk
          new_idx = new_idx + 1
        else
          chunkText = truncate(chunkText, targetWidth - curWidth)
          local hlGroup = chunk[2]
          newVirtText[new_idx] = { chunkText, hlGroup }
          new_idx = new_idx + 1

          chunkWidth = strwidth(chunkText)
          if curWidth + chunkWidth < targetWidth then
            suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
          end
          break
        end
        curWidth = curWidth + chunkWidth
      end

      newVirtText[new_idx] = { suffix, 'FoldText' }
      return newVirtText
    end

    require('ufo').setup({
      open_fold_hl_timeout = 150,
      fold_virt_text_handler = handler,

      provider_selector = function(bufnr, filetype, buftype)
        -- Skip folding for big files (snacks.nvim)
        if vim.b[bufnr].snacks_bigfile then
          return ''
        end

        local function handleFallbackException(bnr, err, providerName)
          if type(err) == 'string' and err:match 'UfoFallbackException' then
            return require('ufo').getFolds(bnr, providerName)
          else
            return require('promise').reject(err)
          end
        end

        -- only use indent until a file is opened
        return (filetype == '' or buftype == 'nofile') and 'indent'
          or function(bnr)
            return require('ufo')
              .getFolds(bnr, 'lsp')
              :catch(function(err)
                return handleFallbackException(bnr, err, 'treesitter')
              end)
              :catch(function(err)
                return handleFallbackException(bnr, err, 'indent')
              end)
          end
      end,

      preview = {
        win_config = {
          border = 'rounded',
          winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder',
          winblend = 0
        },
        mappings = {
          scrollU = '<C-u>',
          scrollD = '<C-d>',
          jumpTop = '[',
          jumpBot = ']'
        }
      }
    })
  end
})