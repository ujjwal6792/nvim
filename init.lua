vim.g.mapleader = " "
vim.g.maplocalleader = " "

_G.dump = function(...)
  print(vim.inspect(...))
end
require("vim._core.ui2").enable {}
require "options"
require "autocwd"
require "configs.pack"
require "configs.ui"
require "configs.conform"
require "configs.lspconfig"
require "mappings"
