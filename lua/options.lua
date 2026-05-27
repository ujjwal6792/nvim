local opt = vim.opt
local o = vim.o
local g = vim.g

o.laststatus = 3
o.showmode = false
o.splitkeep = "screen"

o.clipboard = "unnamedplus"
o.cursorline = true
o.cursorlineopt = "both"

o.expandtab = true
o.autoindent = true
o.shiftwidth = 2
o.smartindent = true
o.tabstop = 2
o.softtabstop = 2

o.ignorecase = true
o.smartcase = true
o.mouse = "a"

o.number = true
o.numberwidth = 2
o.ruler = true

opt.fillchars = { eob = " " }
opt.shortmess:append "sI"
opt.signcolumn = "yes"
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.timeoutlen = 400
opt.undofile = true
opt.swapfile = false
opt.updatetime = 150
opt.iskeyword:append "-"
opt.whichwrap:append "<>[]hl"
opt.backspace = "indent,eol,start"

g.mapleader = " "
g.maplocalleader = " "
g.skip_ts_context_commentstring_module = true
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1

local mason_bin = vim.fs.joinpath(vim.fn.stdpath "data", "mason", "bin")
vim.env.PATH = mason_bin .. ":" .. vim.env.PATH

local markdown_notes_group = vim.api.nvim_create_augroup("DefaultEmptyMarkdown", { clear = true })

local function use_markdown_for_empty_buffer(args)
  local buf = args.buf

  if vim.bo[buf].filetype ~= "" or vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable then
    return
  end

  if vim.api.nvim_buf_get_name(buf) ~= "" then
    return
  end

  if vim.api.nvim_buf_line_count(buf) == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "" then
    vim.bo[buf].filetype = "markdown"
  end
end

vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter" }, {
  group = markdown_notes_group,
  callback = use_markdown_for_empty_buffer,
})

if vim.fn.getenv "TERM_PROGRAM" == "ghostty" then
  opt.title = true
  opt.titlestring = "%{fnamemodify(getcwd(), ':t')}"
end
