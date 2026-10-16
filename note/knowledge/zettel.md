# zettel.lua Documentation

## Overview

Manages Zettelkasten-style note-taking with advanced Neovim integration.

## Core Dependencies

- Uses Lua's `vim` API and `uv` library for filesystem operations
- Leverages `snacks` for backlink functionality

## Key Components

### 1. File Operations

- `get_workspace_root()`: Detects project root using `.marksman.toml`, `.git`, or `Makefile`
- `createbuf_and_curpos()`: Creates buffer and sets cursor position
- `get_target_filepath()`: Generates target file path for notes

### 2. Note Management

- `M.new_card()`: Creates new note with title input
- `M.new_inbox_note()`: Quick capture for inbox notes
- `M.backlinks()`: Displays network of connected notes

### 3. Graph Visualization

- `M.generate_graph()`: Creates visual graph of note connections
- Uses HTML templates (`GRAPH_TEMPLATE_HEAD`, `GRAPH_TEMPLATE_TAIL`)

### 4. Utilities

- File system helpers (`normalize_path`, `find_upward`)
- String manipulation functions (`string_match`, `string_gsub`)
- OS execution utilities (`os.execute`, `vim.system`)

## Templates

Predefined content templates:

- `TOML_CONTENT`: Sample configuration
- `INDEX_CONTENT`: Index structure
- `EXAMPLE_CARD_CONTENT`: Note template
- `EDITORCONFIG`: Editor configuration

## Key Mappings

```lua
-- Example note creation workflow
vim.ui.input({ prompt = ' 󰎚 Card Title (Enter for Quick Note): ' }, function(title)
  if title == '' then
    M.new_inbox_note()
  else
    M.new_card(title)
  end
end)
```

This documentation provides a structural overview of zettel.lua to facilitate AI-assisted development in Neovim.
