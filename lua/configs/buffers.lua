local M = {}

local protected_filetypes = {
  NvimTree = true,
}

local protected_buftypes = {
  terminal = true,
  nofile = true,
  prompt = true,
  quickfix = true,
  help = true,
}

local function is_protected_buffer(buf)
  return protected_filetypes[vim.bo[buf].filetype] or protected_buftypes[vim.bo[buf].buftype]
end

local function is_work_buffer(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and not is_protected_buffer(buf)
end

local function work_windows()
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if is_work_buffer(buf) then
      table.insert(wins, win)
    end
  end
  return wins
end

local function listed_work_buffers()
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_work_buffer(buf) then
      table.insert(buffers, buf)
    end
  end
  table.sort(buffers)
  return buffers
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

local function nvimtree_windows()
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "NvimTree" then
      table.insert(wins, win)
    end
  end
  return wins
end

local function close_nvimtree_windows()
  for _, win in ipairs(nvimtree_windows()) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

local function open_dashboard(replace_buf)
  local ok, starter = pcall(require, "mini.starter")
  if ok then
    local dashboard = vim.api.nvim_create_buf(false, true)
    starter.open(dashboard)
    if vim.api.nvim_buf_is_valid(replace_buf) then
      pcall(vim.api.nvim_buf_delete, replace_buf, {})
    end
    return
  end

  vim.cmd "enew"
  vim.bo.buflisted = false
  if vim.api.nvim_buf_is_valid(replace_buf) then
    pcall(vim.api.nvim_buf_delete, replace_buf, {})
  end
end

function M.keep_nvimtree_width()
  vim.schedule(function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(win) then
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "NvimTree" then
          vim.api.nvim_win_set_width(win, 30)
        end
      end
    end
  end)
end

function M.focus_work_window()
  local current = vim.api.nvim_get_current_win()
  if vim.tbl_contains(work_windows(), current) then
    return current
  end

  local wins = work_windows()
  if #wins > 0 then
    vim.api.nvim_set_current_win(wins[1])
    return wins[1]
  end

  M.keep_nvimtree_width()
end

function M.open_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  for _, win in ipairs(work_windows()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  local current = vim.api.nvim_get_current_win()
  local target = current
  if is_protected_buffer(vim.api.nvim_win_get_buf(current)) then
    target = M.focus_work_window()
  end

  if not target then
    return
  end

  vim.api.nvim_set_current_win(target)
  vim.api.nvim_win_set_buf(target, buf)
  M.keep_nvimtree_width()
end

function M.pick_work_window()
  local current = vim.api.nvim_get_current_win()
  if not is_protected_buffer(vim.api.nvim_win_get_buf(current)) then
    return current
  end

  local wins = work_windows()
  if #wins > 0 then
    return wins[1]
  end

  M.keep_nvimtree_width()
end

function M.pick_file_open_window()
  local target = M.pick_work_window()
  if target then
    return target
  end

  vim.cmd "rightbelow vnew"
  M.keep_nvimtree_width()
  return vim.api.nvim_get_current_win()
end

function M.close_current()
  local current = vim.api.nvim_get_current_buf()
  local current_win = vim.api.nvim_get_current_win()

  if is_protected_buffer(current) then
    M.focus_work_window()
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
  local wins = work_windows()

  if #wins > 1 then
    local focus_after
    for _, win in ipairs(wins) do
      if win ~= current_win then
        focus_after = win
        break
      end
    end

    vim.api.nvim_win_close(current_win, true)
    if focus_after and vim.api.nvim_win_is_valid(focus_after) then
      vim.api.nvim_set_current_win(focus_after)
    else
      M.focus_work_window()
    end
    vim.cmd.bdelete(current)
    M.keep_nvimtree_width()
    return
  end

  if target then
    vim.api.nvim_win_set_buf(current_win, target)
  else
    close_nvimtree_windows()
    open_dashboard(current)
    return
  end

  vim.cmd.bdelete(current)
  M.keep_nvimtree_width()
end

return M
