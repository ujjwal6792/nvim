require "nvchad.options"

-- add yours here!

local o = vim.o
local opt = vim.opt
local g = vim.g

o.cursorlineopt = "both" -- to enable cursorline!

o.expandtab = true
o.autoindent = true
o.shiftwidth = 2
o.smartindent = true
o.tabstop = 2
o.softtabstop = 2

o.ignorecase = true
o.smartcase = true
o.mouse = "a"

-- Numbers
-- o.relativenumber = true
o.number = true
o.numberwidth = 2
o.ruler = true
opt.clipboard = "unnamedplus"
-- disable nvim intro
opt.shortmess:append "sI"

opt.signcolumn = "yes"
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.timeoutlen = 400
opt.undofile = true
opt.swapfile = false
-- interval for writing swap file to disk, also used by gitsigns
opt.updatetime = 150

opt.iskeyword:append "-" -- makes neovim read - as part of the word
-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
opt.whichwrap:append "<>[]hl"
opt.backspace = "indent,eol,start"

g.mapleader = " "
g.skip_ts_context_commentstring_module = true

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

-- wsl setup for clipboard
--[[ vim.g.clipboard = {
  name = "WslClipboard",
  copy = {
    ["+"] = "clip.exe",
    ["*"] = "clip.exe",
  },
  paste = {
    ["+"] = 'pwsh.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    ["*"] = 'pwsh.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
  },
  cache_enabled = 0,
} ]]
