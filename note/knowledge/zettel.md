# zettel — Zettelkasten Note-Taking

> **Purpose**: Create a Zettelkasten workspace and its notes (cards, inbox notes), find backlinks, and render a link graph.
> **Location**: `lua/custom/zettel/init.lua` (logic), `lua/custom/zettel/contents.lua` (file templates)
> **Loaded by**: `lua/plugins/core/snacks/keys.lua` (requires it for the snacks.nvim `keys` spec) and the `:ZettelInit` command in `lua/config/autocmds.lua`

---

## Workspace Root

Every function resolves the root with `vim.fs.root(current_buf, { '.marksman.toml', '.git', 'Makefile', '.jj' })`, falling back to cwd. Inside any git or Makefile project, notes and `.meta/graph.html` are created in that project's root.

## Public API

| Function | Description |
|----------|-------------|
| `M.init_workspace()` | Prompt for a path (default: workspace root, `~` expanded), create the directory tree, write any template files that don't exist yet, then open `index.md` |
| `M.new_card()` | Prompt for a title and create `Cards/<slug>.md` (no timestamp). An empty title uses `YYYYMMDDHHMM` as the filename and `Untitled` as the title |
| `M.new_inbox_note()` | Pick a scenario (Daily, Meetings, Idea, Snippet, Root, Projects, People), then a title, and create the note under `Inbox/<folder>/` |
| `M.backlinks()` | Snacks grep picker for `[[<current file stem>]]` |
| `M.generate_graph(silent?)` | Collect `[[links]]` with `rg`, write an ECharts graph to `<root>/.meta/graph.html` and open it (unless `silent`) |

### Filenames

The title is lowercased, whitespace becomes `-`, and characters outside `a-z0-9_.-` and CJK/kana/hangul are stripped. Non-daily inbox notes get a `YYYYMMDDHHMM-` prefix. Daily notes default to the title `YYYY-MM-DD`, use the exact name, and open the existing file if there is one.

New notes are unsaved buffers (`filetype=markdown`) with YAML frontmatter (`title`, `date`, plus `tags: []` for cards or `scenario:` for inbox notes). Cards also get a `Links: [[index]]` line.

### Workspace Layout (`init_workspace`)

Directories: `.meta/`, `Inbox/{Daily,Meetings,Idea,Snippet,Projects,People}/`, `Cards/Examples/`, `Assets/`.

Files written from `contents.lua`: `.marksman.toml`, `.markdownlint.json`, `.editorconfig`, `.gitignore`, `.rumdl.toml`, `.moxide.toml` (empty), `index.md`, `Cards/Examples/{example-card,example-tag,example-usage}.md`, `.meta/user.md`, `.meta/agent_rules.md`, `AGENTS.md`.

### Graph

- Requires `rg`. Skips `.meta/`, `Assets/`, and dot-directories. Nodes are file stems and link targets; duplicate edges are merged.
- The first call registers a `BufWritePost *.md` autocmd (augroup `ZettelAutoGraph`). It silently regenerates the graph when a saved file is under the root from that first call; reload the browser to see changes.
- The HTML loads ECharts 5.5.0 from the jsDelivr CDN, so viewing it needs network access.

---

## Keymaps & Commands

| Key / Command | Action |
|---------------|--------|
| `<leader>zn` | `new_card()` |
| `<leader>zi` | `new_inbox_note()` |
| `<leader>zI`, `:ZettelInit` | `init_workspace()` |
| `<leader>zb` | `backlinks()` |
| `<leader>zg` | `generate_graph()` |

## Gotchas

- `backlinks()` matches only the exact `[[stem]]`. Aliased or heading links (`[[stem|alias]]`, `[[stem#h]]`) are not found. The graph regex keeps the `|alias`/`#h` part in the target name.
- Template files are written synchronously (existing files are left alone), so `index.md` is on disk before `init_workspace()` opens it.
