-- [Colorful Menu]
return {
  'https://github.com/xzbdmw/colorful-menu.nvim',
  event = { 'InsertEnter', 'CmdlineEnter' },
  config = function()
    require('colorful-menu').setup({
      ls = {
        lua_ls = { arguments_hl = '@comment' },
        gopls = {
          align_type_to_right = true,
          add_colon_before_type = false,
          preserve_type_when_truncate = true,
        },
        ts_ls = { extra_info_hl = '@comment' },
        vtsls = { extra_info_hl = '@comment' },
        ['rust-analyzer'] = {
          extra_info_hl = '@comment',
          align_type_to_right = true,
          preserve_type_when_truncate = true,
        },
        clangd = {
          extra_info_hl = '@comment',
          align_type_to_right = true,
          import_dot_hl = '@comment',
          preserve_type_when_truncate = true,
        },
        zls = { align_type_to_right = true },
        roslyn = { extra_info_hl = '@comment' },
        dartls = { extra_info_hl = '@comment' },
        basedpyright = { extra_info_hl = '@comment' },
        pylsp = {
          extra_info_hl = '@comment',
          arguments_hl = '@comment',
        },
        fallback = true,
        fallback_extra_info_hl = '@comment',
      },
      fallback_highlight = '@variable',
      max_width = 60,
    })
  end
}
