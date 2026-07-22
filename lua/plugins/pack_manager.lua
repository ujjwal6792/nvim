local M = {}

local pack_path = vim.fn.stdpath("data") .. "/site/pack/core/opt"

local function get_plugin_dir_name(src)
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
  return vim.uv.fs_stat(path) ~= nil
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

function M.open()
  if not pcall(require, "snacks") then
    vim.notify("Snacks.nvim is required for PackManager", vim.log.levels.ERROR)
    return
  end

  local plugins = get_plugins()
  local items = {}
  for _, plugin in ipairs(plugins) do
    local icon = plugin.installed and "●" or "◌"
    local status = plugin.installed and "[installed]" or "[missing]"
    table.insert(items, {
      text = plugin.src .. " " .. plugin.name,
      plugin = plugin,
      _icon = icon,
      _status = status,
    })
  end

  Snacks.picker.pick({
    title = "󰏖 Pack Manager (Press ? for actions)",
    items = items,
    format = function(item, picker)
      local plugin = item.plugin
      return {
        { item._icon, plugin.installed and "DiagnosticOk" or "DiagnosticWarn" },
        { " " },
        { plugin.src:gsub("https://github.com/", ""), "String" },
        { " " },
        { item._status, "Comment" },
      }
    end,
    preview = function(ctx)
      local plugin = ctx.item.plugin
      if plugin.installed then
        local path = pack_path .. "/" .. plugin.name
        local readme = (
            vim.uv.fs_stat(path .. "/README.md") and (path .. "/README.md") or
            vim.uv.fs_stat(path .. "/README.mdx") and (path .. "/README.mdx") or
            vim.uv.fs_stat(path .. "/readme.md") and (path .. "/readme.md") or
            vim.uv.fs_stat(path .. "/README.MD") and (path .. "/README.MD")
        )
        if readme then
          local lines = vim.fn.readfile(readme)
          vim.bo[ctx.buf].modifiable = true
          vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
          vim.bo[ctx.buf].modifiable = false
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ctx.buf) then
              local ext = readme:match("^.+(%..+)$")
              if ext == ".mdx" then
                vim.bo[ctx.buf].filetype = "markdown.mdx"
              else
                vim.bo[ctx.buf].filetype = "markdown"
              end
            end
          end)
          return
        end
      end
      local lines = { "No README available (or plugin not installed)." }
      vim.bo[ctx.buf].modifiable = true
      vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
      vim.bo[ctx.buf].modifiable = false
    end,
    confirm = function(picker, item)
      local plugin = item.plugin
      if plugin.installed then
        vim.notify("Plugin " .. plugin.name .. " is already installed.", vim.log.levels.INFO)
        return
      end
      picker:close()
      vim.notify("Installing " .. plugin.name .. "...", vim.log.levels.INFO)
      
      local ok, err = pcall(vim.pack.add, { plugin.spec }, { load = false, confirm = false })
      if not ok then
         vim.notify("Install failed: " .. err, vim.log.levels.ERROR)
      else
         vim.notify("Installed " .. plugin.name, vim.log.levels.INFO)
      end
    end,
    win = {
      input = {
        keys = {
          ["<c-r>"] = { "remove_plugin", mode = { "i", "n" }, desc = "Remove Plugin" },
          ["<c-u>"] = { "update_plugin", mode = { "i", "n" }, desc = "Update Plugin" },
          ["<c-o>"] = { "open_github", mode = { "i", "n" }, desc = "Open GitHub" },
          ["<c-y>"] = { "copy_url", mode = { "i", "n" }, desc = "Copy URL" },
        }
      }
    },
    actions = {
      remove_plugin = function(picker, item)
        if not item then return end
        local plugin = item.plugin
        if not plugin.installed then
          vim.notify("Plugin " .. plugin.name .. " is not installed.", vim.log.levels.WARN)
          return
        end
        local path = pack_path .. "/" .. plugin.name
        vim.ui.select({ "Yes", "No" }, {
          prompt = "Delete plugin " .. plugin.name .. "?",
          format_item = function(item) return item end,
        }, function(choice)
          if choice == "Yes" then
            if execute_command({ "rm", "-rf", path }) then
              vim.notify("Removed " .. plugin.name, vim.log.levels.INFO)
              picker:close()
              M.open()
            end
          end
        end)
      end,
      update_plugin = function(picker, item)
        if not item then return end
        local plugin = item.plugin
        if not plugin.installed then return end
        picker:close()
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
      end,
      open_github = function(picker, item)
        if not item then return end
        execute_command({ "open", item.plugin.src })
      end,
      copy_url = function(picker, item)
        if not item then return end
        vim.fn.setreg("+", item.plugin.src)
        vim.notify("Copied " .. item.plugin.src .. " to clipboard", vim.log.levels.INFO)
      end,
    },
  })
end

vim.api.nvim_create_user_command("PackManager", function()
  M.open()
end, { desc = "Open Snacks pack manager" })

return M
