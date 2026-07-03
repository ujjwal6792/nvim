-- after/ftplugin/jsonl.lua
local function setup_jsonl_highlights()
  if vim.b.jsonl_matches then
    for _, id in ipairs(vim.b.jsonl_matches) do
      pcall(vim.fn.matchdelete, id)
    end
  end
  vim.b.jsonl_matches = {}

  local matches = {}

  -- 1. Status values (Priority 15 - Always colored)
  table.insert(matches, vim.fn.matchadd("JsonlStatusTodo", [["status"\s*:\s*"\zs\(todo\)\ze"]], 15))
  table.insert(matches, vim.fn.matchadd("JsonlStatusInProgress", [["status"\s*:\s*"\zs\(in_progress\)\ze"]], 15))
  table.insert(matches, vim.fn.matchadd("JsonlStatusBlocked", [["status"\s*:\s*"\zs\(blocked\)\ze"]], 15))
  table.insert(matches, vim.fn.matchadd("JsonlStatusDone", [["status"\s*:\s*"\zs\(done\)\ze"]], 15))

  -- 2. Completed At value (Priority 15 - Always colored)
  table.insert(matches, vim.fn.matchadd("JsonlCompletedAt", [["completed_at"\s*:\s*"\zs[^"]*\ze"]], 15))

  -- 3. Metadata fields (Priority 12)
  table.insert(matches, vim.fn.matchadd("JsonlPriorityP0", [["priority"\s*:\s*"\zs\(P0\)\ze"]], 12))
  table.insert(matches, vim.fn.matchadd("JsonlPriorityP1", [["priority"\s*:\s*"\zs\(P1\)\ze"]], 12))
  table.insert(matches, vim.fn.matchadd("JsonlPriorityP2", [["priority"\s*:\s*"\zs\(P2\)\ze"]], 12))
  table.insert(matches, vim.fn.matchadd("JsonlPriorityP3", [["priority"\s*:\s*"\zs\(P3\)\ze"]], 12))
  table.insert(matches, vim.fn.matchadd("JsonlTaskId", [["id"\s*:\s*"\zs\([^"]*\)\ze"]], 12))
  table.insert(matches, vim.fn.matchadd("JsonlSprint", [["sprint"\s*:\s*"\zs\([^"]*\)\ze"]], 12))
  table.insert(matches, vim.fn.matchadd("JsonlMilestone", [["milestone"\s*:\s*"\zs\([^"]*\)\ze"]], 12))

  -- 4. Line Highlights (Priority 5 - Base coloring for the entire line)
  table.insert(matches, vim.fn.matchadd("JsonlLineTodo", [[^.*"status"\s*:\s*"todo".*$]], 5))
  table.insert(matches, vim.fn.matchadd("JsonlLineInProgress", [[^.*"status"\s*:\s*"in_progress".*$]], 5))
  table.insert(matches, vim.fn.matchadd("JsonlLineBlocked", [[^.*"status"\s*:\s*"blocked".*$]], 5))
  table.insert(matches, vim.fn.matchadd("JsonlLineDone", [[^.*"status"\s*:\s*"done".*$]], 5))

  vim.b.jsonl_matches = matches
end

-- Initialize highlights for the current buffer
setup_jsonl_highlights()

-- Automatically re-evaluate highlights when text changes
local group = vim.api.nvim_create_augroup("JsonlHighlights_" .. vim.api.nvim_get_current_buf(), { clear = true })
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWinEnter" }, {
  group = group,
  buffer = 0,
  callback = setup_jsonl_highlights,
})
