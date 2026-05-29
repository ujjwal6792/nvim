local M = {}

local group = vim.api.nvim_create_augroup("AutoReadExternalChanges", { clear = true })
local timer

local function normal_file_buffer(buf)
  if not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].buftype ~= "" or vim.bo[buf].modified then
    return false
  end

  return vim.api.nvim_buf_get_name(buf) ~= ""
end

local function refresh_tree()
  if vim.fn.exists ":NvimTreeRefresh" == 2 then
    vim.cmd "silent! NvimTreeRefresh"
  end
end

function M.sync()
  if vim.v.exiting ~= vim.NIL or vim.fn.mode():match "^[csR]" then
    return
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if normal_file_buffer(buf) then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd "silent! checktime"
      end)
    end
  end

  refresh_tree()
end

function M.schedule(delay)
  delay = delay or 250
  if timer then
    timer:stop()
  else
    timer = vim.uv.new_timer()
  end

  timer:start(delay, 0, vim.schedule_wrap(M.sync))
end

vim.api.nvim_create_autocmd({
  "BufEnter",
  "CursorHold",
  "CursorHoldI",
  "FocusGained",
  "ShellCmdPost",
  "TermClose",
  "TermLeave",
}, {
  group = group,
  callback = function()
    M.schedule()
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = group,
  callback = function(args)
    local name = vim.api.nvim_buf_get_name(args.buf)
    if name ~= "" then
      vim.notify("Reloaded " .. vim.fn.fnamemodify(name, ":~:."), vim.log.levels.INFO)
    end
    refresh_tree()
  end,
})

return M
