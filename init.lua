vim.g.mapleader = " "
vim.g.maplocalleader = " "

_G.dump = function(...)
  print(vim.inspect(...))
end
local ok_ui, ui = pcall(require, "vim.ui")
if ok_ui and ui.enable then
  ui.enable {}
end
require "options"
require "autocwd"
require "configs.pack"
require "plugins._loader"
require("configs.highlights").setup()
require("configs.tabline").setup()
require "configs.conform"
require "configs.lspconfig"
require "configs.lint"
require "configs.dap"
require "mappings"
require("md-table-fmt").setup()
require("tasks-nvim").setup()
