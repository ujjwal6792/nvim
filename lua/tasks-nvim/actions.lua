local M = {}

local parser = require("tasks-nvim.parser")

function M.jump_to_task(picker, item)
  if not item or item.task.is_separator then return end
  local task = item.task
  local tasks_file = item.tasks_file
  
  picker:close()
  vim.cmd("edit " .. vim.fn.fnameescape(tasks_file))
  vim.api.nvim_win_set_cursor(0, { task._line_num, 0 })
end

function M.cycle_status(picker, item)
  if not item or item.task.is_separator then return end
  local task = item.task
  local tasks_file = item.tasks_file
  local picker_opts = item.picker_opts
  
  local statuses = { "todo", "in_progress", "blocked", "done" }
  vim.ui.select(statuses, {
    prompt = "Select new status for " .. task.id .. ":",
    format_item = function(choice)
      return choice:upper():gsub("_", " ")
    end,
  }, function(choice)
    if not choice then return end
    local ok, err = parser.update_task_status(tasks_file, task.id, choice)
    if ok then
      vim.notify("Updated " .. task.id .. " to " .. choice)
      picker:close()
      vim.schedule(function()
        require("tasks-nvim.picker").open(picker_opts)
      end)
    else
      vim.notify("Failed to update status: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

function M.open_file_target(picker, item)
  if not item or item.task.is_separator then return end
  local task = item.task
  if not task.file_targets or #task.file_targets == 0 then
    vim.notify("No file targets specified for task " .. task.id, vim.log.levels.WARN)
    return
  end
  
  local first_target = task.file_targets[1]
  local tasks_file = item.tasks_file
  local tasks_dir = vim.fn.fnamemodify(tasks_file, ":h")
  if tasks_dir:match("/resources$") then
    tasks_dir = vim.fn.fnamemodify(tasks_dir, ":h")
  end
  
  local full_path = tasks_dir .. "/" .. first_target
  picker:close()
  
  if vim.fn.filereadable(full_path) == 1 or vim.fn.isdirectory(full_path) == 1 then
    vim.cmd("vsplit " .. vim.fn.fnameescape(full_path))
  else
    vim.notify("File target not readable: " .. first_target, vim.log.levels.ERROR)
  end
end

function M.delete_task(picker, item)
  if not item or item.task.is_separator then return end
  local task = item.task
  local tasks_file = item.tasks_file
  local picker_opts = item.picker_opts
  
  vim.ui.input({
    prompt = "Are you sure you want to delete task " .. task.id .. "? (y/N) ",
  }, function(input)
    if not input or input:lower() ~= "y" then return end
    local tasks, header = parser.parse_tasks(tasks_file)
    if not tasks then return end
    
    local new_tasks = {}
    for _, t in ipairs(tasks) do
      if t.id ~= task.id then table.insert(new_tasks, t) end
    end
    
    local ok, err = parser.write_tasks(tasks_file, header, new_tasks)
    if ok then
      vim.notify("Deleted task " .. task.id)
      picker:close()
      vim.schedule(function()
        require("tasks-nvim.picker").open(picker_opts)
      end)
    else
      vim.notify("Failed to delete task: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

function M.copy_id(picker, item)
  if not item or item.task.is_separator then return end
  vim.fn.setreg("+", item.task.id)
  vim.fn.setreg('"', item.task.id)
  vim.notify("Copied task ID: " .. item.task.id)
end

return M
