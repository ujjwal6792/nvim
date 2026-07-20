if #vim.api.nvim_list_uis() == 0 then
  return
end

local ok, diagram = pcall(require, "diagram")
if not ok then
  return
end

local markdown_integration = require "diagram.integrations.markdown"
local renderers = require "diagram/renderers"
local d2_ns = vim.api.nvim_create_namespace "d2_hidden_text"

-- Only allow d2 renderer
markdown_integration.renderers = {
  renderers.d2,
}

-- Reveal code block text when entering insert mode to edit
vim.api.nvim_create_autocmd("InsertEnter", {
  pattern = "*.md",
  callback = function(ev)
    vim.api.nvim_buf_clear_namespace(ev.buf, d2_ns, 0, -1)
  end,
})

-- Filter out non-d2 diagrams to avoid errors or warnings
local original_query = markdown_integration.query_buffer_diagrams
markdown_integration.query_buffer_diagrams = function(bufnr)
  local diagrams = original_query(bufnr)
  local filtered = {}

  -- Clear previous highlights
  vim.api.nvim_buf_clear_namespace(bufnr, d2_ns, 0, -1)

  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  local bg = normal_hl.bg or normal_hl.background
  local bg_hex = bg and string.format("#%06x", bg) or "#1e1e2e"
  vim.api.nvim_set_hl(0, "D2HiddenText", { fg = bg_hex, bg = bg_hex, force = true })

  local mode = vim.api.nvim_get_mode().mode
  local is_insert = mode:sub(1, 1) == "i"

  for _, diag in ipairs(diagrams) do
    if diag.renderer_id == "d2" then
      diag.source = diag.source .. '\nstyle.fill: "' .. bg_hex .. '"\n'
      -- Fold the code block and render the diagram immediately after the fold
      if diag.range and diag.range.start_row and not is_insert then
        local start_row = diag.range.start_row
        local end_row = start_row
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        for i = start_row + 1, line_count - 1 do
          local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ""
          if line:match "^%s*```%s*$" then
            end_row = i
            break
          end
        end

        -- Ensure there is a line after the code block to attach the image to
        if end_row >= line_count - 1 then
          local last_line = vim.api.nvim_buf_get_lines(bufnr, -1, -1, false)[1] or ""
          if last_line ~= "" then
            vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "" })
          end
        end

        -- Fold the code block (collapsing it to 1 line)
        local start_line = start_row + 1
        vim.schedule(function()
          pcall(vim.api.nvim_buf_call, bufnr, function()
            pcall(vim.cmd, tostring(start_line) .. "foldclose")
          end)
        end)

        -- Shift the rendering position to the line right after the fold
        -- This allows image.nvim to attach virtual padding to the visible line, pushing it down.
        diag.range.start_row = end_row + 1
      end

      table.insert(filtered, diag)
    end
  end
  return filtered
end

diagram.setup {
  integrations = {
    markdown_integration,
  },
  renderer_options = {
    d2 = {
      theme_id = 100, -- dark theme
      format = "svg",
    },
  },
}
