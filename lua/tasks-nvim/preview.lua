local M = {}

local function add_line(lines, text)
  table.insert(lines, text)
end

function M.render_card(task)
  local lines = {}
  add_line(lines, "╭─ " .. task.id .. " ───────────────────────────────────────────────────╮")
  add_line(lines, "│ " .. task.title)
  add_line(lines, "│ ")
  add_line(lines, string.format("│ Status:    %-12s    Priority: %-2s", task.status, task.priority or "P2"))
  add_line(lines, string.format("│ Sprint:    %-12s    Epic:     %-20s", task.sprint or "(none)", task.epic or "(none)"))
  add_line(lines, string.format("│ Milestone: %-12s    Effort:   %s", task.milestone or "(none)", task.effort_hours and (task.effort_hours .. "h") or "(none)"))
  
  local blocked_by_str = "(none)"
  if task.blocked_by and #task.blocked_by > 0 then
    blocked_by_str = table.concat(task.blocked_by, ", ")
  end
  add_line(lines, "│ Blocked by: " .. blocked_by_str)
  
  if task.completed_at and task.completed_at ~= vim.NIL and task.completed_at ~= "" then
    add_line(lines, "│ Completed:  " .. task.completed_at)
  end
  
  add_line(lines, "│ ")
  
  -- Description
  add_line(lines, "│ ── Description ─────────────────────────────────────────── ")
  if task.description then
    -- wrap description lines
    for desc_line in task.description:gmatch("[^\r\n]+") do
      local remaining = desc_line
      while #remaining > 60 do
        local chunk = remaining:sub(1, 60)
        -- try to split at last space
        local last_space = chunk:match("^.*()%s")
        if last_space and last_space > 10 then
          chunk = remaining:sub(1, last_space - 1)
          remaining = remaining:sub(last_space + 1)
        else
          remaining = remaining:sub(61)
        end
        add_line(lines, "│   " .. chunk)
      end
      if remaining ~= "" then
        add_line(lines, "│   " .. remaining)
      end
    end
  end
  
  -- File Targets
  if task.file_targets and #task.file_targets > 0 then
    add_line(lines, "│ ")
    add_line(lines, "│ ── File Targets ────────────────────────────────────────── ")
    for _, ft in ipairs(task.file_targets) do
      add_line(lines, "│   " .. ft)
    end
  end

  -- Notes
  if task.notes and task.notes ~= "" then
    add_line(lines, "│ ")
    add_line(lines, "│ ── Notes ───────────────────────────────────────────────── ")
    for note_line in task.notes:gmatch("[^\r\n]+") do
      local remaining = note_line
      while #remaining > 60 do
        local chunk = remaining:sub(1, 60)
        local last_space = chunk:match("^.*()%s")
        if last_space and last_space > 10 then
          chunk = remaining:sub(1, last_space - 1)
          remaining = remaining:sub(last_space + 1)
        else
          remaining = remaining:sub(61)
        end
        add_line(lines, "│   " .. chunk)
      end
      if remaining ~= "" then
        add_line(lines, "│   " .. remaining)
      end
    end
  end

  add_line(lines, "╰─────────────────────────────────────────────────────────────╯")
  return lines
end

function M.apply_highlights(bufnr, lines)
  vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
  
  local in_file_targets = false
  local in_description = false
  local in_notes = false
  
  for idx, line in ipairs(lines) do
    local line_num = idx - 1
    
    -- Highlight borders and titles
    if line:match("^╭─") or line:match("^╰─") then
      vim.api.nvim_buf_add_highlight(bufnr, -1, "FloatBorder", line_num, 0, -1)
    elseif line:match("^│%s*──") then
      vim.api.nvim_buf_add_highlight(bufnr, -1, "WhichKeySeparator", line_num, 0, -1)
      
      -- Reset section flags
      in_file_targets = line:match("File Targets") ~= nil
      in_description = line:match("Description") ~= nil
      in_notes = line:match("Notes") ~= nil
      
    elseif line:match("^│%s*Status:") then
      -- Status Label
      vim.api.nvim_buf_add_highlight(bufnr, -1, "WhichKey", line_num, 2, 9)
      
      -- Status Value
      local status = line:match("Status:%s*([%w_]+)")
      if status then
        local hl = "JsonlStatusTodo"
        if status == "in_progress" then hl = "JsonlStatusInProgress"
        elseif status == "blocked" then hl = "JsonlStatusBlocked"
        elseif status == "done" then hl = "JsonlStatusDone" end
        local start_col = line:find("Status:") + 7
        while line:sub(start_col, start_col) == " " do start_col = start_col + 1 end
        vim.api.nvim_buf_add_highlight(bufnr, -1, hl, line_num, start_col - 1, start_col + #status - 1)
      end
      
      -- Priority Label
      vim.api.nvim_buf_add_highlight(bufnr, -1, "WhichKey", line_num, 29, 38)
      
      -- Priority Value
      local priority = line:match("Priority:%s*(P%d)")
      if priority then
        local hl = "JsonlPriorityP2"
        if priority == "P0" then hl = "JsonlPriorityP0"
        elseif priority == "P1" then hl = "JsonlPriorityP1"
        elseif priority == "P2" then hl = "JsonlPriorityP2"
        elseif priority == "P3" then hl = "JsonlPriorityP3" end
        local start_col = line:find("Priority:") + 9
        while line:sub(start_col, start_col) == " " do start_col = start_col + 1 end
        vim.api.nvim_buf_add_highlight(bufnr, -1, hl, line_num, start_col - 1, start_col + #priority - 1)
      end
      
    elseif line:match("^│%s*Sprint:") then
      vim.api.nvim_buf_add_highlight(bufnr, -1, "WhichKey", line_num, 2, 9)
      local sprint = line:match("Sprint:%s*([%w%-]+)")
      if sprint and sprint ~= "(none)" then
        vim.api.nvim_buf_add_highlight(bufnr, -1, "JsonlSprint", line_num, 15, 15 + #sprint)
      end
      
      vim.api.nvim_buf_add_highlight(bufnr, -1, "WhichKey", line_num, 29, 34)
      local epic = line:match("Epic:%s*([%w%-]+)")
      if epic and epic ~= "(none)" then
        vim.api.nvim_buf_add_highlight(bufnr, -1, "JsonlTaskId", line_num, 44, 44 + #epic)
      end
      
    elseif line:match("^│%s*Milestone:") then
      vim.api.nvim_buf_add_highlight(bufnr, -1, "WhichKey", line_num, 2, 12)
      local milestone = line:match("Milestone:%s*([%w%-]+)")
      if milestone and milestone ~= "(none)" then
        vim.api.nvim_buf_add_highlight(bufnr, -1, "JsonlMilestone", line_num, 15, 15 + #milestone)
      end
      
      vim.api.nvim_buf_add_highlight(bufnr, -1, "WhichKey", line_num, 29, 36)
      
    elseif line:match("^│%s*Blocked by:") then
      vim.api.nvim_buf_add_highlight(bufnr, -1, "WhichKey", line_num, 2, 12)
      
    elseif line:match("^│%s*Completed:") then
      vim.api.nvim_buf_add_highlight(bufnr, -1, "WhichKey", line_num, 2, 12)
      local completed = line:match("Completed:%s*(.+)")
      if completed then
        vim.api.nvim_buf_add_highlight(bufnr, -1, "JsonlCompletedAt", line_num, 15, 15 + #completed)
      end
      
    elseif line:match("^│%s+") then
      -- Highlight content lines based on section
      if in_file_targets then
        vim.api.nvim_buf_add_highlight(bufnr, -1, "Directory", line_num, 4, -1)
      elseif in_notes then
        vim.api.nvim_buf_add_highlight(bufnr, -1, "Comment", line_num, 4, -1)
      end
    end
  end
end

return M
