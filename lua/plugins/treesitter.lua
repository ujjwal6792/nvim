local ok, treesitter = pcall(require, "nvim-treesitter.configs")
if not ok then
  return
end

local parsers = {
  "astro",
  "scss",
  "svelte",
  "vim",
  "lua",
  "html",
  "css",
  "json",
  "javascript",
  "typescript",
  "tsx",
  "prisma",
  "go",
  "c",
  "cpp",
  "rust",
  "proto",
  "markdown",
  "markdown_inline",
  "bash",
  "dockerfile",
}

treesitter.setup {
  install_dir = vim.fn.stdpath "data" .. "/site",
  -- Depending on nvim-treesitter version, you might also want ensure_installed here
}
vim.treesitter.language.register("json", "jsonl")
vim.treesitter.language.register("json", "jsonld")
vim.treesitter.language.register("bash", "dotenv")

local ts_install = require "nvim-treesitter.install"
if vim.fn.executable "tree-sitter" == 1 then
  ts_install.ensure_installed(parsers)
else
  vim.schedule(function()
    vim.notify("Install tree-sitter CLI to enable missing Treesitter parsers and folds", vim.log.levels.WARN)
  end)
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.wo.foldmethod = "expr"
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
