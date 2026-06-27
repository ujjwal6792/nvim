local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  return
end

-- ── mason-nvim-dap: auto-install DAP adapters ────────────────────────────────
local ok_mason_dap, mason_dap = pcall(require, "mason-nvim-dap")
if ok_mason_dap then
  mason_dap.setup {
    ensure_installed = {
      "codelldb",      -- Rust + C/C++
      "js",            -- Node.js / browser (js-debug-adapter)
    },
    automatic_installation = true,
    handlers = {
      -- Use default handler for all adapters unless overridden below
      function(config)
        mason_dap.default_setup(config)
      end,

      -- Override: codelldb for Rust and C/C++
      codelldb = function(config)
        config.adapters = {
          type = "server",
          port = "${port}",
          executable = {
            command = vim.fn.exepath "codelldb",
            args = { "--port", "${port}" },
          },
        }
        local configurations = {
          -- C / C++ / Embedded (ESP32)
          {
            name = "Launch (C/C++)",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input("Binary path: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            args = {},
          },
          -- Rust (rustaceanvim will add its own entries, but this is a fallback)
          {
            name = "Launch (Rust)",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input("Binary path: ", vim.fn.getcwd() .. "/target/debug/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            args = {},
          },
        }
        dap.configurations.c = configurations
        dap.configurations.cpp = configurations
        dap.configurations.rust = configurations

        config.configurations = {}
        mason_dap.default_setup(config)
      end,

      -- Override: js-debug-adapter for Node / browser
      js = function(config)
        local js_debug_path = vim.fn.stdpath "data" .. "/mason/packages/js-debug-adapter"
        config.adapters = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            args = { js_debug_path .. "/js-debug/src/dapDebugServer.js", "${port}" },
          },
        }
        local configurations = {
          {
            name = "Launch Node.js",
            type = "pwa-node",
            request = "launch",
            program = "${file}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            protocol = "inspector",
            console = "integratedTerminal",
          },
          {
            name = "Attach Node.js",
            type = "pwa-node",
            request = "attach",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
            sourceMaps = true,
          },
          {
            name = "Launch Chrome",
            type = "pwa-chrome",
            request = "launch",
            url = function()
              return vim.fn.input("URL: ", "http://localhost:3000")
            end,
            webRoot = "${workspaceFolder}",
            sourceMaps = true,
          },
        }

        -- Apply to JS/TS filetypes
        for _, ft in ipairs { "javascript", "javascriptreact", "typescript", "typescriptreact" } do
          dap.configurations[ft] = configurations
        end

        config.configurations = {}
        mason_dap.default_setup(config)
      end,
    },
  }
end

-- ── nvim-dap-virtual-text ──────────────────────────────────────────────────────
local ok_vt, vt = pcall(require, "nvim-dap-virtual-text")
if ok_vt then
  vt.setup {
    enabled = true,
    enabled_commands = true,
    highlight_changed_variables = true,
    highlight_new_as_changed = false,
    show_stop_reason = true,
    commented = false,
    only_first_definition = true,
    all_references = false,
    virt_text_pos = "eol",
  }
end

-- ── nvim-dap-ui ────────────────────────────────────────────────────────────────
local ok_ui, dapui = pcall(require, "dapui")
if ok_ui then
  dapui.setup {
    icons = { expanded = "", collapsed = "", current_frame = "" },
    mappings = {
      expand = { "<CR>", "<2-LeftMouse>" },
      open = "o",
      remove = "d",
      edit = "e",
      repl = "r",
      toggle = "t",
    },
    layouts = {
      {
        elements = {
          { id = "scopes",      size = 0.35 },
          { id = "breakpoints", size = 0.15 },
          { id = "stacks",      size = 0.25 },
          { id = "watches",     size = 0.25 },
        },
        size = 40,
        position = "left",
      },
      {
        elements = {
          { id = "repl",    size = 0.5 },
          { id = "console", size = 0.5 },
        },
        size = 12,
        position = "bottom",
      },
    },
    controls = {
      enabled = true,
      element = "repl",
      icons = {
        pause = "",
        play = "",
        step_into = "",
        step_over = "",
        step_out = "",
        step_back = "",
        run_last = "",
        terminate = "",
        disconnect = "",
      },
    },
    floating = {
      max_height = nil,
      max_width = nil,
      border = "single",
      mappings = { close = { "q", "<Esc>" } },
    },
    render = {
      max_type_length = nil,
      max_value_lines = 100,
    },
  }

  -- Auto-open/close dap-ui on session events
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
end

-- ── Breakpoint signs ───────────────────────────────────────────────────────────
vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DiagnosticError",   linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn",    linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected",  { text = "○", texthl = "DiagnosticHint",    linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint",            { text = "◎", texthl = "DiagnosticInfo",    linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DiagnosticOk",      linehl = "DapStoppedLine", numhl = "" })
