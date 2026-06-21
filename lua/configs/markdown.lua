local M = {}

-- Helper to check selection boundaries and extract them
local function get_visual_selection()
  local _, ls, cs = unpack(vim.fn.getpos "'<")
  local _, le, ce = unpack(vim.fn.getpos "'>")
  if ls > le or (ls == le and cs > ce) then
    ls, le = le, ls
    cs, ce = ce, cs
  end
  return ls, cs, le, ce
end

-- Toggle wrapping of text with a markdown delimiter (handles bold and italic toggles nicely)
local function toggle_wrap_string(text, delim)
  local lead, body, trail = text:match "^(%s*)(.-)(%s*)$"
  if body == "" then
    return text, "", ""
  end

  if delim == "**" then
    if body:sub(1, 3) == "***" and body:sub(-3) == "***" then
      return lead .. "*" .. body:sub(4, -4) .. "*" .. trail, "***", "*"
    elseif body:sub(1, 2) == "**" and body:sub(-2) == "**" then
      return lead .. body:sub(3, -3) .. trail, "**", ""
    elseif body:sub(1, 1) == "*" and body:sub(-1) == "*" then
      return lead .. "**" .. body .. "**" .. trail, "*", "***"
    else
      return lead .. "**" .. body .. "**" .. trail, "", "**"
    end
  elseif delim == "*" then
    if body:sub(1, 3) == "***" and body:sub(-3) == "***" then
      return lead .. "**" .. body:sub(4, -4) .. "**" .. trail, "***", "**"
    elseif body:sub(1, 2) == "**" and body:sub(-2) == "**" then
      return lead .. "*" .. body .. "*" .. trail, "**", "***"
    elseif body:sub(1, 1) == "*" and body:sub(-1) == "*" then
      return lead .. body:sub(2, -2) .. trail, "*", ""
    else
      return lead .. "*" .. body .. "*" .. trail, "", "*"
    end
  else
    -- Generic delimiter (like strikethrough ~~ or inline code `)
    local escaped_delim = delim:gsub("[%-%.%+%*%?%^%$%(%)%%]", "%%%1")
    local pattern = "^(%s*)" .. escaped_delim .. "(.-)" .. escaped_delim .. "(%s*)$"
    if text:match(pattern) then
      return text:gsub(pattern, "%1%2%3"), delim, ""
    else
      return lead .. delim .. body .. delim .. trail, "", delim
    end
  end
end

-- Helper to apply toggle wrapping to a single line in Normal mode
local function toggle_line(delim)
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  if not line then
    return
  end

  local updated, body_prefix_old, body_prefix_new = toggle_wrap_string(line, delim)
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { updated })

  -- Adjust cursor column to keep it relative to the inner text
  local lead = line:match "^(%s*)" or ""
  local lead_len = string.len(lead)
  local old_prefix_len = string.len(body_prefix_old or "")
  local new_prefix_len = string.len(body_prefix_new or "")

  local new_col = col
  if col >= lead_len + old_prefix_len then
    new_col = col + (new_prefix_len - old_prefix_len)
  elseif col >= lead_len then
    new_col = lead_len + new_prefix_len
  end
  vim.api.nvim_win_set_cursor(0, { line_num, new_col })
end

-- Helper to apply toggle wrapping to selection in Visual mode
local function toggle_visual(delim)
  -- Exit visual mode to ensure marks '< and '> are set
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  vim.schedule(function()
    local ls, cs, le, ce = get_visual_selection()
    if not ls or not cs or not le or not ce then
      return
    end

    local lines = vim.api.nvim_buf_get_lines(0, ls - 1, le, false)
    if #lines == 0 then
      return
    end

    if ls == le then
      local line = lines[1]
      cs = math.max(1, cs)
      ce = math.min(string.len(line), ce)

      local prefix = line:sub(1, cs - 1)
      local selected = line:sub(cs, ce)
      local suffix = line:sub(ce + 1)

      local updated_selected, _, _ = toggle_wrap_string(selected, delim)
      vim.api.nvim_buf_set_lines(0, ls - 1, ls, false, { prefix .. updated_selected .. suffix })

      -- Reselect the updated text
      local new_cs = string.len(prefix) + 1
      local new_ce = string.len(prefix) + string.len(updated_selected)
      vim.fn.setpos("'<", { 0, ls, new_cs, 0 })
      vim.fn.setpos("'>", { 0, ls, new_ce, 0 })
      vim.cmd "normal! gv"
    else
      -- Multi-line: toggle/wrap each line individually
      local updated_lines = {}
      for i, line in ipairs(lines) do
        local start_col = (i == 1) and cs or 1
        local end_col = (i == #lines) and ce or string.len(line)

        local prefix = line:sub(1, start_col - 1)
        local selected = line:sub(start_col, end_col)
        local suffix = line:sub(end_col + 1)

        local updated_selected, _, _ = toggle_wrap_string(selected, delim)
        updated_lines[i] = prefix .. updated_selected .. suffix
      end
      vim.api.nvim_buf_set_lines(0, ls - 1, le, false, updated_lines)
    end
  end)
end

local function toggle_line_checkbox(line_num)
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  if not line then
    return
  end

  local bullet_unchecked_pat = "^(%s*[-*+]%s+)%[%s%](%s*)(.*)$"
  local bullet_checked_pat = "^(%s*[-*+]%s+)%[[xX]%](%s*)(.*)$"
  local ordered_unchecked_pat = "^(%s*%d+%.%s+)%[%s%](%s*)(.*)$"
  local ordered_checked_pat = "^(%s*%d+%.%s+)%[[xX]%](%s*)(.*)$"
  local bullet_pat = "^(%s*[-*+]%s+)(.*)$"
  local ordered_pat = "^(%s*%d+%.%s+)(.*)$"
  local no_list_pat = "^(%s*)(.*)$"

  local updated_line
  if line:match(bullet_unchecked_pat) then
    updated_line = line:gsub(bullet_unchecked_pat, "%1[x]%2%3")
  elseif line:match(bullet_checked_pat) then
    updated_line = line:gsub(bullet_checked_pat, "%1%3")
  elseif line:match(ordered_unchecked_pat) then
    updated_line = line:gsub(ordered_unchecked_pat, "%1[x]%2%3")
  elseif line:match(ordered_checked_pat) then
    updated_line = line:gsub(ordered_checked_pat, "%1%3")
  elseif line:match(bullet_pat) then
    updated_line = line:gsub(bullet_pat, "%1[ ] %2")
  elseif line:match(ordered_pat) then
    updated_line = line:gsub(ordered_pat, "%1[ ] %2")
  else
    local indent, content = line:match(no_list_pat)
    updated_line = indent .. "- [ ] " .. content
  end

  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { updated_line })
end

function M.toggle_bold()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" or mode == "\22" then
    toggle_visual "**"
  else
    toggle_line "**"
  end
end

function M.toggle_italic()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" or mode == "\22" then
    toggle_visual "*"
  else
    toggle_line "*"
  end
end

function M.toggle_strikethrough()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" or mode == "\22" then
    toggle_visual "~~"
  else
    toggle_line "~~"
  end
end

function M.toggle_inline_code()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" or mode == "\22" then
    toggle_visual "`"
  else
    toggle_line "`"
  end
end

function M.toggle_checkbox()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.schedule(function()
      local start_line = vim.api.nvim_buf_get_mark(0, "<")[1]
      local end_line = vim.api.nvim_buf_get_mark(0, ">")[1]
      for l = start_line, end_line do
        toggle_line_checkbox(l)
      end
    end)
  else
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    toggle_line_checkbox(current_line)
  end
end

function M.insert_link()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.schedule(function()
      local ls, cs, le, ce = get_visual_selection()
      if not ls or not cs or not le or not ce then
        return
      end

      local line = vim.api.nvim_buf_get_lines(0, ls - 1, ls, false)[1]
      if not line then
        return
      end

      local selected = line:sub(cs, ce)
      local prefix = line:sub(1, cs - 1)
      local suffix = line:sub(ce + 1)

      local updated = prefix .. "[" .. selected .. "]()" .. suffix
      vim.api.nvim_buf_set_lines(0, ls - 1, ls, false, { updated })

      -- Place cursor inside the parenthesis ()
      local new_col = string.len(prefix) + string.len(selected) + 3 -- after '[' + selected + ']' + '('
      vim.api.nvim_win_set_cursor(0, { ls, new_col })
      vim.cmd "startinsert"
    end)
  else
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    if not line then
      return
    end

    local prefix = line:sub(1, col)
    local suffix = line:sub(col + 1)

    local updated = prefix .. "[](url)" .. suffix
    vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { updated })

    -- Place cursor inside the square brackets []
    vim.api.nvim_win_set_cursor(0, { line_num, col + 1 })
    vim.cmd "startinsert"
  end
end

function M.setup(bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  -- Bold: Super/Cmd + b (mac/Neovide), <leader>mb (Terminal/AeroSpace fallback)
  map({ "n", "x" }, "<D-b>", M.toggle_bold, "Markdown: Toggle Bold (Super)")
  map({ "n", "x" }, "<leader>mb", M.toggle_bold, "Markdown: Toggle Bold")

  -- Italic: Super/Cmd + i, <leader>mi
  map({ "n", "x" }, "<D-i>", M.toggle_italic, "Markdown: Toggle Italic (Super)")
  map({ "n", "x" }, "<leader>mi", M.toggle_italic, "Markdown: Toggle Italic")

  -- Checkbox: Super/Cmd + c, <leader>mc (overrides the global mapping with our smarter buffer-local one)
  map({ "n", "x" }, "<D-c>", M.toggle_checkbox, "Markdown: Toggle Checkbox (Super)")
  map({ "n", "x" }, "<leader>mc", M.toggle_checkbox, "Markdown: Toggle Checkbox")

  -- Link: Super/Cmd + k, <leader>ml
  map({ "n", "x" }, "<D-k>", M.insert_link, "Markdown: Insert Link (Super)")
  map({ "n", "x" }, "<leader>ml", M.insert_link, "Markdown: Insert Link")

  -- Strikethrough: <leader>ms
  map({ "n", "x" }, "<leader>ms", M.toggle_strikethrough, "Markdown: Toggle Strikethrough")

  -- Code: Super/Cmd + e, <leader>me
  map({ "n", "x" }, "<D-e>", M.toggle_inline_code, "Markdown: Toggle Inline Code (Super)")
  map({ "n", "x" }, "<leader>me", M.toggle_inline_code, "Markdown: Toggle Inline Code")
end

return M
