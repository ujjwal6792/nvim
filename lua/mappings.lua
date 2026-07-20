local map = vim.keymap.set
local fn = vim.fn

vim.keymap.set("n", "s", "<Nop>")
vim.keymap.set("x", "s", "<Nop>")

map("i", "<C-b>", "<Esc>^i", { desc = "move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "move end of line" })
map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-l>", "<Right>", { desc = "move right" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })

if vim.env.HERDR_ENV == "1" then
  map("n", "<C-h>", function() require("herdr-splits").move_cursor_left() end, { desc = "switch window left (herdr)" })
  map("n", "<C-l>", function() require("herdr-splits").move_cursor_right() end, { desc = "switch window right (herdr)" })
  map("n", "<C-j>", function() require("herdr-splits").move_cursor_down() end, { desc = "switch window down (herdr)" })
  map("n", "<C-k>", function() require("herdr-splits").move_cursor_up() end, { desc = "switch window up (herdr)" })
  map("n", "<C-Left>", function() require("herdr-splits").move_cursor_left() end, { desc = "switch window left (herdr)" })
  map("n", "<C-Right>", function() require("herdr-splits").move_cursor_right() end, { desc = "switch window right (herdr)" })
  map("n", "<C-Down>", function() require("herdr-splits").move_cursor_down() end, { desc = "switch window down (herdr)" })
  map("n", "<C-Up>", function() require("herdr-splits").move_cursor_up() end, { desc = "switch window up (herdr)" })
else
  map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
  map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
  map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
  map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })
  map("n", "<C-Left>", "<C-w>h", { desc = "switch window left" })
  map("n", "<C-Right>", "<C-w>l", { desc = "switch window right" })
  map("n", "<C-Down>", "<C-w>j", { desc = "switch window down" })
  map("n", "<C-Up>", "<C-w>k", { desc = "switch window up" })
end

local function map_if_free(mode, lhs, rhs, opts)
  if vim.fn.maparg(lhs, mode) == "" then
    map(mode, lhs, rhs, opts)
  end
end

map_if_free("n", "f", "za", { desc = "toggle fold" })
map_if_free("n", "F", "zA", { desc = "toggle fold recursively" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "clear highlights" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "copy whole file" })
map("n", ";", ":", { desc = "enter command mode" })

vim.cmd [[cnoreabbrev <expr> q  getcmdtype() == ':' && getcmdline() == 'q'  ? 'qa'  : 'q']]
vim.cmd [[cnoreabbrev <expr> q! getcmdtype() == ':' && getcmdline() == 'q!' ? 'qa!' : 'q!']]

map("i", "jj", "jj")
map("i", "jk", "jk")

map("n", "<leader>n", "<cmd>set nu!<CR>", { desc = "toggle line number" })
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })
map({ "n", "x" }, "<leader>fm", function()
  require("conform").format { lsp_format = "fallback" }
end, { desc = "format file" })
map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })

map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })
map("n", "<Tab>", "<cmd>bnext<CR>", { desc = "buffer goto next" })
map("n", "<S-Tab>", "<cmd>bprevious<CR>", { desc = "buffer goto previous" })
map("n", "<leader>x", function()
  require("configs.buffers").close_current()
end, { desc = "buffer close" })

map("n", "<leader>/", "gcc", { remap = true, desc = "toggle comment" })
map("v", "<leader>/", "gc", { remap = true, desc = "toggle comment" })

map("n", "<leader><leader>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "focus nvimtree" })
map("n", "<leader>we", "<cmd>NvimTreeRefresh<CR>", { desc = "refresh nvimtree" })
map("n", "<leader>ww", "<cmd>NvimTreeToggle<CR>", { desc = "toggle nvimtree" })

map("n", "<leader>fw", function() Snacks.picker.grep() end, { desc = "Live grep" })
map("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Find buffers" })
map("n", "<leader>fh", function() Snacks.picker.help() end, { desc = "Help pages" })
map("n", "<leader>ma", function() Snacks.picker.marks() end, { desc = "Find marks" })
map("n", "<leader>fo", function() Snacks.picker.recent() end, { desc = "Find oldfiles" })
map("n", "<leader>fz", function() Snacks.picker.lines() end, { desc = "Find in buffer" })
map("n", "<leader>cm", function() Snacks.picker.git_commits() end, { desc = "Git commits" })
map("n", "<leader>gt", function() Snacks.picker.git_status() end, { desc = "Git status" })
map("n", "<leader>ff", function() Snacks.picker.files() end, { desc = "Find files" })
map("n", "<leader>fa", function() Snacks.picker.files({ hidden = true, ignored = true }) end, { desc = "Find all files" })

-- Snacks Quick Mappings
map("n", "<leader>.", function() Snacks.scratch() end, { desc = "Toggle Scratch Buffer" })
map("n", "<leader>rn", function() Snacks.rename.rename_file() end, { desc = "Rename File" })

-- Project Manager / tasks.jsonl Plugin Keymaps
map("n", "<leader>ta", function() require("tasks-nvim").open({ group_by = "status" }) end, { desc = "Tasks: all grouped by status" })
map("n", "<leader>ts", function() require("tasks-nvim").open({ filter = "current_sprint" }) end, { desc = "Tasks: current sprint" })
map("n", "<leader>te", function() require("tasks-nvim").open({ group_by = "epic" }) end, { desc = "Tasks: group by epic" })
map("n", "<leader>ti", function() require("tasks-nvim").open({ filter = "in_progress" }) end, { desc = "Tasks: in progress only" })
map("n", "<leader>tb", function() require("tasks-nvim").open({ filter = "blocked" }) end, { desc = "Tasks: blocked only" })
map("n", "<leader>tg", function() require("tasks-nvim").open({ group_by = "milestone" }) end, { desc = "Tasks: group by milestone" })
map("n", "<leader>tn", function() require("tasks-nvim").new_task() end, { desc = "Tasks: create new task" })
map("n", "<leader>td", function() require("tasks-nvim").open({ filter = "done" }) end, { desc = "Tasks: done only" })

map("n", "ea", "$a", { desc = "move cursor to end and enter insert mode" })

map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })

map("n", "<leader>v", function()
  require("configs.term").new { pos = "vsp" }
end, { desc = "terminal new vertical term" })

map("n", "<leader>h", function()
  require("configs.term").new { pos = "sp" }
end, { desc = "terminal new horizontal term" })

map({ "n", "t" }, "<A-v>", function()
  if vim.env.HERDR_ENV == "1" then
    require("configs.herdr").toggle { mode = "v" }
  else
    require("configs.term").toggle { pos = "vsp", id = "vtoggleTerm" }
  end
end, { desc = "terminal toggleable vertical term" })

map({ "n", "t" }, "<A-h>", function()
  if vim.env.HERDR_ENV == "1" then
    require("configs.herdr").toggle { mode = "h" }
  else
    require("configs.term").toggle { pos = "sp", id = "htoggleTerm" }
  end
end, { desc = "terminal toggleable horizontal term" })

map({ "n", "t" }, "<A-i>", function()
  Snacks.terminal.toggle(nil, { win = { position = "float", border = "single" } })
end, { desc = "terminal toggle floating term" })

map("n", "gt", function() Snacks.lazygit() end, { desc = "open lazygit" })
map("n", "<leader>gf", function() Snacks.lazygit.log() end, { desc = "lazygit log" })
map("n", "gG", function() Snacks.lazygit.log_file() end, { desc = "lazygit current file" })
map("n", "<leader>gF", function() Snacks.lazygit.log_file() end, { desc = "lazygit log current" })

map("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>", { desc = "git blame line" })
map("n", "<leader>gg", function()
  require("gitsigns").preview_hunk()
end, { desc = "git preview hunk" })
map("n", "<leader>gh", function()
  require("gitsigns").toggle_deleted()
end, { desc = "git toggle deleted" })
map("n", "<leader>gs", function()
  require("gitsigns").stage_hunk()
end, { desc = "git stage hunk" })
map("n", "<leader>gu", function()
  require("gitsigns").undo_stage_hunk()
end, { desc = "git undo stage hunk" })
map("n", "<leader>gr", function()
  require("gitsigns").reset_hunk()
end, { desc = "git reset hunk" })
map("n", "]c", function()
  require("gitsigns").next_hunk()
end, { desc = "go to next hunk" })
map("n", "[c", function()
  require("gitsigns").prev_hunk()
end, { desc = "go to previous hunk" })

map("n", "<leader>wK", "<cmd>WhichKey<CR>", { desc = "whichkey all keymaps" })
map("n", "<leader>wk", function()
  vim.cmd("WhichKey " .. fn.input "WhichKey: ")
end, { desc = "whichkey query lookup" })

map("n", "<leader>fr", function()
  require("grug-far").open()
end, { desc = "find and replace in files" })

map("n", "<leader>fR", function()
  require("grug-far").open { prefills = { search = vim.fn.expand "<cword>" } }
end, { desc = "find and replace word under cursor" })

map("n", "<leader>qs", function() require("persistence").load() end, { desc = "Restore Session" })
map("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "Restore Last Session" })
map("n", "<leader>qd", function() require("persistence").stop() end, { desc = "Don't Save Current Session" })
map("n", "<leader>dd", "<cmd>DocsViewToggle<CR>", { desc = "docs view toggle" })

map("n", "<leader>mc", "<cmd>Checkbox toggle<CR>", { desc = "markdown checkbox toggle" })
map("n", "<leader>mh-", "<cmd>Heading decrease<CR>", { desc = "markdown heading decrease" })
map("n", "<leader>mh=", "<cmd>Heading increase<CR>", { desc = "markdown heading increase" })
map("n", "<leader>mn", function()
  require("notes").open_notes()
end, { desc = "open notes" })
map("n", "<leader>mt", function()
  require("notes").open_tags()
end, { desc = "notes: tag browser" })
map("n", "<leader>mk", function()
  require("notes").open_tasks()
end, { desc = "notes: task list" })
map("n", "<leader>mb", function()
  require("notes").open_backlinks()
end, { desc = "notes: backlinks" })

-- ── DAP (Debugger) keymaps ────────────────────────────────────────────────────
map("n", "<leader>db", function()
  require("dap").toggle_breakpoint()
end, { desc = "dap toggle breakpoint" })

map("n", "<leader>dB", function()
  require("dap").set_breakpoint(vim.fn.input "Condition: ")
end, { desc = "dap conditional breakpoint" })

map("n", "<leader>dc", function()
  require("dap").continue()
end, { desc = "dap continue" })

map("n", "<leader>dC", function()
  require("dap").run_to_cursor()
end, { desc = "dap run to cursor" })

map("n", "<leader>di", function()
  require("dap").step_into()
end, { desc = "dap step into" })

map("n", "<leader>do", function()
  require("dap").step_over()
end, { desc = "dap step over" })

map("n", "<leader>dO", function()
  require("dap").step_out()
end, { desc = "dap step out" })

map("n", "<leader>dr", function()
  require("dap").repl.toggle()
end, { desc = "dap toggle repl" })

map("n", "<leader>dl", function()
  require("dap").run_last()
end, { desc = "dap run last" })

map("n", "<leader>dt", function()
  require("dap").terminate()
  require("dapui").close()
end, { desc = "dap terminate" })

map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "dap toggle ui" })

map({ "n", "v" }, "<leader>de", function()
  require("dapui").eval()
end, { desc = "dap eval expression" })

map("n", "<leader>dp", function()
  require("dap").set_breakpoint(nil, nil, vim.fn.input "Log message: ")
end, { desc = "dap log point" })

local cargo_toml = fn.getcwd() .. "/Cargo.toml"
if vim.uv.fs_stat(cargo_toml) then
  map("n", "<leader>rc", function()
    require("configs.term").runner {
      pos = "float",
      cmd = "cargo run",
      id = "rcr",
      clear_cmd = false,
    }
  end, { desc = "cargo run" })
end
