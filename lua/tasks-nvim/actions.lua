local M = {}

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local parser = require("tasks-nvim.parser")

function M.jump_to_task(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if not selection or selection.value.is_separator then
    return
  end
  
  local task = selection.value
  local tasks_file = selection.tasks_file
  
  actions.close(prompt_bufnr)
  
  vim.cmd("edit " .. vim.fn.fnameescape(tasks_file))
  vim.api.nvim_win_set_cursor(0, { task._line_num, 0 })
end

function M.cycle_status(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if not selection or selection.value.is_separator then
    return
  end
  
  local task = selection.value
  local tasks_file = selection.tasks_file
  local picker_opts = selection.picker_opts
  
  local statuses = { "todo", "in_progress", "blocked", "done" }
  vim.ui.select(statuses, {
    prompt = "Select new status for " .. task.id .. ":",
    format_item = function(item)
      return item:upper():gsub("_", " ")
    end,
  }, function(choice)
    if not choice then return end
    
    local ok, err = parser.update_task_status(tasks_file, task.id, choice)
    if ok then
      vim.notify("Updated " .. task.id .. " to " .. choice)
      actions.close(prompt_bufnr)
      vim.schedule(function()
        require("tasks-nvim.picker").open(picker_opts)
      end)
    else
      vim.notify("Failed to update status: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

function M.open_file_target(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if not selection or selection.value.is_separator then
    return
  end
  
  local task = selection.value
  if not task.file_targets or #task.file_targets == 0 then
    vim.notify("No file targets specified for task " .. task.id, vim.log.levels.WARN)
    return
  end
  
  local first_target = task.file_targets[1]
  local tasks_file = selection.tasks_file
  local tasks_dir = vim.fn.fnamemodify(tasks_file, ":h")
  if tasks_dir:match("/resources$") then
    tasks_dir = vim.fn.fnamemodify(tasks_dir, ":h")
  end
  
  local full_path = tasks_dir .. "/" .. first_target
  
  actions.close(prompt_bufnr)
  
  if vim.fn.filereadable(full_path) == 1 or vim.fn.isdirectory(full_path) == 1 then
    vim.cmd("vsplit " .. vim.fn.fnameescape(full_path))
  else
    vim.notify("File target not readable: " .. first_target, vim.log.levels.ERROR)
  end
end

function M.delete_task(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if not selection or selection.value.is_separator then
    return
  end
  
  local task = selection.value
  local tasks_file = selection.tasks_file
  local picker_opts = selection.picker_opts
  
  vim.ui.input({
    prompt = "Are you sure you want to delete task " .. task.id .. "? (y/N) ",
  }, function(input)
    if not input or input:lower() ~= "y" then
      return
    end
    
    local tasks, header = parser.parse_tasks(tasks_file)
    if not tasks then
      vim.notify("Failed to parse tasks: " .. tostring(header), vim.log.levels.ERROR)
      return
    end
    
    local new_tasks = {}
    for _, t in ipairs(tasks) do
      if t.id ~= task.id then
        table.insert(new_tasks, t)
      end
    end
    
    local ok, err = parser.write_tasks(tasks_file, header, new_tasks)
    if ok then
      vim.notify("Deleted task " .. task.id)
      actions.close(prompt_bufnr)
      vim.schedule(function()
        require("tasks-nvim.picker").open(picker_opts)
      end)
    else
      vim.notify("Failed to delete task: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

function M.copy_id(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if not selection or selection.value.is_separator then
    return
  end
  
  local task = selection.value
  vim.fn.setreg("+", task.id)
  vim.fn.setreg('"', task.id)
  vim.notify("Copied task ID: " .. task.id)
end

return M
