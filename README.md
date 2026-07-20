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

## Requirements

- Neovim 0.12.x
- Git
- ImageMagick for image rendering

Plugin revisions are tracked in `nvim-pack-lock.json`.

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
