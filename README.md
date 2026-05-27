# Neovim config

Native Neovim 0.12 config using `vim.pack`, built-in LSP configuration, Conform formatting, Blink completion, and a small set of local UI/window helpers.

## Layout

- `init.lua` loads the config entrypoints.
- `lua/configs/pack.lua` declares plugins for `vim.pack`.
- `lua/configs/ui.lua` configures UI plugins and shared behavior.
- `lua/configs/lspconfig.lua` defines native LSP servers.
- `lua/configs/conform.lua` keeps formatting repo-aware.
- `lua/configs/buffers.lua`, `tabline.lua`, `term.lua`, and `highlights.lua` hold local window, tabline, terminal, and theme behavior.
- `lua/notes/init.lua` is the local notes helper.

## Requirements

- Neovim 0.12.x
- Git
- ImageMagick for image rendering

Plugin revisions are tracked in `nvim-pack-lock.json`.
