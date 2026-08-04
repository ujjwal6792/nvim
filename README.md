# Neovim config

Native Neovim 0.12 config using `vim.pack`, built-in LSP configuration, Conform
formatting, Blink completion, and a small set of local UI/window helpers.

## Layout

- `init.lua` loads the config entrypoints.
- `lua/configs/pack.lua` declares plugins for `vim.pack`.
- `lua/configs/highlights.lua` holds theme overrides and UI highlights.
- `lua/configs/lspconfig.lua` defines native LSP servers.
- `lua/configs/conform.lua` keeps formatting repo-aware.
- `lua/configs/buffers.lua`, `tabline.lua`, `term.lua`, and `highlights.lua`
  hold local window, tabline, terminal, and theme behavior.
- `lua/notes/init.lua` is the local notes helper.
- `lua/goals-nvim/` is a read-only explorer for the repository-local planning
  workflow.

## Requirements

- Neovim 0.12.x
- Git
- ImageMagick for image rendering

Plugin revisions are tracked in `nvim-pack-lock.json`.

## Goals Explorer

Use `<leader>tt` or `:Goals` from any buffer under a project containing
`resources/planning/GOALS.md`. The explorer locates the nearest project,
launches a Ratatui terminal dashboard through Snacks. It includes Goals and
Wayfinding tabs, goal tasks, lifecycle artifacts, categorized assets/resources,
and evidence-labeled Wayfinder relationships.

`1`/`2` or `Tab` switch tabs, `j`/`k` navigate, `Enter`/`Space` collapse nodes,
`r` refreshes, and `q` closes. Click list rows to select them. Press `Enter`
twice on a file or ticket to edit its source in Neovim; closing that buffer
returns to the still-running TUI. Press `m` on a Markdown source to view it in
`mdt`; quitting `mdt` returns to the dashboard.

Expand a goal, then **Assets & Resources**, to browse every goal-local Markdown
file and `tasks.jsonl`, along with readable task references and file targets.
Completed goals are ordered by their most recently modified completion artifact.
The terminal layout adapts as Neovim changes shape. The explorer never changes
task, goal, or Wayfinder state; it is a projection of the canonical planning
files. The first launch compiles the local `tools/goals-tui` Cargo crate.

## Package Updates

Run `:PackManager` to view managed packages and stale lockfile entries. The
picker shows installed revisions and available targets when Neovim provides
them. Use `<C-u>` for the selected package or `<C-a>` for all packages; both
open Neovim's native `vim.pack` review buffer, where `:write` applies the
reviewed changes and `:quit` discards them. Use `<M-u>` to update the selected
package immediately or `<M-a>` to update all packages immediately. Use `<C-r>`
to remove a package through `vim.pack`.

## Markdown & MDX Enhancements

Buffer-local mappings for `.md`, `.mdx`, `.qmd` (Quarto), and `.rmd` (R
Markdown) files have been added to streamline document editing:

- **Bold (`**`):** `Cmd+B`(GUI) /`<leader>mb` (Terminal)
- **Italic (`*`):** `Cmd+I` (GUI) / `<leader>mi` (Terminal)
- **Smart Checkbox Cycling:** `Cmd+C` (GUI) / `<leader>mc` (Terminal)
  - Cycles line through: `Plain Line` $\rightarrow$ `Unchecked [ ]`
    $\rightarrow$ `Checked [x]` $\rightarrow$ `Plain Line` (retains list
    indentation and formats).
- **Insert Link:** `Cmd+K` (GUI) / `<leader>ml` (Terminal)
  - Wraps visual selection in `[selected_text]()` and places cursor inside the
    parens, or inserts `[](url)` at cursor in normal mode.
- **Inline Code (`` ` ``):** `Cmd+E` (GUI) / `<leader>me` (Terminal)
- **Strikethrough (`~~`):** `<leader>ms` (Terminal)

### The Role of the `after/` Directory

These configuration scripts are placed inside the `after/ftplugin/` directory.
In Vim/Neovim, this layout serves three major purposes:

1.  **On-Demand (Lazy) Loading:** Keymaps and logic are only loaded when a
    markdown-compatible buffer is opened, keeping startup fast.
2.  **Order of Execution:** Files in `after/` are executed at the very end of
    Neovim's startup pipeline. This prevents standard system-wide filetype
    plugins or other package/plugin managers from overwriting your custom
    buffer-local keymaps.
3.  **Encapsulation:** Keeps filetype-specific helper functions and maps fully
    decoupled from your main global `mappings.lua` setup.
