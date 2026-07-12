local ok, snacks = pcall(require, "snacks")
if not ok then
  return
end

-- ── Explorer: cut action (yank paths + mark for move on paste) ───────────────
local _cut_files = {}

local function explorer_cut(picker)
  local files = {}
  if vim.fn.mode():find "^[vV]" then
    picker.list:select()
  end
  for _, item in ipairs(picker:selected { fallback = true }) do
    table.insert(files, snacks.picker.util.path(item))
  end
  picker.list:set_selected()
  if #files == 0 then
    return
  end
  _cut_files = files
  local value = table.concat(files, "\n")
  vim.fn.setreg(vim.v.register or "+", value, "l")
  snacks.notify.warn("Cut " .. #files .. " file(s) — paste with <p>")
end

local function explorer_cut_paste(picker)
  local files = vim.split(vim.fn.getreg(vim.v.register or "+") or "", "\n", { plain = true })
  files = vim.tbl_filter(function(f)
    return f ~= "" and vim.fn.filereadable(f) == 1
  end, files)

  if #files == 0 then
    return snacks.notify.warn "Nothing to paste"
  end

  local is_cut = #_cut_files > 0 and vim.deep_equal(_cut_files, files)
  local dir = picker:dir()
  local actions = require "snacks.explorer.actions"

  if is_cut then
    -- Track asynchronous operations
    local remaining = #files
    for _, src in ipairs(files) do
      local dest = dir .. "/" .. vim.fn.fnamemodify(src, ":t")
      if src ~= dest then
        vim.uv.fs_rename(src, dest, function(err)
          vim.schedule(function()
            if err then
              snacks.notify.error("Move failed: " .. err)
            else
              remaining = remaining - 1
              -- Trigger UI refresh only after the last file moves successfully
              if remaining == 0 then
                _cut_files = {}
                vim.fn.setreg("+", "")
                actions.update(picker, { target = dir })
                snacks.notify.info "Moved files successfully"
              end
            end
          end)
        end)
      else
        remaining = remaining - 1
      end
    end
  else
    -- Normal copy paste
    snacks.picker.util.copy(files, dir)
    actions.update(picker, { target = dir })
    snacks.notify.info("Pasted " .. #files .. " file(s)")
  end
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
        { icon = "   ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
      },
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
    notification = { wo = { winblend = 0, winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder" } },
    input = { wo = { winblend = 0, winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder" } },
    picker = { backdrop = false, wo = { winblend = 0, winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder" } },
    explorer = { backdrop = false, wo = { winblend = 0, winhighlight = "Normal:Normal,FloatBorder:FloatBorder" } },
    terminal = { backdrop = false, wo = { winblend = 85, winhighlight = "Normal:SnacksTerminalNormal,NormalFloat:SnacksTerminalNormal,FloatBorder:SnacksTerminalBorder" } },
    lazygit = { backdrop = false, wo = { winblend = 0, winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder" } },
  },
}

-- Automatically close Snacks terminal windows when the process exits
vim.api.nvim_create_autocmd("TermClose", {
  pattern = "*",
  callback = function(ev)
    if vim.b[ev.buf].snacks_terminal then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          local win = vim.fn.bufwinid(ev.buf)
          if win ~= -1 then
            pcall(vim.api.nvim_win_close, win, true)
          end
        end
      end)
    end
  end,
})
