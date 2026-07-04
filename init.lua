vim.g.mapleader = " "
vim.g.maplocalleader = " "

_G.dump = function(...)
  print(vim.inspect(...))
end
require("vim._core.ui2").enable {}
require "options"
require "autocwd"
require "configs.pack"
require "plugins._loader"
require "configs.conform"
require "configs.lspconfig"
require "configs.lint"
require "configs.dap"
require "mappings"
require("md-table-fmt").setup()
require("tasks-nvim").setup()
