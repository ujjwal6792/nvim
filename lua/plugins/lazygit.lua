local lazygit_group = vim.api.nvim_create_augroup("LazyGitChecktime", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = lazygit_group,
  pattern = "LazyGitExit",
  callback = function()
    require("configs.autoread").sync()
  end,
})
