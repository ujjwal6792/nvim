local M = {}

local Path = require "plenary.path"
local scan = require "plenary.scandir"
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local notes_dir = vim.fn.expand "~/notes"
local created_notes = {}

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function ensure_notes_dir()
  if not vim.uv.fs_stat(notes_dir) then
    vim.fn.mkdir(notes_dir, "p")
  end
end

local function slugify(str)
  return str:lower():gsub("[^a-z0-9]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
end

local function is_date_filename(name)
  return name:match "^%d%d%d%d%-%d%d%-%d%d%-%d%d%-%d%d%-%d%d%.md$"
end

local function has_note_content(lines)
  for _, line in ipairs(lines) do
    if line:match "%S" then
      return true
    end
  end
  return false
end

local function buffer_for_path(path)
  local normalized = vim.fs.normalize(path)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.fs.normalize(vim.api.nvim_buf_get_name(buf)) == normalized then
      return buf
    end
  end
end

local function note_is_empty(path)
  local buf = buffer_for_path(path)
  if buf and vim.api.nvim_buf_is_loaded(buf) then
    return not has_note_content(vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and not has_note_content(lines)
end

local function untrack_note(path)
  created_notes[vim.fs.normalize(path)] = nil
end

local function track_note(path)
  created_notes[vim.fs.normalize(path)] = true
end

local function is_tracked_note(path)
  return created_notes[vim.fs.normalize(path)]
end

local function delete_empty_note(path)
  if not note_is_empty(path) then
    return false
  end

  local buf = buffer_for_path(path)
  if buf and vim.api.nvim_buf_is_loaded(buf) and buf ~= vim.api.nvim_get_current_buf() then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end

  vim.fn.delete(path)
  untrack_note(path)
  return true
end

local function cleanup_empty_created_notes(except)
  except = except and vim.fs.normalize(except)
  for path in pairs(created_notes) do
    local normalized = vim.fs.normalize(path)
    if normalized ~= except then
      local stat = vim.uv.fs_stat(path)
      if stat and stat.type == "file" then
        delete_empty_note(path)
      end
    end
  end
end

local function note_path(cwd, name)
  name = vim.trim(name or "")
  if name == "" then
    name = tostring(os.date "%Y-%m-%d-%H-%M-%S")
  end

  name = name:gsub("\\", "/"):gsub("^/+", ""):gsub("/+", "/")
  if name == "" or name:find "%.%.%f[/\\]" or name:find "%f[/\\]%.%.$" then
    vim.notify("Invalid note path", vim.log.levels.WARN)
    return
  end

  if not name:match "%.md$" then
    name = name .. ".md"
  end

  return Path:new(cwd .. "/" .. name)
end

local function create_note(cwd, prompt_bufnr)
  cleanup_empty_created_notes()

  local input = vim.fn.input "Note path (blank = date): "
  local path = note_path(cwd, input)
  if not path then
    return
  end

  if not path:exists() then
    path:touch { parents = true }
    track_note(path:absolute())
  end

  if prompt_bufnr then
    actions.close(prompt_bufnr)
  end
  vim.cmd("edit " .. vim.fn.fnameescape(path:absolute()))
end

local function edit_note(path)
  vim.cmd("edit " .. vim.fn.fnameescape(Path:new(path):absolute()))
end

local function list_notes(cwd)
  ensure_notes_dir()
  cwd = cwd or notes_dir
  local files = scan.scan_dir(cwd, { hidden = false, add_dirs = true, depth = 1 })
  local entries = {}
  for _, file in ipairs(files) do
    local stat = vim.uv.fs_stat(file)
    if stat and (file:match "%.md$" or stat.type == "directory") then
      local created = tostring(os.date("%Y-%m-%d %H:%M", stat.ctime.sec))
      table.insert(entries, {
        file = file,
        display = Path:new(file):make_relative(cwd),
        created = created,
        is_dir = (stat.type == "directory"),
      })
    end
  end
  return entries
end

--------------------------------------------------
-- Telescope picker
--------------------------------------------------
function M.open_notes(cwd)
  ensure_notes_dir()
  cwd = cwd or notes_dir
  local entries = list_notes(cwd)

  -- Breadcrumbs relative to base notes_dir
  local breadcrumb = Path:new(cwd):make_relative(notes_dir)
  if breadcrumb == "" then
    breadcrumb = "notes"
  else
    breadcrumb = "notes/" .. breadcrumb
  end

  pickers
    .new({}, {
      prompt_title = breadcrumb,
      finder = finders.new_table {
        results = entries,
        entry_maker = function(e)
          return {
            value = e,
            display = (e.is_dir and "  " or "  ") .. e.display .. "  [" .. e.created .. "]",
            ordinal = e.display,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer {
        define_preview = function(self, entry)
          local buf = self.state.bufnr
          if entry.value.is_dir then
            -- Show folder contents
            local children = scan.scan_dir(entry.value.file, { hidden = false, depth = 1, add_dirs = true })
            local lines = { "📂 " .. Path:new(entry.value.file):make_relative(notes_dir), string.rep("=", 40), "" }
            for _, child in ipairs(children) do
              local name = Path:new(child):make_relative(entry.value.file)
              if vim.uv.fs_stat(child).type == "directory" then
                table.insert(lines, "  " .. name .. "/")
              else
                table.insert(lines, "  " .. name)
              end
            end
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.bo[buf].modifiable = false
          else
            -- Render markdown file content in buffer
            local lines = vim.fn.readfile(entry.value.file)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.bo[buf].filetype = "markdown"
            vim.bo[buf].modifiable = false
          end
        end,
      },
      attach_mappings = function(prompt_bufnr, map)
        local function open_file()
          local selection = action_state.get_selected_entry().value
          actions.close(prompt_bufnr)
          if selection.is_dir then
            M.open_notes(selection.file)
          else
            edit_note(selection.file)
          end
        end

        -- ESC mapping for folder navigation
        local function esc_handler()
          if cwd == notes_dir then
            actions.close(prompt_bufnr)
          else
            local parent = Path:new(cwd):parent():absolute()
            M.open_notes(parent)
          end
        end

        map("i", "<Esc>", esc_handler)
        map("n", "<Esc>", esc_handler)

        map("i", "<CR>", open_file)
        map("i", "<C-n>", function()
          create_note(cwd, prompt_bufnr)
        end)
        map("n", "<C-n>", function()
          create_note(cwd, prompt_bufnr)
        end)
        map("i", "<C-a>", function()
          create_note(cwd, prompt_bufnr)
        end)
        map("i", "<C-f>", function()
          local folder_name = vim.fn.input "Folder name: "
          if folder_name ~= "" then
            vim.fn.mkdir(cwd .. "/" .. folder_name, "p")
          end
          M.open_notes(cwd)
        end)
        map("i", "<C-r>", function()
          local selection = action_state.get_selected_entry().value
          local new_name = vim.fn.input("New name: ", vim.fn.fnamemodify(selection.file, ":t"))
          if new_name ~= "" then
            os.rename(selection.file, Path:new(cwd .. "/" .. new_name):absolute())
          end
          M.open_notes(cwd)
        end)
        map("i", "<C-d>", function()
          local selection = action_state.get_selected_entry().value
          local confirm = vim.fn.input("Delete " .. selection.display .. "? (y/n) ")
          if confirm:lower() == "y" then
            vim.fn.delete(selection.file, "rf")
            print("Deleted: " .. selection.file)
          else
            print "Cancelled"
          end
          M.open_notes(cwd)
        end)

        map("i", "<Tab>", actions.move_selection_next)
        map("i", "<S-Tab>", actions.move_selection_previous)

        return true
      end,
    })
    :find()
end

--------------------------------------------------
-- Autocmd: auto-rename on heading change
--------------------------------------------------
local function maybe_rename_note()
  local buf = vim.api.nvim_get_current_buf()
  local fname = vim.api.nvim_buf_get_name(buf)
  local basename = vim.fn.fnamemodify(fname, ":t")

  if not fname:match(notes_dir) or not fname:match "%.md$" then
    return
  end

  if not is_date_filename(basename) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local title
  for _, line in ipairs(lines) do
    local h = line:match "^#%s+(.+)"
    if h then
      title = h
      break
    end
  end

  if not title then
    return
  end

  local new_name = slugify(title) .. ".md"
  local dir = Path:new(fname):parent():absolute()
  local new_path = dir .. "/" .. new_name

  if fname ~= new_path and not Path:new(new_path):exists() then
    vim.fn.rename(fname, new_path)
    edit_note(new_path)
    print("Renamed note → " .. new_name)
  end
end

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = notes_dir .. "/**/*.md",
  callback = maybe_rename_note,
})

vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
  pattern = notes_dir .. "/**/*.md",
  callback = function(args)
    local path = vim.api.nvim_buf_get_name(args.buf)
    if is_tracked_note(path) then
      delete_empty_note(path)
    end
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    cleanup_empty_created_notes()
  end,
})

return M
