local source = {}

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = vim.tbl_deep_extend("force", {
    max_entries = 200,
    show_hidden = false,
  }, opts or {})
  return self
end

function source:get_completions(_, callback)
  local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
  local cwd = vim.fn.getcwd()
  local entries = {}
  local scan = vim.uv.fs_scandir(cwd)

  if scan then
    while #entries < self.opts.max_entries do
      local name, kind = vim.uv.fs_scandir_next(scan)
      if not name then
        break
      end

      if self.opts.show_hidden or name:sub(1, 1) ~= "." then
        local is_dir = kind == "directory"
        entries[#entries + 1] = {
          label = is_dir and name .. "/" or name,
          kind = is_dir and CompletionItemKind.Folder or CompletionItemKind.File,
          insertText = is_dir and name .. "/" or name,
          sortText = (is_dir and "1" or "2") .. name:lower(),
        }
      end
    end
  end

  callback {
    is_incomplete_backward = false,
    is_incomplete_forward = false,
    items = entries,
  }
end

return source
