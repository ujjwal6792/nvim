require "nvchad.mappings"

-- add yours here
local g = vim.g
local api = vim.api
local map = vim.keymap.set
local uv = vim.loop
local fn = vim.fn

local function opts_to_id(id)
  for _, opts in pairs(g.nvchad_terms) do
    if opts.id == id then
      return opts
    end
  end
end

--[[ -- Disable default 's' in Normal mode ]]
vim.keymap.set("n", "s", "<Nop>")

-- Disable default 's' in Visual mode (optional)
vim.keymap.set("x", "s", "<Nop>")

map("n", ";", ":", { desc = "CMD enter command mode" })
-- Replace :q → :qa
vim.cmd [[cnoreabbrev <expr> q  getcmdtype() == ':' && getcmdline() == 'q'  ? 'qa'  : 'q']]
-- Replace :q! → :qa!
vim.cmd [[cnoreabbrev <expr> q! getcmdtype() == ':' && getcmdline() == 'q!' ? 'qa!' : 'q!']]
map("i", "jj", "jj")
map("i", "jk", "jk")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- Comment.nvim blockwise toggle
map("n", "<leader>/", function()
  require("Comment.api").toggle.blockwise.current()
end, { desc = "Toggle blockwise comment" })

map("v", "<leader>/", function()
  local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
  vim.api.nvim_feedkeys(esc, "nx", false)
  require("Comment.api").toggle.blockwise(vim.fn.visualmode())
end, { desc = "Toggle blockwise comment (visual)" })

-- nvimtree
map("n", "<leader>e", "<cmd> NvimTreeFocus<CR>", { desc = "Focus nvimtree" })
map("n", "<leader>we", "<cmd> NvimTreeRefresh<CR>", { desc = "Refresh nvimtree" })
map("n", "<leader>ww", "<cmd> NvimTreeToggle<CR>", { desc = "Toggle nvimtree" })

-- input edits
map("n", "ea", "$a", { desc = "move cursor to end and enter insert mode" })

-- term toggle
map("n", "<leader>v", function()
  if g.nvchad_terms then
    for _, opts in pairs(g.nvchad_terms) do
      if opts.id == "htoggleTerm" then
        local x = opts_to_id(opts.id)
        if x or api.nvim_buf_is_valid(x.buf) then
          local buf = vim.fn.getbufinfo(x.buf)[1]
          if buf then
            if buf.hidden ~= 1 then
              api.nvim_win_close(x.win, true)
            end
          end
        end
      end
    end
  end
  vim.cmd "wincmd l"
  require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm", size = 0.4 }
end, { desc = "Terminal New horizontal term" })

map("n", "<leader>h", function()
  if g.nvchad_terms then
    for _, opts in pairs(g.nvchad_terms) do
      if opts.id == "vtoggleTerm" then
        local x = opts_to_id(opts.id)
        if x or api.nvim_buf_is_valid(x.buf) then
          local buf = vim.fn.getbufinfo(x.buf)[1]
          if buf then
            if buf.hidden ~= 1 then
              api.nvim_win_close(x.win, true)
            end
          end
        end
      end
    end
  end
  vim.cmd "wincmd l"
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm", size = 0.4 }
end, { desc = "Terminal New vertical window" })

-- toggleable
map({ "n", "t" }, "<A-v>", function()
  if g.nvchad_terms then
    for _, opts in pairs(g.nvchad_terms) do
      if opts.id == "htoggleTerm" then
        local x = opts_to_id(opts.id)
        if x or api.nvim_buf_is_valid(x.buf) then
          local buf = vim.fn.getbufinfo(x.buf)[1]
          if buf then
            if buf.hidden ~= 1 then
              api.nvim_win_close(x.win, true)
            end
          end
        end
      end
    end
  end
  vim.cmd "wincmd l"
  require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm", size = 0.4 }
end, { desc = "Terminal Toggleable vertical term" })

map({ "n", "t" }, "<A-h>", function()
  if g.nvchad_terms then
    for _, opts in pairs(g.nvchad_terms) do
      if opts.id == "vtoggleTerm" then
        local x = opts_to_id(opts.id)
        if x or api.nvim_buf_is_valid(x.buf) then
          local buf = vim.fn.getbufinfo(x.buf)[1]
          if buf then
            if buf.hidden ~= 1 then
              api.nvim_win_close(x.win, true)
            end
          end
        end
      end
    end
  end
  vim.cmd "wincmd l"
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm", size = 0.4 }
end, { desc = "Terminal New horizontal term" })

map({ "n", "t" }, "<A-i>", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "Terminal Toggle Floating term" })

map("t", "<ESC>", function()
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_close(win, true)
end, { desc = "Terminal Close term in terminal mode" })

-- custom
map("n", "<C-d>", "Find Under")
--[[ map("n", "<leader>fp", "<cmd> :Project<CR>", { desc = "Open Projects" }) ]]
map("n", "gt", "<cmd> :LazyGit<CR>", { desc = "open lazygit" })
map("n", "<leader>gf", "<cmd> :LazyGitFilter<CR>", { desc = "lazygit commits" })
map("n", "gG", "<cmd> :LazyGitCurrentFile<CR>", { desc = "open lazygit for current" })
map("n", "<leader>gF", "<cmd> :LazyGitFilter<CR>", { desc = "lazygit commits for current" })
map("n", "<leader>db", "<cmd> DapToggleBreakpoint<CR>", { desc = "debugger toggle breakpoints" })
map("n", "<leader>gt", function()
  require("telescope").extensions.lazygit.lazygit()
end, { desc = "open lazygit telescope" })
map("n", "<leader>dus", function()
  local widgets = require "dap.ui.widgets"
  local sidebar = widgets.sidebar(widgets.scopes)
  sidebar.open()
end, { desc = "Open debugging sidebar" })

-- gitsigns
local gitsigns = require "gitsigns"
map("n", "<leader>gb", "<cmd>:Gitsigns blame_line<CR>", { desc = "git blame line" })
map("n", "<leader>gg", gitsigns.preview_hunk, { desc = "git preview hunk" })
map("n", "<leader>gh", gitsigns.toggle_deleted, { desc = "git toggle deleted" })
map("n", "<leader>gs", gitsigns.stage_hunk, { desc = "git stage hunk" })
map("n", "<leader>gu", gitsigns.undo_stage_hunk, { desc = "git undo stage hunk" })
map("n", "<leader>gr", gitsigns.reset_hunk, { desc = "git reset hunk" })
map("n", "]c", gitsigns.next_hunk, { desc = "go to next hunk" })
map("n", "[c", gitsigns.prev_hunk, { desc = "go to previous hunk" })

-- rust cargo run
-- Get the full path to Cargo.toml in the current working directory
local cargo_toml = fn.getcwd() .. "/Cargo.toml"

-- Check if the file exists
if uv.fs_stat(cargo_toml) then
  vim.keymap.set("n", "<leader>rc", function()
    require("nvchad.term").runner {
      pos = "float",
      cmd = "cargo run",
      id = "rcr",
      clear_cmd = false,
    }
  end, { desc = "cargo run" })
end

-- ghostty show app name in tab
if fn.getenv "TERM_PROGRAM" == "ghostty" then
  vim.opt.title = true
  vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')}"
end

vim.keymap.set({ "n", "v" }, "<RightMouse>", function()
  require("menu.utils").delete_old_menus()

  vim.cmd.exec '"normal! \\<RightMouse>"'

  -- clicked buf
  local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
  local options = vim.bo[buf].ft == "NvimTree" and "nvimtree" or "default"

  require("menu").open(options, { mouse = true })
end, {})
