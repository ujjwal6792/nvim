local M = {}

function M.find(start)
  local path = start or vim.api.nvim_buf_get_name(0)
  local directory = vim.fn.isdirectory(path) == 1 and path or (path ~= "" and vim.fs.dirname(path) or vim.fn.getcwd())
  if vim.fn.isdirectory(directory) == 0 then directory = vim.fn.getcwd() end
  local marker = vim.fs.find("resources/planning/GOALS.md", { path = directory, upward = true })[1]
  return marker and vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(marker))) or nil
end

return M
