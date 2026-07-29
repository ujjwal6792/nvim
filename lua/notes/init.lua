local M = {}

local Path = require "plenary.path"
local scan = require "plenary.scandir"
local Snacks = require "snacks"

local notes_dir = vim.fn.expand "~/notes"
local created_notes = {}

local config = {
  auto_rename   = true,  -- rename date-filename to slugified heading on write
  empty_cleanup = true,  -- delete empty tracked notes on buffer close or exit
  zen_tags      = true,  -- tag list/find via zen CLI (fallback: disabled)
  zen_tasks     = true,  -- global task list/toggle via zen CLI (fallback: grep)
  zen_backlinks = true,  -- backlinks lookup via zen CLI (fallback: grep)
  zen_archive   = true,  -- archive/trash/restore via zen CLI (fallback: hard delete)
}

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

--------------------------------------------------
-- zen CLI helper
--------------------------------------------------
local zen_bin = vim.fn.expand "~/.local/bin/zen"
local zen_env = { "ZENNOTES_VAULT=" .. notes_dir }

local function zen_available()
  return vim.uv.fs_stat(zen_bin) ~= nil
end

--- Run zen synchronously, return decoded JSON or nil on error.
local function zen_json(args)
  if not zen_available() then
    return nil
  end
  local cmd = table.concat(
    vim.iter({ zen_bin, table.unpack(args), "--json", "--no-color" }):totable(),
    " "
  )
  -- prepend env
  local env_str = table.concat(zen_env, " ")
  local out = vim.fn.system(env_str .. " " .. cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local ok, decoded = pcall(vim.fn.json_decode, out)
  return ok and decoded or nil
end

--- Run zen fire-and-forget (no output needed).
local function zen_run(args)
  if not zen_available() then
    return false
  end
  local cmd = vim.iter({ zen_bin, table.unpack(args), "--no-color" }):totable()
  local env_str = table.concat(zen_env, " ")
  vim.fn.system(env_str .. " " .. table.concat(cmd, " "))
  return vim.v.shell_error == 0
end

--- Relative path from notes_dir, usable by zen CLI commands.
local function zen_rel(abs_path)
  return Path:new(abs_path):make_relative(notes_dir)
end

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
  if not config.empty_cleanup then
    return false
  end
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
  if not config.empty_cleanup then
    return
  end
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

local function create_note(cwd)
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
-- Delete / Archive / Trash
--------------------------------------------------
--- Delete a note: uses zen trash if enabled, otherwise hard-deletes.
local function delete_or_trash(file, display, refresh_cb)
  if config.zen_archive and zen_available() then
    local confirm = vim.fn.input("Trash '" .. display .. "'? (y/n) ")
    if confirm:lower() == "y" then
      local ok = zen_run { "trash", zen_rel(file) }
      if ok then
        vim.notify("Trashed: " .. display, vim.log.levels.INFO)
      else
        vim.notify("zen trash failed", vim.log.levels.WARN)
      end
    else
      vim.notify("Cancelled", vim.log.levels.INFO)
    end
  else
    local confirm = vim.fn.input("Permanently delete '" .. display .. "'? (y/n) ")
    if confirm:lower() == "y" then
      vim.fn.delete(file, "rf")
      vim.notify("Deleted: " .. display, vim.log.levels.INFO)
    else
      vim.notify("Cancelled", vim.log.levels.INFO)
    end
  end
  if refresh_cb then
    refresh_cb()
  end
end

--- Archive a note via zen CLI (no fallback — shows info if unavailable).
local function archive_note(file, display, refresh_cb)
  if config.zen_archive and zen_available() then
    local ok = zen_run { "archive", zen_rel(file) }
    if ok then
      vim.notify("Archived: " .. display, vim.log.levels.INFO)
    else
      vim.notify("zen archive failed", vim.log.levels.WARN)
    end
  else
    vim.notify("zen CLI not available – archive requires zen", vim.log.levels.WARN)
  end
  if refresh_cb then
    refresh_cb()
  end
end

--------------------------------------------------
-- Snacks selectors: notes, tags, tasks, and backlinks
--------------------------------------------------
local function markdown_files()
  return vim.fs.find(function(name)
    return name:match "%.md$" ~= nil
  end, { path = notes_dir, type = "file", limit = math.huge })
end

local function pick_notes(title, items, confirm, actions, keys)
  Snacks.picker.pick {
    title = title,
    items = items,
    format = "text",
    preview = "file",
    confirm = confirm,
    actions = actions,
    win = { input = { keys = keys or {} } },
  }
end

function M.open_notes(cwd)
  ensure_notes_dir()
  cwd = cwd or notes_dir
  local breadcrumb = Path:new(cwd):make_relative(notes_dir)
  breadcrumb = breadcrumb == "" and "notes" or "notes/" .. breadcrumb
  local items = vim.tbl_map(function(entry)
    return { text = string.format("%s  [%s]", entry.display, entry.created), file = entry.is_dir and nil or entry.file, entry = entry }
  end, list_notes(cwd))

  pick_notes(breadcrumb, items, function(picker, item)
    if not item then return end
    picker:close()
    if item.entry.is_dir then M.open_notes(item.entry.file) else edit_note(item.entry.file) end
  end, {
    create_note = function(picker) picker:close(); create_note(cwd) end,
    create_folder = function(picker)
      picker:close()
      local name = vim.fn.input "Folder name: "
      if name ~= "" then vim.fn.mkdir(cwd .. "/" .. name, "p") end
      M.open_notes(cwd)
    end,
    go_up = function(picker)
      if cwd == notes_dir then picker:close() else picker:close(); M.open_notes(Path:new(cwd):parent():absolute()) end
    end,
    rename = function(picker, item)
      if item then rename_entry(item.entry.file, item.entry.is_dir, function() picker:close(); M.open_notes(cwd) end) end
    end,
    trash = function(picker, item)
      if item then trash_entry(item.entry.file, item.entry.is_dir, function() picker:close(); M.open_notes(cwd) end) end
    end,
    archive = function(picker, item)
      if item then archive_entry(item.entry.file, function() picker:close(); M.open_notes(cwd) end) end
    end,
  }, {
    ["<c-n>"] = { "create_note", mode = { "n", "i" } },
    ["<c-a>"] = { "create_note", mode = { "n", "i" } },
    ["<c-f>"] = { "create_folder", mode = { "n", "i" } },
    ["<c-r>"] = { "rename", mode = { "n", "i" } },
    ["<c-d>"] = { "trash", mode = { "n", "i" } },
    ["<c-x>"] = { "archive", mode = { "n", "i" } },
    ["<esc>"] = { "go_up", mode = { "n", "i" } },
  })
end

function M.find_by_tag(tag)
  local items = {}
  if config.zen_tags and zen_available() then
    for _, note in ipairs(zen_json { "tag", "find", tag } or {}) do
      items[#items + 1] = { text = note.path or "", file = notes_dir .. "/" .. (note.path or "") }
    end
  else
    local pattern = "#" .. vim.pesc(tag) .. "%f[^%w_-]"
    for _, file in ipairs(markdown_files()) do
      local ok, lines = pcall(vim.fn.readfile, file)
      if ok and table.concat(lines, "\n"):find(pattern) then items[#items + 1] = { text = zen_rel(file), file = file } end
    end
  end
  if #items == 0 then vim.notify("No notes found for #" .. tag, vim.log.levels.INFO); return end
  pick_notes("Notes › #" .. tag, items, function(picker, item)
    if item then picker:close(); edit_note(item.file) end
  end)
end

function M.open_tags()
  local counts = {}
  if config.zen_tags and zen_available() then
    for _, tag in ipairs(zen_json { "tag", "list" } or {}) do counts[tag.tag] = tag.count or 0 end
  else
    for _, file in ipairs(markdown_files()) do
      local ok, lines = pcall(vim.fn.readfile, file)
      if ok then
        local seen = {}
        for tag in table.concat(lines, "\n"):gmatch "#([%w_/-]+)" do seen[tag] = true end
        for tag in pairs(seen) do counts[tag] = (counts[tag] or 0) + 1 end
      end
    end
  end
  local items = {}
  for tag, count in pairs(counts) do items[#items + 1] = { text = string.format("#%-30s  %d notes", tag, count), tag = tag } end
  if #items == 0 then vim.notify("No tags found in vault", vim.log.levels.INFO); return end
  pick_notes("Notes › Tags", items, function(picker, item)
    if item then picker:close(); M.find_by_tag(item.tag) end
  end)
end

function M.open_tasks()
  local items = {}
  if config.zen_tasks and zen_available() then
    for _, task in ipairs(zen_json { "task", "list", "--unchecked" } or {}) do
      items[#items + 1] = { text = string.format("%s  %s", task.text or "", task.path or ""), file = notes_dir .. "/" .. (task.path or ""), task = task }
    end
  else
    for _, file in ipairs(markdown_files()) do
      local ok, lines = pcall(vim.fn.readfile, file)
      if ok then for lnum, line in ipairs(lines) do
        if line:find "%- %[%s%]" then items[#items + 1] = { text = line .. "  " .. zen_rel(file), file = file, lnum = lnum } end
      end end
    end
  end
  if #items == 0 then vim.notify("No open tasks found", vim.log.levels.INFO); return end
  pick_notes("Notes › Open Tasks", items, function(picker, item)
    if item then picker:close(); edit_note(item.file); if item.lnum then vim.api.nvim_win_set_cursor(0, { item.lnum, 0 }) end end
  end, {
    toggle_task = function(picker, item)
      if not item or not item.task or not item.task.id then
        vim.notify("Task has no ID - cannot toggle", vim.log.levels.WARN)
      elseif zen_run { "task", "toggle", tostring(item.task.id) } then
        picker:close(); M.open_tasks()
      else
        vim.notify("zen task toggle failed", vim.log.levels.WARN)
      end
    end,
  }, { ["<c-t>"] = { "toggle_task", mode = { "n", "i" } } })
end

function M.open_backlinks()
  local fname = vim.api.nvim_buf_get_name(0)
  if not fname:match(notes_dir) or not fname:match "%.md$" then vim.notify("Not in a notes buffer", vim.log.levels.WARN); return end
  local rel, items = zen_rel(fname), {}
  if config.zen_backlinks and zen_available() then
    for _, note in ipairs(zen_json { "backlinks", rel } or {}) do
      items[#items + 1] = { text = note.path or "", file = notes_dir .. "/" .. (note.path or "") }
    end
  else
    local pattern = "%[%[" .. vim.pesc(vim.fn.fnamemodify(fname, ":t:r")) .. "%]%]"
    for _, file in ipairs(markdown_files()) do
      local ok, lines = pcall(vim.fn.readfile, file)
      if ok and table.concat(lines, "\n"):find(pattern) then items[#items + 1] = { text = zen_rel(file), file = file } end
    end
  end
  if #items == 0 then vim.notify("No backlinks found for " .. rel, vim.log.levels.INFO); return end
  pick_notes("Notes › Backlinks <- " .. vim.fn.fnamemodify(rel, ":t:r"), items, function(picker, item)
    if item then picker:close(); edit_note(item.file) end
  end)
end

if 0 == 1 then
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

  disabled_selectors
    .new({}, {
      prompt_title = breadcrumb,
      finder = disabled_sources.new_table {
        results = entries,
        entry_maker = function(e)
          return {
            value = e,
            display = (e.is_dir and "  " or "  ") .. e.display .. "  [" .. e.created .. "]",
            ordinal = e.display,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = disabled_previews.new_buffer_previewer {
        define_preview = function(self, entry)
          local buf = self.state.bufnr
          if entry.value.is_dir then
            -- Show folder contents
            local children = scan.scan_dir(entry.value.file, { hidden = false, depth = 1, add_dirs = true })
            local lines = { "📂 " .. Path:new(entry.value.file):make_relative(notes_dir), string.rep("=", 40), "" }
            for _, child in ipairs(children) do
              local name = Path:new(child):make_relative(entry.value.file)
              if vim.uv.fs_stat(child).type == "directory" then
                table.insert(lines, "  " .. name .. "/")
              else
                table.insert(lines, "  " .. name)
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
          local selection = disabled_state.get_selected_entry().value
          actions.close(prompt_bufnr)
          if selection.is_dir then
            M.open_notes(selection.file)
          else
            edit_note(selection.file)
          end
        end

        -- ESC: navigate up one folder or close at root
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

        -- <C-n>/<C-a>: create new note
        map("i", "<C-n>", function()
          create_note(cwd, prompt_bufnr)
        end)
        map("n", "<C-n>", function()
          create_note(cwd, prompt_bufnr)
        end)
        map("i", "<C-a>", function()
          create_note(cwd, prompt_bufnr)
        end)

        -- <C-f>: create new folder
        map("i", "<C-f>", function()
          local folder_name = vim.fn.input "Folder name: "
          if folder_name ~= "" then
            vim.fn.mkdir(cwd .. "/" .. folder_name, "p")
          end
          M.open_notes(cwd)
        end)

        -- <C-r>: rename file/folder
        map("i", "<C-r>", function()
          local selection = disabled_state.get_selected_entry().value
          local new_name = vim.fn.input("New name: ", vim.fn.fnamemodify(selection.file, ":t"))
          if new_name ~= "" then
            os.rename(selection.file, Path:new(cwd .. "/" .. new_name):absolute())
          end
          M.open_notes(cwd)
        end)

        -- <C-d>: trash (zen) or hard delete (fallback)
        map("i", "<C-d>", function()
          local selection = disabled_state.get_selected_entry().value
          actions.close(prompt_bufnr)
          delete_or_trash(selection.file, selection.display, function()
            M.open_notes(cwd)
          end)
        end)

        -- <C-x>: archive via zen (no fallback)
        map("i", "<C-x>", function()
          local selection = disabled_state.get_selected_entry().value
          actions.close(prompt_bufnr)
          archive_note(selection.file, selection.display, function()
            M.open_notes(cwd)
          end)
        end)

        map("i", "<Tab>", actions.move_selection_next)
        map("i", "<S-Tab>", actions.move_selection_previous)

        return true
      end,
    })
    :find()
end

--------------------------------------------------
-- Legacy tag picker (zen or fallback)
--------------------------------------------------
function M.open_tags()
  if config.zen_tags and zen_available() then
    -- zen tag list --json → list of {tag, count}
    local tags = zen_json { "tag", "list" }
    if not tags or #tags == 0 then
      vim.notify("No tags found in vault", vim.log.levels.INFO)
      return
    end

    disabled_selectors
      .new({}, {
        prompt_title = "Notes › Tags",
        finder = disabled_sources.new_table {
          results = tags,
          entry_maker = function(t)
            return {
              value = t.tag,
              display = string.format("#%-30s  %d notes", t.tag, t.count or 0),
              ordinal = t.tag,
            }
          end,
        },
        sorter = conf.generic_sorter {},
        attach_mappings = function(_, map)
          map("i", "<CR>", function(pb)
            local tag = disabled_state.get_selected_entry().value
            actions.close(pb)
            M.find_by_tag(tag)
          end)
          return true
        end,
      })
      :find()
  else
    -- Legacy fallback implementation
    disabled_picker.live_grep {
      search_dirs = { notes_dir },
      prompt_title = "Notes › Search Tags (fallback)",
      default_text = "#",
    }
  end
end

--- Open a legacy picker of notes carrying the given tag.
function M.find_by_tag(tag)
  if config.zen_tags and zen_available() then
    local notes = zen_json { "tag", "find", tag }
    if not notes or #notes == 0 then
      vim.notify("No notes found for #" .. tag, vim.log.levels.INFO)
      return
    end

    disabled_selectors
      .new({}, {
        prompt_title = "Notes › #" .. tag,
        finder = disabled_sources.new_table {
          results = notes,
          entry_maker = function(n)
            local rel = zen_rel(notes_dir .. "/" .. (n.path or ""))
            return {
              value = notes_dir .. "/" .. (n.path or ""),
              display = rel,
              ordinal = rel,
            }
          end,
        },
        sorter = conf.generic_sorter {},
        previewer = conf.file_previewer {},
        attach_mappings = function(_, map)
          map("i", "<CR>", function(pb)
            local file = disabled_state.get_selected_entry().value
            actions.close(pb)
            edit_note(file)
          end)
          return true
        end,
      })
      :find()
  else
    disabled_picker.live_grep {
      search_dirs = { notes_dir },
      prompt_title = "Notes › #" .. tag .. " (fallback)",
      default_text = "#" .. tag,
    }
  end
end

--------------------------------------------------
-- Legacy global task picker (zen or fallback grep)
--------------------------------------------------
function M.open_tasks()
  if config.zen_tasks and zen_available() then
    local tasks = zen_json { "task", "list", "--unchecked" }
    if not tasks or #tasks == 0 then
      vim.notify("No open tasks found", vim.log.levels.INFO)
      return
    end

    disabled_selectors
      .new({}, {
        prompt_title = "Notes › Open Tasks",
        finder = disabled_sources.new_table {
          results = tasks,
          entry_maker = function(t)
            local note_rel = t.path or ""
            local label = string.format("%-40s  %s", t.text or "", note_rel)
            return {
              value = t,
              display = "☐  " .. label,
              ordinal = (t.text or "") .. note_rel,
            }
          end,
        },
        sorter = conf.generic_sorter {},
        attach_mappings = function(_, map)
          -- <CR>: open the containing note
          map("i", "<CR>", function(pb)
            local t = disabled_state.get_selected_entry().value
            actions.close(pb)
            edit_note(notes_dir .. "/" .. (t.path or ""))
          end)
          -- <C-t>: toggle task (zen task toggle <id>)
          map("i", "<C-t>", function(pb)
            local t = disabled_state.get_selected_entry().value
            actions.close(pb)
            if t.id then
              local ok = zen_run { "task", "toggle", tostring(t.id) }
              if ok then
                vim.notify("Task toggled ✓", vim.log.levels.INFO)
              else
                vim.notify("zen task toggle failed", vim.log.levels.WARN)
              end
            else
              vim.notify("Task has no ID – cannot toggle", vim.log.levels.WARN)
            end
          end)
          return true
        end,
      })
      :find()
  else
    -- Fallback: grep for unchecked checkboxes
    disabled_picker.live_grep {
      search_dirs = { notes_dir },
      prompt_title = "Notes › Tasks (fallback grep)",
      default_text = "- [ ]",
    }
  end
end

--------------------------------------------------
-- Legacy backlinks picker (zen or fallback grep)
--------------------------------------------------
function M.open_backlinks()
  local buf = vim.api.nvim_get_current_buf()
  local fname = vim.api.nvim_buf_get_name(buf)
  if not fname:match(notes_dir) or not fname:match "%.md$" then
    vim.notify("Not in a notes buffer", vim.log.levels.WARN)
    return
  end

  local rel = zen_rel(fname)

  if config.zen_backlinks and zen_available() then
    local links = zen_json { "backlinks", rel }
    if not links or #links == 0 then
      vim.notify("No backlinks found for " .. rel, vim.log.levels.INFO)
      return
    end

    disabled_selectors
      .new({}, {
        prompt_title = "Notes › Backlinks ← " .. vim.fn.fnamemodify(rel, ":t:r"),
        finder = disabled_sources.new_table {
          results = links,
          entry_maker = function(n)
            local note_rel = n.path or ""
            return {
              value = notes_dir .. "/" .. note_rel,
              display = note_rel,
              ordinal = note_rel,
            }
          end,
        },
        sorter = conf.generic_sorter {},
        previewer = conf.file_previewer {},
        attach_mappings = function(_, map)
          map("i", "<CR>", function(pb)
            local file = disabled_state.get_selected_entry().value
            actions.close(pb)
            edit_note(file)
          end)
          return true
        end,
      })
      :find()
  else
    -- Fallback: grep for [[filename-stem]] across notes
    local stem = vim.fn.fnamemodify(fname, ":t:r")
    disabled_picker.live_grep {
      search_dirs = { notes_dir },
      prompt_title = "Notes › Backlinks (fallback grep)",
      default_text = "[[" .. stem,
    }
  end
end
end

--------------------------------------------------
-- Autocmd: auto-rename on heading change
--------------------------------------------------
local function maybe_rename_note()
  if not config.auto_rename then
    return
  end
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
