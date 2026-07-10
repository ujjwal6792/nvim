local M = {}

function M.toggle(opts)
  local mode = opts.mode
  vim.fn.system("python3 /Users/ace/.config/herdr/toggle-pane.py " .. mode)
end

return M
