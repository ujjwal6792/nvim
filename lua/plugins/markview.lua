local ok, markview = pcall(require, "markview")
if not ok then
  return
end

local markdown_filetypes = {
  ["markdown"] = true,
  ["markdown.mdx"] = true,
  ["quarto"] = true,
  ["rmd"] = true,
  ["typst"] = true,
  ["asciidoc"] = true,
}

markview.setup {
  preview = {
    filetypes = vim.tbl_keys(markdown_filetypes),
    ignore_buftypes = { "terminal", "prompt", "quickfix", "help" },
    condition = function(buf)
      if not vim.api.nvim_buf_is_valid(buf) then
        return false
      end

      local ft = vim.bo[buf].filetype
      if not markdown_filetypes[ft] then
        return false
      end

      local lang = vim.treesitter.language.get_lang(ft) or ft
      local ok_ts = pcall(vim.treesitter.get_parser, buf, lang)
      return ok_ts
    end,
  },
}

local actions = require "markview.actions"
local original_set_query = actions.set_query
actions.set_query = function(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local ft = vim.bo[buf].filetype
  if not markdown_filetypes[ft] then
    return
  end

  local lang = vim.treesitter.language.get_lang(ft) or ft
  local ok_ts = pcall(vim.treesitter.get_parser, buf, lang)
  if not ok_ts then
    return
  end

  return original_set_query(buf)
end

local ok_checkboxes, checkboxes = pcall(require, "markview.extras.checkboxes")
if ok_checkboxes then
  checkboxes.setup()
end
local ok_editor, editor = pcall(require, "markview.extras.editor")
if ok_editor then
  editor.setup()
end
local ok_headings, headings = pcall(require, "markview.extras.headings")
if ok_headings then
  headings.setup()
end
