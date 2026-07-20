local ok, treesitter = pcall(require, "nvim-treesitter.config")
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
  ensure_installed = parsers,
  install_dir = vim.fn.stdpath "data" .. "/site",
}
vim.treesitter.language.register("json", "jsonl")
vim.treesitter.language.register("json", "jsonld")
vim.treesitter.language.register("bash", "dotenv")

-- ensure_installed above handles parser installation automatically

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
