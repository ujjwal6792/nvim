local ok, snacks = pcall(require, "snacks")
if not ok then return end

-- ── Explorer: cut action (yank paths + mark for move on paste) ───────────────
local _cut_files = {}

local function explorer_cut(picker)
  local files = {}
  if vim.fn.mode():find("^[vV]") then
    picker.list:select()
  end
  for _, item in ipairs(picker:selected({ fallback = true })) do
    table.insert(files, Snacks.picker.util.path(item))
  end
  picker.list:set_selected()
  if #files == 0 then return end
  _cut_files = files
  local value = table.concat(files, "\n")
  vim.fn.setreg(vim.v.register or "+", value, "l")
  Snacks.notify.warn("Cut " .. #files .. " file(s) — paste with <p>")
end

local function explorer_cut_paste(picker)
  local files = vim.split(vim.fn.getreg(vim.v.register or "+") or "", "\n", { plain = true })
  files = vim.tbl_filter(function(f) return f ~= "" and vim.fn.filereadable(f) == 1 end, files)

  if #files == 0 then
    return Snacks.notify.warn("Nothing to paste")
  end

  local is_cut = #_cut_files > 0 and vim.deep_equal(_cut_files, files)
  local dir = picker:dir()

  if is_cut then
    -- Move files
    for _, src in ipairs(files) do
      local dest = dir .. "/" .. vim.fn.fnamemodify(src, ":t")
      if src ~= dest then
        vim.uv.fs_rename(src, dest, function(err)
          if err then
            vim.schedule(function()
              Snacks.notify.error("Move failed: " .. err)
            end)
          end
        end)
      end
    end
    _cut_files = {}
    vim.fn.setreg("+", "")
    Snacks.notify.info("Moved " .. #files .. " file(s)")
  else
    -- Normal copy paste
    Snacks.picker.util.copy(files, dir)
    Snacks.notify.info("Pasted " .. #files .. " file(s)")
  end

  local Tree = require("snacks.explorer.tree")
  Tree:refresh(dir)
  Tree:open(dir)
  -- update picker
  vim.schedule(function()
    local actions = require("snacks.explorer.actions")
    actions.update(picker, { target = dir })
  end)
end

snacks.setup({
  bigfile = { enabled = true },
  dashboard = {
    enabled = true,
    sections = {
      { section = "recent_files", icon = " ", title = "Recent Files", indent = 2, padding = 2 },
      { section = "projects", icon = " ", title = "Projects", indent = 2, padding = 2 },
      { section = "keys", gap = 1, padding = 1 },
    },
  },
  explorer = {
    enabled = true,
  },
  image = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true, timeout = 3000 },
  picker = {
    enabled = true,
    sources = {
      explorer = {
        actions = {
          explorer_cut = explorer_cut,
          explorer_cut_paste = explorer_cut_paste,
        },
        win = {
          list = {
            keys = {
              ["x"] = { "explorer_cut", mode = { "n", "x" } },
              ["p"] = "explorer_cut_paste",
            },
          },
        },
      },
    },
  },
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

-- vim.notify is automatically routed to Snacks.notifier.notify
-- by Snacks itself when notifier.enabled = true. No override needed.
