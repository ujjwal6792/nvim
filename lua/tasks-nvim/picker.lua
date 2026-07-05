local parser = require("tasks-nvim.parser")
local preview = require("tasks-nvim.preview")
local picker_actions = require("tasks-nvim.actions")

local M = {}

local function get_relative_time(completed_at)
  if not completed_at or completed_at == vim.NIL or completed_at == "" then
    return ""
  end
  local y, m, d, h, min = completed_at:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d)%:(%d%d)")
  if not y then return completed_at end
  
  local completed_time = os.time({
    year = tonumber(y),
    month = tonumber(m),
    day = tonumber(d),
    hour = tonumber(h),
    min = tonumber(min),
  })
  
  local diff = os.time() - completed_time
  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    return math.floor(diff / 60) .. "m ago"
  elseif diff < 86400 then
    return math.floor(diff / 3600) .. "h ago"
  else
    return math.floor(diff / 86400) .. "d ago"
  end
end

function M.open(opts)
  if not pcall(require, "snacks") then
    vim.notify("Snacks.nvim is required for tasks-nvim picker", vim.log.levels.ERROR)
    return
  end
  
  opts = opts or {}
  local tasks_file = parser.find_tasks_file()
  if not tasks_file then
    vim.notify("Could not find tasks.jsonl file!", vim.log.levels.ERROR)
    return
  end

  local tasks, err_or_header = parser.parse_tasks(tasks_file)
  if not tasks then
    vim.notify("Failed to parse tasks: " .. tostring(err_or_header), vim.log.levels.ERROR)
    return
  end
  
  local header = err_or_header

  local filtered_tasks = {}
  local current_sprint = nil
  for _, task in ipairs(tasks) do
    if task.status ~= "done" and task.sprint then
      current_sprint = task.sprint
      break
    end
  end

  for _, task in ipairs(tasks) do
    local keep = true
    if opts.filter == "current_sprint" then
      keep = (task.sprint == current_sprint)
    elseif opts.filter == "in_progress" then
      keep = (task.status == "in_progress")
    elseif opts.filter == "blocked" then
      keep = (task.status == "blocked")
    elseif opts.filter == "done" then
      keep = (task.status == "done")
    end
    if keep then
      table.insert(filtered_tasks, task)
    end
  end

  local function sort_tasks(t1, t2)
    local p1 = t1.priority or "P2"
    local p2 = t2.priority or "P2"
    if p1 ~= p2 then return p1 < p2 end
    local s1 = t1.sprint or ""
    local s2 = t2.sprint or ""
    if s1 ~= s2 then return s1 < s2 end
    return (t1.id or "") < (t2.id or "")
  end

  local entries = {}
  local group_by = opts.group_by or "status"

  if group_by == "status" then
    local status_groups = {
      { name = "in_progress", title = "── ● IN PROGRESS", icon = "⚡" },
      { name = "blocked",     title = "── ● BLOCKED",     icon = "⛔" },
      { name = "todo",        title = "── ● TODO",        icon = "○" },
      { name = "done",        title = "── ✓ DONE",        icon = "✓" },
    }
    
    for _, group in ipairs(status_groups) do
      local group_tasks = {}
      for _, task in ipairs(filtered_tasks) do
        if task.status == group.name then
          table.insert(group_tasks, task)
        end
      end
      
      if #group_tasks > 0 then
        table.sort(group_tasks, sort_tasks)
        local sep_text = string.format("%s (%d) %s", group.title, #group_tasks, string.rep("─", 45))
        table.insert(entries, { is_separator = true, title = sep_text })
        for _, task in ipairs(group_tasks) do
          table.insert(entries, task)
        end
      end
    end
  elseif group_by == "epic" then
    local epic_map = {}
    for _, task in ipairs(filtered_tasks) do
      local epic = task.epic or "(no epic)"
      epic_map[epic] = epic_map[epic] or {}
      table.insert(epic_map[epic], task)
    end
    
    local epics = {}
    for name, _ in pairs(epic_map) do table.insert(epics, name) end
    table.sort(epics)
    
    for _, epic in ipairs(epics) do
      local epic_tasks = epic_map[epic]
      table.sort(epic_tasks, sort_tasks)
      local sep_text = string.format("── ❏ EPIC: %s (%d) %s", epic:upper(), #epic_tasks, string.rep("─", 40))
      table.insert(entries, { is_separator = true, title = sep_text })
      for _, task in ipairs(epic_tasks) do
        table.insert(entries, task)
      end
    end
  elseif group_by == "milestone" then
    local milestone_map = {}
    for _, task in ipairs(filtered_tasks) do
      local ms = task.milestone or "(no milestone)"
      milestone_map[ms] = milestone_map[ms] or {}
      table.insert(milestone_map[ms], task)
    end
    
    local milestones = {}
    for name, _ in pairs(milestone_map) do table.insert(milestones, name) end
    table.sort(milestones)
    
    for _, ms in ipairs(milestones) do
      local ms_tasks = milestone_map[ms]
      table.sort(ms_tasks, sort_tasks)
      local sep_text = string.format("── 🎯 MILESTONE: %s (%d) %s", ms:upper(), #ms_tasks, string.rep("─", 35))
      table.insert(entries, { is_separator = true, title = sep_text })
      for _, task in ipairs(ms_tasks) do
        table.insert(entries, task)
      end
    end
  else
    table.sort(filtered_tasks, sort_tasks)
    for _, task in ipairs(filtered_tasks) do
      table.insert(entries, task)
    end
  end

  local items = {}
  for _, entry in ipairs(entries) do
    if entry.is_separator then
      table.insert(items, {
        text = entry.title,
        task = entry,
      })
    else
      local icon = "○"
      local hl = "String"
      if entry.status == "in_progress" then icon = "⚡"; hl = "WarningMsg"
      elseif entry.status == "blocked" then icon = "⛔"; hl = "ErrorMsg"
      elseif entry.status == "done" then icon = "✓"; hl = "Comment" end

      local time_col = entry.sprint or ""
      if entry.status == "done" then
        time_col = get_relative_time(entry.completed_at)
      end
      
      local filter_text = string.format("%s %s %s %s %s %s",
        entry.id or "", entry.title or "", entry.epic or "", entry.milestone or "", entry.sprint or "", entry.status or ""
      )

      table.insert(items, {
        text = filter_text,
        task = entry,
        _icon = icon,
        _icon_hl = hl,
        _id = entry.id or "",
        _priority = entry.priority or "P2",
        _time = time_col,
        _title = entry.title or "",
        tasks_file = tasks_file,
        picker_opts = opts,
      })
    end
  end

  Snacks.picker.pick({
    title = string.format("Project Tasks (%s)", header.project or "tasks.jsonl"),
    items = items,
    format = function(item, picker)
      if item.task.is_separator then
        return { { item.task.title, "Comment" } }
      end
      return {
        { item._icon, item._icon_hl },
        { " " },
        { string.format("%-2s", item._priority), "Type" },
        { " " },
        { string.format("%-10s", item._id), "Identifier" },
        { " " },
        { string.format("%-10s", item._time), "Comment" },
        { " " },
        { item._title, item.task.status == "done" and "Comment" or "Normal" }
      }
    end,
    preview = function(ctx)
      local bufnr = ctx.buf
      vim.bo[bufnr].modifiable = true
      vim.bo[bufnr].filetype = "markdown"
      if ctx.item.task.is_separator then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
          "",
          "  " .. ctx.item.task.title,
          "",
          "  Use arrow keys to navigate to individual tasks."
        })
        vim.bo[bufnr].modifiable = false
        return
      end
      
      local card_lines = preview.render_card(ctx.item.task)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, card_lines)
      preview.apply_highlights(bufnr, card_lines)
      vim.bo[bufnr].modifiable = false
    end,
    confirm = picker_actions.jump_to_task,
    win = {
      input = {
        keys = {
          ["<c-s>"] = { "cycle_status", mode = { "i", "n" } },
          ["<c-e>"] = { "open_file_target", mode = { "i", "n" } },
          ["<c-d>"] = { "delete_task", mode = { "i", "n" } },
          ["<c-y>"] = { "copy_id", mode = { "i", "n" } },
        }
      }
    },
    actions = {
      cycle_status = picker_actions.cycle_status,
      open_file_target = picker_actions.open_file_target,
      delete_task = picker_actions.delete_task,
      copy_id = picker_actions.copy_id,
    },
  })
end

return M
