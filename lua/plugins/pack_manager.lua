local M = {}

local function plugin_name(spec)
  return spec.name or vim.fs.basename(spec.src):gsub("%.git$", "")
end

local function declared_plugins()
  local declared = {}
  for _, spec in ipairs(require("configs.pack").specs) do
    declared[plugin_name(spec)] = true
  end
  return declared
end

local function plugins()
  local declared = declared_plugins()
  local items = {}
  local ok, managed = pcall(vim.pack.get, nil, { offline = false })
  if not ok then
    vim.notify("Could not read vim.pack state: " .. managed, vim.log.levels.ERROR)
    return items
  end

  for _, plugin in ipairs(managed) do
    local name = plugin.spec.name
    items[#items + 1] = {
      name = name,
      src = plugin.spec.src,
      text = name .. " " .. plugin.spec.src,
      rev = plugin.rev,
      rev_to = plugin.rev_to,
      active = plugin.active,
      orphaned = not declared[name],
      pending = plugin.rev_to and plugin.rev_to ~= plugin.rev,
    }
  end

  table.sort(items, function(a, b)
    local function rank(plugin)
      if plugin.pending then return 1 end
      if plugin.orphaned then return 2 end
      return 3
    end
    local a_rank, b_rank = rank(a), rank(b)
    return a_rank == b_rank and a.name < b.name or a_rank < b_rank
  end)
  return items
end

local function status(plugin)
  if plugin.orphaned then
    return "stale lockfile entry", "DiagnosticWarn", "!"
  end
  if plugin.pending then
    return "update available", "DiagnosticInfo", "^"
  end
  if not plugin.active then
    return "installed", "Comment", "o"
  end
  return "ready to review", "Comment", "?"
end

local function revision(rev)
  return rev and rev:sub(1, 8) or "unknown"
end

function M.open()
  local ok, Snacks = pcall(require, "snacks")
  if not ok then
    vim.notify("Snacks.nvim is required for PackManager", vim.log.levels.ERROR)
    return
  end

  Snacks.picker.pick({
    title = "Packages (? for actions; <C-u> review, <M-u> update now)",
    items = plugins(),
    format = function(plugin)
      local label, highlight, icon = status(plugin)
      local target = plugin.rev_to and { " -> " .. revision(plugin.rev_to), "DiagnosticInfo" } or {}
      return {
        { icon, highlight },
        { " " },
        { plugin.name, "String" },
        { " " },
        { label, highlight },
        { " " },
        { revision(plugin.rev), "Comment" },
        target,
      }
    end,
    preview = function(ctx)
      local plugin = ctx.item
      local label = status(plugin)
      local lines = {
        plugin.src,
        "",
        "Status: " .. label,
        "Current revision: " .. revision(plugin.rev),
        "Target revision: " .. revision(plugin.rev_to),
        "",
        plugin.orphaned
            and "This package is only in nvim-pack-lock.json. Remove it if it is no longer intentional."
          or "Press <C-u> to open vim.pack's native review buffer with commit details.",
      }
      vim.bo[ctx.buf].modifiable = true
      vim.api.nvim_buf_set_lines(ctx.buf, 0, -1, false, lines)
      vim.bo[ctx.buf].modifiable = false
    end,
    confirm = function(picker, plugin)
      if plugin.orphaned then
        vim.notify("This is a stale lockfile entry. Use <C-r> to remove it.", vim.log.levels.WARN)
        return
      end
      picker:close()
      local spec = vim.iter(require("configs.pack").specs):find(function(candidate)
        return plugin_name(candidate) == plugin.name
      end)
      local add_ok, err = pcall(vim.pack.add, { spec }, { load = false, confirm = false })
      if not add_ok then
        vim.notify("Install failed: " .. err, vim.log.levels.ERROR)
      else
        vim.notify("Installed " .. plugin.name, vim.log.levels.INFO)
      end
    end,
    win = {
      input = {
        keys = {
          ["<c-r>"] = { "remove_plugin", mode = { "i", "n" }, desc = "Remove Plugin" },
          ["<c-u>"] = { "update_plugin", mode = { "i", "n" }, desc = "Review Plugin Update" },
          ["<c-a>"] = { "update_all", mode = { "i", "n" }, desc = "Review All Updates" },
          ["<m-u>"] = { "update_plugin_now", mode = { "i", "n" }, desc = "Update Plugin Now" },
          ["<m-a>"] = { "update_all_now", mode = { "i", "n" }, desc = "Update All Now" },
          ["<c-o>"] = { "open_github", mode = { "i", "n" }, desc = "Open Source" },
          ["<c-y>"] = { "copy_url", mode = { "i", "n" }, desc = "Copy Source URL" },
        },
      },
    },
    actions = {
      remove_plugin = function(picker, plugin)
        if not plugin then return end
        vim.ui.select({ "Yes", "No" }, { prompt = "Remove " .. plugin.name .. " with vim.pack?" }, function(choice)
          if choice ~= "Yes" then return end
          local del_ok, err = pcall(vim.pack.del, { plugin.name }, { force = true })
          if not del_ok then
            vim.notify("Removal failed: " .. err, vim.log.levels.ERROR)
            return
          end
          vim.notify("Removed " .. plugin.name, vim.log.levels.INFO)
          picker:close()
          M.open()
        end)
      end,
      update_plugin = function(picker, plugin)
        if not plugin then return end
        if plugin.orphaned then
          vim.notify("Stale lockfile entries cannot be updated.", vim.log.levels.WARN)
          return
        end
        picker:close()
        vim.pack.update({ plugin.name })
      end,
      update_all = function(picker)
        picker:close()
        vim.pack.update()
      end,
      update_plugin_now = function(picker, plugin)
        if not plugin then return end
        if plugin.orphaned then
          vim.notify("Stale lockfile entries cannot be updated.", vim.log.levels.WARN)
          return
        end
        picker:close()
        local ok, err = pcall(vim.pack.update, { plugin.name }, { force = true })
        if not ok then
          vim.notify("Update failed: " .. err, vim.log.levels.ERROR)
          return
        end
        vim.notify("Updated " .. plugin.name .. "; restart Neovim to load the new revision.", vim.log.levels.INFO)
      end,
      update_all_now = function(picker)
        picker:close()
        local ok, err = pcall(vim.pack.update, nil, { force = true })
        if not ok then
          vim.notify("Update failed: " .. err, vim.log.levels.ERROR)
          return
        end
        vim.notify("Updated packages; restart Neovim to load new revisions.", vim.log.levels.INFO)
      end,
      open_github = function(_, plugin)
        if plugin then vim.ui.open(plugin.src) end
      end,
      copy_url = function(_, plugin)
        if not plugin then return end
        vim.fn.setreg("+", plugin.src)
        vim.notify("Copied " .. plugin.src .. " to clipboard", vim.log.levels.INFO)
      end,
    },
  })
end

vim.api.nvim_create_user_command("PackManager", M.open, { desc = "Open package manager" })

return M
