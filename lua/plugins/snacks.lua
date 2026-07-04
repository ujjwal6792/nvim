local ok, snacks = pcall(require, "snacks")
if not ok then return end

snacks.setup({
  bigfile = { enabled = true },
  dashboard = {
    enabled = true,
    sections = {
      { section = "recent_files", icon = " ", title = "Recent Files", indent = 2, padding = 2 },
      { section = "projects", icon = " ", title = "Projects", indent = 2, padding = 2 },
      { section = "keys", gap = 1, padding = 1 },
    },
  },
  explorer = { enabled = true },
  image = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true, timeout = 3000 },
  picker = { enabled = true },
  quickfile = { enabled = true },
  scope = { enabled = true },
  scratch = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = false },
  words = { enabled = true },
  styles = {
    picker = { backdrop = false },
    explorer = { backdrop = false },
    terminal = { backdrop = false },
    lazygit = { backdrop = false },
  },
})
