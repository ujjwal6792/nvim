local namespace = vim.api.nvim_create_namespace("jsonl-planning-highlights")

local function value_range(line, key, value)
  local pattern = '"' .. key .. '"%s*:%s*"?()' .. vim.pesc(tostring(value)) .. '()"?'
  local first, last = line:match(pattern)
  return first and first - 1, last and last - 1
end

local function highlight(buf, line, start_col, end_col, group, extra)
  if start_col then
    vim.api.nvim_buf_set_extmark(buf, namespace, line, start_col, vim.tbl_extend("force", {
      end_col = end_col,
      hl_group = group,
    }, extra or {}))
  end
end

local function refresh(buf)
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  for index, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line ~= "" then
      local ok, record = pcall(vim.json.decode, line)
      if not ok or type(record) ~= "table" then
        highlight(buf, index - 1, 0, -1, "JsonlInvalid")
      else
        local status_groups = {
          todo = "JsonlStatusTodo",
          in_progress = "JsonlStatusInProgress",
          blocked = "JsonlStatusBlocked",
          done = "JsonlStatusDone",
        }
        local status = record.status
        if status_groups[status] then
          local start_col, end_col = value_range(line, "status", status)
          highlight(buf, index - 1, start_col, end_col, status_groups[status])
          local line_group = ({ in_progress = "JsonlLineInProgress", blocked = "JsonlLineBlocked", done = "JsonlLineDone" })[status]
          if line_group then
            highlight(buf, index - 1, 0, 0, line_group, { hl_eol = true, priority = 5 })
          end
        end
        if record.priority then
          local start_col, end_col = value_range(line, "priority", record.priority)
          highlight(buf, index - 1, start_col, end_col, "JsonlPriority" .. tostring(record.priority))
        end
        for key, group in pairs({ id = "JsonlTaskId", goal = "JsonlPointer", active_goal = "JsonlPointer", next_goal = "JsonlPointer" }) do
          if record[key] then
            local start_col, end_col = value_range(line, key, record[key])
            highlight(buf, index - 1, start_col, end_col, group)
          end
        end
        if record._type then
          local start_col, end_col = value_range(line, "_type", record._type)
          highlight(buf, index - 1, start_col, end_col, "JsonlSentinel")
        end
      end
    end
  end
end

refresh(0)
local group = vim.api.nvim_create_augroup("JsonlPlanningHighlights" .. vim.api.nvim_get_current_buf(), { clear = true })
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
  group = group,
  buffer = 0,
  callback = function(args) refresh(args.buf) end,
})
