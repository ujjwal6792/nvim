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

map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })
map("n", "<C-Left>", "<C-w>h", { desc = "switch window left" })
map("n", "<C-Right>", "<C-w>l", { desc = "switch window right" })
map("n", "<C-Down>", "<C-w>j", { desc = "switch window down" })
map("n", "<C-Up>", "<C-w>k", { desc = "switch window up" })

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

map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "focus nvimtree" })
map("n", "<leader>we", "<cmd>NvimTreeRefresh<CR>", { desc = "refresh nvimtree" })
map("n", "<leader>ww", "<cmd>NvimTreeToggle<CR>", { desc = "toggle nvimtree" })

map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "telescope help page" })
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "telescope find marks" })
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in buffer" })
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "telescope find files" })
map("n", "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>", { desc = "telescope find all files" })

map("n", "ea", "$a", { desc = "move cursor to end and enter insert mode" })

map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })

map("n", "<leader>v", function()
  require("configs.term").new { pos = "vsp" }
end, { desc = "terminal new vertical term" })

map("n", "<leader>h", function()
  require("configs.term").new { pos = "sp" }
end, { desc = "terminal new horizontal term" })

map({ "n", "t" }, "<A-v>", function()
  require("configs.term").toggle { pos = "vsp", id = "vtoggleTerm" }
end, { desc = "terminal toggleable vertical term" })

map({ "n", "t" }, "<A-h>", function()
  require("configs.term").toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "terminal toggleable horizontal term" })

map({ "n", "t" }, "<A-i>", function()
  require("configs.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "terminal toggle floating term" })

map("n", "gt", "<cmd>LazyGit<CR>", { desc = "open lazygit" })
map("n", "<leader>gf", "<cmd>LazyGitFilter<CR>", { desc = "lazygit commits" })
map("n", "gG", "<cmd>LazyGitCurrentFile<CR>", { desc = "open lazygit for current" })
map("n", "<leader>gF", "<cmd>LazyGitFilterCurrentFile<CR>", { desc = "lazygit commits for current" })
map("n", "<leader>gt", function()
  local ok, telescope = pcall(require, "telescope")
  if ok then
    telescope.extensions.lazygit.lazygit()
  else
    vim.cmd "LazyGit"
  end
end, { desc = "open lazygit telescope" })

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

map("n", "<leader><leader>", "<cmd>Yazi<CR>", { desc = "open yazi at current file" })
map({ "n", "v" }, "<leader>cw", "<cmd>Yazi cwd<CR>", { desc = "open yazi cwd" })

map("n", "<leader>fr", function()
  require("spectre").open()
end, { desc = "replace in files" })

map("n", "<leader>sr", "<cmd>AutoSession search<CR>", { desc = "session search" })
map("n", "<leader>ss", "<cmd>AutoSession save<CR>", { desc = "save session" })
map("n", "<leader>sa", "<cmd>AutoSession toggle<CR>", { desc = "toggle autosave" })
map("n", "<leader>dd", "<cmd>DocsViewToggle<CR>", { desc = "docs view toggle" })

map("n", "<leader>mc", "<cmd>Checkbox toggle<CR>", { desc = "markdown checkbox toggle" })
map("n", "<leader>mh-", "<cmd>Heading decrease<CR>", { desc = "markdown heading decrease" })
map("n", "<leader>mh=", "<cmd>Heading increase<CR>", { desc = "markdown heading increase" })
map("n", "<leader>mn", function()
  require("notes").open_notes()
end, { desc = "open notes" })

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
