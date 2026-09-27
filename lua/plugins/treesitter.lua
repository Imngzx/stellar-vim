local parsers = {
  'c', 'cpp', 'make', 'cmake', 'python', 'lua', 'vim', 'vimdoc', 'markdown', 'markdown_inline',
  'bash', 'json', 'yaml', 'toml', 'rust', 'zig', 'javascript', 'typescript', 'vue',
  'latex', 'html', 'regex', 'css', 'gitcommit', 'fish', 'kdl', 'powershell', 'luau', 'nix', 'just',
  'meson', 'scss', 'svelte', 'tsx', 'typst',
}

local function setup_compiler()
  if require('libs.utils').is_windows() then
    vim.env.CC = 'gcc'
    vim.env.CXX = 'g++'
  end
end

require('resonance').load({
  'https://github.com/nvim-treesitter/nvim-treesitter',
  version = 'main',
  build = function()
    setup_compiler()
    vim.schedule(function()
      local ok, ts = pcall(require, 'nvim-treesitter')
      if ok and ts.update then
        ts.update()()
      else
        pcall(function() vim.cmd('TSUpdate') end)
      end
    end)
  end,

  event = { 'BufReadPre', 'BufNewFile' },

  config = function()
    setup_compiler()
    local ts = require('nvim-treesitter')

    vim.schedule(function()
      ts.install(parsers, { summary = false })
    end)

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('TreesitterAttach', { clear = true }),
      callback = function(args)
        if vim.bo[args.buf].buftype ~= '' then return end
        if vim.b[args.buf].snacks_bigfile then return end

        local lang = vim.treesitter.language.get_lang(args.match)
        if lang then
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              local ok = pcall(vim.treesitter.start, args.buf, lang)
              if ok then
                vim.bo[args.buf].indentexpr = require('nvim-treesitter').indentexpr
              end
            end
          end)
        end
      end,
    })
  end
})
