-- after/ftplugin/jsonl.lua
local function setup_jsonl_highlights()
  if vim.b.jsonl_matches then
    for _, id in ipairs(vim.b.jsonl_matches) do
      pcall(vim.fn.matchdelete, id)
    end
  end
  vim.b.jsonl_matches = {}

  local matches = {}

  -- ─── Priority 5: Row-level tints ───────────────────────────────────────────
  -- Matches the entire line based on status value. bg tints keep JSON keys
  -- readable in their normal colour; done lines get a muted fg instead.
  table.insert(matches, vim.fn.matchadd("JsonlLineTodo",       [[\v^.*"status"\s*:\s*"todo".*$]],        5))
  table.insert(matches, vim.fn.matchadd("JsonlLineInProgress", [[\v^.*"status"\s*:\s*"in_progress".*$]], 5))
  table.insert(matches, vim.fn.matchadd("JsonlLineBlocked",    [[\v^.*"status"\s*:\s*"blocked".*$]],     5))
  table.insert(matches, vim.fn.matchadd("JsonlLineDone",       [[\v^.*"status"\s*:\s*"done".*$]],        5))

  -- ─── Priority 12: Metadata field VALUES ────────────────────────────────────
  -- Only the value text inside the quotes is matched (after \zs, before \ze).
  table.insert(matches, vim.fn.matchadd("JsonlTaskId",    [["id"\s*:\s*"\zs[^"]\+\ze"]], 12))
  table.insert(matches, vim.fn.matchadd("JsonlSprint",    [["sprint"\s*:\s*"\zs[^"]\+\ze"]], 12))
  table.insert(matches, vim.fn.matchadd("JsonlMilestone", [["milestone"\s*:\s*"\zs[^"]\+\ze"]], 12))
  table.insert(matches, vim.fn.matchadd("JsonlEpic",      [["epic"\s*:\s*"\zs[^"]\+\ze"]], 12))

  -- Priority values
  table.insert(matches, vim.fn.matchadd("JsonlPriorityP0", [["priority"\s*:\s*"\zsP0\ze"]], 12))
  table.insert(matches, vim.fn.matchadd("JsonlPriorityP1", [["priority"\s*:\s*"\zsP1\ze"]], 12))
  table.insert(matches, vim.fn.matchadd("JsonlPriorityP2", [["priority"\s*:\s*"\zsP2\ze"]], 12))
  table.insert(matches, vim.fn.matchadd("JsonlPriorityP3", [["priority"\s*:\s*"\zsP3\ze"]], 12))

  -- ─── Priority 15: Key status tokens — always visible on any row ────────────
  -- These fire last so they override the row tint on done/in_progress lines.
  table.insert(matches, vim.fn.matchadd("JsonlStatusTodo",       [["status"\s*:\s*"\zstodo\ze"]],        15))
  table.insert(matches, vim.fn.matchadd("JsonlStatusInProgress", [["status"\s*:\s*"\zsin_progress\ze"]], 15))
  table.insert(matches, vim.fn.matchadd("JsonlStatusBlocked",    [["status"\s*:\s*"\zsblocked\ze"]],     15))
  table.insert(matches, vim.fn.matchadd("JsonlStatusDone",       [["status"\s*:\s*"\zsdone\ze"]],        15))
  table.insert(matches, vim.fn.matchadd("JsonlCompletedAt",      [["completed_at"\s*:\s*"\zs[^"]\+\ze"]], 15))

  vim.b.jsonl_matches = matches
end

-- Initialise for the current buffer
setup_jsonl_highlights()

-- Re-run when buffer content changes so new lines pick up highlights
local group = vim.api.nvim_create_augroup("JsonlHighlights_" .. vim.api.nvim_get_current_buf(), { clear = true })
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWinEnter" }, {
  group = group,
  buffer = 0,
  callback = setup_jsonl_highlights,
})
