local M = {}

local function listed_work_buffers()
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "NvimTree" then
      table.insert(buffers, buf)
    end
  end
  table.sort(buffers)
  return buffers
end

local function focus_work_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "NvimTree" then
      vim.api.nvim_set_current_win(win)
      return buf
    end
  end
end

local function next_buffer_after(current, buffers)
  if #buffers == 0 then
    return
  end

  for index, buf in ipairs(buffers) do
    if buf == current then
      return buffers[index + 1] or buffers[index - 1]
    end
  end

  return buffers[1]
end

function M.close_current()
  local current = vim.api.nvim_get_current_buf()

  if vim.bo[current].filetype == "NvimTree" then
    focus_work_window()
    return
  end

  if vim.bo[current].modified then
    vim.notify("Buffer has unsaved changes", vim.log.levels.WARN)
    return
  end

  local candidates = vim.tbl_filter(function(buf)
    return buf ~= current
  end, listed_work_buffers())

  local target = next_buffer_after(current, candidates)
  if target then
    vim.cmd.buffer(target)
  else
    vim.cmd.enew()
    vim.bo.buflisted = true
  end

  vim.cmd.bdelete(current)
end

return M
