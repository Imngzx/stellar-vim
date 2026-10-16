# coderunner.lua Configuration and Core Logic

## Configuration Switches

- `C_BUILD_TYPE`: 1=Release (GCC -O2), 2=Debug (Clang -g -fsanitize)
- `CPP_BUILD_TYPE`: 1=Release (G++ -O2), 2=Debug (Clang++ -g -fsanitize)

## OS Detection

- Detects Windows vs Unix systems for platform-specific configurations

## Core Functions

- `get_c_mode()` / `get_cpp_mode()`: Returns compiler flags based on build type
- `shellescape()`: Escapes values for shell commands
- `normalize_path()`: Standardizes path formatting
- `find_upward()`: Searches for files upward in directory tree
- `relative_path()`: Computes relative paths
- `find_cargo_bin_name()`: Locates Cargo bin name from file path
- `cargo_project_command()`: Builds command for Cargo projects
- `execute_cmd()`: Executes commands in terminal with error handling
- `build_run_command()`: Determines appropriate build/run command
- `build_project_command()`: Constructs project build command

## Key Mappings

- `<leader>rp` : Runs project via `M.run_project()`

## Terminal Management

- Manages terminal lifecycle with `active_term` handling and cleanup

## Project Detection

- Checks for Cargo.toml or Makefile to determine project type

```lua
-- Example build command construction
function M.build_run_command()
  local ft = vim.bo.filetype
  if ft == 'cpp' or ft == 'c' then
    return 'make && ./' .. vim.fn basil.setContentType(path)
  end
  -- ... other filetype handlers
end
```

This documentation captures the essential components of `coderunner.lua` to facilitate AI-assisted development in Neovim.
