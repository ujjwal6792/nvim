vim.g.mapleader = " "
vim.g.maplocalleader = " "

_G.dump = function(...)
  print(vim.inspect(...))
end

require "options"
require "autocwd"
require "configs.pack"
require "configs.ui"
require "configs.conform"
require "configs.lspconfig"
require "mappings"
