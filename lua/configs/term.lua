local api = vim.api

local M = {}
local terms = {}

local defaults = {
  startinsert = true,
  winopts = {
    number = false,
    relativenumber = false,
    winhl = "Normal:NormalFloat,WinSeparator:WinSeparator",
  },
  sizes = { sp = 0.5, vsp = 0.5 },
  float = {
    relative = "editor",
    row = 0.035,
    col = 0.035,
    width = 0.9,
    height = 0.9,
    border = "single",
  },
}

local pos_data = {
  sp = { resize = "height", area = "lines" },
  vsp = { resize = "width", area = "columns" },
}

local function is_work_window(win)
  local target_win = (win == 0 or win == nil) and api.nvim_get_current_win() or win
  if not api.nvim_win_is_valid(target_win) then
    return false
  end
  local buf = api.nvim_win_get_buf(target_win)
  return vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "NvimTree"
end

local function focus_work_window()
  if is_work_window(0) then
    return
  end

  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if is_work_window(win) and (api.nvim_win_get_config(win).relative or "") == "" then
      api.nvim_set_current_win(win)
      return
    end
  end

  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    local buf = api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    local rel = api.nvim_win_get_config(win).relative or ""
    if ft ~= "NvimTree" and rel == "" then
      api.nvim_set_current_win(win)
      return
    end
  end
end

local function format_cmd(cmd)
  return type(cmd) == "function" and cmd() or cmd
end

local function apply_winopts(win, opts)
  for key, value in pairs(vim.tbl_extend("force", defaults.winopts, opts.winopts or {})) do
    vim.wo[win][key] = value
  end
end

local function create_float(buf, opts)
  local float = vim.tbl_deep_extend("force", defaults.float, opts.float_opts or {})
  float.width = math.ceil(float.width * vim.o.columns)
  float.height = math.ceil(float.height * vim.o.lines)
  float.row = math.ceil(float.row * vim.o.lines)
  float.col = math.ceil(float.col * vim.o.columns)
  return api.nvim_open_win(buf, true, float)
end

function M.display(opts)
  if opts.pos == "float" then
    opts.win = create_float(opts.buf, opts)
  else
    focus_work_window()
    vim.cmd(opts.pos)
    opts.win = api.nvim_get_current_win()
    local pos_type = pos_data[opts.pos]
    local size = opts.size or defaults.sizes[opts.pos]
    if pos_type and size then
      api["nvim_win_set_" .. pos_type.resize](opts.win, math.floor(vim.o[pos_type.area] * size))
    end
  end

  api.nvim_win_set_buf(opts.win, opts.buf)
  vim.bo[opts.buf].buflisted = false
  vim.bo[opts.buf].filetype = "terminal"
  apply_winopts(opts.win, opts)

  if defaults.startinsert then
    vim.cmd "startinsert"
  end

  if opts.id then
    terms[opts.id] = opts
  end
end

local function create(opts)
  opts.buf = opts.buf or api.nvim_create_buf(false, true)
  M.display(opts)

  if not vim.b[opts.buf].terminal_job_id then
    local shell = vim.o.shell
    local cmd = opts.cmd and { shell, "-c", format_cmd(opts.cmd) .. "; " .. shell } or { shell }
    vim.fn.termopen(cmd, vim.tbl_extend("force", opts.termopen_opts or {}, { detach = false }))
  end
end

function M.new(opts)
  create(opts)
end

function M.toggle(opts)
  local current = terms[opts.id]
  local is_target_visible = current and current.buf and api.nvim_buf_is_valid(current.buf) and vim.fn.bufwinid(current.buf) ~= -1

  for id, term in pairs(terms) do
    if id ~= opts.id then
      local win = term.buf and api.nvim_buf_is_valid(term.buf) and vim.fn.bufwinid(term.buf) or -1
      if win ~= -1 and api.nvim_win_is_valid(win) then
        pcall(api.nvim_win_close, win, true)
      end
    end
  end

  if is_target_visible then
    local win = vim.fn.bufwinid(current.buf)
    if win ~= -1 and api.nvim_win_is_valid(win) then
      pcall(api.nvim_win_close, win, true)
    end
  else
    opts.buf = current and current.buf or nil
    create(opts)
  end
end

function M.runner(opts)
  local current = terms[opts.id]
  opts.buf = current and current.buf or nil

  if not current or not api.nvim_buf_is_valid(current.buf) then
    create(opts)
  else
    if vim.fn.bufwinid(current.buf) == -1 then
      M.display(vim.tbl_extend("force", current, opts))
    end

    local job_id = vim.b[current.buf].terminal_job_id
    if job_id then
      local clear_cmd = opts.clear_cmd
      if clear_cmd == nil then
        clear_cmd = "clear; "
      elseif clear_cmd == false then
        clear_cmd = ""
      end
      vim.api.nvim_chan_send(job_id, clear_cmd .. format_cmd(opts.cmd) .. "\n")
    end
  end
end

api.nvim_create_autocmd("TermClose", {
  callback = function(args)
    for id, term in pairs(terms) do
      if term.buf == args.buf then
        terms[id] = nil
      end
    end
    if vim.api.nvim_buf_is_valid(args.buf) then
      vim.bo[args.buf].bufhidden = "wipe"
      local win = vim.fn.bufwinid(args.buf)
      if win ~= -1 then
        vim.api.nvim_win_close(win, true)
      end
    end
  end,
})

return M
