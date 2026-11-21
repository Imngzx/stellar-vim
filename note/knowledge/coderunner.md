# coderunner.lua — Build & Run Code with Project Detection

> **Purpose**: Compile and run the current file, or the surrounding project, in a floating Snacks terminal.
> **Location**: `lua/custom/coderunner.lua`
> **Loaded**: `safe_setup('custom.coderunner', ...)` inside the `User VeryLazy` block of `lua/config/resonance.lua`; keymaps are set by `M.setup()`.

---

## Public API

| Function | Description |
|----------|-------------|
| `M.build_run_command()` | Returns the shell command for the current buffer's filetype (or `nil` + warning if no runner / unnamed buffer). For `rust`, prefers a `cargo run` command when a `Cargo.toml` is found upward. |
| `M.run()` | `build_run_command()` then execute. |
| `M.build_project_command()` | Returns a project command (see table below) or `nil` + warning. |
| `M.run_project()` | `build_project_command()` then execute. |
| `M.close()` | Closes the active runner terminal. |
| `M.setup()` | Registers keymaps. |

Execution (`execute_cmd`): `silent! write` the current buffer, close any previous runner, open `Snacks.terminal(cmd .. pause_cmd)` in an 80%×80% rounded float titled ` Code Runner `, enter insert mode, and map `<Esc><Esc>` (terminal mode, buffer-local) to leave terminal mode. The pause suffix keeps the window open after the program exits (`read` prompt on Unix, `pause` on Windows).

---

## Keymaps (normal mode)

| Key | Action |
|-----|--------|
| `<F5>` / `<leader>rc` | `M.run` — "Save and Run Code" |
| `<C-F5>` / `<leader>rf` | `M.run` — "Save and Run File" (identical to the above) |
| `<S-F5>` / `<leader>rx` | `M.close` — "Stop / Close Runner" |
| `<leader>rp` | `M.run_project` — "Run Project" |

---

## Configuration (`vim.g.coderunner`)

```lua
vim.g.coderunner = {
  c_build_type = 2,       -- 1 = Release (gcc -O2), 2 = Debug (clang -g -fsanitize=address,undefined); both -std=c2y
  cpp_build_type = 2,     -- 1 = Release (g++ -O2), 2 = Debug (clang++ ... sanitizers); both -std=c++26
  c_extra_flags = '',     -- appended after the opt/sanitizer flags (a separating space is added)
  cpp_extra_flags = '',
  project_commands = {},  -- per-filetype overrides of the single-file command table, e.g. { go = { 'go run $fileName' } }
}
```

- Read once when the module is first required (during `VeryLazy`); set it before then. Changes later have no effect until restart.
- Extra flags are concatenated with no separator — include a leading space (`' -DDEBUG'`).
- `build_type` and extra flags only affect Unix; Windows uses fixed MSVC `cl` commands.
- Despite its name, `project_commands` overrides `build_run_command()` per filetype; it does not affect `build_project_command()`.

---

## Single-file commands

Templates are lists joined with spaces; `$dir`, `$fileName`, `$fileNameWithoutExt` are substituted (shell-escaped).

| Filetype | Unix | Windows |
|----------|------|---------|
| `c` / `cpp` | build into `$dir/out/` then run (see config) | `cl ... /Fe:<name>.exe` then run |
| `python` | `python3 -u` | `python -u` |
| `java` | `javac` + `java` | `javac` + `java` |
| `rust` | `rustc` + run (fallback when no Cargo project) | `rustc` + run `.exe` |
| `typescript` | `deno run` | `deno run` |
| `zig` | `cd $dir && zig build run` | same |
| `go` | `go run $fileName` | same |

---

## Project detection (`build_project_command`)

Checked in order:

| Condition | Command |
|-----------|---------|
| `Cargo.toml` found upward from the buffer | `cd <root> && cargo run`, with `--bin <name>` when the current Rust file matches a `[[bin]]` `path`, `src/bin/<name>.rs`, `src/bin/<name>/main.rs`, or `src/main.rs` (uses `[package].name`) |
| `Makefile` | `cd <dir> && make` |
| `build.zig` | `cd <dir> && zig build run` |
| `package.json` | `cd <dir> && npm start` |
| `go.mod` | `cd <dir> && go run .` |

All are searched upward from the buffer's directory (cwd for unnamed buffers). For the non-Cargo files, `<dir>` is
the nearest directory holding any of them; if it holds several, the order above decides.

---

## Gotchas

- Parsed `Cargo.toml` contents are cached per path for the session; edits to `Cargo.toml` aren't seen until restart.
- Cargo parsing is line-based pattern matching, not a TOML parser.
