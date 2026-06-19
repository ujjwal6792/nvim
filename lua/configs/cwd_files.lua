local source = {}

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = vim.tbl_deep_extend("force", {
    max_entries = 200,
    show_hidden = true,
  }, opts or {})
  return self
end

function source:get_trigger_characters()
  return { "/", ".", "\\" }
end

function source:get_completions(context, callback)
  local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
  local cwd = vim.fn.getcwd()
  local entries = {}

  local line_before_cursor = ""
  if context and context.line and context.cursor then
    line_before_cursor = context.line:sub(1, context.cursor[2])
  end

  local path_str = line_before_cursor:match("([^'\"%s%(%)%[%]%{%}%,%;%=%<%>%&%|%*]+)$") or ""
  local dir, _ = path_str:match("^(.-)([^/\\\\]*)$")
  dir = dir or ""

  local target_dir
  if dir == "" then
    target_dir = cwd
  elseif dir:sub(1, 1) == "/" or dir:match("^%a+:") or dir:sub(1, 1) == "~" then
    target_dir = vim.fs.normalize(dir)
  else
    target_dir = vim.fs.normalize(cwd .. "/" .. dir)
  end

  local scan = vim.uv.fs_scandir(target_dir)

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
