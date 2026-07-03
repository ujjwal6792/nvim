local M = {}

local parser = require("tasks-nvim.parser")
local picker = require("tasks-nvim.picker")

function M.setup(opts)
  -- Create user commands
  vim.api.nvim_create_user_command("TasksOpen", function(args)
    local group = nil
    local filter = nil
    if args.args ~= "" then
      for arg in args.args:gmatch("%S+") do
        if arg:match("^group_by=") then
          group = arg:match("^group_by=(.+)")
        elseif arg:match("^filter=") then
          filter = arg:match("^filter=(.+)")
        end
      end
    end
    picker.open({ group_by = group, filter = filter })
  end, {
    nargs = "*",
    complete = function(arg_lead)
      local options = { "group_by=status", "group_by=epic", "group_by=milestone", "filter=current_sprint", "filter=in_progress", "filter=blocked", "filter=done" }
      local results = {}
      for _, opt in ipairs(options) do
        if opt:match("^" .. vim.pesc(arg_lead)) then
          table.insert(results, opt)
        end
      end
      return results
    end,
  })

  vim.api.nvim_create_user_command("TasksNew", function()
    M.new_task()
  end, {})
end

function M.open(opts)
  picker.open(opts)
end

function M.new_task()
  local tasks_file = parser.find_tasks_file()
  if not tasks_file then
    vim.notify("Could not find tasks.jsonl file!", vim.log.levels.ERROR)
    return
  end
  
  local tasks, header = parser.parse_tasks(tasks_file)
  if not tasks then
    vim.notify("Failed to parse tasks file", vim.log.levels.ERROR)
    return
  end
  
  -- Step-by-step inputs
  vim.ui.input({ prompt = "Task ID (e.g. M3-1-1): " }, function(id)
    if not id or id == "" then return end
    
    vim.ui.input({ prompt = "Title: " }, function(title)
      if not title or title == "" then return end
      
      vim.ui.input({ prompt = "Priority (P0-P3, default P2): " }, function(priority)
        priority = (priority == "" and "P2" or priority)
        
        vim.ui.input({ prompt = "Sprint (e.g. 2026-W27): " }, function(sprint)
          vim.ui.input({ prompt = "Milestone (e.g. M3): " }, function(milestone)
            vim.ui.input({ prompt = "Epic: " }, function(epic)
              vim.ui.input({ prompt = "Description: " }, function(desc)
                vim.ui.input({ prompt = "File targets (comma separated): " }, function(files_str)
                  local file_targets = {}
                  if files_str and files_str ~= "" then
                    for file in files_str:gmatch("[^,]+") do
                      table.insert(file_targets, vim.trim(file))
                    end
                  end
                  
                  local new_task = {
                    id = id,
                    title = title,
                    priority = priority,
                    sprint = sprint ~= "" and sprint or nil,
                    milestone = milestone ~= "" and milestone or nil,
                    epic = epic ~= "" and epic or nil,
                    description = desc ~= "" and desc or "",
                    file_targets = file_targets,
                    blocked_by = {},
                    status = "todo",
                    assisted_by = vim.NIL,
                    completed_at = vim.NIL,
                    notes = ""
                  }
                  
                  table.insert(tasks, new_task)
                  local ok, err = parser.write_tasks(tasks_file, header, tasks)
                  if ok then
                    vim.notify("Task " .. id .. " created successfully!")
                  else
                    vim.notify("Failed to write new task: " .. tostring(err), vim.log.levels.ERROR)
                  end
                end)
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end

return M
