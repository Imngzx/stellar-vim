---@type vim.lsp.Config

return {
  rumdl = {
    root_markers = { '.git', '.rumdl.toml', },
    filetypes = { 'markdown' },
    settings = {
      rumdl = {
        -- MD013 Line length
        -- MD033 Inline HTML
        -- MD034 Bare URL used
        -- MD040 Fenced code blocks should have a language specified
        -- MD041 First line in a file should be a top-level heading
        -- MD045 Images should have alternate text
        disableRules = { 'MD013', 'MD033', 'MD034', 'MD040', 'MD041', 'MD045' },
        settings = {
          enableLinting = true,
          -- MD060 Makes significant formatting changes to existing tables
          -- MD084 May trigger false positives in languages that use direction marks
          -- MD088 Whether ASCII or typographic punctuation is correct is a style choice
          -- MD089 CJK spacing
          extendEnable = { 'MD060', 'MD084', 'MD088', 'MD089' },
          exclude = {
            'node_modules',
            'build',
            'dist',
            '*.tmp.md',
          },
          MD025 = {
            front_matter_title = '',
            allow_document_sections = true,
          },
          MD073 = {
            enabled = true,
            min_level = 2,
            max_level = 4,
            enforce_order = true,
            indent = 2,
          },
          MD032 = { allowLazyContinuation = false },
          MD060 = { enabled = true, style = 'aligned' },
          MD076 = { allowLooseContinuation = true },
          MD088 = { enabled = true, allow = { 'U+201C', 'U+201D', 'U+2018', 'U+2019' } }
        }
      }
    }
  },

  markdown_oxide = {
    cmd = { 'markdown-oxide' },
    filetypes = { 'markdown' },
    root_markers = { '.moxide.toml', '.obsidian', '.git' },
    settings = {
      markdown_oxide = {
        -- Enable heading completions for [[wiki-links]]
        heading_completions = true,
        -- Use first heading as title for wiki-links
        title_headings = true,
        -- Show diagnostics for unresolved links
        unresolved_diagnostics = true,
        -- Enable semantic tokens for syntax highlighting
        semantic_tokens = true,
        -- Resolve tags/references in code blocks
        tags_in_codeblocks = false,
        references_in_codeblocks = false,
        -- Include .md extension in markdown links
        include_md_extension_md_link = false,
        -- Daily notes configuration
        dailynote = {
          format = '%Y-%m-%d',
          folder = 'daily',
        },
        -- New file creation folder
        new_file_folder_path = '',
        -- Daily notes folder (absolute path recommended)
        daily_notes_folder = '',
      }
    },
  }
}
