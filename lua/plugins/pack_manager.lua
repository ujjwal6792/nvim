local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local M = {}

local pack_path = vim.fn.stdpath("data") .. "/site/pack/core/opt"

local function get_plugin_dir_name(src)
  -- extract the repo name from the github url
  local parts = {}
  for part in string.gmatch(src, "[^/]+") do
    table.insert(parts, part)
  end
  if #parts > 0 then
    local name = parts[#parts]
    if name:sub(-4) == ".git" then
      name = name:sub(1, -5)
    end
    return name
  end
  return ""
end

local function is_installed(name)
  local path = pack_path .. "/" .. name
  return vim.loop.fs_stat(path) ~= nil
end

local function get_plugins()
  local pack = require "configs.pack"
  local plugins = {}
  for _, spec in ipairs(pack.specs) do
    local dir_name = spec.name or get_plugin_dir_name(spec.src)
    table.insert(plugins, {
      src = spec.src,
      name = dir_name,
      installed = is_installed(dir_name),
      spec = spec
    })
  end
  return plugins
end

local function execute_command(cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd, text = true }):wait()
  if result.code ~= 0 then
    vim.notify("Command failed: " .. table.concat(cmd, " ") .. "\n" .. (result.stderr or ""), vim.log.levels.ERROR)
    return false
  end
  return true
end

function M.open(opts)
  opts = opts or {}
  local plugins = get_plugins()

  pickers.new(opts, {
    prompt_title = "Pack Manager (Press <C-/> for actions)",
    finder = finders.new_table {
      results = plugins,
      entry_maker = function(entry)
        local icon = entry.installed and "●" or "◌"
        local status = entry.installed and "[installed]" or "[missing]"
        local display = string.format("%s %-30s %-12s %s", icon, entry.src:gsub("https://github.com/", ""), status, entry.name)

        return {
          value = entry,
          display = display,
          ordinal = entry.src .. " " .. entry.name .. " " .. status,
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    previewer = previewers.new_buffer_previewer({
      title = "README",
      define_preview = function(self, entry, status)
        local plugin = entry.value
        if plugin.installed then
          local path = pack_path .. "/" .. plugin.name
          local readme = (
            vim.loop.fs_stat(path .. "/README.md") and (path .. "/README.md") or
            vim.loop.fs_stat(path .. "/README.mdx") and (path .. "/README.mdx") or
            vim.loop.fs_stat(path .. "/readme.md") and (path .. "/readme.md") or
            vim.loop.fs_stat(path .. "/README.MD") and (path .. "/README.MD")
          )
          
          if readme then
            conf.buffer_previewer_maker(readme, self.state.bufnr, {
              bufname = self.state.bufname,
              winid = self.state.winid,
            })
            
            vim.schedule(function()
              if vim.api.nvim_buf_is_valid(self.state.bufnr) then
                local ext = readme:match("^.+(%..+)$")
                if ext == ".mdx" then
                  vim.bo[self.state.bufnr].filetype = "markdown.mdx"
                else
                  vim.bo[self.state.bufnr].filetype = "markdown"
                end
              end
            end)
            return
          end
        end
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "No README available (or plugin not installed)." })
      end,
    }),
    attach_mappings = function(prompt_bufnr, map)
      -- Install (if missing) / no-op (if installed)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if not selection then return end
        local plugin = selection.value

        if plugin.installed then
          vim.notify("Plugin " .. plugin.name .. " is already installed.", vim.log.levels.INFO)
          return
        end

        actions.close(prompt_bufnr)
        vim.notify("Installing " .. plugin.name .. "...", vim.log.levels.INFO)
        
        -- use vim.pack.add for this specific plugin
        local ok, err = pcall(vim.pack.add, { plugin.spec }, { load = false, confirm = false })
        if not ok then
           vim.notify("Install failed: " .. err, vim.log.levels.ERROR)
        else
           vim.notify("Installed " .. plugin.name, vim.log.levels.INFO)
        end
      end)

      -- Remove
      map("i", "<C-r>", function()
        local selection = action_state.get_selected_entry()
        if not selection then return end
        local plugin = selection.value

        if not plugin.installed then
          vim.notify("Plugin " .. plugin.name .. " is not installed.", vim.log.levels.WARN)
          return
        end

        local path = pack_path .. "/" .. plugin.name
        local choice = vim.fn.confirm("Delete plugin " .. plugin.name .. "?", "&Yes\n&No", 2)
        if choice == 1 then
          if execute_command({ "rm", "-rf", path }) then
            vim.notify("Removed " .. plugin.name, vim.log.levels.INFO)
            actions.close(prompt_bufnr)
            M.open() -- reopen to refresh
          end
        end
      end, { desc = "Remove selected plugin" })

      -- Update
      map("i", "<C-u>", function()
        local selection = action_state.get_selected_entry()
        if not selection then return end
        local plugin = selection.value

        if not plugin.installed then
          vim.notify("Plugin " .. plugin.name .. " is not installed.", vim.log.levels.WARN)
          return
        end

        actions.close(prompt_bufnr)
        vim.notify("Updating " .. plugin.name .. "...", vim.log.levels.INFO)
        local path = pack_path .. "/" .. plugin.name
        
        vim.system({ "git", "pull" }, { cwd = path, text = true }, function(result)
          vim.schedule(function()
            if result.code == 0 then
              vim.notify("Updated " .. plugin.name .. "\n" .. result.stdout, vim.log.levels.INFO)
            else
               vim.notify("Failed to update " .. plugin.name .. "\n" .. result.stderr, vim.log.levels.ERROR)
            end
          end)
        end)
      end, { desc = "Update selected plugin (git pull)" })

      -- Open GitHub URL in browser
      map("i", "<C-o>", function()
        local selection = action_state.get_selected_entry()
        if not selection then return end
        local plugin = selection.value
        execute_command({ "open", plugin.src })
      end, { desc = "Open GitHub URL in browser" })
      
      -- Copy source URL to clipboard
      map("i", "<C-y>", function()
        local selection = action_state.get_selected_entry()
        if not selection then return end
        local plugin = selection.value
        vim.fn.setreg("+", plugin.src)
        vim.notify("Copied " .. plugin.src .. " to clipboard", vim.log.levels.INFO)
      end, { desc = "Copy plugin source URL to clipboard" })

      -- Toggle enabled/disabled (placeholder for future implementation)
      map("i", "<C-t>", function()
         vim.notify("Toggle disabled state not yet implemented in vim.pack", vim.log.levels.WARN)
      end, { desc = "Toggle plugin enabled state" })

      return true
    end,
  }):find()
end

-- Register as extension
local ok_telescope, telescope = pcall(require, "telescope")
if ok_telescope then
  telescope.register_extension {
    exports = {
      pack_manager = M.open,
    },
  }
end

vim.api.nvim_create_user_command("PackManager", function()
  M.open()
end, { desc = "Open Telescope pack manager" })

return M
