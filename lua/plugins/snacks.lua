local ok, snacks = pcall(require, "snacks")
if not ok then
  return
end

snacks.setup {
  bigfile = { enabled = true },
  dashboard = {
    enabled = true,
    sections = {
      { section = "recent_files", icon = " ", title = "Recent Files", indent = 2, padding = 2 },
      { section = "projects", icon = " ", title = "Projects", indent = 2, padding = 2 },
      { section = "keys", gap = 1, padding = 1 },
    },
    preset = {
      keys = {
        { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        {
          icon = " ",
          key = "c",
          desc = "Config",
          action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
        },
        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
        { icon = "󰏖 ", key = "L", desc = "Pack Manager", action = ":PackManager", enabled = true },
      },
    },
  },
  explorer = {
    enabled = false,
  },
  image = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true, timeout = 3000 },
  picker = {
    enabled = true,
  },
  quickfile = { enabled = true },
  scope = { enabled = true },
  scratch = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = false },
  words = { enabled = true },
  styles = {
    notification = { wo = { winblend = 0, winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder" } },
    input = { wo = { winblend = 0, winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder" } },
    picker = { backdrop = false, wo = { winblend = 0, winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder" } },
    terminal = { backdrop = false, wo = { winblend = 85, winhighlight = "Normal:SnacksTerminalNormal,NormalFloat:SnacksTerminalNormal,FloatBorder:SnacksTerminalBorder" } },
    lazygit = { backdrop = false, wo = { winblend = 0, winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder" } },
  },
}

