local M = {}

function M.find_tasks_file()
  -- Search upwards from CWD
  local current_dir = vim.fn.getcwd()
  while current_dir and current_dir ~= "/" and current_dir ~= "" do
    local possible_paths = {
      current_dir .. "/resources/tasks.jsonl",
      current_dir .. "/tasks.jsonl",
    }
    for _, path in ipairs(possible_paths) do
      if vim.fn.filereadable(path) == 1 then
        return path
      end
    end
    current_dir = vim.fn.fnamemodify(current_dir, ":h")
  end
  -- Fallback to workspace/notes
  local fallback = vim.fn.expand("~/notes/Auth-Center/tasks.jsonl")
  if vim.fn.filereadable(fallback) == 1 then
    return fallback
  end
  return nil
end

function M.verify_tasks_file(path)
  if not path or vim.fn.filereadable(path) == 0 then
    return false, "File not readable"
  end
  local file = io.open(path, "r")
  if not file then
    return false, "Cannot open file"
  end
  local first_line = file:read("*l")
  file:close()
  if not first_line then
    return false, "Empty file"
  end
  local ok, decoded = pcall(vim.fn.json_decode, first_line)
  if not ok then
    return false, "First line is not valid JSON"
  end
  if decoded._type ~= "tasks-v1" then
    return false, "Invalid sentinel type: " .. tostring(decoded._type)
  end
  return true, decoded
end

function M.parse_tasks(path)
  local is_valid, header_or_err = M.verify_tasks_file(path)
  if not is_valid then
    return nil, header_or_err
  end

  local file = io.open(path, "r")
  if not file then
    return nil, "Cannot open file"
  end

  local tasks = {}
  local line_num = 1
  -- skip header
  file:read("*l")

  while true do
    line_num = line_num + 1
    local line = file:read("*l")
    if not line then
      break
    end
    if line ~= "" then
      local ok, task = pcall(vim.fn.json_decode, line)
      if ok and task and task.id then
        task._line_num = line_num
        task._raw_line = line
        table.insert(tasks, task)
      end
    end
  end
  file:close()
  return tasks, header_or_err
end

function M.write_tasks(path, header, tasks)
  local file = io.open(path, "w")
  if not file then
    return false, "Cannot open file for writing"
  end

  -- Update header updated_at timestamp
  header.updated_at = os.date("%Y-%m-%dT%H:%M:%S+05:30")
  file:write(vim.fn.json_encode(header) .. "\n")

  for _, task in ipairs(tasks) do
    local clean_task = {}
    for k, v in pairs(task) do
      if not k:match("^_.+$") then
        clean_task[k] = v
      end
    end
    file:write(vim.fn.json_encode(clean_task) .. "\n")
  end
  file:close()
  return true
end

function M.update_task_status(path, task_id, new_status)
  local tasks, header = M.parse_tasks(path)
  if not tasks then
    return false, header
  end

  local found = false
  for _, task in ipairs(tasks) do
    if task.id == task_id then
      task.status = new_status
      if new_status == "done" then
        task.completed_at = os.date("%Y-%m-%dT%H:%M:%S+05:30")
      else
        task.completed_at = vim.NIL
      end
      found = true
      break
    end
  end

  if not found then
    return false, "Task not found"
  end
  return M.write_tasks(path, header, tasks)
end

return M
