local discovery = require("goals-nvim.discovery")

local M = {}

function M.open(path)
  local root = discovery.find(path)
  if not root then
    vim.notify("No resources/planning/GOALS.md found above the current project", vim.log.levels.WARN)
    return
  end
  local snacks_ok, snacks = pcall(require, "snacks")
  if not snacks_ok then
    vim.notify("Snacks.nvim is required to open goals-tui", vim.log.levels.ERROR)
    return
  end
  local tool_root = vim.fn.stdpath("config") .. "/tools/goals-tui"
  local binary = tool_root .. "/target/debug/goals-tui"
  local binary_stat = vim.uv.fs_stat(binary)
  local source_stat = vim.uv.fs_stat(tool_root .. "/src/main.rs")
  local manifest_stat = vim.uv.fs_stat(tool_root .. "/Cargo.toml")
  local needs_build = vim.fn.executable(binary) == 0
    or (source_stat and binary_stat and source_stat.mtime.sec > binary_stat.mtime.sec)
    or (manifest_stat and binary_stat and manifest_stat.mtime.sec > binary_stat.mtime.sec)
  if needs_build then
    local build = vim.system({ "cargo", "build", "--quiet", "--manifest-path", tool_root .. "/Cargo.toml" }):wait()
    if build.code ~= 0 then
      vim.notify("goals-tui build failed:\n" .. build.stderr, vim.log.levels.ERROR)
      return
    end
  end
  snacks.terminal.open({ binary, root }, {
    cwd = root,
    interactive = true,
    win = { style = "terminal" },
  })
end

function M.setup()
  vim.api.nvim_create_user_command("Goals", function(args) M.open(args.args ~= "" and args.args or nil) end, { nargs = "?", complete = "dir" })
  vim.keymap.set("n", "<leader>tt", M.open, { desc = "Open goals explorer" })
end

return M
