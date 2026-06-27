--[[
md-table-fmt/formatter.lua
Core table parsing, normalisation and re-serialisation logic.

Public API:
  M.format_buffer(bufnr, config)   -- rewrite all tables in-place, restore cursor
]]

local M = {}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--- Display-width of a string (Unicode-aware via Neovim's built-in).
local function dw(s)
  return vim.fn.strdisplaywidth(s)
end


-- ---------------------------------------------------------------------------
-- Row detection
-- ---------------------------------------------------------------------------

--- True if a raw line belongs to a GFM table (starts with optional
--- whitespace then a pipe character).
local function is_table_line(line)
  return line:match("^%s*|") ~= nil
end

--- True if the row is the alignment-separator (the `|:---|---:|:---:|` row).
--- A separator line contains ONLY pipes, dashes, colons and whitespace.
local function is_separator_line(line)
  -- Must start with optional spaces then a pipe (is_table_line already checked)
  -- Must contain at least one cell that looks like a dash sequence
  -- The entire line should only have: | - : space
  if not line:match("%-") then return false end
  -- Strip leading whitespace and check remaining chars are only |, -, :, space
  local stripped = line:match("^%s*(.-)%s*$")
  return stripped:match("^[|%-%:%s]+$") ~= nil
end

-- ---------------------------------------------------------------------------
-- Row parsing
-- ---------------------------------------------------------------------------

--- Split a raw table line into its individual cell strings.
--- Strips leading/trailing whitespace from each cell.
--- Leading and trailing outer pipes are consumed.
---@param line string
---@return string[]
local function split_cells(line)
  line = trim(line)
  -- consume leading pipe
  if line:sub(1, 1) == "|" then line = line:sub(2) end
  -- consume trailing pipe
  if line:sub(-1) == "|" then line = line:sub(1, -2) end

  local cells = {}
  -- append sentinel so the last cell is captured by the pattern
  for cell in (line .. "|"):gmatch("([^|]*)|") do
    table.insert(cells, trim(cell))
  end
  return cells
end

-- ---------------------------------------------------------------------------
-- Alignment
-- ---------------------------------------------------------------------------

--- Derive alignment from a separator cell like `---`, `:---`, `---:`, `:---:`.
---@param cell string
---@return "left"|"right"|"center"
local function parse_alignment(cell)
  cell = trim(cell)
  local starts = cell:sub(1, 1) == ":"
  local ends   = cell:sub(-1)   == ":"
  if starts and ends then return "center"
  elseif ends        then return "right"
  else                    return "left"
  end
end

-- ---------------------------------------------------------------------------
-- Cell rendering
-- ---------------------------------------------------------------------------

--- Render a separator cell for column {c} with the given alignment.
--- The returned string does NOT include the surrounding padding spaces.
---@param width   integer  content-area width (without padding)
---@param align   "left"|"right"|"center"
---@return string
local function render_sep(width, align)
  if align == "center" then
    -- ":---:" — need at least 5 chars; pad with extra dashes
    local inner = math.max(1, width - 2)
    return ":" .. string.rep("-", inner) .. ":"
  elseif align == "right" then
    -- "---:" — need at least 4 chars
    local inner = math.max(1, width - 1)
    return string.rep("-", inner) .. ":"
  else
    -- "---" (left-align; just dashes)
    return string.rep("-", math.max(3, width))
  end
end

--- Render a content cell.
---@param text    string
---@param width   integer  content-area width (without padding)
---@param align   "left"|"right"|"center"
---@param padding integer  spaces on each side inside the pipes
---@return string          including surrounding padding
local function render_cell(text, width, align, padding)
  local fill  = math.max(0, width - dw(text))
  local space = string.rep(" ", padding)

  if align == "right" then
    return space .. string.rep(" ", fill) .. text .. space
  elseif align == "center" then
    local lf = math.floor(fill / 2)
    local rf = fill - lf
    return space .. string.rep(" ", lf) .. text .. string.rep(" ", rf) .. space
  else  -- left
    return space .. text .. string.rep(" ", fill) .. space
  end
end

--- Render a separator cell including surrounding padding.
local function render_sep_cell(width, align, padding)
  local space = string.rep(" ", padding)
  local inner = math.max(3, width)   -- always at least 3 dashes
  return space .. render_sep(inner, align) .. space
end

-- ---------------------------------------------------------------------------
-- Column-fit & word-wrap maths
-- ---------------------------------------------------------------------------

--- word_wrap wraps text into lines of display width ≤ width.
local function wrap_text(text, width)
  width = math.max(1, width)
  local lines = {}
  local cur_line = {}
  local cur_len = 0

  for word in string.gmatch(text, "%S+") do
    local word_len = dw(word)
    if word_len > width then
      if #cur_line > 0 then
        table.insert(lines, table.concat(cur_line, " "))
        cur_line = {}
        cur_len = 0
      end
      local remaining = word
      while dw(remaining) > width do
        local prefix = ""
        local chars = vim.fn.split(remaining, "\\zs")
        local idx = 0
        local w = 0
        for i, ch in ipairs(chars) do
          local cw = dw(ch)
          if w + cw > width then
            break
          end
          prefix = prefix .. ch
          w = w + cw
          idx = i
        end
        if idx == 0 then
          prefix = chars[1] or ""
          idx = 1
        end
        table.insert(lines, prefix)
        remaining = table.concat(vim.list_slice(chars, idx + 1), "")
      end
      if remaining ~= "" then
        table.insert(cur_line, remaining)
        cur_len = dw(remaining)
      end
    elseif cur_len == 0 then
      table.insert(cur_line, word)
      cur_len = word_len
    elseif cur_len + 1 + word_len <= width then
      table.insert(cur_line, word)
      cur_len = cur_len + 1 + word_len
    else
      table.insert(lines, table.concat(cur_line, " "))
      cur_line = { word }
      cur_len = word_len
    end
  end

  if #cur_line > 0 then
    table.insert(lines, table.concat(cur_line, " "))
  end

  if #lines == 0 then
    table.insert(lines, "")
  end

  return lines
end

--- fit_columns shaves width from the widest columns until they fit the budget.
local function fit_columns(natural_widths, budget, min_col)
  local fitted = {}
  local total = 0
  for i, w in ipairs(natural_widths) do
    fitted[i] = w
    total = total + w
  end

  if total <= budget or #fitted == 0 then
    return fitted
  end

  local guard = 0
  local function shrink_to(floor)
    while total > budget and guard < 200000 do
      guard = guard + 1
      local widest = -1
      local wi = nil
      for i, w in ipairs(fitted) do
        if w > floor and w > widest then
          widest = w
          wi = i
        end
      end
      if not wi then break end
      fitted[wi] = fitted[wi] - 1
      total = total - 1
    end
  end

  shrink_to(min_col)
  if total > budget then
    shrink_to(1)
  end

  return fitted
end

-- ---------------------------------------------------------------------------
-- Table block formatter
-- ---------------------------------------------------------------------------

--- Format a single table block (list of raw lines) and return the
--- reformatted lines.
---@param block  string[]
---@param config table
---@return string[]
local function format_block(block, config)
  local padding         = config.padding or 1
  local min_col_width   = config.min_column_width or 3

  -- 1. Parse every row into cells
  local parsed = {}   -- { cells, is_sep }
  local sep_idx = nil

  for i, line in ipairs(block) do
    local is_sep = is_separator_line(line)
    table.insert(parsed, { cells = split_cells(line), is_sep = is_sep })
    if is_sep and not sep_idx then sep_idx = i end
  end

  -- 2. Determine column count
  local ncols = 0
  for _, p in ipairs(parsed) do
    ncols = math.max(ncols, #p.cells)
  end
  if ncols == 0 then return block end  -- nothing to do

  -- 3. Read alignments from separator row (or default left)
  local aligns = {}
  if sep_idx then
    local sep_cells = parsed[sep_idx].cells
    for c = 1, ncols do
      aligns[c] = parse_alignment(sep_cells[c] or "---")
    end
  else
    for c = 1, ncols do aligns[c] = "left" end
  end

  -- 4. Compute per-column content widths (max of non-sep rows)
  local col_w = {}
  for c = 1, ncols do col_w[c] = min_col_width end

  for _, p in ipairs(parsed) do
    if not p.is_sep then
      for c = 1, ncols do
        col_w[c] = math.max(col_w[c], dw(p.cells[c] or ""))
      end
    end
  end

  -- Ensure separator fits (":---:" etc. need minimum widths)
  if sep_idx then
    for c = 1, ncols do
      local a = aligns[c]
      local min_w = (a == "center") and 3 or (a == "right") and 3 or 3
      col_w[c] = math.max(col_w[c], min_w)
    end
  end

  -- Fit columns to max_width budget
  local max_width = config.max_width or 80
  local budget = max_width - 1 - ncols * (2 * padding + 1)
  col_w = fit_columns(col_w, budget, min_col_width)

  -- 5. Serialise
  local out = {}
  for _, p in ipairs(parsed) do
    if p.is_sep then
      local parts = {}
      for c = 1, ncols do
        table.insert(parts, render_sep_cell(col_w[c], aligns[c], padding))
      end
      table.insert(out, "|" .. table.concat(parts, "|") .. "|")
    else
      local wrapped_cols = {}
      local max_lines = 1
      for c = 1, ncols do
        local cell_lines = wrap_text(p.cells[c] or "", col_w[c])
        wrapped_cols[c] = cell_lines
        max_lines = math.max(max_lines, #cell_lines)
      end

      for line_idx = 1, max_lines do
        local parts = {}
        for c = 1, ncols do
          local cell_text = wrapped_cols[c][line_idx] or ""
          table.insert(parts, render_cell(cell_text, col_w[c], aligns[c], padding))
        end
        table.insert(out, "|" .. table.concat(parts, "|") .. "|")
      end
    end
  end

  return out
end

-- ---------------------------------------------------------------------------
-- Buffer-level entry point
-- ---------------------------------------------------------------------------

--- Reformat all GFM tables in {bufnr} in-place and restore cursor position.
---@param bufnr  integer
---@param config table
function M.format_buffer(bufnr, config)
  -- Save cursor so we can restore it after the buffer update
  local win    = vim.fn.bufwinid(bufnr)
  local cursor = (win ~= -1) and vim.api.nvim_win_get_cursor(win) or nil

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local result = {}
  local i = 1

  while i <= #lines do
    if is_table_line(lines[i]) then
      -- Collect the whole table block
      local block = {}
      while i <= #lines and is_table_line(lines[i]) do
        table.insert(block, lines[i])
        i = i + 1
      end

      -- Format and emit
      local formatted = format_block(block, config)
      for _, fl in ipairs(formatted) do
        table.insert(result, fl)
      end
    else
      table.insert(result, lines[i])
      i = i + 1
    end
  end

  -- Only write back if something actually changed
  local changed = (#result ~= #lines)
  if not changed then
    for j = 1, #lines do
      if lines[j] ~= result[j] then changed = true; break end
    end
  end

  if changed then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, result)
  end

  -- Restore cursor (clamped to new buffer size)
  if cursor and win ~= -1 then
    local row = math.min(cursor[1], vim.api.nvim_buf_line_count(bufnr))
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
    local col  = math.min(cursor[2], math.max(0, #line - 1))
    pcall(vim.api.nvim_win_set_cursor, win, { row, col })
  end
end

return M
