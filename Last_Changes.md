# Changes Summary

### Plugins Added (pack.lua)

| Plugin                          | Purpose                          |
| ------------------------------- | -------------------------------- |
| mfussenegder/nvim-dap           | DAP client (debugger)            |
| rcarriga/nvim-dap-ui            | Floating debugger UI, auto-opens |
| mfussenegger/nvim-lint          | Async linter orchestrator        |
| on session start                |                                  |
| theHamsta/nvim-dap-virtual-text | Inline variable values during    |
| debug sessions                  |                                  |
| jay-babu/mason-nvim-dap.nvim    | Auto-installs DAP adapters via   |
| Mason                           |                                  |
| MagicDuck/grug-far.nvim         | Modern multi-file find & replace |
| (spectre replacement)           |                                  |

### ❌ Plugins Removed (pack.lua)

• nvim-pack/nvim-spectre → replaced by grug-far • mikavilpas/yazi.nvim → unused,
nvim-tree covers the need

### 🆕 New Files Created

• lint.lua — wires nvim-lint with eslint_d (JS/TS/Svelte/Astro), golangci-lint +
staticcheck (Go), hadolint (Dockerfile), yamllint (YAML), dotenv-linter (.env) •
dap.lua — full DAP setup: codelldb (Rust+C/C++), js-debug- adapter
(Node/Browser), dap-ui with auto-open, virtual text, breakpoint signs

### ⚙️ Files Updated

• lspconfig.lua — eslint added as a proper enabled LSP server (formats disabled
— conform/prettier handle that) • ui.lua — vale removed; hadolint ,
dotenv-linter , yamllint , staticcheck added to Mason auto-install •
mappings.lua — <leader>fr/fR → grug-far; <leader>db/dc/di/do/dO/dt/du/de/dp →
DAP keymaps; yazi maps removed • init.lua — require "configs.lint" and require
"configs.dap" added

### ⌨️ New DAP Keymaps

| Key        | Action                       |
| ---------- | ---------------------------- |
| <leader>db | Toggle breakpoint            |
| <leader>dB | Conditional breakpoint       |
| <leader>dc | Continue                     |
| <leader>di | Step into                    |
| <leader>do | Step over                    |
| <leader>dO | Step out                     |
| <leader>dt | Terminate + close UI         |
| <leader>du | Toggle DAP UI                |
| <leader>de | Eval expression (visual too) |
| <leader>dp | Log point                    |

│ [!IMPORTANT] │ On your next Neovim launch, vim.pack will need to install the
new │ plugins. If it doesn't auto-install, you may need to manually trigger │
the sync. After that, Mason will automatically install codelldb , │
js-debug-adapter , hadolint , dotenv-linter , yamllint , and │ staticcheck in
the background.
