--[[
md-table-fmt — zero-cost GFM table formatter for Neovim
========================================================

Formats GitHub-Flavoured Markdown tables on BufWritePre:
  • Aligns column widths
  • Normalises pipes and whitespace
  • Adds missing trailing pipes
  • Respects :---: / ---: / :--- alignment markers
  • Preserves cursor position
  • Zero virtual-line overhead — operates on real buffer text only

Usage:
  require("md-table-fmt").setup()           -- defaults
  require("md-table-fmt").setup({
    enabled         = true,
    filetypes       = { "markdown", "mdx" },
    min_column_width = 3,
    padding          = 1,
  })
]]

local M = {}

-- ---------------------------------------------------------------------------
-- Defaults
-- ---------------------------------------------------------------------------

---@class MdTableFmt.Config
---@field enabled          boolean   Enable/disable the plugin globally.
---@field filetypes        string[]  Filetypes to auto-format.
---@field min_column_width integer   Minimum content-area width per column.
---@field padding          integer   Spaces to add on each side of cell text.
M.config = {
  enabled          = true,
  filetypes        = { "markdown", "mdx" },
  min_column_width = 3,
  padding          = 1,
  max_width        = 80,
}

-- ---------------------------------------------------------------------------
-- Per-buffer toggle
-- ---------------------------------------------------------------------------

--- Disable auto-formatting for the current buffer only.
function M.disable_buf()
  vim.b.md_table_fmt_disabled = true
end

--- Re-enable auto-formatting for the current buffer.
function M.enable_buf()
  vim.b.md_table_fmt_disabled = nil
end

-- ---------------------------------------------------------------------------
-- Format on demand
-- ---------------------------------------------------------------------------

--- Format the tables in the current buffer immediately (no save needed).
function M.format()
  local bufnr = vim.api.nvim_get_current_buf()
  require("md-table-fmt.formatter").format_buffer(bufnr, M.config)
end

-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------

---@param opts? MdTableFmt.Config  Partial overrides merged with defaults.
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  if not M.config.enabled then return end

  -- Build the autocmd pattern from the configured filetypes
  -- e.g.  { "markdown", "mdx" }  ->  matches *.md, *.mdx, *.markdown
  local ft_set = {}
  for _, ft in ipairs(M.config.filetypes) do
    ft_set[ft] = true
  end

  vim.api.nvim_create_autocmd("BufWritePre", {
    group   = vim.api.nvim_create_augroup("MdTableFmt", { clear = true }),
    pattern = { "*.md", "*.mdx", "*.markdown", "*.mkd", "*.mkdn" },
    callback = function(args)
      -- Per-buffer opt-out
      if vim.b[args.buf].md_table_fmt_disabled then return end

      -- Check if this buffer's filetype is in our configured list
      local ft = vim.bo[args.buf].filetype
      if not ft_set[ft] then
        -- Also accept by extension for filetypes Neovim might not detect yet
        local ext = vim.fn.fnamemodify(args.file, ":e")
        if not ft_set[ext] then return end
      end

      require("md-table-fmt.formatter").format_buffer(args.buf, M.config)
    end,
  })

  -- Expose user commands
  vim.api.nvim_create_user_command("MdTableFmt",      M.format,      { desc = "Format markdown tables in current buffer" })
  vim.api.nvim_create_user_command("MdTableFmtOff",   M.disable_buf, { desc = "Disable md-table-fmt for this buffer" })
  vim.api.nvim_create_user_command("MdTableFmtOn",    M.enable_buf,  { desc = "Re-enable md-table-fmt for this buffer" })
end

return M
