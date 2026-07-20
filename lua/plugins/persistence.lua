local ok, persistence = pcall(require, "persistence")
if not ok then
  return
end

persistence.setup({
  -- default options
  dir = vim.fn.stdpath("state") .. "/sessions/",
  need = 2,
  branch = true,
})
